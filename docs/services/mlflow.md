# MLflow (Tier 2 – Analytics & Development)

**Purpose:** Centralized experiment tracking for metrics, parameters, and artifacts produced by notebooks, Spark jobs, or dbt models.

## Image
- Custom image built from `docker/mlflow.Dockerfile`, installing `mlflow==${MLFLOW_VERSION}` plus Postgres and S3 dependencies.

## Configuration
- Template: `templates/mlflow/server.env.tpl` → `config/mlflow/server.env` via `make config-mlflow`.
- Environment variables (set in `.env`):
  - `MLFLOW_PORT` – host/UI port (defaults to `5000`).
  - `MLFLOW_ARTIFACT_PATH` – S3 prefix inside the MinIO bucket (`s3://lakehouse/<path>`).
  - `MLFLOW_VERSION` – version of MLflow installed in the container.
- Backend store: PostgreSQL (`postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:${POSTGRES_PORT}/${POSTGRES_DB}`).
- Artifact store: MinIO bucket using S3-compatible credentials.
- Named volume: `flumen_mlflow_data` mounted at `/opt/mlflow` (retains CLI logs/scripts if needed).

## Usage
```bash
make up-tier2          # Starts MLflow alongside JupyterLab and dbt
make health-mlflow     # Verifies the tracking server is reachable
make logs-mlflow       # Streams server logs
make shell-mlflow      # Opens a lightweight shell inside the container
```

Access the UI at `http://localhost:${MLFLOW_PORT}`.

### Tracking URI
In notebooks or CLI tools set:
```python
import mlflow
mlflow.set_tracking_uri("http://mlflow:5000")      # inside Docker network
# or from host:
mlflow.set_tracking_uri("http://127.0.0.1:5000")
```

### Artifacts & Credentials
Artifacts are stored under `s3://$(MINIO_BUCKET)/${MLFLOW_ARTIFACT_PATH}`. Reuse the MinIO credentials already defined in `.env` (either via environment variables or the `~/.aws/credentials` profile when running locally).

## Initialization
`make init-mlflow` idempotently creates a starter experiment named `flumen-default`. You can rename or create additional experiments via the UI or API at any time.

## Troubleshooting
- **Cannot connect / 500 errors:** ensure Tier 0 services (Postgres + MinIO) are healthy. MLflow depends on both.
- **Artifact uploads fail:** verify `MLFLOW_S3_ENDPOINT_URL` matches the internal MinIO address (`http://minio:9000`) and that the bucket exists (`make health-minio`).
- **SSL warnings when accessing MinIO:** development mode intentionally uses HTTP. For production, front MinIO with TLS and update `MLFLOW_S3_ENDPOINT_URL`.
