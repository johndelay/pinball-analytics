# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a PostgreSQL-based pinball leaderboard analytics system that tracks high scores from pinball tournaments (specifically Stern League events). The system processes API snapshots, stores immutable score data, and calculates combined leaderboards using a custom scoring algorithm.

## Database Setup Commands

All database operations require environment variables to be sourced first:

```bash
source .env
```

### Common Database Operations

- **Initialize/Reset Database**: `./bootstrap_db.sh <DB_NAME> --init-tables`
  - Drops and recreates the database, then runs all SQL scripts
  - Requires postgres superuser access for database creation
  - Prompts for confirmation before wiping

- **Update Existing Database**: `./bootstrap_db.sh <DB_NAME>`
  - Runs SQL scripts against existing database without wiping
  - Use this for schema updates or repairs

- **Show Database Structure**: `./bootstrap_db.sh <DB_NAME> --show-current`
  - Lists all tables in the specified database

- **Help**: `./bootstrap_db.sh`
  - Displays usage instructions

### SQL Execution Order

The bootstrap script executes SQL files in this order:

1. **Phase 1 - Core Schema** (`database/init/`):
   - `01_schema_tables.sql`: Creates all tables
   - `02_constraints_indexes.sql`: Adds constraints and indexes
   - `03_seed_data.sql`: Initial data population

2. **Phase 2 - Business Logic** (`database/functions/`):
   - `01_update_combined_leaderboard_function.sql`: Scoring calculation function

## Database Architecture

### Table Structure and Data Flow

```
API Fetch → Api_Snapshots (immutable audit trail)
              ↓
          (Processing)
              ↓
High_Scores_Archive (source of truth) → update_combined_leaderboard() → Leaderboard_Cache (kiosk display)
     ↓               ↓
  Players        Machines
     ↓
  Events
```

### Core Tables

- **Players**: Player profile data (player_id is primary key, includes all-access flag)
- **Machines**: Pinball machine metadata (machine_id like 'BAT', 'IM')
- **Events**: Tournament events with date ranges and event_code (e.g., 'hJjW-WXu-oCGQ')
- **Api_Snapshots**: Immutable JSONB storage of raw API responses
- **High_Scores_Archive**: Normalized score records with foreign keys to Players, Machines, Events
- **Leaderboard_Cache**: Pre-calculated rankings for fast kiosk display

### Key Constraints

- **Unique Score Constraint**: `unique_score_per_event` on High_Scores_Archive prevents duplicate scores for the same player/machine/event combination
- **Performance Indexes**:
  - `idx_scores_lookup` on (event_code, machine_id, player_id)
  - `idx_scores_date_set` on date_set for temporal queries
  - `idx_snapshots_event_time` on API snapshots

## Scoring Logic

The `update_combined_leaderboard()` function implements the league scoring system:

- **1st place per machine**: 100 points
- **2nd place per machine**: 90 points
- **3rd+ place per machine**: GREATEST(0, 88 - rank)
  - 3rd = 85 points, 4th = 84 points, etc., down to 0

The function takes parameters:
- `p_start_date`: Beginning of scoring period
- `p_end_date`: End of scoring period
- `p_event_code`: Event identifier for multi-event support

Players are ranked by their total combined score across all machines for the event period.

## Configuration

The `.env` file (not committed to git) contains:
- `DB_USER`: PostgreSQL username
- `DB_PASSWORD`: Database password
- `DB_HOST`: Database server hostname/IP
