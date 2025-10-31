# 🎯 Pinball API Snapshot Monitor - Complete Package

## 📋 What You Got

Complete monitoring solution for your Pinball Leaderboard API ingestion pipeline!

### Files:
1. **`Pinball_Ingestion_Monitor_FINAL.json`** - n8n workflow (import this!)
2. **`FINAL_SETUP_GUIDE.md`** - Complete setup instructions
3. **`API_SNAPSHOT_VERIFICATION.sql`** - Diagnostic queries to run now

---

## 🎯 What This Monitors

Your n8n workflow calls an external API every hour and stores the results in PostgreSQL:

```
External API (Pinball Leaderboard)
        ↓
    n8n Workflow (hourly)
        ↓
  api_snapshots table
  - fetched_at (timestamp)
  - raw_response (JSONB data)
```

**This monitor watches the `api_snapshots` table and alerts if:**
- ❌ No snapshots for 90+ minutes
- ❌ Last snapshot was 90+ minutes ago
- ✅ Sends recovery alert when snapshots resume

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Verify Current Health (1 min)
Open `API_SNAPSHOT_VERIFICATION.sql` and run **Query #1** in PostgreSQL:

```sql
-- Shows if ingestion is currently working
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

**Expected result:** Status should be "✅ HEALTHY"

### Step 2: Import Workflow (2 min)
1. Open n8n
2. Click "Import from File"
3. Select `Pinball_Ingestion_Monitor_FINAL.json`
4. Update PostgreSQL credentials in **4 nodes**:
   - "Check Recent Snapshots"
   - "Get 24hr Stats"
   - "Check Data Quality"
   - "Check Active Events"

### Step 3: Test & Activate (2 min)
1. Click "Execute Workflow" to test
2. Verify all nodes return data
3. Toggle "Active" to start monitoring

**Done!** You'll get Gmail alerts if ingestion fails.

---

## 📊 Your Database Structure

```
events (tournament configuration)
├── event_code (PK)
├── event_name
├── start_date
├── stop_date
└── is_active

api_snapshots (INGESTION DATA) ← Monitored by workflow
├── snapshot_id (PK)
├── event_code (FK → events)
├── fetched_at ← KEY TIMESTAMP
└── raw_response (JSONB) ← Leaderboard data

players (player information)
machines (pinball machine data)
leaderboard_cache (cached results)
... other tables ...
```

---

## 🚨 How Alerts Work

### Alert Trigger Logic:
```
Every 15 minutes:
  Check api_snapshots table
  
  IF no snapshots in last 90 minutes
    OR last snapshot > 90 minutes ago
  THEN
    IF not already in "failing" state
      Send failure alert via Gmail
      Mark state as "failing"
    END IF
  ELSE
    IF previously in "failing" state
      Send recovery alert via Gmail
      Mark state as "healthy"
    END IF
  END IF
```

### Why 90 Minutes?
- Your ingestion runs **every 60 minutes**
- 90 minutes = 60 + 30 minute buffer
- Avoids false alarms from slight delays

---

## 📧 Email Alerts

### 🚨 Failure Alert Contains:
```
Subject: 🚨 ALERT: Pinball API Ingestion Failure

⚠️ Pinball API Ingestion Alert
Status: API snapshots are NOT being captured
Time: 2024-10-31 14:35:22

Problem Detected:
- Recent Snapshots: 0 in last 90 minutes ⚠️
- Last Snapshot: 2024-10-31 12:45:18
- Minutes Since Last: 110 minutes ⚠️

Possible Issues:
- n8n workflow not running on schedule
- External API down
- Database connection issues
- [... more diagnostics ...]

Action Required:
1. Check n8n execution history
2. Verify workflow schedule
3. Test API endpoint
[... detailed troubleshooting steps ...]

[Shows 24-hour snapshot pattern]
```

### ✅ Recovery Alert Contains:
```
Subject: ✅ Pinball API Ingestion Recovered

✅ API Ingestion Recovery
Status: API snapshots are being captured normally
Time: 2024-10-31 16:15:33

Current Status:
- Recent Snapshots: 2 in last 90 minutes
- Last Snapshot: 2024-10-31 16:12:45
- Minutes Since Last: 3 minutes
- Total Snapshots: 1,247
- Events Tracked: 3

The API ingestion has recovered!
```

---

## 🔍 Diagnostic Queries

Run these in PostgreSQL to understand your ingestion:

### Current Status
```sql
SELECT 
    MAX(fetched_at) as last_snapshot,
    EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 as minutes_ago
FROM api_snapshots;
```

### 24-Hour Pattern
```sql
SELECT 
    DATE_TRUNC('hour', fetched_at) as hour,
    COUNT(*) as snapshots
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```
**Expected:** ~1 snapshot per hour for last 24 hours

### Recent Snapshots
```sql
SELECT 
    snapshot_id,
    event_code,
    fetched_at,
    EXTRACT(EPOCH FROM (NOW() - fetched_at))/60 as minutes_ago
