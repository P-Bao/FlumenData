# CLI Reference

FlumenData provides a comprehensive Python-based CLI for managing the lakehouse environment.

## Quick Reference

```bash
python3 flumen init              # Complete initialization (recommended for first-time setup)
python3 flumen health            # Check all services health
python3 flumen ps                # Show running containers
python3 flumen summary           # Display environment overview
python3 flumen logs              # View logs for all services
python3 flumen restart           # Restart all services
python3 flumen clean             # Stop and remove everything (DESTRUCTIVE)
python3 flumen dashboard-collect # Run metrics collection
```

## Installation & Prerequisites

FlumenData CLI requires:
- **Python 3.6+** (pre-installed on Linux/macOS, install via Microsoft Store on Windows)
- **Docker** 20.10+
- **Docker Compose** 2.0+

## Command Structure

```bash
python3 flumen <command> [options]

# Or use the optional Makefile wrapper:
make <command>
```

## Initialization Commands

### `python3 flumen init`
Complete environment initialization - recommended for first-time setup.

**What it does:**
1. Loads environment variables from `.env`
2. Initializes data directories
3. Generates all configuration files
4. Starts Tier 0 services (PostgreSQL, MinIO)
5. Checks Tier 0 health and initializes MinIO buckets
6. Starts Tier 1 services (Hive Metastore, Spark)
7. Checks Tier 1 health and initializes Hive
8. Displays environment summary

**Usage:**
```bash
python3 flumen init

# Skip banner display
python3 flumen init --skip-banner
```

**Output:**
```
Starting complete FlumenData initialization...

Step 1/7: Initializing data directories
✓ Created /path/to/data/minio/lakehouse
✓ Created /path/to/data/notebooks/_examples

Step 2/7: Generating configurations
✓ Generated MinIO configuration
✓ Generated Hive configuration
✓ Generated Spark configuration

Step 3/7: Starting Tier 0 services
✓ PostgreSQL started
✓ MinIO started

Step 4/7: Initializing Tier 0
✓ PostgreSQL is healthy
✓ MinIO is healthy
✓ Created lakehouse bucket

Step 5/7: Starting Tier 1 services
✓ Hive Metastore started
✓ Spark Master started
✓ Spark Workers started

Step 6/7: Checking Tier 1 health
✓ Hive Metastore is healthy
✓ Spark Master is healthy

Step 7/7: Environment Summary
[Summary display...]

✓ FlumenData initialized successfully!

Next steps:
  • Start Tier 2: python3 flumen up --tier 2
  • Start Tier 3: python3 flumen up --tier 3
  • Check health: python3 flumen health
```

### `python3 flumen init-dirs`
Initialize data directories only (useful for first-time setup or data directory recreation).

**Usage:**
```bash
python3 flumen init-dirs
```

### `python3 flumen config`
Generate all configuration files from templates.

**Usage:**
```bash
# Generate all configs
python3 flumen config

# Generate specific service config
python3 flumen config --service minio
python3 flumen config --service hive
python3 flumen config --service spark
python3 flumen config --service jupyterlab
python3 flumen config --service trino
python3 flumen config --service superset
```

**When to use:**
- After modifying `.env` file
- After updating template files
- When configuration files are missing

## Service Management

### Starting Services

#### `python3 flumen up`
Start all services (Tiers 0 through 3).

```bash
python3 flumen up
```

#### `python3 flumen up --tier <N>`
Start specific tier services.

```bash
python3 flumen up --tier 0  # PostgreSQL, MinIO
python3 flumen up --tier 1  # Hive Metastore, Spark cluster
python3 flumen up --tier 2  # JupyterLab
python3 flumen up --tier 3  # Trino, Superset
```

#### `python3 flumen up --services <service1> <service2>`
Start specific services.

```bash
python3 flumen up --services spark-master spark-worker1
```

### Stopping Services

#### `python3 flumen down`
Stop all services (containers removed, volumes preserved).

```bash
python3 flumen down
```

### Restarting Services

#### `python3 flumen restart`
Restart all services.

```bash
python3 flumen restart
```

**Equivalent to:**
```bash
python3 flumen down && python3 flumen up
```

