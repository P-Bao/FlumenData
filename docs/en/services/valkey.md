# Valkey (Tier 0 – Foundation)

**Purpose:** In-memory key/value store for caching and coordination.

## Image
- Docker image: `valkey/valkey:9.0.0-alpine3.22` (pinned in `docker-compose.yml`).

## Configuration
- Environment: `VALKEY_PORT` from `.env`.
- Persistent volume: `valkey_data`.
- Config template: `/templates/valkey/valkey.conf.tpl` → rendered to `/config/valkey/valkey.conf`.
- Healthcheck: container must reach `healthy` before tests.

## How it is generated
- Target: `make config-valkey` renders templates into `/config/valkey/` using envsubst (local or Docker fallback).

## Validate
```bash
# Wait for health
make health-valkey

# Smoke test: SET/GET
make test-valkey

# Persistence: restart and verify the key still exists
make persist-valkey
```

## Useful endpoints
- Host port: `6379` (mapped to container default `6379`).

