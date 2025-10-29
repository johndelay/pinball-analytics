# Future Work: Error Handling & Retry Logic

## Current State
The n8n workflow "Pinball Leaderboard Ingestion (Production - Working)" runs every 60 minutes but has no explicit error handling or notification system.

## Proposed Improvements

### 1. Error Detection Nodes
Add error-catching branches after critical nodes:
- **After "Fetch Stern API Data"**: Catch HTTP errors (timeout, 404, 500)
- **After Database Operations**: Catch connection failures, constraint violations
- **After "Recalculate Leaderboard"**: Catch function execution errors

### 2. Retry Logic
Implement exponential backoff for transient failures:
```
Attempt 1: Immediate retry
Attempt 2: Wait 1 minute
Attempt 3: Wait 5 minutes
After 3 failures: Send alert email
```

**n8n Implementation:**
- Add "Error Trigger" nodes that catch failures
- Use "Wait" nodes with calculated delays
- Add "Loop" nodes or "Split In Batches" for retry attempts
- Store retry count in workflow state

### 3. Error Notification System

#### Option A: Email Alerts
Create a new node chain:
```
Error Trigger → Format Error Message → Send Gmail
```

**Email Template:**
```
Subject: ⚠️ Pinball Workflow Failed - [Error Type]

Time: {timestamp}
Node: {failed_node_name}
Error: {error_message}
Retry Count: {retry_count}
Last Successful Run: {last_success_time}

Action Required: [Manual/Automatic]
```

#### Option B: Slack/Discord Webhook
Faster notification for real-time monitoring

#### Option C: SMS (Twilio)
For critical production failures

### 4. Health Monitoring Dashboard

Add a new workflow: "Pinball System Health Check"
- Runs every 15 minutes
- Checks last successful API fetch timestamp
- Alerts if no data received in 2+ hours
- Monitors database connection health

**SQL Query:**
```sql
SELECT 
    EXTRACT(EPOCH FROM (NOW() - MAX(fetched_at)))/60 as minutes_since_last_fetch,
    COUNT(*) FILTER (WHERE fetched_at > NOW() - INTERVAL '2 hours') as recent_runs
FROM Api_Snapshots
HAVING MAX(fetched_at) < NOW() - INTERVAL '2 hours';
```

### 5. Dead Letter Queue
Store failed API responses for manual inspection:
```sql
CREATE TABLE Failed_Ingestions (
    failure_id SERIAL PRIMARY KEY,
    failed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    error_message TEXT,
    raw_request TEXT,
    raw_response TEXT,
    retry_count INTEGER DEFAULT 0,
    resolved BOOLEAN DEFAULT FALSE
);
```

### 6. Automatic Recovery Workflow
Create a separate workflow: "Pinball Recovery Manager"
- Runs every 6 hours
- Checks Failed_Ingestions table
- Re-attempts processing with manual approval flag
- Updates resolved status

## Priority Ranking
1. **HIGH**: Email error notifications (easy win, immediate value)
2. **HIGH**: Basic retry logic on API fetch (prevents data gaps)
3. **MEDIUM**: Health monitoring dashboard
4. **MEDIUM**: Dead letter queue for debugging
5. **LOW**: Advanced recovery workflow
6. **LOW**: SMS alerts (only if running production 24/7)

## Implementation Checklist
- [ ] Create error notification email template
- [ ] Add error trigger nodes to main workflow
- [ ] Implement 3-attempt retry logic with exponential backoff
- [ ] Create health check workflow
- [ ] Add Failed_Ingestions table to schema
- [ ] Test error scenarios (disconnect network, kill postgres)
- [ ] Document error recovery procedures
- [ ] Set up monitoring dashboard (Grafana alert rules)

## Notes
- Consider using n8n's built-in "Error Workflow" feature
- Log all errors to a centralized location for pattern analysis
- Balance between automatic recovery and manual oversight
- Don't over-engineer: start with email alerts and simple retries