FROM api_snapshots
ORDER BY fetched_at DESC
LIMIT 5;
```
**Expected:** 5 most recent snapshots, ~60 minutes apart

---

## ⚙️ Configuration

```yaml
What:     Monitors api_snapshots.fetched_at
When:     Checks every 15 minutes
Alert:    If 90+ minutes without snapshot
Notify:   Gmail to john@thedelay.com
State:    /tmp/pinball_ingestion_state
```

### Nodes in Workflow:
1. **Check Every 15 Minutes** - Schedule trigger
2. **Check Recent Snapshots** - Main health query
3. **Get 24hr Stats** - Hourly pattern analysis
4. **Check Data Quality** - JSONB validation
5. **Check Active Events** - Which tournaments tracked
6. **Is Ingestion Healthy?** - Decision logic
7. **Check Previous State** - State tracking
8. **Was Previously Failing?** - Prevent spam
9. **Gmail Failure Alert** - Send failure email
10. **Gmail Recovery Alert** - Send recovery email
11. **Mark as Failing/Healthy** - Update state

---

## 🔧 Customization

### Adjust Alert Threshold

**If you get false alarms** (increase to 120 minutes):

1. "Check Recent Snapshots" node:
   ```sql
   WHERE fetched_at > NOW() - INTERVAL '120 minutes';
   ```

2. "Is Ingestion Healthy?" node:
   - Change: `< 90` 
   - To: `< 120`

**If you speed up ingestion to 30 minutes:**

1. Change threshold from 90 to 45 minutes
2. Follow same steps above

### Change Check Frequency

**"Check Every 15 Minutes" node:**
- Current: 15 minutes
- Change to: 5, 10, 30, or 60 minutes

---

## 🔍 Troubleshooting

### "No recent snapshots" alert but ingestion is running

**Debug:**
1. Check n8n execution history
2. Look for errors in workflow
3. Verify workflow schedule
4. Check api_snapshots table:
   ```sql
   SELECT * FROM api_snapshots 
   ORDER BY fetched_at DESC LIMIT 5;
   ```

### "Empty JSONB responses"

**Check data quality:**
```sql
SELECT 
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE raw_response IS NULL) as nulls,
    COUNT(*) FILTER (WHERE jsonb_array_length(raw_response) = 0) as empty
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours';
```

If seeing empty responses:
- API might be down
- Tournament hasn't started
- Authentication issue

### "PostgreSQL connection failed"

1. Verify credentials in each node
2. Test database connection: `SELECT 1;`
3. Check n8n can reach PostgreSQL

---

## 📈 What Success Looks Like

### After 24 Hours of Monitoring:

✅ **Healthy System:**
- No alerts received
- Query #1 shows "✅ HEALTHY"
- Query #3 shows ~24 snapshots (one per hour)
- No gaps in hourly pattern

❌ **If You Get Alerts:**
1. Check n8n workflow execution history
2. Verify external API is accessible
3. Review error logs
4. Manually trigger ingestion workflow

---

## 🎨 Optional Enhancements

### Add Slack Notifications
1. Add Slack node alongside Gmail nodes
2. Use same message format
3. Connect after "Was Previously Failing?"

### Monitor Data Quality
Add alert if too many empty responses:
```sql
SELECT COUNT(*) 
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '6 hours'
  AND jsonb_array_length(raw_response) = 0;
```

### Daily Summary Report
New schedule trigger at 9am:
```sql
SELECT 
    COUNT(*) as snapshots_yesterday,
    COUNT(DISTINCT event_code) as events_tracked,
    MIN(fetched_at) as first_snapshot,
    MAX(fetched_at) as last_snapshot
FROM api_snapshots
WHERE fetched_at::date = CURRENT_DATE - 1;
```

---

## 📁 File Reference

### Workflow
- **`Pinball_Ingestion_Monitor_FINAL.json`**
  - Import into n8n
  - Configure 4 PostgreSQL credentials
  - Activate

### Documentation
- **`FINAL_SETUP_GUIDE.md`**
  - Detailed setup instructions
  - SQL query explanations
  - Troubleshooting guide
  - Customization options

- **`API_SNAPSHOT_VERIFICATION.sql`**
  - 10 diagnostic queries
  - Run these to verify health
  - Interpret results
  - Identify issues

---

## ✅ Setup Checklist

- [ ] Run Query #1 to verify current health
- [ ] Import workflow into n8n
- [ ] Configure PostgreSQL credentials (4 nodes)
- [ ] Test workflow execution
- [ ] Verify all queries return data
- [ ] Activate workflow
- [ ] Wait for first check (15 minutes)
- [ ] Monitor for 24 hours
- [ ] Adjust thresholds if needed

---

## 🆘 Need Help?

### Quick Health Check
```sql
-- Run this right now to see current status
SELECT 
    'Last Snapshot' as metric,
    MAX(fetched_at)::text as value
FROM api_snapshots
UNION ALL
SELECT 
    'Minutes Ago',
    ROUND(EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60, 2)::text
FROM api_snapshots
UNION ALL
SELECT 
    'Status',
    CASE 
        WHEN MAX(fetched_at) > NOW() - INTERVAL '90 minutes' 
        THEN '✅ HEALTHY'
        ELSE '⚠️ FAILING'
    END
FROM api_snapshots;
```

### Check n8n Workflow
1. Open n8n
2. Find "Pinball Leaderboard Ingestion (Production - Working)"
3. Click "Executions" tab
4. Look for recent runs
5. Check for errors

---

## 🎉 You're All Set!

**You now have:**
✅ Automated monitoring every 15 minutes  
✅ Gmail alerts for failures and recovery  
✅ Smart state tracking (no spam)  
✅ Data quality checks  
✅ 24-hour pattern analysis  
✅ Comprehensive diagnostics  

**Next:** Monitor for 24 hours and adjust thresholds if needed!

---

**Questions?** Everything is documented in `FINAL_SETUP_GUIDE.md`  
**Problems?** Run queries in `API_SNAPSHOT_VERIFICATION.sql`  
**Working?** Activate and forget about it! 🚀
