# Superset (Tier 3 – Orchestration & BI)

**Purpose:** SQL exploration and dashboarding UI on top of Trino catalogs (Hive, Delta/Lakehouse).

## Image
- Custom image built from `docker/superset.Dockerfile`, which layers on top of `apache/superset:${SUPERSET_VERSION}`.
  - Installs `psycopg2-binary` for the PostgreSQL metadata database.
  - Installs `sqlalchemy-trino` so Superset can talk to Trino catalogs out of the box.

## Configuration
- Templates:
  - `templates/superset/superset.env.tpl` → `config/superset/superset.env` via `make config-superset`.
  - `templates/superset/superset_config.py.tpl` → `config/superset/superset_config.py`.
- Key environment variables (set in `.env`):
  - `SUPERSET_VERSION` – image tag.
  - `SUPERSET_PORT` – host/UI port (default `8088`).
  - `SUPERSET_DB_NAME` – metadata database (created inside PostgreSQL).
  - `SUPERSET_SECRET_KEY` – Flask secret key for sessions/CSRF.
  - `SUPERSET_ADMIN_*` – bootstrap admin user (username, password, email, names).
- Runtime dependencies:
  - **Metadata DB**: PostgreSQL (`postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${SUPERSET_DB_NAME}`).
  - **Cache / async**: Valkey via `REDIS_URL=redis://valkey:${VALKEY_PORT}/0`.
  - **Named volume**: `flumen_superset_home` mounted at `/app/superset_home` (stores uploads, config, and state).

## Usage
```bash
make build-superset    # Build custom image (auto-run by compose if skipped)
make config-superset   # Render env + config
make superset-db       # Ensure metadata database exists in PostgreSQL
make up-tier3          # Starts Trino + Superset + Airflow
make health-superset   # HTTP health probe
make logs-superset     # Tail logs
make shell-superset    # Bash shell inside the container
```

Access the UI at `http://localhost:${SUPERSET_PORT}` (defaults to `http://localhost:8088`).

### Default Credentials
- Username: `admin`
- Password: `admin123`

Update these values in `.env` before running `make config-superset` to avoid using the defaults.

### Connect Superset to Trino
Add a new Database inside Superset:

1. Go to **Settings → Database Connections → + Database**.
2. Choose **Other** and use the SQLAlchemy URI (the `sqlalchemy-trino` driver is already installed):
   - From inside the Docker network: `trino://trino@trino:8080/lakehouse`
   - From your host: `trino://trino@localhost:8082/lakehouse` (or `host.docker.internal` on macOS/Windows if `localhost` does not reach the container)
3. Test the connection and save. The catalog list (`hive`, `delta`, `lakehouse`) becomes available for dataset creation.

### Initialization Details
The container command performs:

1. `superset db upgrade` – apply migrations.
2. `superset fab create-admin ...` – idempotently create the admin user using `.env` values.
3. `superset init` – load default roles and permissions.
4. Start Gunicorn (`gunicorn -w 4 -k gevent ...`).

## Troubleshooting
- **Login fails immediately**: ensure browser cookies are allowed and `SUPERSET_SECRET_KEY` remains stable between restarts (set it explicitly in `.env`).
- **Cannot reach Superset**: run `make health-superset` and inspect `docker compose -f docker-compose.tier3.yml logs superset`.
- **Metadata DB errors**: run `make superset-db` after Tier 0 (PostgreSQL) is healthy so the `superset` database exists before starting the container.
- **Timeout when querying Trino**: confirm Tier 3 services are on the same Docker network (start with `make up`), and verify the SQLAlchemy URI uses the internal hostname `trino`.
