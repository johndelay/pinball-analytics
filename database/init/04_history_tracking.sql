-- Historical tracking for Grafana dashboards
-- Safe to run multiple times (idempotent)

-- Leaderboard history snapshots
CREATE TABLE IF NOT EXISTS Leaderboard_History (
    history_id SERIAL PRIMARY KEY,
    player_id VARCHAR(100) REFERENCES Players(player_id),
    combined_score INTEGER,
    current_rank INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_history_recorded 
ON Leaderboard_History(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_history_player_time 
ON Leaderboard_History(player_id, recorded_at DESC);

-- Workflow health monitoring view
CREATE OR REPLACE VIEW workflow_health AS
SELECT 
    MAX(fetched_at) as last_successful_run,
    COUNT(*) as total_runs_today,
    COUNT(*) FILTER (WHERE fetched_at > NOW() - INTERVAL '1 hour') as runs_last_hour,
    COUNT(*) FILTER (WHERE fetched_at > NOW() - INTERVAL '24 hours') as runs_last_24h
FROM Api_Snapshots
WHERE fetched_at > CURRENT_DATE;

-- Rank change tracking view (last 72 hours)
CREATE OR REPLACE VIEW recent_rank_changes AS
SELECT 
    p.display_name,
    h1.current_rank as current_rank,
    h2.current_rank as rank_72h_ago,
    (h2.current_rank - h1.current_rank) as rank_change,
    h1.combined_score - h2.combined_score as score_gain
FROM Leaderboard_History h1
JOIN Players p ON h1.player_id = p.player_id
LEFT JOIN LATERAL (
    SELECT current_rank, combined_score
    FROM Leaderboard_History h2
    WHERE h2.player_id = h1.player_id
      AND h2.recorded_at <= NOW() - INTERVAL '72 hours'
    ORDER BY h2.recorded_at DESC
    LIMIT 1
) h2 ON true
WHERE h1.recorded_at = (
    SELECT MAX(recorded_at) 
    FROM Leaderboard_History
)
AND h2.current_rank IS NOT NULL
ORDER BY rank_change DESC;