## Health Checks

### `python3 flumen health`
Check health status of all services.

**Usage:**
```bash
# Check all services
python3 flumen health

# Check specific tier
python3 flumen health --tier 0
python3 flumen health --tier 1
python3 flumen health --tier 2
python3 flumen health --tier 3
```

**Output:**
```
=== Tier 0 - Foundation Services ===
✓ postgres is healthy
✓ minio is healthy

=== Tier 1 - Data Platform ===
✓ hive-metastore is healthy
✓ spark-master is healthy
✓ spark-worker1 is healthy
✓ spark-worker2 is healthy
```

## Testing Commands

### `python3 flumen test`
Run all integration tests.

**Usage:**
```bash
# Test all services
python3 flumen test

# Test specific tier
python3 flumen test --tier 0
python3 flumen test --tier 1
python3 flumen test --tier 2
python3 flumen test --tier 3

# Run integration test
python3 flumen test --integration
```

**What it tests:**
- PostgreSQL: Connection, table creation, data persistence
- MinIO: Bucket creation, object upload/download
- Hive Metastore: Database creation, metadata storage
- Spark: Job submission, Delta Lake operations
- JupyterLab: HTTP availability probe
- Trino: CLI query against the coordinator

## Verification Commands

### `python3 flumen verify-hive`
Display Hive Metastore databases and configuration.

**Usage:**
```bash
python3 flumen verify-hive
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

### `python3 flumen summary`
Display comprehensive environment summary.

**Usage:**
```bash
python3 flumen summary
```

**Output includes:**
- FlumenData version
- All services status
- Ports and URLs
- Volume information
- Configuration summary

## Logging Commands

### `python3 flumen logs`
View logs for services.

**Usage:**
```bash
# All services (follow mode)
python3 flumen logs

# Specific tier
python3 flumen logs --tier 0
python3 flumen logs --tier 1

# Specific service
python3 flumen logs --service spark-master
python3 flumen logs --service hive-metastore

# No follow (show recent logs and exit)
python3 flumen logs --no-follow
python3 flumen logs --service postgres --no-follow
```

## Interactive Shells

### Database Shells

#### `python3 flumen shell-postgres`
Open PostgreSQL interactive shell.

**Usage:**
```bash
python3 flumen shell-postgres
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

#### `python3 flumen shell-spark`
Open Spark interactive Scala shell.

**Usage:**
```bash
python3 flumen shell-spark
```

**Example:**
```scala
val df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

#### `python3 flumen shell-pyspark`
Open PySpark interactive Python shell.

**Usage:**
```bash
python3 flumen shell-pyspark
```

**Example:**
```python
df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

#### `python3 flumen shell-spark-sql`
Open Spark SQL interactive shell.

**Usage:**
```bash
python3 flumen shell-spark-sql
```

**Example:**
```sql
SHOW DATABASES;
USE quickstart;
SELECT * FROM customers LIMIT 10;
```

### MinIO Client

#### `python3 flumen shell-mc`
Open MinIO client (mc) for object storage operations.

**Usage:**
```bash
python3 flumen shell-mc

# List buckets
mc ls local

# List objects in bucket
mc ls local/lakehouse/warehouse

# Copy object
mc cp local/lakehouse/file.parquet /tmp/

# Create bucket
mc mb local/bronze
```

## Service-Specific Commands

### `python3 flumen token-jupyterlab`
Get JupyterLab access token.

**Usage:**
```bash
python3 flumen token-jupyterlab
```

**Output:**
```
JupyterLab Access Token:
http://localhost:8888/?token=abc123def456...
```

### `python3 flumen superset-db`
Initialize Superset database.

**Usage:**
```bash
python3 flumen superset-db
```

## Dashboard & Metrics Commands

### `python3 flumen dashboard-collect`
Run one-time metrics collection from MinIO, Spark, and Delta Lake.

**Usage:**
```bash
python3 flumen dashboard-collect
```

### `python3 flumen dashboard-setup`
One-time setup for the metrics database and Trino views.

**Usage:**
```bash
python3 flumen dashboard-setup
```

