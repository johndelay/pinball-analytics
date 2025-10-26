💾 Pinball Leaderboard Database Setup
Pinball Leaderboard Database SetupThis guide details how to initialize or completely rebuild the PostgreSQL database schema (pinball-analytics).

The process uses the bootstrap_db.sh script to execute versioned SQL files, ensuring all tables, indexes, and custom functions are created in the correct order.

1. PrerequisitesPostgreSQL Server: A running PostgreSQL instance (local or remote).psql Client: The PostgreSQL command-line client must be installed and accessible in your system's PATH.Permissions: You must have the credentials for a user who can create/own databases (DB_USER). For the --wipe-me option, you will need access to a PostgreSQL superuser (typically postgres).

2. Configuration (The .env File)Create a file named .env in this directory to hold your database credentials. Do not commit this file to Git!VariableDescriptionExample ValueDB_USERThe database user/owner.pinballDB_PASSWORDThe password for the user.mypassword123DB_HOSTThe hostname or IP of the Postgres server.localhost or 192.168.1.10Example .env# Credentials for the database owner
  DB_USER="pinball"
  DB_PASSWORD="your_strong_password_here"
  DB_HOST="localhost"

3. Run the ScriptThe script requires you to specify the target database name as the first argument and explicitly source the environment variables.A. Sourcing CredentialsBefore every run, you must load the variables into your shell environment:source .env

B. Core CommandsRun the script from the root project directory 
(pinball-analytics/).CommandPurpose./bootstrap_db.sh 
<DB_NAME>Default Operation: Tests the connection, then executes all SQL files to create/update the schema, tables, functions, and constraints../bootstrap_db.sh 
<DB_NAME> --show-currentAudit: Tests the connection and lists the current tables present in the specified database../bootstrap_db.sh 
<DB_NAME> --wipe-meDANGER: Requires user confirmation, then drops and recreates the database from scratch before running the bootstrap. Use for a complete reset../bootstrap_db.shHelp: Displays the usage instructions.Example Full BootstrapTo fully wipe and rebuild a database named pinball_league:# 1. Load credentials
source .env

# 2. Execute wipe and bootstrap
./bootstrap_db.sh pinball_league --wipe-me
4. SQL File StructureThe SQL files are organized and executed in the following order:database/init/*.sql: Creates the base schema, including all tables and all indexes/constraints.database/functions/*.sql: Creates the custom PostgreSQL functions, such as update_combined_leaderboard(), which contains the league's scoring logic.
