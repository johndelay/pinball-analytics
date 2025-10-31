# API Snapshot Verification Queries
-- Run these to verify your current ingestion health

-- ===================================
-- 1. CURRENT STATUS (Run this first!)
-- ===================================
SELECT 
    COUNT(*) as snapshots_last_90_min,
    MAX(fetched_at) as last_snapshot,
    EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 as minutes_ago,
    CASE 
        WHEN MAX(fetched_at) > NOW() - INTERVAL '90 minutes' 
        THEN '✅ HEALTHY - Ingestion is working'
        ELSE '⚠️ STALE - Ingestion may be failing'
    END as status,
    CASE 
        WHEN EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 < 60 
        THEN 'On schedule'
        WHEN EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 < 90 
        THEN 'Slightly delayed but OK'
        ELSE 'ALERT: Overdue for snapshot!'
    END as schedule_status
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '90 minutes';

-- ===================================
-- 2. RECENT SNAPSHOTS (Last 5)
-- ===================================
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
    END as num_records_in_response,
    CASE 
        WHEN raw_response IS NULL THEN '❌ NULL RESPONSE'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) = 0 THEN '⚠️ EMPTY ARRAY'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) > 0 THEN '✅ HAS DATA'
        ELSE '⚠️ UNEXPECTED FORMAT'
    END as data_quality
FROM api_snapshots
ORDER BY fetched_at DESC
LIMIT 5;

-- ===================================
-- 3. 24-HOUR PATTERN
-- ===================================
SELECT 
    DATE_TRUNC('hour', fetched_at) as hour,
    COUNT(*) as snapshots_in_hour,
    COUNT(DISTINCT event_code) as unique_events,
    array_agg(DISTINCT event_code) as event_codes,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ NO SNAPSHOTS'
        WHEN COUNT(*) = 1 THEN '✅ NORMAL (1 per hour)'
        WHEN COUNT(*) > 1 THEN '⚠️ MULTIPLE (' || COUNT(*) || ')'
        ELSE '?'
    END as hourly_status
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', fetched_at)
ORDER BY hour DESC;

-- ===================================
-- 4. CHECK FOR GAPS (Missing Hours)
-- ===================================
WITH hourly_snapshots AS (
    SELECT 
        DATE_TRUNC('hour', fetched_at) as hour,
        COUNT(*) as snapshot_count
    FROM api_snapshots
    WHERE fetched_at > NOW() - INTERVAL '48 hours'
    GROUP BY DATE_TRUNC('hour', fetched_at)
),
expected_hours AS (
    SELECT generate_series(
        DATE_TRUNC('hour', NOW() - INTERVAL '48 hours'),
        DATE_TRUNC('hour', NOW()),
        '1 hour'::interval
    ) as hour
)
SELECT 
    e.hour,
    COALESCE(h.snapshot_count, 0) as snapshots,
    CASE 
        WHEN COALESCE(h.snapshot_count, 0) = 0 THEN '❌ GAP - No snapshots this hour'
        WHEN h.snapshot_count = 1 THEN '✅ Normal'
        ELSE '⚠️ Multiple snapshots'
    END as status
FROM expected_hours e
LEFT JOIN hourly_snapshots h ON e.hour = h.hour
WHERE COALESCE(h.snapshot_count, 0) = 0  -- Only show gaps
ORDER BY e.hour DESC
LIMIT 20;

-- ===================================
-- 5. DATA QUALITY CHECK
-- ===================================
SELECT 
    COUNT(*) as total_snapshots_24h,
    COUNT(*) FILTER (WHERE raw_response IS NULL) as null_responses,
    COUNT(*) FILTER (WHERE jsonb_typeof(raw_response) = 'array' 
                     AND jsonb_array_length(raw_response) = 0) as empty_responses,
    COUNT(*) FILTER (WHERE jsonb_typeof(raw_response) = 'array' 
                     AND jsonb_array_length(raw_response) > 0) as valid_responses,
    ROUND(100.0 * COUNT(*) FILTER (WHERE jsonb_typeof(raw_response) = 'array' 
          AND jsonb_array_length(raw_response) > 0) / COUNT(*), 2) as pct_valid
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours';

