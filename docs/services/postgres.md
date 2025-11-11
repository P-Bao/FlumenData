# PostgreSQL (Tier 0 – Foundation)

**Purpose:** Relational metadata store for orchestration, BI and platform services.

## Image
- Docker image: `postgres:17.6-alpine3.22` (pinned, never `:latest`)

## Configuration
- Environment variables from `.env`: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT`.
- Persistent volume: `postgres_data` → `/var/lib/postgresql/data`.
- Healthcheck: `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}`.
- Static configs: Using container defaults (no custom file under `/config/postgres` at this tier).

## How it is generated
Configuration is created by **Makefile** targets; do not edit files manually.
- Target: `make config-postgres` (no-op, uses container defaults).

## Validate
```bash
# Wait for health
make health-postgres

# Smoke test (create table, insert, select)
make test-postgres

# Persistence check (restart and verify rows)
make persist-postgres
```

## Useful endpoints
- Host port: `5432` (mapped to container `5432`).

