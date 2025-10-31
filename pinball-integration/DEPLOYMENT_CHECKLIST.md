# 📋 PostgreSQL Integration - Deployment Checklist

## Pre-Deployment Verification

- [ ] PostgreSQL database is running
- [ ] Database initialized with bootstrap_db.sh
- [ ] Have database credentials ready
- [ ] n8n workflow has run at least once
- [ ] SSH access to jd-docker-01 working
- [ ] Docker and docker-compose installed

## Phase 1: Database Views (5 min)

- [ ] Extract integration package: `tar -xzf pinball-integration.tar.gz`
- [ ] Copy database_views.sql to server
- [ ] Connect to PostgreSQL: `psql -U pinball -d pinball_analytics`
- [ ] Run SQL file: `\i database_views.sql`
- [ ] Verify views exist: `\dv`
- [ ] Test views return data: `SELECT COUNT(*) FROM leaderboard_current;`

## Phase 2: Application Files (10 min)

- [ ] Backup current app.py: `cp app.py app.py.backup`
- [ ] Copy new app.py to server
- [ ] Copy new requirements.txt to server
- [ ] Copy .env.example to server
- [ ] Create .env from template: `cp .env.example .env`
- [ ] Edit .env with real credentials: `nano .env`
- [ ] Secure .env file: `chmod 600 .env`
- [ ] Verify .gitignore includes .env

## Phase 3: Docker Configuration (5 min)

- [ ] Edit docker-compose.yml
- [ ] Add .env to volumes section:
  ```yaml
  volumes:
    - ./config.json:/app/config.json
    - ./.env:/app/.env  # Add this line
  ```
- [ ] Save and exit

## Phase 4: Connection Testing (5 min)

- [ ] Test PostgreSQL connection:
  ```bash
  psql -h localhost -U pinball -d pinball_analytics -c "SELECT 1;"
  ```
- [ ] Test Python connection:
  ```bash
  pip3 install psycopg2-binary python-dotenv
  python3 -c "import psycopg2; from dotenv import load_dotenv; load_dotenv(); print('OK')"
  ```
- [ ] Verify views have data:
  ```bash
  psql -U pinball -d pinball_analytics -c "SELECT * FROM leaderboard_current LIMIT 5;"
  ```

## Phase 5: Deployment (5 min)

- [ ] Navigate to app directory: `cd /opt/pinball-leaderboard`
- [ ] Stop current container: `docker-compose down`
- [ ] Rebuild container: `docker-compose build --no-cache`
- [ ] Start container: `docker-compose up -d`
- [ ] Check logs for success: `docker-compose logs -f`
- [ ] Look for: "✓ Database connection successful"

## Phase 6: Endpoint Verification (5 min)

- [ ] Test health endpoint:
  ```bash
  curl http://localhost:5050/api/health | jq
  ```
  Expected: `{"status": "healthy", "database": "connected", ...}`

- [ ] Test top 10 leaderboard:
  ```bash
  curl http://localhost:5050/api/leaderboard/top10 | jq '.[0]'
  ```
  Expected: Real player data

- [ ] Test full leaderboard:
  ```bash
  curl http://localhost:5050/api/leaderboard/full | jq '. | length'
  ```
  Expected: Number > 0

- [ ] Test game champions:
  ```bash
  curl http://localhost:5050/api/game-champions | jq
  ```
  Expected: Array of games with champions

- [ ] Test recent activity:
  ```bash
  curl http://localhost:5050/api/recent-activity | jq '.[0]'
  ```
  Expected: Recent game data

- [ ] Test statistics:
  ```bash
  curl http://localhost:5050/api/statistics | jq
  ```
  Expected: League statistics object

## Phase 7: Web Interface Check (5 min)

- [ ] Open local URL: http://jd-docker-01:5050
- [ ] Open public URL: https://pinball.thedelay.org
- [ ] Verify Scene 1 (Top 10) shows real players
- [ ] Verify Scene 2 (Game Champions) shows real machines
- [ ] Verify Scene 3 (Recent Activity) shows actual games
- [ ] Verify Scene 4 (Full Roster) shows all players
- [ ] Verify Scene 5 (Statistics) shows real numbers
- [ ] Check scenes rotate every 60 seconds
- [ ] Verify manual controls work (Prev, Next, Pause)

## Phase 8: Monitoring (10 min)

