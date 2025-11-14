# Airflow (Tier 3 – Orchestration & BI)

**Purpose:** Schedule, orchestrate, and monitor ETL/ELT jobs that run against the lakehouse (Spark, Trino, etc.).

## Image
- Official `apache/airflow:${AIRFLOW_VERSION}` image running both scheduler and webserver inside a single container (LocalExecutor).

## Configuration
- Template: `templates/airflow/airflow.env.tpl` → `config/airflow/airflow.env` via `make config-airflow`.
- Key environment variables (set in `.env`):
  - `AIRFLOW_VERSION` – Docker image tag.
  - `AIRFLOW_PORT` – Host/UI port (default `8085`).
  - `AIRFLOW_DB_NAME` – Metadata database name inside PostgreSQL.
  - `_AIRFLOW_WWW_USER_*` – Bootstrap admin user credentials consumed by the official entrypoint.
  - `AIRFLOW_FERNET_KEY` & `AIRFLOW_SECRET_KEY` – cryptography keys for connections and sessions.
- Runtime dependencies:
  - **Metadata DB**: PostgreSQL (same Tier 0 instance used by other services).
  - **Cache/queue**: LocalExecutor only, so no Celery/Redis needed.
  - **Named volumes**: `flumen_airflow_dags`, `flumen_airflow_logs`, `flumen_airflow_plugins` (DAGs remain inside a Docker volume per current requirement).

## Usage
```bash
make config-airflow    # Render environment file
make airflow-db        # Ensure PostgreSQL metadata DB exists
make up-tier3          # Start Trino + Superset + Airflow
make health-airflow    # Verify the webserver responds on /health
make logs-airflow      # Tail Airflow logs
make shell-airflow     # Open bash shell inside the container
```

Access the UI at `http://localhost:${AIRFLOW_PORT}` (defaults to `http://localhost:8085`).

### Default Credentials
- Username: `admin`
- Password: `admin123`

Update these values in `.env` before running `make config-airflow` to avoid using the defaults.

### DAGs & Persistence
- DAGs live under `/opt/airflow/dags`, persisted via the named Docker volume `flumen_airflow_dags`. Future work can swap this for a bind mount to a host directory if you prefer editing DAGs locally.
- Logs and plugins follow the same pattern (`flumen_airflow_logs`, `flumen_airflow_plugins`).

### Initialization Details
The container command performs:
1. The stock Airflow entrypoint runs `airflow db migrate` whenever `_AIRFLOW_DB_MIGRATE=true`.
2. The same entrypoint inspects `_AIRFLOW_WWW_USER_*` and creates/updates the admin user before startup, just like the upstream Docker Compose example.
3. The container executes `airflow standalone`, which starts the scheduler, triggerer, and API server/web UI in a single process bundle.

## Troubleshooting
- **Metadata DB errors**: ensure PostgreSQL is healthy (Tier 0) and rerun `make airflow-db` to create the database.
- **Webserver not reachable**: run `make logs-airflow` and look for stack traces; also confirm `http://localhost:${AIRFLOW_PORT}/health` succeeds.
- **DAG changes not appearing**: remember that DAGs live in the Docker volume. Either exec into the container (`make shell-airflow`) to edit files under `/opt/airflow/dags`, or replace the named volume with a bind mount once you are ready to manage DAGs from the host.
