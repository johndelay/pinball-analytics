# PostgreSQL Integration Guide

This guide will help you connect the leaderboard to your actual PostgreSQL database with data from your n8n workflow.

## Prerequisites

- PostgreSQL database with pinball analytics data
- Database credentials
- n8n workflow successfully populating data

## Step 1: Understand Your Database Schema

First, we need to know what tables and columns exist in your database. Common structures:

### Option A: Single Player Stats Table
```sql
CREATE TABLE player_stats (
    player_id SERIAL PRIMARY KEY,
    player_name VARCHAR(100),
    total_score BIGINT,
    games_played INT,
    last_played TIMESTAMP,
    created_at TIMESTAMP
);
```

### Option B: Game Logs Table
```sql
CREATE TABLE game_logs (
    game_id SERIAL PRIMARY KEY,
    player_name VARCHAR(100),
    machine_name VARCHAR(100),
    score BIGINT,
    played_at TIMESTAMP
);
```

**ACTION NEEDED**: 
1. Connect to your PostgreSQL: `psql -h your-host -U your-user -d your-database`
2. List tables: `\dt`
3. Describe tables: `\d table_name`
4. Share schema with Claude for custom queries

## Step 2: Create Database Views

Create views to simplify queries and calculations. These views can be refreshed by your n8n workflow.

### Leaderboard View
```sql
CREATE OR REPLACE VIEW leaderboard_current AS
WITH ranked_players AS (
    SELECT 
        player_name,
        SUM(score) as total_score,
        COUNT(*) as games_played,
        MAX(played_at) as last_played,
        RANK() OVER (ORDER BY SUM(score) DESC) as current_rank
    FROM game_logs
    GROUP BY player_name
),
previous_ranks AS (
    -- This would come from a historical_ranks table
    -- For now, we'll calculate trend as NULL
    SELECT player_name, 0 as previous_rank
    FROM game_logs
    GROUP BY player_name
)
SELECT 
    rp.current_rank as rank,
    rp.player_name as name,
    rp.total_score as score,
    rp.games_played,
    rp.last_played,
    CASE 
        WHEN pr.previous_rank > rp.current_rank THEN 'up'
        WHEN pr.previous_rank < rp.current_rank THEN 'down'
        ELSE 'stable'
    END as trend,
    ABS(pr.previous_rank - rp.current_rank) as trend_positions
FROM ranked_players rp
LEFT JOIN previous_ranks pr ON rp.player_name = pr.player_name
ORDER BY rp.current_rank;
```

### Game Champions View
```sql
CREATE OR REPLACE VIEW game_champions AS
SELECT DISTINCT ON (machine_name)
    machine_name as game_name,
    player_name as champion,
    score as high_score
FROM game_logs
ORDER BY machine_name, score DESC;
```

### Recent Activity View
```sql
CREATE OR REPLACE VIEW recent_activity AS
WITH player_bests AS (
    SELECT player_name, machine_name, MAX(score) as best_score
    FROM game_logs
    GROUP BY player_name, machine_name
)
SELECT 
    gl.player_name,
    gl.machine_name as game_name,
    gl.score,
    gl.played_at,
    EXTRACT(EPOCH FROM (NOW() - gl.played_at))/60 as minutes_ago,
    (gl.score = pb.best_score) as is_personal_best
FROM game_logs gl
LEFT JOIN player_bests pb 
    ON gl.player_name = pb.player_name 
    AND gl.machine_name = pb.machine_name
ORDER BY gl.played_at DESC
LIMIT 20;
```

### Statistics View
```sql
CREATE OR REPLACE VIEW league_statistics AS
SELECT 
    COUNT(CASE WHEN played_at > NOW() - INTERVAL '7 days' THEN 1 END) as games_this_week,
    COUNT(CASE WHEN played_at > NOW() - INTERVAL '30 days' THEN 1 END) as games_this_month,
    COUNT(DISTINCT player_name) as active_players,
    AVG(score)::BIGINT as average_score,
    (SELECT machine_name FROM game_logs 
     GROUP BY machine_name 
     ORDER BY COUNT(*) DESC 
     LIMIT 1) as most_popular_game,
    (SELECT TO_CHAR(played_at, 'Day') FROM game_logs
     GROUP BY TO_CHAR(played_at, 'Day')
     ORDER BY COUNT(*) DESC
     LIMIT 1) as busiest_day
FROM game_logs;
```

## Step 3: Update app.py

Replace the sample data functions with real database queries:

```python
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """Create database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD')
    )

@app.route('/api/leaderboard/top10')
def top_10():
    """Get top 10 players from database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                rank,
                name,
                score,
                games_played,
                trend,
                trend_positions,
                last_played
            FROM leaderboard_current
            WHERE rank <= 10
            ORDER BY rank
        """)
        
        players = cur.fetchall()
        
        # Convert to JSON-serializable format
        for player in players:
            if player['last_played']:
                player['last_played'] = player['last_played'].isoformat()
        
        cur.close()
        conn.close()
        
        return jsonify(players)
    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"error": "Database error"}), 500

@app.route('/api/leaderboard/full')
def full_leaderboard():
    """Get all players from database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT rank, name, score, games_played
            FROM leaderboard_current
            ORDER BY rank
        """)
        
        players = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify(players)
    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"error": "Database error"}), 500

@app.route('/api/game-champions')
def game_champions():
    """Get champions for each game"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                game_name as name,
                champion,
                high_score as score
            FROM game_champions
            ORDER BY game_name
        """)
        
        champions = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify(champions)
    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"error": "Database error"}), 500

@app.route('/api/recent-activity')
def recent_activity():
    """Get recent game activity"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                player_name as player,
                game_name as game,
                score,
                played_at as timestamp,
                minutes_ago,
                is_personal_best
            FROM recent_activity
            ORDER BY played_at DESC
            LIMIT 15
        """)
        
        activities = cur.fetchall()
        
        # Convert timestamps
        for activity in activities:
            if activity['timestamp']:
                activity['timestamp'] = activity['timestamp'].isoformat()
        
        cur.close()
        conn.close()
        
        return jsonify(activities)
    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"error": "Database error"}), 500

@app.route('/api/statistics')
def statistics():
    """Get league statistics"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT 
                games_this_week as total_games_this_week,
                games_this_month as total_games_this_month,
                active_players,
                average_score,
                most_popular_game,
                TRIM(busiest_day) as busiest_day
            FROM league_statistics
        """)
        
        stats = cur.fetchone()
        cur.close()
        conn.close()
        
        return jsonify(stats)
    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"error": "Database error"}), 500
```

## Step 4: Configure Environment Variables

Create a `.env` file with your database credentials:

```bash
DB_HOST=your-postgres-host-or-ip
DB_PORT=5432
DB_NAME=pinball_analytics
DB_USER=your-db-user
DB_PASSWORD=your-db-password
FLASK_ENV=production
```

**IMPORTANT**: Never commit this file to git! It's already in .gitignore.

## Step 5: Update docker-compose.yml

Add environment variables to docker-compose:

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
      - ./.env:/app/.env  # Mount .env file
    environment:
      - FLASK_ENV=production
    restart: unless-stopped
    networks:
      - pinball-network

networks:
  pinball-network:
    driver: bridge
```

## Step 6: Test Database Connection

Before deploying, test the connection:

```bash
# Shell into container
docker-compose exec pinball-leaderboard /bin/bash

# Test Python connection
python3 << EOF
import psycopg2
conn = psycopg2.connect(
    host='your-host',
    database='your-db',
    user='your-user',
    password='your-password'
)
print("Connection successful!")
conn.close()
EOF
```

## Step 7: Deploy with Database

```bash
# Create .env file
nano .env
# Add your database credentials

# Rebuild and restart
docker-compose down
docker-compose up -d --build

# Check logs
docker-compose logs -f
```

## Troubleshooting

### Connection refused
- Check DB host is accessible from Docker
- Verify PostgreSQL allows remote connections
- Check firewall rules
- Test: `telnet your-db-host 5432`

### Authentication failed
- Verify username/password
- Check PostgreSQL pg_hba.conf
- Ensure user has proper permissions

### Queries return no data
- Check if views exist: `\dv` in psql
- Verify views have data: `SELECT * FROM leaderboard_current;`
- Check n8n workflow is running

### Performance issues
- Add indexes to frequently queried columns
- Use materialized views (refresh periodically)
- Add connection pooling

## Optimization Tips

### Materialized Views (Better Performance)
```sql
CREATE MATERIALIZED VIEW leaderboard_current AS
-- ... same query as before

-- Refresh in your n8n workflow or cron job
REFRESH MATERIALIZED VIEW leaderboard_current;
```

### Indexes
```sql
CREATE INDEX idx_game_logs_player ON game_logs(player_name);
CREATE INDEX idx_game_logs_played_at ON game_logs(played_at DESC);
CREATE INDEX idx_game_logs_machine ON game_logs(machine_name);
```

### Connection Pooling
Consider using pgBouncer if you have many concurrent connections.

## n8n Integration

Update your n8n workflow to:
1. Ingest data (as currently done)
2. Refresh materialized views after ingestion
3. Calculate rank changes
4. Update historical_ranks table

Example PostgreSQL node in n8n:
```sql
-- After ingestion, refresh views
REFRESH MATERIALIZED VIEW leaderboard_current;
REFRESH MATERIALIZED VIEW game_champions;
REFRESH MATERIALIZED VIEW recent_activity;
REFRESH MATERIALIZED VIEW league_statistics;
```

## Testing Checklist

- [ ] Database connection works
- [ ] All API endpoints return data
- [ ] Top 10 shows correct players
- [ ] Game champions accurate
- [ ] Recent activity updates
- [ ] Statistics calculate correctly
- [ ] Rank changes display properly
- [ ] Performance is acceptable (<100ms queries)

## Next Steps

Once connected:
1. Monitor query performance
2. Add error handling
3. Implement caching if needed
4. Set up database backups
5. Consider read replicas for high traffic

Need help with your specific schema? Share your database structure and I'll write custom queries!