- [ ] Watch logs for 5 minutes: `docker-compose logs -f`
- [ ] Check for errors or warnings
- [ ] Verify no database connection errors
- [ ] Check query performance is acceptable
- [ ] Note current player rankings
- [ ] Wait for n8n workflow to run
- [ ] Verify rankings update after workflow
- [ ] Confirm data refresh is working

## Troubleshooting Checklist

If something doesn't work:

### Container Won't Start
- [ ] Check logs: `docker-compose logs`
- [ ] Verify .env file exists: `ls -la .env`
- [ ] Check .env has correct values: `cat .env`
- [ ] Verify port 5050 is free: `netstat -tlnp | grep 5050`
- [ ] Try rebuilding: `docker-compose build --no-cache`

### Database Connection Failed
- [ ] Test psql connection from server
- [ ] Verify DB_HOST in .env is correct
- [ ] Check DB_USER and DB_PASSWORD
- [ ] Verify PostgreSQL is running: `systemctl status postgresql`
- [ ] Check PostgreSQL logs: `tail -f /var/log/postgresql/*.log`
- [ ] Try from inside container: `docker-compose exec pinball-leaderboard bash`

### API Returns 500 Errors
- [ ] Check container logs: `docker-compose logs -f`
- [ ] Verify views exist: `psql -c "\dv"`
- [ ] Test views directly: `psql -c "SELECT * FROM leaderboard_current LIMIT 1;"`
- [ ] Check Python traceback in logs
- [ ] Verify requirements.txt has psycopg2-binary
- [ ] Rebuild container if needed

### No Data Displayed
- [ ] Verify database has data: `SELECT COUNT(*) FROM High_Scores_Archive;`
- [ ] Check if n8n workflow has run
- [ ] Verify views return data: `SELECT * FROM leaderboard_current;`
- [ ] Check API endpoints return data: `curl http://localhost:5050/api/leaderboard/top10`
- [ ] Clear browser cache (Ctrl+Shift+R)
- [ ] Check browser console for JavaScript errors

## Success Criteria

✅ You're successful when ALL of these are true:

- [ ] Health endpoint returns "healthy"
- [ ] All 6 API endpoints return real data
- [ ] Web interface displays real player names
- [ ] Rankings match database Leaderboard_Cache table
- [ ] Recent activity shows actual game timestamps
- [ ] Statistics reflect your league data
- [ ] Data updates when n8n workflow runs
- [ ] No errors in docker-compose logs
- [ ] Container stays running (not restarting)
- [ ] Bar owner is impressed! 🎉

## Post-Deployment Tasks

After successful deployment:

- [ ] Update n8n workflow to refresh views after ingestion
- [ ] Customize config.json with bar branding
- [ ] Add logo_url to config.json
- [ ] Adjust colors if needed
- [ ] Test from multiple devices
- [ ] Set up monitoring alerts for /api/health
- [ ] Document any custom changes made
- [ ] Take screenshots of working display
- [ ] Celebrate! 🍻

## Time Tracking

| Phase | Estimated | Actual | Notes |
|-------|-----------|--------|-------|
| Phase 1: Views | 5 min | | |
| Phase 2: Files | 10 min | | |
| Phase 3: Docker | 5 min | | |
| Phase 4: Testing | 5 min | | |
| Phase 5: Deploy | 5 min | | |
| Phase 6: Verify | 5 min | | |
| Phase 7: Web UI | 5 min | | |
| Phase 8: Monitor | 10 min | | |
| **Total** | **50 min** | | |

## Notes Section

Use this space to track any issues encountered or custom modifications:

```
Date: 
Issue: 
Solution: 

Date: 
Issue: 
Solution: 

Date: 
Issue: 
Solution: 
```

## Rollback Plan

If something goes wrong and you need to revert:

```bash
# Stop new container
docker-compose down

# Restore backup
cp app.py.backup app.py
cp requirements.txt.backup requirements.txt

# Remove .env
rm .env

# Rebuild with old code
docker-compose build --no-cache
docker-compose up -d
```

## Contact Information

**Server:** jd-docker-01
**App Location:** /opt/pinball-leaderboard
**Database:** pinball_analytics
**Public URL:** https://pinball.thedelay.org
**Local URL:** http://jd-docker-01:5050

---

**Print this checklist and check off items as you complete them!** ✓

Good luck! 🎯
