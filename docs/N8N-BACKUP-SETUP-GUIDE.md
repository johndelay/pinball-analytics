# N8n Workflow Backup Setup Guide

## Overview
This workflow automatically backs up all active N8n workflows daily at 2 AM, stores them with timestamps, and cleans up backups older than 30 days.

## Features
- ✅ Daily automatic backups at 2 AM
- ✅ Backs up only ACTIVE workflows
- ✅ Timestamped backup directories
- ✅ Individual JSON files per workflow
- ✅ Manifest file with backup metadata
- ✅ Automatic cleanup of old backups (30+ days)
- ✅ Safe filename sanitization

## Prerequisites

### 1. Create N8n API Credentials
1. In N8n, go to **Settings** → **API**
2. Generate an API key
3. In N8n, go to **Credentials** → **New Credential**
4. Select **Header Auth**
5. Name it: `N8n API Key`
6. Add header:
   - **Name:** `X-N8N-API-KEY`
   - **Value:** `[your-api-key]`
7. Save the credential

### 2. Set Environment Variable
Add this to your N8n environment (Docker Compose, .env file, etc.):
```bash
WEBHOOK_URL=http://localhost:5678
```
Or if N8n is accessible at a different URL:
```bash
WEBHOOK_URL=https://your-n8n-domain.com
```

### 3. Create Backup Directory (Optional - Auto-created on first run)
The workflow will automatically create the backup directory structure, but you can pre-create it if desired:

**On your Docker host:**
```bash
mkdir -p /opt/n8n/backups/workflows
```

**Inside the container, this maps to:**
```
/home/node/.n8n/backups/workflows
```

**Your current Docker Compose configuration already handles this!**
Your existing volume mount:
```yaml
volumes:
  - /opt/n8n:/home/node/.n8n
```
This means backups will be stored at `/opt/n8n/backups/` on your host machine.

**Important:** 
- ✅ Already writable by N8n container
- ✅ Already persisted (part of your /opt/n8n mount)
- ✅ Already included in your weekly Docker backups
- ✅ No additional Docker Compose changes needed!

## Installation

### Step 1: Import the Workflow
1. In N8n, go to **Workflows** → **Add workflow** → **Import from file**
2. Upload the `n8n-workflow-backup.json` file
3. The workflow will be imported as **inactive**

### Step 2: Configure the Workflow
1. Open the imported workflow
2. Click on **"Get Active Workflows"** node
3. Select your **N8n API Key** credential
4. Click on **"Get Workflow Details"** node
5. Select your **N8n API Key** credential
6. Save the workflow

### Step 3: Test the Workflow
**IMPORTANT:** Test before activating!

