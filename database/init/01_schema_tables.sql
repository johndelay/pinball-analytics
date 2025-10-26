-- Core Tables
CREATE TABLE Players (
    player_id VARCHAR(100) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    background_color_hex VARCHAR(7),
    is_all_access BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Machines (
    machine_id VARCHAR(50) PRIMARY KEY, -- e.g., 'BAT', 'IM'
    machine_name VARCHAR(100) NOT NULL,
    artwork_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- For Tournament Management
CREATE TABLE Events (
    event_code VARCHAR(100) PRIMARY KEY, -- e.g., 'hJjW-WXu-oCGQ'
    event_name VARCHAR(255) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    stop_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location_id VARCHAR(50), 
    event_type VARCHAR(50) NOT NULL DEFAULT 'STERN_LEAGUE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- The Immutable Audit Trail
CREATE TABLE Api_Snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    event_code VARCHAR(100) REFERENCES Events(event_code),
    fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), 
    raw_response JSONB NOT NULL
);

-- The Source of Truth for Calculations
CREATE TABLE High_Scores_Archive (
    score_id SERIAL PRIMARY KEY,
    player_id VARCHAR(100) REFERENCES Players(player_id),
    machine_id VARCHAR(50) REFERENCES Machines(machine_id),
    high_score BIGINT NOT NULL,
    date_set TIMESTAMP WITH TIME ZONE NOT NULL,
    event_code VARCHAR(100) REFERENCES Events(event_code),
    score_source VARCHAR(20) NOT NULL DEFAULT 'API',
    is_approved BOOLEAN NOT NULL DEFAULT TRUE
);

-- Fast Display for Kiosk
CREATE TABLE Leaderboard_Cache (
    player_id VARCHAR(100) PRIMARY KEY REFERENCES Players(player_id),
    combined_score INTEGER NOT NULL,
    current_rank INTEGER NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