### `python3 flumen dashboard-status`
Show the status of the metrics collector.

**Usage:**
```bash
python3 flumen dashboard-status
```

## Cleanup & Maintenance Commands

### `python3 flumen cleanup`
Cleanup test data from storage.

**Usage:**
```bash
# Cleanup all tiers
python3 flumen cleanup

# Cleanup specific tier
python3 flumen cleanup --tier 0
python3 flumen cleanup --tier 1
python3 flumen cleanup --tier 2
```

### `python3 flumen clean`
Complete environment cleanup - stops services and removes all data.

**What it does:**
1. Prompts for confirmation
2. Stops all services
3. Removes all containers
4. Removes all volumes (data deleted)
5. Removes networks

**Usage:**
```bash
# Interactive prompt
python3 flumen clean

# Force without confirmation
python3 flumen clean --force
```

!!! danger "Data Loss"
    This command permanently deletes all data stored in Docker volumes. Export any important data before running this command.

### `python3 flumen rebuild`
Rebuild all custom Docker images.

**Usage:**
```bash
python3 flumen rebuild
```

**What it rebuilds:**
- Hive Metastore image
- Spark image (with Delta Lake)
- Superset image (with Trino support)

### `python3 flumen prune`
Prune unused Docker resources.

**Usage:**
```bash
python3 flumen prune
```

**What it removes:**
- Stopped containers
- Unused networks
- Dangling images
- Build cache

## Container Status

### `python3 flumen ps`
Show running containers with status.

**Usage:**
```bash
python3 flumen ps
```

**Alias:**
```bash
python3 flumen status
```

**Output:**
```
NAME                    STATUS          PORTS
flumen_postgres         healthy         0.0.0.0:5432->5432/tcp
flumen_minio            healthy         0.0.0.0:9000-9001->9000-9001/tcp
flumen_hive_metastore   healthy         0.0.0.0:9083->9083/tcp
flumen_spark_master     healthy         0.0.0.0:7077,8080->7077,8080/tcp
```

## Command Cheat Sheet

| Task | Command |
|------|---------|
| First-time setup | `python3 flumen init` |
| Check everything | `python3 flumen health` |
| View logs | `python3 flumen logs --service spark-master` |
| Restart after config change | `python3 flumen config && python3 flumen restart` |
| Run tests | `python3 flumen test` |
| Open Spark SQL | `python3 flumen shell-spark-sql` |
| Open PySpark | `python3 flumen shell-pyspark` |
| View environment | `python3 flumen summary` |
| Complete cleanup | `python3 flumen clean` |

## Using the Makefile Wrapper

For convenience, all commands have Makefile aliases:

```bash
# These are equivalent:
python3 flumen init
make init

python3 flumen health
make health

python3 flumen up --tier 0
make up-tier0
```

The Makefile simply delegates to the Python CLI, so you can use whichever you prefer.

## Advanced Usage

### Sequential Commands

```bash
# Typical workflow after changing .env
python3 flumen config && python3 flumen restart && python3 flumen health
```

### Conditional Execution

```bash
# Only restart if config succeeds
python3 flumen config && python3 flumen restart || echo "Config failed!"
```

### Cross-Platform Compatibility

The Python CLI works identically on:
- **Linux**: Native Python 3
- **macOS**: Native Python 3
- **Windows**: Python 3 from Microsoft Store or python.org
- **WSL2**: Native Python 3

No platform-specific workarounds needed!

## Getting Help

### `python3 flumen --help`
Show general help and all available commands.

```bash
python3 flumen --help
```

### `python3 flumen <command> --help`
Show help for specific command.

```bash
python3 flumen up --help
python3 flumen test --help
python3 flumen logs --help
```

### `python3 flumen --version`
Show FlumenData version.

```bash
python3 flumen --version
```

### No Command (Welcome Message)
Running `python3 flumen` without a command shows a friendly welcome message with quick start guide.

```bash
python3 flumen
```

## Next Steps

- [Environment Variables](environment.md) - Configure services
- [Architecture](../getting-started/architecture.md) - Understand components
- [Testing Guide](../development/testing.md) - Write integration tests
