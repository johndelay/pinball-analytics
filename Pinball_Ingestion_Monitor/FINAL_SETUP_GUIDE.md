# ✅ FINAL Setup Guide - Pinball API Snapshot Monitor

## 🎯 Understanding Your Data Model

After reviewing your schema, here's what's actually happening:

### Your Tables:
- **`events`** - Tournament/event configuration (metadata only)
  - `event_code` - Tournament ID (e.g., "STERN_LEAGUE")
  - `event_name`, `start_date`, `stop_date` - Event details
  - **NOT the ingestion target!**

- **`api_snapshots`** - ✅ **ACTUAL INGESTION TABLE**
  - `snapshot_id` - Auto-incrementing primary key
  - `event_code` - Which tournament this snapshot is for
  - `fetched_at` - **Timestamp when API was called** (THIS is what we monitor!)
  - `raw_response` - JSONB containing the actual leaderboard data

### Your Ingestion Flow:
```
n8n Workflow (hourly)
    ↓
Calls External API
    ↓
Stores raw JSON in api_snapshots.raw_response
    ↓
Sets fetched_at = NOW()
```

---

## 🔧 What This Workflow Monitors

### Primary Check: API Snapshot Freshness
**Monitors:** `api_snapshots` table, `fetched_at` column  
**Alert Threshold:** 90 minutes without a new snapshot  
**Check Frequency:** Every 15 minutes

### Secondary Checks:
1. **24-hour snapshot pattern** - How many snapshots per hour
2. **Data quality** - Is the JSONB response valid/empty?
3. **Active events** - Which tournaments are being tracked

---

## ⚡ Setup (5 Minutes)

### 1. Import the Workflow
1. Import `Pinball_Ingestion_Monitor_FINAL.json` into n8n

### 2. Configure PostgreSQL Credentials (4 nodes)
Update these nodes with your PostgreSQL credential:
- ✅ "Check Recent Snapshots"
- ✅ "Get 24hr Stats"
- ✅ "Check Data Quality"
- ✅ "Check Active Events"

Click each node → Parameters → Credentials → Select your credential

### 3. Test
1. Click "Execute Workflow"
2. Verify all nodes return data
3. Check email formatting looks good

### 4. Activate
Toggle "Active" to start monitoring!

---

## 📊 SQL Queries Explained

### Main Health Check
```sql
SELECT 
    COUNT(*) as recent_snapshots,
    MAX(fetched_at) as last_snapshot,
    EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 as minutes_since_last
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '90 minutes';
```

**Alert Logic:**
- `recent_snapshots = 0` → FAILING (no snapshots in 90 min)
- `minutes_since_last >= 90` → FAILING (last snapshot too old)
- Otherwise → HEALTHY

### Data Quality Check
```sql
-- Checks if JSONB responses are valid
SELECT 
    snapshot_id,
    event_code,
    fetched_at,
    jsonb_typeof(raw_response) as response_type,
    jsonb_array_length(raw_response) as response_size,
    CASE 
        WHEN raw_response IS NULL THEN '❌ NULL'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) = 0 THEN '⚠️ EMPTY'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) > 0 THEN '✅ VALID'
        ELSE '⚠️ UNEXPECTED'
    END as data_quality
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '3 hours'
ORDER BY fetched_at DESC
LIMIT 5;
```

This catches issues like:
- API returning empty responses
- Null data being stored
- Unexpected response formats

### Active Events Check
```sql
-- Shows which tournaments are actively being tracked
SELECT 
    e.event_code,
    e.event_name,
    e.is_active,
    COUNT(a.snapshot_id) as snapshots_last_24h,
    MAX(a.fetched_at) as last_snapshot_for_event
FROM events e
LEFT JOIN api_snapshots a ON e.event_code = a.event_code 
    AND a.fetched_at > NOW() - INTERVAL '24 hours'
WHERE e.is_active = true
GROUP BY e.event_code, e.event_name, e.is_active
ORDER BY last_snapshot_for_event DESC NULLS LAST;
```

---

## 🚨 Alert Behavior

