#!/bin/bash
# Script: bootstrap_db.sh
# Purpose: Manages the Pinball Leaderboard PostgreSQL database setup.

# --- Instructions for Environment Variables ---
# This script requires the following environment variables to be set:
# DB_USER, DB_PASSWORD, and DB_HOST
# 
# To set them, run: source .env
# --------------------------------------------

# --- Configuration ---
# DB_NAME is passed as the first command-line argument ($1)
# ---------------------

# --- Helper Functions ---

# Function to display the help message
function show_help {
    echo "Usage: ./bootstrap_db.sh <DB_NAME> [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  <DB_NAME>         The name of the PostgreSQL database to manage (e.g., pinball_prod)"
    echo ""
    echo "Options:"
    echo "  --wipe-me         DANGER: Drops and recreates the specified database."
    echo "  --init-tables     Initializes or resets the database and creates all tables/functions."
    echo "  --show-current    Displays the configured database and its current table structure."
    echo ""
    echo "Example: source .env && ./bootstrap_db.sh pinball --init-tables"
    echo "Example: source .env && ./bootstrap_db.sh pinball"
    exit 0
}

# Function to execute the database wipe (Drop and Recreate)
function wipe_database {
    echo -e "\n\n!!! DANGER: You are about to manage the database: ${DB_NAME} on host ${DB_HOST} !!!"
    echo "This operation will drop the database if it exists, and then recreate it."
    read -r -p "Are you absolutely sure you want to proceed? (y/N): " response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Proceeding with database drop/recreation..."
        
        # Drop the database (requires superuser, typically 'postgres')
        psql -h ${DB_HOST} -U postgres -c "DROP DATABASE IF EXISTS ${DB_NAME}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to drop database. Check superuser permissions or if 'postgres' user can connect."
            exit 1
        fi
        
        # Create the database with the specified owner
        psql -h ${DB_HOST} -U postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create database. Check permissions or if user ${DB_USER} exists on the host."
            exit 1
        fi
        echo "Database ${DB_NAME} successfully initialized and recreated."
    else
        echo "Operation cancelled by user."
        exit 0
    fi
}

# Function to display database structure
function show_structure {
    echo -e "\n--- Current Database Configuration ---"
    echo "DB Name: ${DB_NAME}"
    echo "DB Host: ${DB_HOST}"
    echo "DB User: ${DB_USER}"
    
    echo -e "\n--- Current Table Structure (${DB_NAME}) ---"
    # The \dt command lists tables and is executed using psql
    psql -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} -c '\dt'
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not retrieve table structure. Check connection or if DB exists."
        exit 1
    fi
    exit 0
}

# --- Argument and Environment Checks ---

# 1. Display help if no arguments are provided
if [ $# -eq 0 ]; then
    show_help
fi

# 2. Assign the database name
DB_NAME="$1"

# 3. Check for required environment variables (DB_USER, DB_PASSWORD, DB_HOST)
if [ -z "${DB_USER}" ] || [ -z "${DB_PASSWORD}" ] || [ -z "${DB_HOST}" ]; then
    echo "ERROR: Missing required environment variables."
    echo "Please set DB_USER, DB_PASSWORD, and DB_HOST. Run: source .env"
    exit 1
fi

# 4. Check for known options (and execute if found)
case "$2" in
    --wipe-me|--init-tables)
        wipe_database
        # If wipe_database succeeds, the script continues to the Standard Bootstrap Execution
        ;;
    --show-current)
        show_structure
        ;;
    "")
        # No extra option, proceed to standard bootstrap
        ;;
    *)
        echo "ERROR: Unknown option '$2'. Use no option or see help message."
        show_help
        ;;
esac

# 5. TEST CONNECTION: Attempt a simple query to verify connectivity
echo "Attempting test connection to ${DB_USER}@${DB_HOST}:${DB_NAME}..."
# Using the exit code check ($?) for the connection
psql -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} -c "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    # --- ENHANCED ERROR CHECK AND INSTRUCTION ---
    echo "=========================================================================================="
    echo "🚨 ERROR: Failed to connect to the PostgreSQL server and database."
    echo "This usually means the database '${DB_NAME}' does not exist yet."
    echo "Please run the initialization command first to create the database:"
    echo ""
    echo "    ./bootstrap_db.sh ${DB_NAME} --init-tables"
    echo ""
    echo "=========================================================================================="
    exit 1
fi
echo "Connection successful. Starting schema setup..."

# --- Standard Bootstrap Execution ---

# 1. Run Initial Schema Setup (Tables, Indexes, Constraints)
echo "--- PHASE 1: Running core schema and constraints (database/init) ---"
for f in database/init/*.sql; do 
    echo "Executing $f..."
    psql -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} -f "$f"
    if [ $? -ne 0 ]; then
        echo "ERROR running $f. Aborting."
        exit 1
    fi
done

# 2. Run Functions and Views Setup (Business Logic: Recalculation)
echo "--- PHASE 2: Running functions and views (database/functions) ---"
for f in database/functions/*.sql; do
    echo "Executing $f..."
    psql -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} -f "$f"
    if [ $? -ne 0 ]; then
        echo "ERROR running $f. Aborting."
        exit 1
    fi
done

# 3. Run Sequence Repair (A preventative measure to fix issues like the one you just saw)
echo "--- PHASE 3: Fixing table sequences (to prevent duplicate key errors) ---"

# These commands dynamically find the sequence for each SERIAL column and 
# force-set the next value to MAX(ID) + 1, or 1 if the table is empty.
psql -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} -c "
SELECT setval(pg_get_serial_sequence('Api_Snapshots', 'snapshot_id'), COALESCE((SELECT MAX(snapshot_id) FROM Api_Snapshots) + 1, 1), false);
SELECT setval(pg_get_serial_sequence('High_Scores_Archive', 'score_id'), COALESCE((SELECT MAX(score_id) FROM High_Scores_Archive) + 1, 1), false);
SELECT setval(pg_get_serial_sequence('Leaderboard_History', 'history_id'), COALESCE((SELECT MAX(history_id) FROM Leaderboard_History) + 1, 1), false);
"
if [ $? -ne 0 ]; then
    echo "ERROR running SEQUENCE REPAIR. Aborting."
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Database bootstrap completed successfully!"
echo "Database: ${DB_NAME}"
echo "Host: ${DB_HOST}"
echo "========================================="
