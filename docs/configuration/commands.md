# Make Commands Reference

FlumenData provides a comprehensive set of Make commands for managing the lakehouse environment.

## Quick Reference

```bash
make init          # Complete initialization (recommended for first-time setup)
make health        # Check all services health
make ps            # Show running containers
make summary       # Display environment overview
make logs          # View logs for all services
make restart       # Restart all services
make reset         # Complete reset and reinitialize
make clean         # Stop and remove everything (DESTRUCTIVE)
```

## Initialization Commands

### `make init`
Complete environment initialization - recommended for first-time setup.

**What it does:**
1. Generates all configuration files
2. Builds custom Docker images
3. Starts Tier 0 services (PostgreSQL, Valkey, MinIO)
4. Initializes MinIO buckets
5. Starts Tier 1 services (Hive Metastore, Spark)
6. Runs health checks
7. Displays summary

**Usage:**
```bash
make init
```

**Output:**
```
[config] Generating all configuration files...
[build] Building custom images...
[tier0] Starting foundation services...
[tier0] All services healthy
[minio] Initializing buckets...
[tier1] Starting data platform...
[tier1] All services healthy
[summary] Environment ready!
```

### `make config`
Generate all configuration files from templates.

**Usage:**
```bash
# Generate all configs
make config

# Generate specific service config
make config-postgres
make config-valkey
make config-minio
make config-hive
make config-spark
```

**When to use:**
- After modifying `.env` file
- After updating template files
- When configuration files are missing

## Service Management

### Starting Services

#### `make up`
Start all services (Tier 0 + Tier 1).

```bash
make up
```

#### `make up-tier0`
Start only Tier 0 foundation services.

```bash
make up-tier0  # PostgreSQL, Valkey, MinIO
```

#### `make up-tier1`
Start only Tier 1 data platform services.

```bash
make up-tier1  # Hive Metastore, Spark cluster
```

### Stopping Services

#### `make down`
Stop all services (containers remain, volumes preserved).

```bash
make down
```

#### `make down-tier0`
Stop only Tier 0 services.

```bash
make down-tier0
```

#### `make down-tier1`
Stop only Tier 1 services.

```bash
make down-tier1
```

### Restarting Services

#### `make restart`
Restart all services.

```bash
make restart
```

**Equivalent to:**
```bash
make down
make up
```

## Health Checks

### `make health`
Check health status of all services.

**Usage:**
```bash
make health
```

**Output:**
```
✓ postgres is healthy
✓ valkey is healthy
✓ minio is healthy
✓ hive-metastore is healthy
✓ spark-master is healthy
✓ spark-worker1 is healthy
✓ spark-worker2 is healthy
```

### Tier-Specific Health Checks

```bash
make health-tier0   # PostgreSQL, Valkey, MinIO
make health-tier1   # Hive Metastore, Spark cluster
```

### Individual Service Health

```bash
make health-postgres
make health-valkey
make health-minio
make health-hive
make health-spark-master
make health-spark-workers
```

## Testing Commands

### `make test`
Run all integration tests.

**Usage:**
```bash
make test
```

**What it tests:**
- PostgreSQL: Connection, table creation, data persistence
- Valkey: Connection, SET/GET operations
- MinIO: Bucket creation, object upload/download
- Hive Metastore: Database creation, metadata storage
- Spark: Job submission, Delta Lake operations

### Tier-Specific Tests

```bash
make test-tier0     # Test foundation services
make test-tier1     # Test data platform services
```

### Individual Service Tests

```bash
make test-postgres
make test-valkey
make test-minio
make test-hive
make test-spark
```

### Persistence Tests

Verify data survives container restarts:

```bash
make persist-postgres
make persist-valkey
make persist-minio
make persist-spark
```

## Verification Commands

### `make verify-hive`
Display Hive Metastore databases and configuration.

**Usage:**
```bash
make verify-hive
```

**Output:**
```
=== Hive Metastore Databases ===
default
quickstart
analytics

=== Configuration ===
Metastore URI: thrift://hive-metastore:9083
Warehouse: s3a://lakehouse/warehouse
Backend: PostgreSQL
```

### `make summary`
Display comprehensive environment summary.

**Usage:**
```bash
make summary
```

**Output includes:**
- FlumenData version
- All services status
- Ports and URLs
- Volume sizes
- Configuration summary

## Logging Commands

### `make logs`
View logs for all services (follows/streams).

**Usage:**
```bash
make logs           # All services
make logs-tier0     # Tier 0 services
make logs-tier1     # Tier 1 services
```

**Options:**
```bash
# View last 100 lines (no follow)
docker-compose -f docker-compose.tier0.yml logs --tail=100

# View specific time range
docker-compose -f docker-compose.tier0.yml logs --since=1h
```

### Individual Service Logs

```bash
make logs-postgres
make logs-valkey
make logs-minio
make logs-hive
make logs-spark
```

