# dbt (Tier 2 – Analytics & Development)

**Purpose:** Analytics engineering workflows (models/tests/docs) executed inside the FlumenData network against PostgreSQL and Delta-backed tables exposed via Spark.

## Image
- Custom image built from `docker/dbt.Dockerfile`, installing `dbt-core==${DBT_CORE_VERSION}` plus adapters from [`dbt-labs/dbt-adapters`](https://github.com/dbt-labs/dbt-adapters) defined via `DBT_ADAPTERS` (defaults to `dbt-postgres`).
- Build args can include multiple adapters (e.g., `dbt-postgres` + `dbt-spark[PyHive]`) so the same container can connect to different compute engines.

## Configuration
- Environment: `POSTGRES_*` plus dbt-specific `DBT_TARGET_SCHEMA` and `DBT_THREADS` from `.env`.
- Bind mounts:
  - `./config/dbt/profiles.yml` → `/root/.dbt/profiles.yml` (rendered via `envsubst`).
  - `./config/dbt/project` → `/usr/app` (editable project workspace).
  - `flumen_shared_data` → `/data` (optional exchange area with JupyterLab).
- Healthcheck: `dbt debug --project-dir /usr/app --profiles-dir /root/.dbt`.

!!! tip "Switching adapters"
    Set `DBT_ADAPTERS` in `.env` to a space-separated list such as `dbt-postgres==1.7.14 dbt-spark[PyHive]==1.7.2` and rerun `make up-tier2`. The Docker build will reinstall the requested adapters automatically.

## How it is generated
- `make config-dbt` renders `templates/dbt/profiles.yml.tpl` and bootstraps a starter project from `templates/dbt/project/`.
- The starter project ships with a simple model (`models/example.sql`) plus schema tests so `dbt run/test` succeed out of the box.

## Usage
```bash
make up-tier2          # also starts the dbt container
make shell-dbt         # enter the CLI container
make debug-dbt         # validate connectivity (dbt debug)
make run-dbt           # run all models in /config/dbt/project
make test-dbt          # execute schema/data tests
make build-dbt         # deps + seed + run + test
```

## Quick workflow
1. Update `.env` if you need a different schema or thread count.
2. Run `make config-dbt` (already part of `make config`) to ensure the profile and project exist.
3. Edit models under `config/dbt/project/models/` with your preferred editor or via `make shell-dbt`.
4. Execute `make run-dbt` / `make test-dbt` to materialize objects in PostgreSQL.
5. Use JupyterLab or Spark to query the resulting objects.

## Troubleshooting
- `dbt debug` failures usually mean PostgreSQL is down or credentials mismatch the `.env` file.
- If you want to reset the workspace, run `make clean-dbt-config` and rerun `make config-dbt` to regenerate the starter project.
