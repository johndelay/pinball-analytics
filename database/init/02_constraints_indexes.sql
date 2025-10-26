-- Unique constraint for Smart Filtering logic 
-- (Ensures no identical score is saved more than once per event)
ALTER TABLE High_Scores_Archive
    ADD CONSTRAINT unique_score_per_event
        UNIQUE (player_id, machine_id, high_score, event_code);

-- Indexes for performance lookups (for Smart Filtering and Calculations)
CREATE INDEX idx_scores_lookup ON High_Scores_Archive(event_code, machine_id, player_id);
CREATE INDEX idx_scores_date_set ON High_Scores_Archive(date_set);

-- Index for Audit Snapshots
CREATE INDEX idx_snapshots_event_time ON Api_Snapshots(event_code, fetched_at DESC);
