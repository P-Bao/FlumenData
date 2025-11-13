# Trino (Tier 3 – Orchestration & BI)

**Purpose:** Interactive SQL engine that exposes the Hive/Delta Lake tables (backed by MinIO) to BI tools and orchestrators.

## Image
- Official `trinodb/trino:${TRINO_VERSION}` image with Hive connector configured against the shared metastore.

## Configuration
- Templates in `templates/trino/` render to `config/trino/` via `make config-trino`.
- Key environment variables (`.env`):
  - `TRINO_PORT` – host port that maps to Trino’s internal `8080` UI/API.
  - `TRINO_VERSION` – Trino image tag.
  - `TRINO_ENVIRONMENT` – value stored in `node.properties`.
  - `HIVE_METASTORE_URI`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_SERVER_URL` – reused for the Hive connector.
- Generated files:
  - `config.properties`, `node.properties`, `jvm.config`.
  - `catalog/hive.properties` (pre-wired to the Hive metastore + MinIO).

## Usage
```bash
make up-tier3          # Starts Trino + Superset + Airflow (requires tiers 0–2 running)
make shell-trino       # Opens a shell inside the container
make sql-trino         # Launches the CLI connected to the coordinator
```

Access the web UI at `http://localhost:${TRINO_PORT}` once the container reports healthy.

## Initialization & Health
- `make init-trino` runs `SHOW CATALOGS` and `SHOW SCHEMAS FROM hive` through the CLI to ensure the coordinator and Hive connector are ready.
- `make health-trino` performs a lightweight HTTP probe against `/v1/info`.
- Docker healthcheck mirrors the same endpoint so `docker compose ps` reflects readiness.

## Connectivity
- Hive catalog targets the same metastore used by Spark/ dbt, so schemas and Delta tables appear automatically.
- S3 credentials point to MinIO (`s3://$(MINIO_BUCKET)/warehouse`) enabling read/write through Trino.

## Troubleshooting
- **401/Forbidden:** verify the Hive catalog picked up MinIO credentials (`config/trino/catalog/hive.properties`).
- **Catalog missing:** ensure Tier 1 (Hive Metastore) is healthy before starting Tier 3.
- **Port conflict:** adjust `TRINO_PORT` if `8082` is already in use locally, then rerun `make config-trino` before `make up-tier3`.
