# MinIO (Tier 0 – Foundation)

**Purpose:** S3-compatible object storage for the Lake (bronze/silver/gold).

## Image
- Docker image: `minio/minio:RELEASE.2025-09-07T16-13-09Z` (pinned in `docker-compose.yml`).

## Configuration
- Environment from `.env`: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_SERVER_URL`, `MINIO_BROWSER_REDIRECT_URL`, `MINIO_PORT_API`, `MINIO_PORT_CONSOLE`.
- Persistent volume: `minio_data` → `/data`.
- Policy template: `/templates/minio/policy-readonly.json.tpl` → `/config/minio/policy-readonly.json`.
- Healthcheck: `GET /minio/health/live` on container.
- MinIO Client (mc) used inside the Compose network with a pinned image for tests/backups.

### Default Buckets
- `MINIO_BUCKET` (default `lakehouse`): Delta Lake warehouse at `s3a://lakehouse/warehouse`.
- `MINIO_STORAGE_BUCKET` (default `storage`): Staging bucket for CSV/XLSX/ZIP files prior to ingestion.

## How it is generated
- Target: `make config-minio` renders templates into `/config/minio/` using envsubst (local or Docker fallback).

## Validate
```bash
# Wait for health
make health-minio

# Smoke test: create bucket, upload and read a file
make test-minio

# Persistence: restart and verify uploaded object
make persist-minio
```

## Useful endpoints
- API: `http://localhost:9000`
- Console/UI: `http://localhost:9001`
