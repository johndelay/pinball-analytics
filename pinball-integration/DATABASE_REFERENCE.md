# 📊 Database Schema Quick Reference

## Tables Overview

### Core Data Tables

**Players**
```
player_id (PK)       - Unique player identifier
display_name         - Player's display name
avatar_url          - URL to player avatar
background_color_hex - Player's color theme
is_all_access       - Premium member flag
last_seen           - Last activity timestamp
```

**Machines**
```
machine_id (PK)     - Unique machine identifier (e.g., 'BAT', 'IM')
machine_name        - Full machine name (e.g., 'Batman')
artwork_url         - Machine artwork URL
is_active           - Whether machine is currently active
```

**High_Scores_Archive** (Raw game data)
```
score_id (PK)       - Auto-increment ID
player_id (FK)      - References Players
machine_id (FK)     - References Machines
high_score          - The score value
date_set            - When score was achieved
event_code (FK)     - Which event/tournament
score_source        - 'API', 'MANUAL', etc.
is_approved         - Whether score is validated
```

**Leaderboard_Cache** (Pre-calculated rankings) ⭐
```
player_id (PK, FK)  - References Players
combined_score      - Total score across all games
current_rank        - Player's current rank
last_updated        - When this was last calculated
```

### History & Tracking Tables

**Leaderboard_History** (Snapshots for trends)
```
history_id (PK)     - Auto-increment ID
player_id (FK)      - References Players
combined_score      - Score at this snapshot
current_rank        - Rank at this snapshot
recorded_at         - When snapshot was taken
```

**Events** (Tournaments/Leagues)
```
event_code (PK)     - Unique event identifier
event_name          - Display name
start_date          - Event start
stop_date           - Event end
location_id         - Venue identifier
event_type          - 'STERN_LEAGUE', etc.
is_active           - Currently active event
```

**Api_Snapshots** (Audit trail)
```
snapshot_id (PK)    - Auto-increment ID
event_code (FK)     - Which event was fetched
fetched_at          - Timestamp of API call
raw_response        - Complete JSON response (JSONB)
```

**Daily_Stats** (Aggregate metrics)
```
snapshot_date (PK)  - Date of snapshot
total_scores        - Total scores in system
total_players       - Total players
total_machines      - Total machines
new_scores_today    - Scores added this day
active_players_today - Players who played today
recorded_at         - When snapshot was taken
```

## Views Created for Leaderboard App

### leaderboard_current
**Purpose:** Main leaderboard with trends
**Key columns:** rank, name, score, games_played, trend, trend_positions
**Data source:** Leaderboard_Cache + Leaderboard_History
**Used by:** Top 10 scene, Full roster scene

### game_champions
**Purpose:** Highest score per machine
**Key columns:** name (machine), champion (player), score
**Data source:** High_Scores_Archive (grouped by machine_id)
**Used by:** Game Champions scene

### recent_activity
**Purpose:** Latest games played
**Key columns:** player, game, score, timestamp, minutes_ago, is_personal_best
**Data source:** High_Scores_Archive (ordered by date_set)
**Used by:** Recent Activity scene

### league_statistics
**Purpose:** Overall league metrics
**Key columns:** games_this_week, games_this_month, active_players, average_score, most_popular_game, busiest_day
**Data source:** Aggregated from High_Scores_Archive
**Used by:** Statistics scene

## Key Relationships

```
Players (1) ─────< High_Scores_Archive (M)
                   ↓
                   Uses player_id
                   
Machines (1) ────< High_Scores_Archive (M)
                   ↓
                   Uses machine_id
                   
Events (1) ──────< High_Scores_Archive (M)
                   ↓
                   Uses event_code
                   
Players (1) ─────< Leaderboard_Cache (1)
                   ↓
                   One-to-one current ranking
                   
Players (1) ─────< Leaderboard_History (M)
                   ↓
                   Historical snapshots
```

## Important Indexes