-- ===================================
-- 6. ACTIVE EVENTS BEING TRACKED
-- ===================================
SELECT 
    e.event_code,
    e.event_name,
    e.event_type,
    e.is_active,
    e.start_date,
    e.stop_date,
    (SELECT COUNT(*) 
     FROM api_snapshots a 
     WHERE a.event_code = e.event_code 
       AND a.fetched_at > NOW() - INTERVAL '24 hours') as snapshots_last_24h,
    (SELECT MAX(fetched_at) 
     FROM api_snapshots a 
     WHERE a.event_code = e.event_code) as last_snapshot,
    CASE 
        WHEN (SELECT MAX(fetched_at) FROM api_snapshots a 
              WHERE a.event_code = e.event_code) > NOW() - INTERVAL '90 minutes' 
        THEN '✅ Recent'
        WHEN (SELECT MAX(fetched_at) FROM api_snapshots a 
              WHERE a.event_code = e.event_code) IS NULL 
        THEN '❌ Never captured'
        ELSE '⚠️ Stale'
    END as event_status
FROM events e
WHERE e.is_active = true
ORDER BY last_snapshot DESC NULLS LAST;

-- ===================================
-- 7. OVERALL DATABASE STATISTICS
-- ===================================
SELECT 
    'api_snapshots' as table_name,
    (SELECT COUNT(*) FROM api_snapshots) as total_records,
    (SELECT MAX(fetched_at) FROM api_snapshots) as latest_record,
    (SELECT MIN(fetched_at) FROM api_snapshots) as oldest_record,
    EXTRACT(EPOCH FROM (NOW() - (SELECT MAX(fetched_at) FROM api_snapshots)))/60 as minutes_since_latest
UNION ALL
SELECT 
    'events',
    (SELECT COUNT(*) FROM events),
    NULL,
    NULL,
    NULL
UNION ALL
SELECT 
    'players',
    (SELECT COUNT(*) FROM players),
    NULL,
    NULL,
    NULL
UNION ALL
SELECT 
    'machines',
    (SELECT COUNT(*) FROM machines),
    NULL,
    NULL,
    NULL;

-- ===================================
-- 8. PROBLEM SNAPSHOTS (Last 24h)
-- ===================================
-- Finds snapshots with issues
SELECT 
    snapshot_id,
    event_code,
    fetched_at,
    EXTRACT(EPOCH FROM (NOW() - fetched_at))/60 as minutes_ago,
    CASE 
        WHEN raw_response IS NULL THEN '❌ NULL - API returned nothing'
        WHEN jsonb_typeof(raw_response) = 'array' 
             AND jsonb_array_length(raw_response) = 0 
             THEN '⚠️ EMPTY - API returned empty array'
        WHEN jsonb_typeof(raw_response) != 'array' 
             THEN '⚠️ WRONG TYPE - Expected array, got ' || jsonb_typeof(raw_response)
        ELSE 'Unknown issue'
    END as issue_description
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
  AND (
      raw_response IS NULL 
      OR (jsonb_typeof(raw_response) = 'array' 
          AND jsonb_array_length(raw_response) = 0)
      OR jsonb_typeof(raw_response) != 'array'
  )
ORDER BY fetched_at DESC;