### Failure Alert Sent When:
- **No snapshots in last 90 minutes**, OR
- **Last snapshot was 90+ minutes ago**

### Recovery Alert Sent When:
- System was previously failing
- AND now has recent snapshots (< 90 minutes)

### State Tracking:
- Uses `/tmp/pinball_ingestion_state` file
- Prevents alert spam
- Only alerts on state changes

---

## 📧 What the Emails Look Like

### 🚨 Failure Alert Includes:
```
⚠️ Pinball API Ingestion Alert

Problem Detected:
- Recent Snapshots: 0 in last 90 minutes ⚠️
- Last Snapshot: 2024-10-31 14:23:45
- Minutes Since Last: 127 minutes ⚠️

Possible Issues:
- n8n workflow not running on schedule
- External API down or unreachable
- API credentials expired
- Database connection issues
- Network connectivity problems

Action Required:
1. Check n8n execution history
2. Verify workflow still scheduled hourly
3. Test API endpoint manually
4. Check PostgreSQL connection
5. Review error logs

[24-hour snapshot pattern shown]
```

### ✅ Recovery Alert Includes:
```
✅ API Ingestion Recovery

Current Status:
- Recent Snapshots: 2 in last 90 minutes
- Last Snapshot: 2024-10-31 16:05:12
- Minutes Since Last: 8 minutes
- Total Snapshots: 1,247
- Events Tracked: 3

The API ingestion has recovered!
```

---

## 🔍 Diagnostic Queries to Run

### Check Current Status
```sql
-- What's happening right now?
SELECT 
    COUNT(*) as snapshots_last_90_min,
    MAX(fetched_at) as last_snapshot,
    EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 as minutes_ago,
    CASE 
        WHEN MAX(fetched_at) > NOW() - INTERVAL '90 minutes' 
        THEN '✅ HEALTHY'
        ELSE '⚠️ STALE'
    END as status
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '90 minutes';
```

### Check 24-Hour Pattern
```sql
-- When are snapshots actually coming in?
SELECT 
    DATE_TRUNC('hour', fetched_at) as hour,
    COUNT(*) as snapshot_count,
    array_agg(DISTINCT event_code) as events
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

### Check Recent Snapshots
```sql
-- Show me the last 5 snapshots
SELECT 
    snapshot_id,
    event_code,
    fetched_at,
    EXTRACT(EPOCH FROM (NOW() - fetched_at))/60 as minutes_ago,
    jsonb_typeof(raw_response) as response_type,
    CASE 
        WHEN jsonb_typeof(raw_response) = 'array' 
        THEN jsonb_array_length(raw_response)
        ELSE NULL
    END as response_size
FROM api_snapshots
ORDER BY fetched_at DESC
LIMIT 5;
```

### Check for Empty Responses
```sql
-- Find snapshots with no data (potential API issues)
SELECT 
    snapshot_id,
    event_code,
    fetched_at,
    CASE 
        WHEN raw_response IS NULL THEN 'NULL'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) = 0 THEN 'EMPTY ARRAY'
        ELSE 'OK'
    END as issue
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
    AND (
        raw_response IS NULL 
        OR (jsonb_typeof(raw_response) = 'array' 
            AND jsonb_array_length(raw_response) = 0)
    )
ORDER BY fetched_at DESC;
```

---

## ⚙️ Configuration Summary

```yaml
Monitoring Target: api_snapshots table
Timestamp Column: fetched_at
Ingestion Schedule: Every 60 minutes
Alert Threshold: 90 minutes (60 + 30 buffer)
Check Frequency: Every 15 minutes
Alert Method: Gmail to john@thedelay.com
State Tracking: /tmp/pinball_ingestion_state
```

---

## 🎨 Customization Options

### Adjust Sensitivity (if getting false alarms)
**Increase threshold to 120 minutes:**

1. "Check Recent Snapshots" node:
   ```sql
   -- Change: INTERVAL '90 minutes'
   -- To: INTERVAL '120 minutes'
   ```

2. "Is Ingestion Healthy?" node:
   - Change condition: `< 90`
   - To: `< 120`

### When You Speed Up Ingestion
**If you run every 30 minutes instead of hourly:**

1. Change threshold from 90 to 45 minutes
2. Follow same steps as above but use `45`

---

## 🔍 Troubleshooting

### "PostgreSQL connection failed"
1. Check credentials in each node
2. Verify n8n can reach database
3. Test with: `SELECT 1;`

### "No recent snapshots" but ingestion is running
**Possible causes:**
1. n8n workflow not scheduled correctly
2. n8n workflow has errors (check execution history)
3. External API is down
4. API credentials expired
5. Network issues blocking API calls

**Debug steps:**
```sql
-- Check last 10 snapshots
SELECT * FROM api_snapshots 
ORDER BY fetched_at DESC LIMIT 10;

