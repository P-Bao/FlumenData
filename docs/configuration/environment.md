# Environment Variables

FlumenData uses environment variables to configure all services. Variables are defined in the `.env` file and used by Docker Compose and Makefile templates.

## Configuration Management

### Template System

Configuration files are generated from templates:

```
templates/               # Source templates
├── hive/
│   └── hive-site.xml.tpl
├── spark/
│   ├── spark-defaults.conf.tpl
│   └── spark-env.sh.tpl
├── dbt/
│   ├── profiles.yml.tpl
│   └── project/
├── minio/
│   └── policy-readonly.json.tpl
└── valkey/
    └── valkey.conf.tpl

config/                  # Generated files (DO NOT EDIT)
├── hive/
│   └── hive-site.xml
├── spark/
│   ├── spark-defaults.conf
│   ├── spark-env.sh
│   └── hive-site.xml (copied from hive/)
├── dbt/
│   ├── profiles.yml
│   └── project/
├── minio/
│   └── policy-readonly.json
└── valkey/
    └── valkey.conf
```

### Regenerating Configuration

After modifying `.env`, regenerate configuration:

```bash
# Regenerate all configuration files
make config

# Regenerate specific service
make config-hive
make config-spark
make config-minio
make config-valkey
make config-jupyterlab
make config-dbt

# Restart services to apply changes
make restart
```

!!! warning "Never Edit Generated Files"
    Files in the `config/` directory are auto-generated. Always edit templates in `templates/` and run `make config`.

## Core Variables

### PostgreSQL

```bash
# PostgreSQL configuration
POSTGRES_USER=flumen           # Database user
POSTGRES_PASSWORD=flumen123    # User password
POSTGRES_DB=flumendata         # Database name
POSTGRES_PORT=5432             # External port
```

**Used by:**
- PostgreSQL container
- Hive Metastore (JDBC connection)
- All targets that access PostgreSQL

**Examples:**
```bash
# Connect to PostgreSQL
docker exec -it flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Change password (requires restart)
POSTGRES_PASSWORD=newsecurepass123
make config
make restart
```

### Valkey (Redis)

```bash
# Valkey configuration
VALKEY_PORT=6379              # External port
VALKEY_PASSWORD=               # Optional password (leave empty for no auth)
```

**Used by:**
- Valkey container
- Spark (optional caching)

**Examples:**
```bash
# Set password
VALKEY_PASSWORD=valkey123
make config-valkey
make restart

# Connect with password
docker exec -it flumen_valkey redis-cli -a ${VALKEY_PASSWORD}
```

### MinIO

```bash
# MinIO S3-compatible object storage
MINIO_ROOT_USER=minioadmin           # Admin username
MINIO_ROOT_PASSWORD=minioadmin123    # Admin password (min 8 chars)
MINIO_SERVER_URL=http://minio:9000   # Internal S3 endpoint
MINIO_CONSOLE_PORT=9001              # Console UI port
MINIO_BUCKET=lakehouse               # Default bucket name
```

**Used by:**
- MinIO container
- Spark (S3A configuration)
- Hive Metastore (warehouse location)

**Security Notes:**
- Use strong passwords in production
- Default credentials are for development only
- Console accessible at: http://localhost:9001

**Examples:**
```bash
# Change credentials (requires restart)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=SuperSecure123
make config
make restart

# Create additional buckets
docker exec flumen_minio mc mb /data/bronze
docker exec flumen_minio mc mb /data/silver
docker exec flumen_minio mc mb /data/gold
```

### Hive Metastore

```bash
# Hive Metastore configuration
HIVE_METASTORE_URI=thrift://hive-metastore:9083   # Thrift endpoint
```

**Used by:**
- Spark (catalog connection)
- Any external tool connecting to Hive Metastore

**Examples:**
```bash
# Verify connectivity
docker exec flumen_spark_master nc -zv hive-metastore 9083

# Check metastore logs
make logs-hive
```

### Spark

```bash
# Spark cluster configuration
SPARK_MASTER_HOST=spark-master    # Master hostname
SPARK_MASTER_PORT=7077             # Spark protocol port
SPARK_MASTER_WEBUI_PORT=8080      # Web UI port
SPARK_WORKER_CORES=2               # Cores per worker
SPARK_WORKER_MEMORY=2g             # Memory per worker
```

**Used by:**
- Spark Master container
- Spark Worker containers
- spark-env.sh template

**Examples:**
```bash
# Increase worker resources
SPARK_WORKER_CORES=4
SPARK_WORKER_MEMORY=4g
make config-spark
make restart

# Access Spark UI
open http://localhost:${SPARK_MASTER_WEBUI_PORT}
```

### Delta Lake

