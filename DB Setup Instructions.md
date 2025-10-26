Run the bootstrap command:  /opt/n8n/SyncThing/Pinball/pinball-analytics/bootstrap_db.sh 

## Commands To Run
source .env
bootstrap_db.sh pinball --init-tables

Current Error:
**jdelay@jd-docker-01**:**/opt/n8n/SyncThing/Pinball/pinball-analytics**$ ./bootstrap_db.sh pinball --init-tables

!!! DANGER: You are about to manage the database: pinball on host 192.168.86.108 !!!
This operation will drop the database if it exists, and then recreate it.
Are you absolutely sure you want to proceed? (y/N): Y
Proceeding with database drop/recreation...
Password for user postgres: 
DROP DATABASE
Password for user postgres: 
CREATE DATABASE
Database pinball successfully initialized and recreated.
Attempting test connection to postgres@192.168.86.108:pinball...
Password for user postgres: 
Connection successful. Starting schema setup...
--- PHASE 1: Running core schema and constraints (database/init) ---
Executing database/init/01_schema_tables.sql...
Password for user postgres: 
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
Executing database/init/02_constraints_indexes.sql...
Password for user postgres: 
ALTER TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
Executing database/init/03_seed_data.sql...
Password for user postgres: 
--- PHASE 2: Running functions and views (database/functions) ---
./bootstrap_db.sh: line 151: unexpected EOF while looking for matching `"'

./bootstrap_db.sh: line 152: syntax error: unexpected end of file