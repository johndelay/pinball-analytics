# 🎯 Database Integration - Step by Step Guide

This guide will walk you through connecting your pinball leaderboard to PostgreSQL.

## Prerequisites Checklist

- [ ] PostgreSQL database is running and accessible
- [ ] Database has been initialized with `bootstrap_db.sh`
- [ ] You have database credentials (host, user, password)
- [ ] Your n8n workflow is populating data
- [ ] Docker is running on jd-docker-01

## Phase 1: Create Database Views (5 minutes)

### Step 1.1: Connect to PostgreSQL

```bash
# From your server or wherever PostgreSQL is accessible
psql -h localhost -U pinball -d pinball_analytics
```

### Step 1.2: Run the Views SQL

```bash
# Copy the database_views.sql file to your server
scp database_views.sql jdelay@jd-docker-01:/tmp/

# SSH into your server
ssh jdelay@jd-docker-01

# Run the SQL file
psql -h localhost -U your_db_user -d pinball_analytics -f /tmp/database_views.sql
```

### Step 1.3: Verify Views Were Created

```sql
-- In psql, list all views
\dv

-- Should see:
-- leaderboard_current
-- game_champions
-- recent_activity
-- league_statistics
-- weekly_top_performers
```

### Step 1.4: Test the Views

```sql
-- Test each view to ensure data is returned
SELECT COUNT(*) FROM leaderboard_current;
SELECT COUNT(*) FROM game_champions;
SELECT COUNT(*) FROM recent_activity;
SELECT * FROM league_statistics;

-- If any return 0 or NULL, your database might not have data yet
-- Make sure your n8n workflow has run at least once
```

## Phase 2: Update Application Files (10 minutes)

### Step 2.1: Backup Current Files

```bash
# On jd-docker-01
cd /opt/pinball-leaderboard
cp app.py app.py.backup
cp requirements.txt requirements.txt.backup
```

### Step 2.2: Copy New Files

```bash
# Copy the new app.py
scp app.py jdelay@jd-docker-01:/opt/pinball-leaderboard/

# Copy the new requirements.txt
scp requirements.txt jdelay@jd-docker-01:/opt/pinball-leaderboard/

# Copy the .env.example
scp .env.example jdelay@jd-docker-01:/opt/pinball-leaderboard/
```

### Step 2.3: Create .env File

```bash
# On jd-docker-01
cd /opt/pinball-leaderboard

# Copy the example and edit it
cp .env.example .env
nano .env
```

Edit `.env` with your actual credentials:

```bash
DB_HOST=localhost               # or your PostgreSQL server IP
DB_PORT=5432
DB_NAME=pinball_analytics      # your database name
DB_USER=pinball                # your database user
DB_PASSWORD=your_actual_password_here

FLASK_ENV=production
FLASK_DEBUG=False
```

**Save and exit** (Ctrl+X, Y, Enter)

### Step 2.4: Secure the .env File

```bash
# Make sure only you can read it
chmod 600 .env

# Verify it's in .gitignore
grep -q ".env" .gitignore || echo ".env" >> .gitignore
```

## Phase 3: Update Docker Configuration (5 minutes)

### Step 3.1: Update docker-compose.yml

Edit your `docker-compose.yml` to mount the .env file:

```bash
nano /opt/pinball-leaderboard/docker-compose.yml
```

Update to include the .env file:

```yaml
version: '3.8'

services:
  pinball-leaderboard:
    build: .
    container_name: pinball-leaderboard
    ports:
      - "5050:5050"
    volumes:
      - ./config.json:/app/config.json
      - ./.env:/app/.env  # Add this line
    environment:
      - FLASK_ENV=production
    restart: unless-stopped
    networks:
      - pinball-network

networks:
  pinball-network:
    driver: bridge
```

## Phase 4: Test Connection Before Deploying (5 minutes)

### Step 4.1: Test Database Connection from Server

```bash
# Test with psql
psql -h localhost -U pinball -d pinball_analytics -c "SELECT COUNT(*) FROM leaderboard_current;"

# Should show a number (not an error)
```

### Step 4.2: Test Python Connection

```bash
cd /opt/pinball-leaderboard

# Install psycopg2 temporarily for testing
pip3 install psycopg2-binary python-dotenv

# Test connection
python3 << 'EOF'
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

try:
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT'),
        database=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD')
    )
    print("✓ Connection successful!")
    
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM leaderboard_current")
    count = cur.fetchone()[0]
    print(f"✓ Found {count} players in leaderboard")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"✗ Connection failed: {e}")
EOF
```

If you see "✓ Connection successful!", proceed to deployment!

## Phase 5: Deploy (5 minutes)

### Step 5.1: Rebuild and Deploy

```bash
cd /opt/pinball-leaderboard

# Stop current container
docker-compose down

# Rebuild with new code
docker-compose build --no-cache

# Start the new container
docker-compose up -d

# Watch the logs
docker-compose logs -f
```

