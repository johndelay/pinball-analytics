# n8n Workflow Setup Instructions

## Overview
This workflow automatically fetches pinball tournament data from the Stern API every 10 minutes, stores it in PostgreSQL, and calculates leaderboard rankings.

## Prerequisites

1. **n8n installed** on Ubuntu 22.04
2. **PostgreSQL database** set up with all tables (run `bootstrap_db.sh` first)
3. **PostgreSQL credentials** configured in n8n

## Step 1: Import Workflow

1. Open n8n in your browser
2. Go to **Workflows** → **Import from File**
3. Select: `n8n_pinball_ingestion_corrected.json`
4. Click **Import**

## Step 2: Configure PostgreSQL Credentials

Each PostgreSQL node needs credentials configured:

1. Click on any **Postgres** node (nodes 3, 5, 6, 7, 8, 9)
2. In the **Credential to connect with** dropdown, click **Create New**
3. Enter your credentials:
   - **Host**: `192.168.86.108` (from your .env file)
   - **Database**: `pinball`
   - **User**: `postgres`
   - **Password**: (from your .env DB_PASSWORD)
   - **Port**: `5432` (default)
   - **SSL**: `disable` (for local network)
4. Click **Save**
5. Apply this credential to ALL PostgreSQL nodes (3, 5, 6, 7, 8, 9)

## Step 3: Test the Workflow

1. Click **Execute Workflow** (play button at bottom)
2. Check each node for successful execution:
   - **Node 1**: Should trigger immediately
   - **Node 2**: Should fetch API data (look for JSON response)
   - **Node 3**: Should insert into Api_Snapshots
   - **Node 4**: Should parse data into 2 outputs
   - **Node 5**: Should upsert event metadata
   - **Node 6**: Should upsert players and machines
   - **Node 7**: Should filter for higher scores only
   - **Node 8**: Should insert new high scores
   - **Node 9**: Should recalculate leaderboard

## Step 4: Activate the Workflow

1. Click the **Inactive** toggle at the top to **Active**
2. The workflow will now run automatically every 10 minutes

## Workflow Details

### Node Flow

```
1. Cron Trigger (Every 10 min)
   ↓
2. Fetch Stern API
   ↓
3. Store API Snapshot (Api_Snapshots table)
   ↓
4. Parse Data (JavaScript - 2 outputs)
   ↓                    ↓
5. Upsert Event    6. Upsert Players/Machines
                       ↓
                   7. Filter Higher Scores (smart filtering)
                       ↓
                   8. Insert High Scores
                       ↓
                   9. Recalculate Leaderboard
```

### Key Features

- **Immutable Audit Trail**: Node 3 stores every API response in `Api_Snapshots`
- **Smart Filtering**: Node 7 only passes through scores that are HIGHER than existing scores
- **Automatic Updates**: Player `last_seen` timestamps update on every run
- **Machine Discovery**: New machines are automatically added when they appear in API data

### Database Tables Updated

- `Api_Snapshots`: Raw API responses (INSERT only)
- `Events`: Event metadata (UPSERT)
- `Players`: Player profiles (UPSERT, updates last_seen)
- `Machines`: Pinball machines (UPSERT)
- `High_Scores_Archive`: Score records (INSERT only, filtered)
- `Leaderboard_Cache`: Combined rankings (TRUNCATE/INSERT via function)

## Troubleshooting

### "Credential not configured" error
- Make sure you've set up PostgreSQL credentials in EVERY postgres node (3, 5, 6, 7, 8, 9)

### Node 7 returns no items
- This is normal! It means no new high scores were found (all scores are lower than existing)
- Check `High_Scores_Archive` table to see current scores

### Node 9 fails with "function does not exist"
- Run the bootstrap script to deploy the `update_combined_leaderboard()` function
- See: `bootstrap_db.sh` (fix line 151 first - there's a syntax error)

### API returns empty data
- Check the event_code in Node 2's URL: `hJjW-WXu-oCGQ`
- Verify the event is still active on Stern's API

## Monitoring

Check workflow execution history:
1. Go to **Executions** in n8n
2. Look for successful runs every 10 minutes
3. Click on any execution to see detailed node outputs

## Modifying the Event

To track a different event, change Node 2's URL:
```
https://api.prd.sternpinball.io/api/v1/portal/leaderboards/?event_code=YOUR_EVENT_CODE&event_state=current&format=json
```
