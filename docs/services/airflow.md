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
  - `AIRFLOW_ADMIN_*` – Bootstrap admin user credentials.
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
1. `airflow db migrate` – apply database migrations on the shared PostgreSQL instance.
2. `airflow users create ...` – idempotently create the bootstrap admin user using `.env` values.
3. Start the scheduler in the background and launch the webserver (Gunicorn) in the foreground.

## Troubleshooting
- **Metadata DB errors**: ensure PostgreSQL is healthy (Tier 0) and rerun `make airflow-db` to create the database.
- **Webserver not reachable**: run `make logs-airflow` and look for stack traces; also confirm `http://localhost:${AIRFLOW_PORT}/health` succeeds.
- **DAG changes not appearing**: remember that DAGs live in the Docker volume. Either exec into the container (`make shell-airflow`) to edit files under `/opt/airflow/dags`, or replace the named volume with a bind mount once you are ready to manage DAGs from the host.