**Equivalent to:**
```bash
docker logs -f flumen_postgres
docker logs -f flumen_hive_metastore
docker logs -f flumen_spark_master
```

## Interactive Shells

### Database Shells

#### `make shell-postgres`
Open PostgreSQL interactive shell.

**Usage:**
```bash
make shell-postgres
```

**Example queries:**
```sql
-- List Hive Metastore tables
\dt

-- Check Hive version
SELECT * FROM "VERSION";

-- View database list
SELECT * FROM "DBS";
```

### Spark Shells

#### `make shell-spark`
Open Spark interactive Scala shell.

**Usage:**
```bash
make shell-spark
```

**Example:**
```scala
val df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

#### `make shell-pyspark`
Open PySpark interactive Python shell.

**Usage:**
```bash
make shell-pyspark
```

**Example:**
```python
df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

#### `make shell-spark-sql`
Open Spark SQL interactive shell.

**Usage:**
```bash
make shell-spark-sql
```

**Example:**
```sql
SHOW DATABASES;
USE quickstart;
SELECT * FROM customers LIMIT 10;
```

### MinIO Client

#### `make mc`
Open MinIO client (mc) for object storage operations.

**Usage:**
```bash
make mc

# List buckets
mc ls local

# List objects in bucket
mc ls local/lakehouse/warehouse

# Copy object
mc cp local/lakehouse/file.parquet /tmp/

# Create bucket
mc mb local/bronze
```

## Maintenance Commands

### `make reset`
Complete environment reset and reinitialization.

**What it does:**
1. Stops all services
2. Removes containers
3. Keeps volumes (data preserved)
4. Runs `make init` to restart everything

**Usage:**
```bash
make reset
```

**When to use:**
- After major configuration changes
- When services are in inconsistent state
- To apply Docker Compose changes

!!! tip "Data Preserved"
    The `reset` command preserves all data in volumes. It's safe to use for applying configuration changes.

### `make clean`
Complete cleanup - removes everything including data.

**What it does:**
1. Stops all services
2. Removes all containers
3. Removes all volumes (data deleted)
4. Removes networks
5. Removes generated configuration files

**Usage:**
```bash
make clean
```

!!! danger "Data Loss"
    This command permanently deletes all data. Only use when you want to start completely fresh.

**Confirmation prompt:**
```bash
make clean
# WARNING: This will delete all data. Are you sure? [y/N]
```

## Docker Commands

### `make ps`
Show running containers with status.

**Usage:**
```bash
make ps
```

**Output:**
```
NAME                    STATUS          PORTS
flumen_postgres         healthy         0.0.0.0:5432->5432/tcp
flumen_valkey           healthy         0.0.0.0:6379->6379/tcp
flumen_minio            healthy         0.0.0.0:9000-9001->9000-9001/tcp
flumen_hive_metastore   healthy         0.0.0.0:9083->9083/tcp
flumen_spark_master     healthy         0.0.0.0:7077,8080->7077,8080/tcp
```

### Build Commands

```bash
# Build all custom images
make build

# Build specific image
docker build -f docker/hive.Dockerfile -t flumendata/hive:standalone-metastore-4.1.0 .
docker build -f docker/spark.Dockerfile -t flumendata/spark:4.0.1-health .
```

## Utility Commands

### `make help`
Display all available commands with descriptions.

**Usage:**
```bash
make help
```

### Check Docker Resources

```bash
# View Docker disk usage
docker system df

# View detailed volume information
docker volume ls
docker volume inspect flumen_postgres_data
```

### Cleanup Unused Resources

```bash
# Remove unused images
docker image prune

# Remove unused volumes (careful!)
docker volume prune

# Complete system cleanup (very careful!)
docker system prune -a --volumes
```

## Command Cheat Sheet

| Task | Command |
|------|---------|
| First-time setup | `make init` |
| Check everything | `make health` |
| View logs | `make logs` |
| Restart after config change | `make config && make restart` |
| Run tests | `make test` |
| Open Spark SQL | `make shell-spark-sql` |
| Open PySpark | `make shell-pyspark` |
| View environment | `make summary` |
| Clean start | `make reset` |
| Nuclear option | `make clean` |

## Advanced Usage

### Sequential Commands

```bash
# Typical workflow after changing .env
make config && make restart && make health
```

### Conditional Execution

```bash
# Only restart if config succeeds
make config && make restart || echo "Config failed!"
```

### Debugging

```bash
# Verbose output
make logs | grep ERROR

# Check specific service
docker inspect flumen_spark_master

# Execute command in container
docker exec flumen_spark_master /opt/spark/bin/spark-submit --version
```

## Next Steps

- [Environment Variables](environment.md) - Configure services
- [Architecture](../getting-started/architecture.md) - Understand components
- [Testing Guide](../development/testing.md) - Write integration tests