```sql
-- For leaderboard lookups
idx_leaderboard_cache_rank ON Leaderboard_Cache(current_rank)

-- For recent activity
idx_high_scores_date_approved ON High_Scores_Archive(date_set DESC)

-- For game champions
idx_high_scores_player_machine ON High_Scores_Archive(player_id, machine_id)

-- For score lookups (from init scripts)
idx_scores_lookup ON High_Scores_Archive(event_code, machine_id, player_id)
idx_scores_date_set ON High_Scores_Archive(date_set)
```

## Data Flow

```
1. Stern API
   ↓
2. n8n Workflow (fetches scores)
   ↓
3. Api_Snapshots (stores raw JSON)
   ↓
4. High_Scores_Archive (parsed scores)
   ↓
5. update_combined_leaderboard() function
   ↓
6. Leaderboard_Cache (calculated rankings)
   ↓
7. Leaderboard_History (snapshots)
   ↓
8. Leaderboard Views (for display)
   ↓
9. Flask API (serves to frontend)
   ↓
10. Kiosk Display (shows to players)
```

## Critical Functions

### update_combined_leaderboard()
**Purpose:** Calculates combined scores and rankings
**Located:** database/functions/*.sql
**Triggered by:** n8n workflow after data ingestion
**Updates:** Leaderboard_Cache table

## Common Queries

### Get a player's stats
```sql
SELECT 
    p.display_name,
    lc.combined_score,
    lc.current_rank,
    COUNT(hsa.score_id) as total_games
FROM Players p
JOIN Leaderboard_Cache lc ON p.player_id = lc.player_id
LEFT JOIN High_Scores_Archive hsa ON p.player_id = hsa.player_id
WHERE p.player_id = 'PLAYER_ID_HERE'
GROUP BY p.display_name, lc.combined_score, lc.current_rank;
```

### Get machine leaderboard
```sql
SELECT 
    p.display_name,
    MAX(hsa.high_score) as best_score,
    COUNT(*) as times_played
FROM High_Scores_Archive hsa
JOIN Players p ON hsa.player_id = p.player_id
WHERE hsa.machine_id = 'BAT'  -- Batman
  AND hsa.is_approved = TRUE
GROUP BY p.display_name
ORDER BY best_score DESC
LIMIT 10;
```

### Get player's recent games
```sql
SELECT 
    m.machine_name,
    hsa.high_score,
    hsa.date_set
FROM High_Scores_Archive hsa
JOIN Machines m ON hsa.machine_id = m.machine_id
WHERE hsa.player_id = 'PLAYER_ID_HERE'
  AND hsa.is_approved = TRUE
ORDER BY hsa.date_set DESC
LIMIT 10;
```

## Environment Variables Needed

```bash
DB_HOST=localhost          # PostgreSQL server
DB_PORT=5432              # PostgreSQL port
DB_NAME=pinball_analytics # Database name
DB_USER=pinball           # Database user
DB_PASSWORD=***           # Database password
```

## Maintenance Queries

### Check data freshness
```sql
SELECT 
    'High Scores' as table_name,
    MAX(date_set) as last_entry,
    COUNT(*) as total_records
FROM High_Scores_Archive
UNION ALL
SELECT 
    'API Snapshots',
    MAX(fetched_at),
    COUNT(*)
FROM Api_Snapshots;
```

### Find duplicate scores (shouldn't exist)
```sql
SELECT 
    player_id,
    machine_id,
    high_score,
    event_code,
    COUNT(*) as duplicates
FROM High_Scores_Archive
GROUP BY player_id, machine_id, high_score, event_code
HAVING COUNT(*) > 1;
```

### Check leaderboard consistency
```sql
SELECT 
    COUNT(*) as total_players,
    MIN(current_rank) as lowest_rank,
    MAX(current_rank) as highest_rank
FROM Leaderboard_Cache;
-- Should have consecutive ranks 1, 2, 3...
```

---

This is your database at a glance! Keep this handy for quick reference.
