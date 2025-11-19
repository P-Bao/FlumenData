#!/bin/bash
set -e

# Create additional databases required by FlumenData services
# This script runs automatically on first PostgreSQL container startup

echo "Creating additional databases..."

# Create superset database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE superset'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'superset')\gexec
EOSQL

echo "Database initialization completed successfully"
