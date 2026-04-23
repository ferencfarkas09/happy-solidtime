-- Initialize database with proper users for Solidtime
-- This script runs on database initialization

-- Create the main application user if it doesn't exist
CREATE USER solidtime WITH ENCRYPTED PASSWORD '${DB_PASSWORD:-secret}';

-- Grant privileges for the solidtime database
GRANT ALL PRIVILEGES ON DATABASE solidtime TO solidtime;

-- Connect to the database and grant schema permissions
\c solidtime

-- Grant schema permissions
GRANT ALL PRIVILEGES ON SCHEMA public TO solidtime;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO solidtime;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO solidtime;

