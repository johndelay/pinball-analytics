# Repository Reorganization Guide

**Prerequisites**: You should be in the `pinball-analytics` directory before starting.

```bash
# Confirm you're in the right place
pwd
# Should show: /path/to/pinball-analytics
```

## Step 1: Get the Reorganization Script

The script is in `/mnt/user-data/outputs/` on your system. Download it to your current directory:

```bash
# Copy script to current directory (pinball-analytics)
cp /path/to/downloaded/reorganize_repo.py .

# Make it executable
chmod +x reorganize_repo.py

# Run it
python3 reorganize_repo.py
```

The script will:
- Create `docs/` and `workflows/` folders
- Move documentation files to `docs/`
- Move workflow JSON files to `workflows/`
- Remove empty `n8n_components/` folder

## Step 2: Add New Documentation Files

Download the files from Claude's outputs and copy them to your current directory:

```bash
# Copy main documentation files to current directory (root)
cp /path/to/downloaded/PROJECT_DOCUMENTATION.md .
cp /path/to/downloaded/CLAUDE.md .
cp /path/to/downloaded/SESSION_SUMMARY.md .

# Copy workflow-specific guides to docs/ (created by script in Step 1)
cp /path/to/downloaded/DAILY_EMAIL_SETUP_GUIDE.md docs/
cp /path/to/downloaded/WEEKLY_REPORT_SETUP_GUIDE.md docs/

# Copy new workflow to workflows/ (created by script in Step 1)
cp /path/to/downloaded/Pinball_Weekly_Bar_Owner_Report_FIXED.json workflows/

# Copy new SQL files to database/init/
cp /path/to/downloaded/05_daily_stats_table.sql database/init/
cp /path/to/downloaded/06_fix_api_snapshots_constraint.sql database/init/
```

**Note**: Replace `/path/to/downloaded/` with wherever you downloaded the files from Claude.
- If you saved them to `~/Downloads/`, use `~/Downloads/filename`
- The files are available in Claude's outputs folder

## Step 3: Update .gitignore (if needed)

Make sure your `.gitignore` includes:

```
# Environment & Secrets
.env
.env.*
*.env

# Credentials
credentials.json
config/secrets.yaml

# N8n specific
.n8n/
*.credentials.json

# Database
*.db
*.sqlite

# Logs
*.log
logs/

# OS Files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Node modules
node_modules/

# Claude
.claude/

# Backup files
*.backup
*.bak
*~
```

## Step 4: Review Changes

```bash
# See what changed
git status

# Review the moves
git diff --cached
```

You should see:
- ✅ New folders: `docs/`, `workflows/`
- ✅ Moved files showing as renames (Git preserves history)
- ✅ New documentation files
- ✅ New workflow and SQL files

## Step 5: Commit Everything

```bash
# Stage all changes
git add -A

# Create a comprehensive commit message
git commit -m "Major reorganization and documentation update

Structure Changes:
- Created docs/ folder for all documentation
- Created workflows/ folder for all n8n JSON files
- Moved files into logical structure
- Removed empty n8n_components/ folder

New Documentation:
- Added PROJECT_DOCUMENTATION.md (comprehensive system guide)
- Updated CLAUDE.md with critical issue info and references
- Added SESSION_SUMMARY.md (Oct 29, 2025 improvements)
- Added DAILY_EMAIL_SETUP_GUIDE.md
- Added WEEKLY_REPORT_SETUP_GUIDE.md

New Features:
- Added Daily_Stats table (05_daily_stats_table.sql)
- Added Weekly Bar Owner Report workflow
- Added Api_Snapshots constraint fix (06_fix_api_snapshots_constraint.sql)

Bug Fixes:
- Fixed Api_Snapshots duplicate key issue
- Updated ingestion workflow (removed snapshot_id from mapping)
- Fixed weekly report merge node strategy (nested merges)

All workflows tested and operational."

# Push to GitHub
git push origin main
```

## Step 6: Verify on GitHub

