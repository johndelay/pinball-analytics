-- Database Views for Pinball Leaderboard Kiosk
-- These views are optimized for your actual schema structure
-- Run these after your database is initialized

-- ==============================================
-- VIEW 1: Current Leaderboard with Trends
-- ==============================================
CREATE OR REPLACE VIEW leaderboard_current AS
WITH current_rankings AS (
    SELECT 
        lc.player_id,
        p.display_name as name,
        lc.combined_score as score,
        lc.current_rank as rank,
        p.avatar_url,
        p.background_color_hex,
        p.last_seen,
        lc.last_updated
    FROM Leaderboard_Cache lc
    JOIN Players p ON lc.player_id = p.player_id
),
games_played AS (
    SELECT 
        player_id,
        COUNT(*) as games_played
    FROM High_Scores_Archive
    WHERE is_approved = TRUE
    GROUP BY player_id
),
rank_history AS (
    -- Get rank from 24 hours ago for trend calculation
    SELECT DISTINCT ON (player_id)
        player_id,
        current_rank as rank_24h_ago
    FROM Leaderboard_History
    WHERE recorded_at <= NOW() - INTERVAL '24 hours'
    ORDER BY player_id, recorded_at DESC
)
SELECT 
    cr.rank,
    cr.name,
    cr.score,
    COALESCE(gp.games_played, 0) as games_played,
    CASE 
        WHEN rh.rank_24h_ago IS NULL THEN 'stable'
        WHEN rh.rank_24h_ago > cr.rank THEN 'up'
        WHEN rh.rank_24h_ago < cr.rank THEN 'down'
        ELSE 'stable'
    END as trend,
    COALESCE(ABS(rh.rank_24h_ago - cr.rank), 0) as trend_positions,
    cr.last_seen,
    cr.avatar_url,
    cr.background_color_hex
FROM current_rankings cr
LEFT JOIN games_played gp ON cr.player_id = gp.player_id
LEFT JOIN rank_history rh ON cr.player_id = rh.player_id
ORDER BY cr.rank;

-- ==============================================
-- VIEW 2: Game Champions (High Score per Machine)
-- ==============================================
CREATE OR REPLACE VIEW game_champions AS
SELECT DISTINCT ON (hsa.machine_id)
    m.machine_name as name,
    p.display_name as champion,
    hsa.high_score as score,
    m.artwork_url,
    hsa.date_set
FROM High_Scores_Archive hsa
JOIN Machines m ON hsa.machine_id = m.machine_id
JOIN Players p ON hsa.player_id = p.player_id
WHERE hsa.is_approved = TRUE
  AND m.is_active = TRUE
ORDER BY hsa.machine_id, hsa.high_score DESC;

-- ==============================================
-- VIEW 3: Recent Activity Feed
-- ==============================================
CREATE OR REPLACE VIEW recent_activity AS
WITH player_machine_bests AS (
    SELECT 
        player_id,
        machine_id,
        MAX(high_score) as best_score
    FROM High_Scores_Archive
    WHERE is_approved = TRUE
    GROUP BY player_id, machine_id
)
SELECT 
    p.display_name as player,
    m.machine_name as game,
    hsa.high_score as score,
    hsa.date_set as timestamp,
    EXTRACT(EPOCH FROM (NOW() - hsa.date_set))/60 as minutes_ago,
    (hsa.high_score = pmb.best_score) as is_personal_best,
    p.background_color_hex,
    m.artwork_url
FROM High_Scores_Archive hsa
JOIN Players p ON hsa.player_id = p.player_id
JOIN Machines m ON hsa.machine_id = m.machine_id
LEFT JOIN player_machine_bests pmb 
    ON hsa.player_id = pmb.player_id 
    AND hsa.machine_id = pmb.machine_id
WHERE hsa.is_approved = TRUE
ORDER BY hsa.date_set DESC
LIMIT 20;

-- ==============================================
-- VIEW 4: League Statistics
-- ==============================================
CREATE OR REPLACE VIEW league_statistics AS
WITH time_filtered_scores AS (
    SELECT 
        date_set,
        player_id,
        high_score
    FROM High_Scores_Archive
    WHERE is_approved = TRUE
)
SELECT 
    COUNT(*) FILTER (WHERE date_set > NOW() - INTERVAL '7 days') as games_this_week,
    COUNT(*) FILTER (WHERE date_set > NOW() - INTERVAL '30 days') as games_this_month,
    (SELECT COUNT(*) FROM Leaderboard_Cache) as active_players,
    COALESCE(AVG(high_score)::BIGINT, 0) as average_score,
    (
        SELECT m.machine_name
        FROM High_Scores_Archive hsa
        JOIN Machines m ON hsa.machine_id = m.machine_id
        WHERE hsa.is_approved = TRUE
          AND hsa.date_set > NOW() - INTERVAL '30 days'
        GROUP BY m.machine_name
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) as most_popular_game,
    (
        SELECT TO_CHAR(date_set, 'Day')
        FROM High_Scores_Archive
        WHERE is_approved = TRUE
          AND date_set > NOW() - INTERVAL '30 days'
        GROUP BY TO_CHAR(date_set, 'Day')
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) as busiest_day
FROM time_filtered_scores;

-- ==============================================
-- VIEW 5: Top Performers This Week
-- ==============================================
CREATE OR REPLACE VIEW weekly_top_performers AS
SELECT 
    p.display_name as player_name,
    COUNT(*) as games_played_this_week,
    SUM(hsa.high_score) as total_score_this_week,
    AVG(hsa.high_score)::BIGINT as avg_score,
    MAX(hsa.high_score) as best_score
FROM High_Scores_Archive hsa
JOIN Players p ON hsa.player_id = p.player_id
WHERE hsa.is_approved = TRUE
  AND hsa.date_set > NOW() - INTERVAL '7 days'
GROUP BY p.display_name
ORDER BY total_score_this_week DESC
LIMIT 10;

-- ==============================================
-- INDEXES for Performance (if not already created)
-- ==============================================
-- These may already exist from your init scripts
CREATE INDEX IF NOT EXISTS idx_leaderboard_cache_rank 
    ON Leaderboard_Cache(current_rank);

CREATE INDEX IF NOT EXISTS idx_high_scores_date_approved 
    ON High_Scores_Archive(date_set DESC) WHERE is_approved = TRUE;

CREATE INDEX IF NOT EXISTS idx_high_scores_player_machine 
    ON High_Scores_Archive(player_id, machine_id) WHERE is_approved = TRUE;

-- ==============================================
-- COMMENTS for Documentation
-- ==============================================
COMMENT ON VIEW leaderboard_current IS 'Current leaderboard with rank trends (24h comparison)';
COMMENT ON VIEW game_champions IS 'Highest score per machine (active machines only)';
COMMENT ON VIEW recent_activity IS 'Last 20 games played with personal best flags';
COMMENT ON VIEW league_statistics IS 'League-wide statistics for kiosk display';
COMMENT ON VIEW weekly_top_performers IS 'Top 10 players by total score this week';

-- ==============================================
-- TEST QUERIES (Comment out after testing)
-- ==============================================
-- SELECT * FROM leaderboard_current LIMIT 10;
-- SELECT * FROM game_champions;
-- SELECT * FROM recent_activity LIMIT 10;
-- SELECT * FROM league_statistics;