1. Click **"Execute Workflow"** button (don't activate yet)
2. Verify that:
   - Backup directory is created: `/backups/workflows/[timestamp]/`
   - Each workflow has a JSON file
   - `_backup_manifest.json` is created
3. Check the console output for any errors

### Step 4: Activate the Workflow
Once testing is successful:
1. Click the **"Active"** toggle in the top right
2. The workflow will now run daily at 2 AM

## Backup Structure

**On Docker Host (accessible to you):**
```
/opt/n8n/backups/workflows/
├── 2025-10-28_020000/
│   ├── Pinball_Leaderboard_Ingestion_Production_Working_123.json
│   ├── Pinball_Stats_Calculator_456.json
│   ├── Another_Workflow_789.json
│   └── _backup_manifest.json
├── 2025-10-29_020000/
│   ├── ...
│   └── _backup_manifest.json
└── 2025-10-30_020000/
    ├── ...
    └── _backup_manifest.json
```

**Inside N8n Container:**
```
/home/node/.n8n/backups/workflows/
├── 2025-10-28_020000/
│   └── ...
```
(Same files, different path perspective)

### Manifest File Contents
```json
{
  "backupDate": "2025-10-28 02:00:15",
  "totalWorkflows": 5,
  "backupLocation": "/home/node/.n8n/backups/workflows/2025-10-28_020000/",
  "status": "SUCCESS",
  "workflows": [
    {
      "id": "123",
      "name": "Pinball Leaderboard Ingestion (Production - Working)",
      "active": true
    },
    ...
  ]
}
```

## Backup Retention
- **Daily backups:** Kept for 30 days
- **Cleanup:** Automatic on each run
- **Your weekly Docker backups:** Permanent retention

## Monitoring

### Check Last Backup (from Docker host)
```bash
ls -lht /opt/n8n/backups/workflows/ | head -5
```

### Verify Backup Integrity (from Docker host)
```bash
# Check most recent backup
LATEST=$(ls -t /opt/n8n/backups/workflows/ | head -1)
cat /opt/n8n/backups/workflows/$LATEST/_backup_manifest.json | jq .
```

### From inside the container
```bash
docker exec n8n ls -lht /home/node/.n8n/backups/workflows/ | head -5
```

### View Workflow Execution History
In N8n:
1. Go to **Executions**
2. Filter by workflow: **"N8n Workflow Backup (Daily DR)"**
3. Check for failures or warnings

## Disaster Recovery - Restoration Process

### To Restore a Single Workflow:
1. Locate the backup on your Docker host: `/opt/n8n/backups/workflows/[date]/[workflow-name]_[id].json`
2. In N8n: **Workflows** → **Add workflow** → **Import from file**
3. Upload the JSON file
4. Activate if needed

### To Restore ALL Workflows (from Docker host):
```bash
# From your backup directory on the host
cd /opt/n8n/backups/workflows/[date]/
for file in *.json; do
  if [[ $file != "_backup_manifest.json" ]]; then
    echo "Restore $file manually in N8n UI"
    # Or use N8n API to import programmatically
  fi
done
```

### Using N8n API to Restore (Advanced):
```bash
# Run from Docker host
BACKUP_DIR="/opt/n8n/backups/workflows/2025-10-28_020000"
API_KEY="your-n8n-api-key"
N8N_URL="https://atom.thedelay.org"

for file in $BACKUP_DIR/*.json; do
  if [[ $file != *"_backup_manifest.json" ]]; then
    curl -X POST "$N8N_URL/api/v1/workflows" \
      -H "X-N8N-API-KEY: $API_KEY" \
      -H "Content-Type: application/json" \
      -d @"$file"
  fi
done
```

## Troubleshooting

### Issue: "Permission Denied" Writing Files
**Solution:** Your current setup should not have this issue since /opt/n8n is already mounted and writable. But if it occurs:
```bash
# On host machine
chmod -R 755 /opt/n8n/backups
# Or check ownership (n8n typically runs as node user, UID 1000)
ls -la /opt/n8n/backups
```

### Issue: Directory Not Created
**Solution:** The workflow auto-creates directories, but you can verify:
```bash
# From Docker host
ls -la /opt/n8n/backups/

# From inside container
docker exec n8n ls -la /home/node/.n8n/backups/
```

### Issue: "API Authentication Failed"
**Solution:** 
1. Verify API key is correct
2. Check that credential is selected in both HTTP Request nodes
3. Ensure `WEBHOOK_URL` environment variable is set

### Issue: No Backups Created
**Solution:**
1. Check N8n execution log for the workflow
2. Verify the backup directory path exists
3. Ensure N8n has write permissions

### Issue: Workflow Not Running at 2 AM
**Solution:**
1. Verify workflow is **Active** (toggle in top right)
2. Check timezone settings in N8n
3. Verify cron expression: `0 2 * * *`

## Customization

### Change Backup Time
Edit the **Schedule Daily 2 AM** node:
- Current: `0 2 * * *` (2:00 AM daily)
- Examples:
  - `0 1 * * *` = 1:00 AM daily
  - `0 */6 * * *` = Every 6 hours
  - `0 0 * * 0` = Weekly on Sunday at midnight

### Change Retention Period
Edit the **Cleanup Old Backups** node:
- Current: `-mtime +30` (30 days)
- Change to: `-mtime +60` (60 days)
- Change to: `-mtime +7` (7 days)

### Backup Inactive Workflows Too
Edit the **Get Active Workflows** node:
- Remove or change the query parameter `active=true`

### Add Email Notifications
Add a **Send Email** node after **Final Output**:
- Subject: "N8n Workflow Backup Complete"
- Body: `{{ $json.message }}`

## Best Practices

1. ✅ **Test restoration** at least once before production
2. ✅ **Monitor execution logs** weekly for the first month
3. ✅ **Keep your weekly Docker backups** as additional redundancy
4. ✅ **Store backups off-site** if possible (sync to S3, cloud storage)
5. ✅ **Document any custom workflows** that aren't backed up
6. ✅ **Version control critical workflows** in Git as well

## Integration with Your Pinball Analytics Project

This backup workflow protects:
- ✅ Pinball Leaderboard Ingestion (Production - Working)
- ✅ Any future analytics workflows
- ✅ Reporting workflows
- ✅ Data transformation workflows

**Remember:** This backs up the WORKFLOW DEFINITIONS, not the data itself. 
Your PostgreSQL database needs separate backup strategy (see main DR documentation).

## Support

If you encounter issues:
1. Check N8n execution logs
2. Verify Docker container logs: `docker logs [n8n-container]`
3. Check file system permissions
4. Review the troubleshooting section above

## Next Steps

After implementing this backup:
1. [ ] Test a full workflow restoration
2. [ ] Set up PostgreSQL database backups (daily dumps)
3. [ ] Configure monitoring/alerting for workflow failures
4. [ ] Document your complete DR plan
5. [ ] Schedule quarterly DR drills

---
**Version:** 1.0  
**Last Updated:** 2025-10-28  
**Maintained By:** John Delay