-- ===================================
-- 9. INGESTION FREQUENCY ANALYSIS
-- ===================================
-- Shows actual time between snapshots
WITH snapshot_times AS (
    SELECT 
        snapshot_id,
        event_code,
        fetched_at,
        LAG(fetched_at) OVER (ORDER BY fetched_at) as previous_fetched_at,
        EXTRACT(EPOCH FROM (fetched_at - LAG(fetched_at) 
                OVER (ORDER BY fetched_at)))/60 as minutes_since_previous
    FROM api_snapshots
    WHERE fetched_at > NOW() - INTERVAL '48 hours'
)
SELECT 
    COUNT(*) as total_snapshots,
    ROUND(AVG(minutes_since_previous), 2) as avg_minutes_between,
    ROUND(MIN(minutes_since_previous), 2) as min_gap,
    ROUND(MAX(minutes_since_previous), 2) as max_gap,
    CASE 
        WHEN AVG(minutes_since_previous) BETWEEN 55 AND 65 
        THEN '✅ Averaging ~60 minutes (hourly)'
        WHEN AVG(minutes_since_previous) BETWEEN 25 AND 35 
        THEN '✅ Averaging ~30 minutes'
        WHEN AVG(minutes_since_previous) > 90 
        THEN '⚠️ Gaps too large'
        ELSE '⚠️ Irregular pattern'
    END as schedule_assessment
FROM snapshot_times
WHERE minutes_since_previous IS NOT NULL;

-- ===================================
-- 10. COMPREHENSIVE HEALTH REPORT
-- ===================================
SELECT 
    '=== INGESTION HEALTH REPORT ===' as report,
    NOW() as generated_at
UNION ALL
SELECT 
    'Last Snapshot: ' || MAX(fetched_at)::text,
    NULL
FROM api_snapshots
UNION ALL
SELECT 
    'Minutes Since Last: ' || 
    ROUND(EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60, 2)::text,
    NULL
FROM api_snapshots
UNION ALL
SELECT 
    'Status: ' || CASE 
        WHEN MAX(fetched_at) > NOW() - INTERVAL '90 minutes' 
        THEN '✅ HEALTHY'
        ELSE '⚠️ FAILING'
    END,
    NULL
FROM api_snapshots
UNION ALL
SELECT 
    'Snapshots (24h): ' || COUNT(*)::text,
    NULL
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Valid Data (24h): ' || 
    COUNT(*) FILTER (WHERE jsonb_typeof(raw_response) = 'array' 
                     AND jsonb_array_length(raw_response) > 0)::text,
    NULL
FROM api_snapshots
WHERE fetched_at > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Active Events: ' || COUNT(*)::text,
    NULL
FROM events
WHERE is_active = true
UNION ALL
SELECT 
    'Total Players: ' || COUNT(*)::text,
    NULL
FROM players
UNION ALL
SELECT 
    'Total Machines: ' || COUNT(*)::text,
    NULL
FROM machines;


-- ===================================
-- INTERPRETATION GUIDE
-- ===================================
/*

Query #1 (CURRENT STATUS):
- ✅ HEALTHY = Last snapshot within 90 minutes
- ⚠️ STALE = Last snapshot over 90 minutes ago (ALERT!)

Query #2 (RECENT SNAPSHOTS):
- Should see ~5 snapshots
- fetched_at timestamps should be ~60 minutes apart
- data_quality should be "✅ HAS DATA"

Query #3 (24-HOUR PATTERN):
- Should see ~24 rows (one per hour)
- snapshots_in_hour should mostly be 1
- Gaps indicate ingestion failures

Query #4 (CHECK FOR GAPS):
- Empty result = No gaps (good!)
- Rows shown = Hours where ingestion failed

Query #5 (DATA QUALITY):
- pct_valid should be close to 100%
- null_responses should be 0
- empty_responses should be 0 (or very few)

Query #6 (ACTIVE EVENTS):
- All active events should have "✅ Recent" status
- "❌ Never captured" = Event not being ingested
- "⚠️ Stale" = Event hasn't been updated recently

Query #7 (STATISTICS):
- Shows total counts across all tables
- minutes_since_latest should be < 90

Query #8 (PROBLEM SNAPSHOTS):
- Empty result = No problems (good!)
- Rows shown = Snapshots with data quality issues

Query #9 (FREQUENCY ANALYSIS):
- avg_minutes_between should be ~60
- max_gap should be < 90 (or you have issues)

Query #10 (HEALTH REPORT):
- Quick summary of overall system health

*/