```bash
# Delta Lake and dependency versions
DELTA_VERSION=4.0.0                   # Delta Lake version
SCALA_BINARY_VERSION=2.13             # Scala version
POSTGRESQL_JDBC_VERSION=42.7.1        # PostgreSQL JDBC driver
HADOOP_AWS_VERSION=3.3.6              # Hadoop AWS (S3A) version
AWS_SDK_BUNDLE_VERSION=1.12.367       # AWS SDK version
```

**Used by:**
- spark-defaults.conf template (JAR dependencies)
- Spark Ivy cache

**Changing Versions:**
```bash
# Upgrade Delta Lake
DELTA_VERSION=4.1.0
make config-spark
# Clear Ivy cache to download new JARs
docker volume rm flumen_spark_ivy
make restart
```

!!! warning "Version Compatibility"
    Ensure Delta Lake, Spark, and Scala versions are compatible. Check [Delta Lake releases](https://docs.delta.io/latest/releases.html).

### dbt

```bash
# dbt workspace defaults
DBT_TARGET_SCHEMA=analytics   # PostgreSQL schema for dbt models
DBT_THREADS=4                 # Parallelism for dbt runs
DBT_CORE_VERSION=1.7.14       # Version of dbt-core installed in the dbt image
DBT_ADAPTERS=dbt-postgres==1.7.14  # Space-separated list of adapter packages to install
```

**Used by:**
- `templates/dbt/profiles.yml.tpl`
- dbt container launched via `make up-tier2`
- Make targets such as `run-dbt`, `test-dbt`, `build-dbt`
- `docker/dbt.Dockerfile` build args (via docker-compose)

**Examples:**
```bash
# Deploy into a dedicated schema
DBT_TARGET_SCHEMA=analytics_dev
make config-dbt

# Increase parallelism for heavier pipelines
DBT_THREADS=8
make config-dbt

# Include Spark adapter alongside Postgres
DBT_ADAPTERS="dbt-postgres==1.7.14 dbt-spark[PyHive]==1.7.2"
make up-tier2
```

### MLflow

```bash
# MLflow tracking server
MLFLOW_PORT=5000                 # Host/UI port
MLFLOW_ARTIFACT_PATH=mlflow      # Prefix inside the MinIO bucket
MLFLOW_VERSION=2.14.1            # mlflow package version baked into docker/mlflow.Dockerfile
```

**Used by:**
- `templates/mlflow/server.env.tpl`
- `docker/mlflow.Dockerfile` build args
- `docker-compose.tier2.yml` service definition (ports and command)

**Examples:**
```bash
# Run MLflow on another port
MLFLOW_PORT=5050
make up-tier2

# Store artifacts in a separate prefix
MLFLOW_ARTIFACT_PATH=experiments/mlflow
make config-mlflow
```

### Trino

```bash
# Trino coordinator
TRINO_PORT=8082             # Host/UI port mapped to internal 8080
TRINO_VERSION=450           # Trino image tag
TRINO_ENVIRONMENT=lakehouse # Value stored in node.properties
```

**Used by:**
- `docker-compose.tier3.yml` (ports, image tag)
- `makefiles/trino.mk` targets
- `templates/trino/node.properties.tpl`

**Examples:**
```bash
# Avoid port conflicts
TRINO_PORT=9090
make up-tier3

# Pin a specific Trino release
TRINO_VERSION=448
make up-tier3
```

### Superset

```bash
# Superset BI UI
SUPERSET_VERSION=5.0.0            # Apache Superset image tag
SUPERSET_PORT=8088                # Host/UI port
SUPERSET_DB_NAME=superset         # Metadata database inside PostgreSQL
SUPERSET_SECRET_KEY=flumen_superset_secret
SUPERSET_ADMIN_USERNAME=admin
SUPERSET_ADMIN_PASSWORD=admin123
SUPERSET_ADMIN_EMAIL=admin@flumen.local
SUPERSET_ADMIN_FIRST_NAME=Superset
SUPERSET_ADMIN_LAST_NAME=Admin
```

**Used by:**
- `templates/superset/superset.env.tpl` and `superset_config.py.tpl`
- `makefiles/superset.mk` (config + database bootstrap)
- `docker-compose.tier3.yml` (service definition, ports, command)
- `docker/superset.Dockerfile` build args

**Examples:**
```bash
# Serve Superset on a different port
SUPERSET_PORT=8090
make up-tier3

# Rotate admin credentials
SUPERSET_ADMIN_USERNAME=bi_admin
SUPERSET_ADMIN_PASSWORD="$(openssl rand -hex 12)"
make config-superset

# Upgrade Superset version (remember to rebuild the image)
SUPERSET_VERSION=5.1.0
make build-superset
make up-tier3

### Airflow

```bash
# Airflow all-in-one
AIRFLOW_VERSION=3.1.2              # Apache Airflow image tag
AIRFLOW_PORT=8085                  # Host/UI port mapped to webserver 8080
AIRFLOW_DB_NAME=airflow            # Metadata database inside PostgreSQL
AIRFLOW_SECRET_KEY=flumen_airflow_secret
_AIRFLOW_WWW_USER_CREATE=true      # Ask entrypoint to bootstrap a UI user
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=admin123
_AIRFLOW_WWW_USER_EMAIL=admin@flumen.local
_AIRFLOW_WWW_USER_FIRSTNAME=Airflow
_AIRFLOW_WWW_USER_LASTNAME=Admin
_AIRFLOW_WWW_USER_ROLE=Admin
_PIP_ADDITIONAL_REQUIREMENTS=      # Optional dev-only packages to install on startup
AIRFLOW_FERNET_KEY=dXNlLWFjdHVhbC1mZXJuZXQta2V5LWhlcmUtbGF0ZXIh
```

**Used by:**
- `templates/airflow/airflow.env.tpl`
- `makefiles/airflow.mk` (config + db bootstrap)
- `docker-compose.tier3.yml` Airflow service definition

**Examples:**
```bash
# Run Airflow on a different port
AIRFLOW_PORT=8095
make up-tier3

# Rotate admin credentials
_AIRFLOW_WWW_USER_USERNAME=orchestrator
_AIRFLOW_WWW_USER_PASSWORD="$(openssl rand -base64 16)"
make config-airflow
```
```

## Advanced Configuration

### S3A Performance Tuning

Add to `.env` (requires template modifications):

```bash
# S3A connection pool
S3A_CONNECTION_MAXIMUM=100
S3A_CONNECTION_TIMEOUT=60000
S3A_ESTABLISH_TIMEOUT=30000

# S3A upload settings
S3A_BLOCK_SIZE=134217728                # 128 MB
S3A_MULTIPART_SIZE=134217728            # 128 MB
S3A_MULTIPART_THRESHOLD=268435456       # 256 MB
```

### Spark Performance

```bash
# Spark SQL optimization
SPARK_SQL_ADAPTIVE_ENABLED=true
SPARK_SQL_SHUFFLE_PARTITIONS=200
SPARK_SQL_FILES_MAX_PARTITION_BYTES=134217728

# Spark memory
SPARK_DRIVER_MEMORY=2g
SPARK_EXECUTOR_MEMORY=2g
```

### Logging Levels

Control verbosity:

```bash
# Log levels: ALL, DEBUG, INFO, WARN, ERROR, FATAL, OFF
SPARK_LOG_LEVEL=INFO
HIVE_LOG_LEVEL=INFO
```

## Environment-Specific Configurations

### Development

```bash
# .env.dev
POSTGRES_PASSWORD=dev123
MINIO_ROOT_PASSWORD=dev123
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=2g
```

### Staging

```bash
# .env.staging
POSTGRES_PASSWORD=staging_secure_pass
MINIO_ROOT_PASSWORD=staging_secure_pass
SPARK_WORKER_CORES=4
SPARK_WORKER_MEMORY=4g
```

### Production

```bash
# .env.prod
POSTGRES_PASSWORD=$(generate_secure_password)
MINIO_ROOT_PASSWORD=$(generate_secure_password)
SPARK_WORKER_CORES=8
SPARK_WORKER_MEMORY=16g

# Enable TLS
MINIO_SERVER_URL=https://minio:9000
```

## Validation

### Check Current Values

```bash
# View all environment variables
cat .env

# Check a specific variable
grep POSTGRES_PASSWORD .env
```

### Verify Configuration Applied

```bash
# Check Spark configuration
docker exec flumen_spark_master cat /opt/spark/conf/spark-defaults.conf

# Check Hive configuration
docker exec flumen_hive_metastore cat /opt/hive/conf/hive-site.xml
```

### Test Changes

```bash
# After changing .env
make config          # Regenerate configs
make health          # Verify services still healthy
make test           # Run integration tests
```

## Troubleshooting

### Changes not taking effect

```bash
# Full reset with new configuration
make config
make restart
make health
```

### Services fail after config change

```bash
# View logs for errors
make logs

# Revert to previous .env
git checkout .env

# Regenerate and restart
make config
make restart
```

### Template rendering errors

```bash
# Check Makefile render function
make config 2>&1 | grep ERROR

# Verify all required variables are set
env | grep -E "POSTGRES|MINIO|SPARK|HIVE|DELTA"
```

## Best Practices

1. **Version Control**: Commit `.env.example`, never commit `.env`
2. **Secrets**: Use secrets management in production (Vault, AWS Secrets Manager)
3. **Documentation**: Comment your `.env` file with explanations
4. **Testing**: Test configuration changes in development first
5. **Backups**: Backup `.env` before making changes
6. **Validation**: Run `make health` after any configuration change

## Next Steps

- [Make Commands Reference](commands.md) - All available commands
- [Architecture](../getting-started/architecture.md) - Understand component relationships
- [Contributing](../development/contributing.md) - Add new configuration options