After pushing, check GitHub to ensure:
1. Folder structure looks correct
2. File history is preserved (check a moved file's history)
3. README.md still displays properly
4. All documentation files are readable

## Final Directory Structure

```
pinball-analytics/
├── README.md                              # Project overview
├── CLAUDE.md                              # AI assistant reference (UPDATED)
├── PROJECT_DOCUMENTATION.md               # Master reference (NEW)
├── SESSION_SUMMARY.md                     # Oct 29 work summary (NEW)
├── bootstrap_db.sh                        # Database setup script
├── .env                                   # Local config (gitignored)
├── .gitignore                            # Git ignore rules
│
├── database/
│   ├── init/
│   │   ├── 01_schema_tables.sql
│   │   ├── 02_constraints_indexes.sql
│   │   ├── 03_seed_data.sql
│   │   ├── 04_history_tracking.sql
│   │   ├── 05_daily_stats_table.sql               # NEW
│   │   └── 06_fix_api_snapshots_constraint.sql    # NEW
│   └── functions/
│       └── 01_update_combined_leaderboard_function.sql
│
├── docs/                                  # CREATED
│   ├── DB Setup Instructions.md           # Moved
│   ├── N8N_SETUP_INSTRUCTIONS.md         # Moved
│   ├── FUTURE_WORK_ERROR_HANDLING.md     # Moved
│   ├── DAILY_EMAIL_SETUP_GUIDE.md        # NEW
│   └── WEEKLY_REPORT_SETUP_GUIDE.md      # NEW
│
└── workflows/                             # CREATED
    ├── Pinball Leaderboard Ingestion (Production - Working).json  # Moved
    ├── Pinball_daily_email_summary.json                           # Moved
    ├── N8n_Pinball_Weekly_Bar_Owner_Report_FIXED.json            # NEW
    ├── snapshot_leaderboard_history.json                          # Moved
    └── grafana_keppy_demo.json                                    # Moved
```

## Troubleshooting

### If you see sync conflicts

```bash
# If you have sync conflict files from SyncThing
find . -name "*.sync-conflict*" -delete
git status
```

### If Git shows files as deleted instead of moved

This is fine! Git is smart enough to track moves. Just commit normally.

### If you want to undo everything

```bash
# Before committing
git reset --hard HEAD

# After committing (to previous commit)
git reset --hard HEAD~1
```

## Benefits of New Structure

### Before:
- All files mixed in root directory
- Hard to find specific workflows
- Documentation scattered

### After:
✅ **Clear organization** - Related files grouped together  
✅ **Easy navigation** - docs/ and workflows/ folders  
✅ **Better discoverability** - New contributors know where to look  
✅ **Scalable** - Easy to add more workflows or docs  
✅ **Professional** - Matches open-source project standards  

## Update Your Local Paths

After reorganization, update any scripts or documentation that reference old paths:

### In n8n:
- Workflow imports still work (just the filename matters)

### In Documentation:
- Already updated in new files
- Old docs moved to docs/ folder

### In Scripts:
- bootstrap_db.sh still works (doesn't reference moved files)
- Any custom scripts may need path updates

## Next Time You Clone

```bash
git clone https://github.com/johndelay/pinball-analytics.git
cd pinball-analytics

# Setup still works the same
source .env
./bootstrap_db.sh pinball --init-tables

# But now documentation is easier to find!
ls docs/        # All guides
ls workflows/   # All n8n JSONs
```

---

## Quick Command Reference

**Assumption**: You're already in the `pinball-analytics` directory.

```bash
# Step 1: Run reorganization script
python3 reorganize_repo.py

# Step 2: Copy new files from wherever you downloaded them
# (Replace /path/to/downloaded/ with your actual download location)
cp /path/to/downloaded/PROJECT_DOCUMENTATION.md .
cp /path/to/downloaded/CLAUDE.md .
cp /path/to/downloaded/SESSION_SUMMARY.md .
cp /path/to/downloaded/*_GUIDE.md docs/
cp /path/to/downloaded/Pinball_Weekly_Bar_Owner_Report_FIXED.json workflows/
cp /path/to/downloaded/05_daily_stats_table.sql database/init/
cp /path/to/downloaded/06_fix_api_snapshots_constraint.sql database/init/

# Step 3: Review and commit
git status
git add -A
git commit -m "Reorganize repository and add comprehensive documentation"
git push origin main
```

Done! Your repository is now professionally organized. 🎉
