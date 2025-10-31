# Pinball Leaderboard - PostgreSQL Integration Package

This package contains everything you need to connect your pinball leaderboard kiosk to your PostgreSQL database.

## 📦 What's Included

```
pinball-integration/
├── README.md                    ← You are here
├── INTEGRATION_SUMMARY.md       ← Overview and architecture
├── INTEGRATION_GUIDE.md         ← Step-by-step instructions ⭐ START HERE
├── DATABASE_REFERENCE.md        ← Schema quick reference
├── database_views.sql           ← SQL to create views
├── app.py                       ← Updated Flask application
├── requirements.txt             ← Python dependencies
└── .env.example                 ← Environment variable template
```

## 🚀 Quick Start

### 1. Read the Summary (5 min)
```bash
cat INTEGRATION_SUMMARY.md
```
Understand what we're building and how it works.

### 2. Follow the Guide (40 min)
```bash
cat INTEGRATION_GUIDE.md
```
Complete step-by-step instructions with testing and verification.

### 3. Keep the Reference Handy
```bash
cat DATABASE_REFERENCE.md
```
Quick reference for your database schema and common queries.

## 📋 Prerequisites

Before starting, make sure you have:

- [ ] PostgreSQL database running
- [ ] Database initialized with `bootstrap_db.sh`
- [ ] Database credentials (host, user, password)
- [ ] n8n workflow populating data
- [ ] SSH access to jd-docker-01
- [ ] Docker and docker-compose installed

## 🎯 What This Does

**Connects your leaderboard kiosk to PostgreSQL:**

1. Creates optimized database views
2. Updates Flask app to query real data
3. Configures database credentials
4. Deploys with Docker
5. Verifies everything works

**Result:** Your leaderboard shows REAL player data from the Stern API!

## 📝 Files Explained

### database_views.sql
SQL script that creates 5 views in your database:
- `leaderboard_current` - Main rankings with trends
- `game_champions` - High scores per machine
- `recent_activity` - Latest games played
- `league_statistics` - Overall metrics
- `weekly_top_performers` - Top players this week

**Run this ONCE in your database.**

### app.py
Updated Flask application that:
- Connects to PostgreSQL using psycopg2
- Queries the views we created
- Returns JSON to the frontend
- Includes health check endpoint
- Has comprehensive error handling

**Replace your existing app.py with this file.**

### requirements.txt
Python dependencies including:
- psycopg2-binary (PostgreSQL driver)
- python-dotenv (environment variables)
- Flask and Flask-CORS (existing)

**Replace your existing requirements.txt with this file.**

### .env.example
Template for database credentials:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pinball_analytics
DB_USER=pinball
DB_PASSWORD=your_password
```

**Copy to .env and fill in your actual credentials.**

## ⚡ Fast Track (For the Brave)

If you want to deploy quickly without reading everything:

```bash
# 1. Create database views
psql -U pinball -d pinball_analytics -f database_views.sql

# 2. Copy files to server
scp app.py requirements.txt .env.example jdelay@jd-docker-01:/opt/pinball-leaderboard/

# 3. Create .env file
cd /opt/pinball-leaderboard
cp .env.example .env
nano .env  # Fill in your credentials

# 4. Update docker-compose.yml to mount .env
nano docker-compose.yml  # Add .env to volumes

# 5. Deploy
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 6. Test
curl http://localhost:5050/api/health | jq
```

**But seriously, read INTEGRATION_GUIDE.md for proper testing!**

## 🔍 Verification Steps

After deployment, run these commands to verify everything works:

```bash
# 1. Health check
curl http://localhost:5050/api/health

# Should return: {"status": "healthy", "database": "connected", ...}

# 2. Top 10 players
curl http://localhost:5050/api/leaderboard/top10 | jq

# Should return: Array of 10 players with real names

# 3. Game champions
curl http://localhost:5050/api/game-champions | jq

# Should return: Array of machines with champions

# 4. Recent activity
curl http://localhost:5050/api/recent-activity | jq

# Should return: Array of recent games

# 5. Statistics
curl http://localhost:5050/api/statistics | jq

# Should return: Object with league statistics
```

## 🐛 Troubleshooting

### Container won't start?
```bash
docker-compose logs -f
```
Look for the error message and check INTEGRATION_GUIDE.md troubleshooting section.

### Can't connect to database?
```bash
# Test from server
psql -h localhost -U pinball -d pinball_analytics

# If that works, check your .env file
cat /opt/pinball-leaderboard/.env
```

### Views return no data?
```bash
# Check if you have data
psql -U pinball -d pinball_analytics -c "SELECT COUNT(*) FROM High_Scores_Archive;"

# If 0, run your n8n workflow to populate data
```

### API returns 500 errors?
```bash
# Check if views exist
psql -U pinball -d pinball_analytics -c "\dv"

# Should list: leaderboard_current, game_champions, etc.
# If not, run database_views.sql again
```

## 📚 Documentation Order

**Recommended reading order:**

1. **README.md** (this file) - Overview
2. **INTEGRATION_SUMMARY.md** - Architecture and design
3. **INTEGRATION_GUIDE.md** - Step-by-step deployment ⭐
4. **DATABASE_REFERENCE.md** - Keep handy for troubleshooting

## 🎮 What You'll See

After successful deployment, your leaderboard at https://pinball.thedelay.org will show:

- **Scene 1:** Real top 10 players from your league
- **Scene 2:** Actual champions for each pinball machine
- **Scene 3:** Recent games with real timestamps
- **Scene 4:** Full roster of all players
- **Scene 5:** Live statistics from your data

All updating automatically as your n8n workflow runs!

## ⏱️ Time Estimate

- **Reading docs:** 15 minutes
- **Creating views:** 5 minutes
- **Updating files:** 10 minutes
- **Testing connection:** 5 minutes
- **Deploying:** 5 minutes
- **Verification:** 5 minutes

**Total: ~45 minutes**

## 🆘 Need Help?

1. Check the logs: `docker-compose logs -f`
2. Review INTEGRATION_GUIDE.md troubleshooting section
3. Test database connection: `psql -U pinball -d pinball_analytics`
4. Verify views exist: `\dv` in psql
5. Test health endpoint: `curl http://localhost:5050/api/health`

## ✅ Success Checklist

You'll know it worked when:

- [ ] Health endpoint returns "healthy"
- [ ] All 5 API endpoints return data
- [ ] Web interface shows real player names
- [ ] Recent activity has actual timestamps
- [ ] Statistics reflect your league data
- [ ] Rankings update when n8n runs

## 🎯 Next Steps

After successful integration:

1. Customize `config.json` with your bar's branding
2. Update n8n workflow to refresh views after ingestion
3. Add monitoring alerts for /api/health endpoint
4. Consider performance optimizations if needed
5. Show it to the bar owner! 🎉

## 🔐 Security Notes

- **.env file contains passwords** - Never commit to git!
- **File permissions:** `chmod 600 .env`
- **.gitignore:** Verify .env is listed
- **Database user:** Use read-only credentials if possible
- **Firewall:** Restrict PostgreSQL port access

## 📊 Performance

Expected performance after integration:

- API response time: <100ms
- Query execution: <50ms
- Memory usage: ~100MB
- CPU usage: <5%
- Concurrent users: 50+

If you need better performance, see INTEGRATION_GUIDE.md for materialized view options.

## 🎉 You're Ready!

Open **INTEGRATION_GUIDE.md** and follow the step-by-step instructions.

Good luck, and enjoy your real-time pinball leaderboard! 🏆

---

**Questions?** 
- Check the logs
- Review the guides
- Test the endpoints
- You got this! 💪