### Step 5.2: Watch for Success Messages

You should see:

```
✓ Database connection successful
 * Running on http://0.0.0.0:5050
```

### Step 5.3: Test the Health Endpoint

```bash
# From server
curl http://localhost:5050/api/health | jq

# Should return:
# {
#   "status": "healthy",
#   "database": "connected",
#   "timestamp": "2025-..."
# }
```

## Phase 6: Verify All Endpoints (5 minutes)

### Step 6.1: Test Each API Endpoint

```bash
# Top 10 leaderboard
curl http://localhost:5050/api/leaderboard/top10 | jq '.[0]'

# Full leaderboard
curl http://localhost:5050/api/leaderboard/full | jq '. | length'

# Game champions
curl http://localhost:5050/api/game-champions | jq

# Recent activity
curl http://localhost:5050/api/recent-activity | jq '.[0]'

# Statistics
curl http://localhost:5050/api/statistics | jq
```

### Step 6.2: Check the Web Interface

Open in your browser:
- Local: http://jd-docker-01:5050
- Public: https://pinball.thedelay.org

The leaderboard should now show **REAL DATA** from your database!

## Phase 7: Monitor and Verify (10 minutes)

### Step 7.1: Watch Logs for Issues

```bash
# Watch live logs
docker-compose logs -f

# Look for any errors
docker-compose logs | grep -i error

# Check last 100 lines
docker-compose logs --tail 100
```

### Step 7.2: Verify Data Updates

1. Open the leaderboard: https://pinball.thedelay.org
2. Note current rankings
3. Wait for your n8n workflow to run
4. Refresh the page (should update within 5 minutes based on config)
5. Confirm rankings reflect new data

## Troubleshooting

### Problem: "Database connection failed"

**Solution 1:** Check .env file
```bash
cat /opt/pinball-leaderboard/.env
# Verify all values are correct
```

**Solution 2:** Test database accessibility
```bash
# From inside Docker container
docker-compose exec pinball-leaderboard /bin/bash
apt-get update && apt-get install -y postgresql-client
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

**Solution 3:** Check if PostgreSQL allows connections
```bash
# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Problem: Views return no data

**Solution:** Run n8n workflow manually to populate data
```bash
# Check if you have any data
psql -U pinball -d pinball_analytics -c "SELECT COUNT(*) FROM High_Scores_Archive;"
```

### Problem: Container won't start

**Solution:** Check logs for specific error
```bash
docker-compose logs
# Fix the error shown, usually it's:
# - Missing .env file
# - Wrong database credentials
# - Port 5050 already in use
```

### Problem: API returns 500 errors

**Solution:** Check application logs
```bash
docker-compose logs -f
# Look for Python tracebacks
# Usually means:
# - View doesn't exist (run database_views.sql)
# - Column mismatch (check view definitions)
# - Database connection lost
```

## Success Checklist

- [ ] Database views created and tested
- [ ] .env file created with correct credentials
- [ ] Connection test passed
- [ ] Container rebuilt and started
- [ ] Health endpoint returns "healthy"
- [ ] All API endpoints return data
- [ ] Web interface shows real data
- [ ] Data updates when n8n runs

## Post-Deployment

### Update Your n8n Workflow

Add a PostgreSQL node at the end of your workflow to refresh the views:

```sql
-- After ingesting new scores, refresh the views
REFRESH MATERIALIZED VIEW IF EXISTS leaderboard_current;
REFRESH MATERIALIZED VIEW IF EXISTS game_champions;
REFRESH MATERIALIZED VIEW IF EXISTS recent_activity;
REFRESH MATERIALIZED VIEW IF EXISTS league_statistics;
```

(Note: Only if you convert the views to MATERIALIZED VIEWS for better performance)

### Monitor Performance

```bash
# Check query performance
psql -U pinball -d pinball_analytics << 'EOF'
EXPLAIN ANALYZE SELECT * FROM leaderboard_current LIMIT 10;
EOF
```

### Setup Automated Backups

```bash
# Add to crontab
crontab -e

# Backup database daily at 2 AM
0 2 * * * pg_dump -U pinball pinball_analytics > /backups/pinball_$(date +\%Y\%m\%d).sql
```

## Next Steps

1. **Customize the Display**: Edit `config.json` to match your bar's branding
2. **Add Monitoring**: Setup alerts if the health endpoint fails
3. **Optimize Performance**: Convert views to MATERIALIZED if needed
4. **Add Features**: Consider adding player photos, achievements, etc.

## Need Help?

- Check logs: `docker-compose logs -f`
- Test database: `psql -U pinball -d pinball_analytics`
- Test views: `SELECT * FROM leaderboard_current LIMIT 5;`
- Health check: `curl http://localhost:5050/api/health`

---

**Congratulations!** Your pinball leaderboard is now connected to real data! 🎉