-- Check n8n workflow execution history in n8n UI
-- Look for errors or failed executions
```

### "Empty responses in api_snapshots"
If you see empty JSONB responses:
```sql
-- Find problematic snapshots
SELECT * FROM api_snapshots 
WHERE raw_response IS NULL 
   OR jsonb_array_length(raw_response) = 0
ORDER BY fetched_at DESC LIMIT 10;
```

This means:
- API is responding but with empty data
- Possibly tournament hasn't started yet
- Or API authentication issue

---

## 📈 Expected Behavior

### Healthy System (First 24 Hours):
- ✅ Snapshots every ~60 minutes
- ✅ No alerts (stays in "healthy" state)
- ✅ JSONB responses contain data
- ✅ All active events have recent snapshots

### If Ingestion Fails:
1. **First check** (after 90 min gap): Sends failure alert
2. **State changes** to "failing"
3. **Subsequent checks**: No more alerts (prevents spam)
4. **When recovered**: Sends recovery alert
5. **State changes** back to "healthy"

---

## 🚀 Next Steps After Setup

### 1. Monitor for 24 Hours
Let it run and see if you get any false alarms

### 2. Check Data Quality
Run the data quality query regularly:
```sql
SELECT 
    COUNT(*) as total_snapshots,
    COUNT(*) FILTER (WHERE raw_response IS NULL) as null_responses,
    COUNT(*) FILTER (WHERE jsonb_array_length(raw_response) = 0) as empty_responses,
    COUNT(*) FILTER (WHERE jsonb_array_length(raw_response) > 0) as valid_responses
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours';
```

### 3. Add More Checks (Optional)
Consider monitoring:
- **Players table** - Are new players being added?
- **Machines table** - Are machines being tracked?
- **Leaderboard cache** - Is cache being updated?

---

## 💡 Pro Tips

1. **Check your n8n workflow** - Make sure "Pinball Leaderboard Ingestion (Production - Working)" is:
   - Still active
   - Scheduled to run every hour
   - Not showing errors in execution history

2. **Understand your API** - Know what the external API returns:
   - Format of the JSONB response
   - When it returns empty vs. null
   - If it has rate limits

3. **Watch the pattern** - After 24 hours, check:
   ```sql
   -- See your actual pattern
   SELECT 
       DATE_TRUNC('hour', fetched_at) as hour,
       COUNT(*) as snapshots
   FROM api_snapshots
   WHERE fetched_at > NOW() - INTERVAL '7 days'
   GROUP BY hour
   ORDER BY hour DESC;
   ```

---

## ✅ Ready to Go!

**Checklist:**
- [x] Workflow imported
- [x] PostgreSQL credentials configured (4 nodes)
- [x] Test execution successful
- [x] Workflow activated
- [x] Email alerts configured
- [x] Understand what's being monitored

**You're monitoring:**
- ✅ `api_snapshots.fetched_at` - When snapshots are captured
- ✅ Data quality - JSONB response validity
- ✅ 24-hour pattern - Hourly snapshot counts
- ✅ Active events - Which tournaments are tracked

**Alert triggers:**
- 🚨 No snapshots for 90+ minutes
- ✅ Recovery when snapshots resume

---

Now your ingestion pipeline has proper monitoring! 🎉
