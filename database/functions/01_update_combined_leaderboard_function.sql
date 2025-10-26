-- Function to calculate and update the Leaderboard_Cache
CREATE OR REPLACE FUNCTION update_combined_leaderboard(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_event_code VARCHAR(100) -- Added event_code parameter for multi-event support
)
RETURNS VOID AS $$
BEGIN
    -- 1. Clear the old cache (or truncate if you don't partition by event)
    TRUNCATE TABLE Leaderboard_Cache;

    -- 2. Calculate the new Combined Score and populate the cache
    INSERT INTO Leaderboard_Cache (player_id, combined_score, current_rank)
    WITH RankedScores AS (
        -- Step 2a: Filter to event, find the max score per player per machine
        SELECT
            h.player_id,
            h.machine_id,
            -- Use window function to rank scores within each machine
            RANK() OVER (
                PARTITION BY h.machine_id
                ORDER BY MAX(h.high_score) DESC
            ) AS machine_rank
        FROM
            High_Scores_Archive h
        WHERE
            h.event_code = p_event_code
            AND h.date_set >= p_start_date
            AND h.date_set < p_end_date
        GROUP BY
            h.player_id, h.machine_id
    ),
    ScoredRanks AS (
        -- Step 2b: Assign points based on the custom scoring logic (100, 90, GREATEST(0, 88-N))
        SELECT
            player_id,
            (CASE
                WHEN machine_rank = 1 THEN 100
                WHEN machine_rank = 2 THEN 90
                WHEN machine_rank >= 3 THEN GREATEST(0, 88 - machine_rank)
                ELSE 0
            END) AS rank_points
        FROM
            RankedScores
    ),
    CombinedScores AS (
        -- Step 2c: Sum the points for the total Combined Score and determine overall rank
        SELECT
            player_id,
            SUM(rank_points) AS total_combined_score,
            RANK() OVER (ORDER BY SUM(rank_points) DESC) AS overall_rank
        FROM
            ScoredRanks
        GROUP BY
            player_id
    )
    SELECT
        player_id,
        total_combined_score,
        overall_rank
    FROM
        CombinedScores
    WHERE total_combined_score > 0;

END;
$$ LANGUAGE plpgsql;
