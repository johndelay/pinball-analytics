-- Daily statistics tracking for trend analysis and reporting
-- Safe to run multiple times (idempotent)

CREATE TABLE IF NOT EXISTS Daily_Stats (
    snapshot_date DATE PRIMARY KEY,
    total_scores INTEGER NOT NULL,
    total_players INTEGER NOT NULL,
    total_machines INTEGER NOT NULL,
    new_scores_today INTEGER DEFAULT 0,
    updated_scores_today INTEGER DEFAULT 0,
    active_players_today INTEGER DEFAULT 0,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for date range queries (for Grafana dashboards)
CREATE INDEX IF NOT EXISTS idx_daily_stats_date 
ON Daily_Stats(snapshot_date DESC);

-- View for growth trends (7-day rolling average)
CREATE OR REPLACE VIEW weekly_growth_trends AS
SELECT 
    snapshot_date,
    total_scores,
    total_players,
    new_scores_today,
    AVG(new_scores_today) OVER (
        ORDER BY snapshot_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as avg_new_scores_7d,
    total_scores - LAG(total_scores, 7) OVER (ORDER BY snapshot_date) as weekly_score_growth
FROM Daily_Stats
ORDER BY snapshot_date DESC;

COMMENT ON TABLE Daily_Stats IS 'Daily snapshot of system metrics for historical trend analysis';
COMMENT ON VIEW weekly_growth_trends IS '7-day rolling averages for Grafana dashboards';
