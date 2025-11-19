# Apache Spark

Apache Spark serves as the distributed compute engine for FlumenData, providing query processing and analytics capabilities for the lakehouse.

## Overview

**Image**: `flumendata/spark:4.0.1-health` (custom built)
**Base**: `apache/spark:4.0.1`
**Cluster**: 1 Master + 2 Workers
**Master Port**: 7077 (Spark protocol), 8080 (Web UI)
**Worker Port**: 8081 (Web UI)
**Health**: HTTP check on Master UI

## Architecture

The Spark cluster provides:
- **Distributed compute**: 1 Master coordinating 2 Worker nodes
- **Delta Lake 4.0**: ACID table format with time travel
- **Hive Metastore catalog**: 2-level namespace (database.table)
- **S3A integration**: Direct access to MinIO object storage
- **Ivy cache**: Fast dependency resolution for libraries

## Custom Dockerfile

Our custom image adds health check utilities and prepares the Ivy cache:

```dockerfile
FROM apache/spark:4.0.1
USER root

# Install curl and procps for health checks
RUN (apt-get update && apt-get install -y curl procps) || \
    (microdnf -y install curl procps && microdnf clean all) || \
    (apk add --no-cache curl procps) || true

# Prepare writable ivy cache for spark user (uid 185)
RUN mkdir -p /opt/spark/.ivy2 && chown -R 185:0 /opt/spark/.ivy2

USER 185
```

## Configuration

### spark-defaults.conf

Configuration is generated from `templates/spark/spark-defaults.conf.tpl`:

```properties
# JAR Dependencies
spark.jars.packages io.delta:delta-spark_2.13:4.0.0,\
                   org.postgresql:postgresql:42.7.1,\
                   org.apache.hadoop:hadoop-aws:3.3.6,\
                   com.amazonaws:aws-java-sdk-bundle:1.12.367

# Delta Lake Extensions
spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension
spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog

# Hive Metastore Integration
spark.hadoop.hive.metastore.uris thrift://hive-metastore:9083
spark.sql.catalogImplementation hive
spark.sql.warehouse.dir s3a://lakehouse/warehouse

# S3A MinIO Configuration
spark.hadoop.fs.s3a.endpoint http://minio:9000
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.connection.ssl.enabled false

# Performance Tuning
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
```

### spark-env.sh

Environment variables generated from `templates/spark/spark-env.sh.tpl`:

```bash
SPARK_MASTER_HOST=spark-master
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=2g
SPARK_WORKER_WEBUI_PORT=8081
```

## Make Commands

```bash
# Configuration
make config-spark          # Generate spark-defaults.conf and spark-env.sh

# Service management
make up-tier1              # Start Spark cluster (Master + Workers)
make logs-spark            # View Spark logs

# Health & verification
make health-spark-master   # Check if Master is healthy
make health-spark-workers  # Check if Workers are healthy

# Testing
make test-spark            # Run SparkPi example job
make persist-spark         # Test cluster restart stability
```

## Cluster Architecture

### Master Node

The Master node (`flumen_spark_master`):
- Coordinates job execution across workers
- Provides Web UI on port 8080
- Accepts Spark applications on port 7077
- Depends on Hive Metastore being healthy

### Worker Nodes

Two worker nodes (`flumen_spark_worker1`, `flumen_spark_worker2`):
- Execute tasks assigned by the Master
- 2 CPU cores per worker
- 2GB memory per worker
- Each provides Web UI on port 8081
- Start only after Master is healthy

## Named Volumes

Spark uses four named volumes for persistence:

```
flumen_spark_conf   # Spark configuration files
flumen_spark_ivy    # Ivy cache for JAR dependencies
flumen_spark_work   # Worker work directories
flumen_spark_logs   # Spark logs
```

## Interactive Shells

### Spark Shell (Scala)

```bash
make shell-spark
# or directly
docker exec -it flumen_spark_master /opt/spark/bin/spark-shell \
  --master spark://spark-master:7077
```

Example usage:
```scala
// Read Delta table
val df = spark.read.format("delta").load("s3a://lakehouse/warehouse/my_table")
df.show()

// Write Delta table
df.write.format("delta").mode("overwrite")
  .save("s3a://lakehouse/warehouse/output_table")
```

### PySpark (Python)

```bash
make shell-pyspark
# or directly
docker exec -it flumen_spark_master /opt/spark/bin/pyspark \
  --master spark://spark-master:7077
```

Example usage:
```python
# Show available databases
spark.sql("SHOW DATABASES").show()

# Create a new database
spark.sql("CREATE DATABASE IF NOT EXISTS analytics")

# Use the database
spark.sql("USE analytics")

# Create a Delta table
spark.sql("""
    CREATE TABLE customers (
        id INT,
        name STRING,
        email STRING,
        country STRING,
        created_at TIMESTAMP
    ) USING DELTA
""")

# Insert data
spark.sql("""
    INSERT INTO customers VALUES
    (1, 'Alice', 'alice@example.com', 'USA', current_timestamp()),
    (2, 'Bob', 'bob@example.com', 'Canada', current_timestamp())
""")

# Query data
spark.sql("SELECT * FROM customers").show()

# View table history (Delta Lake time travel)
spark.sql("DESCRIBE HISTORY customers").show(truncate=False)

# Query previous version
spark.sql("SELECT * FROM customers VERSION AS OF 0").show()
```

### Spark SQL

```bash
make shell-spark-sql
# or directly
docker exec -it flumen_spark_master /opt/spark/bin/spark-sql \
  --master spark://spark-master:7077
```

Example usage:
```sql
-- List databases
SHOW DATABASES;

-- Create database
CREATE DATABASE IF NOT EXISTS analytics
LOCATION 's3a://lakehouse/warehouse/analytics.db';

-- Create Delta table
CREATE TABLE analytics.sales (
  id BIGINT,
  amount DECIMAL(10,2),
  date DATE
) USING DELTA
LOCATION 's3a://lakehouse/warehouse/analytics.db/sales';

-- Query data
SELECT date, SUM(amount) as total
FROM analytics.sales
GROUP BY date
ORDER BY date DESC;
```

## Delta Lake Features

### ACID Transactions

All table operations are ACID-compliant:

```sql
-- Atomic writes
INSERT INTO my_table VALUES (1, 'data');

-- Updates and deletes
UPDATE my_table SET status = 'processed' WHERE id = 1;
DELETE FROM my_table WHERE date < '2024-01-01';

-- Merge (upsert)
MERGE INTO target_table t
USING source_table s ON t.id = s.id
WHEN MATCHED THEN UPDATE SET t.status = s.status
WHEN NOT MATCHED THEN INSERT *;
```

### Time Travel

Query historical versions of tables:

```sql
-- Query as of timestamp
SELECT * FROM my_table TIMESTAMP AS OF '2024-11-10 10:00:00';

-- Query specific version
SELECT * FROM my_table VERSION AS OF 42;

-- View table history
DESCRIBE HISTORY my_table;
```

### Schema Evolution

Delta Lake handles schema changes automatically:

```sql
-- Add new column
ALTER TABLE my_table ADD COLUMN new_field STRING;

-- Schema is merged during writes
INSERT INTO my_table SELECT *, 'default_value' as new_field FROM old_data;
```

## Submitting Jobs

### Using spark-submit

```bash
docker exec flumen_spark_master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --deploy-mode client \
  --class com.example.MyApp \
  /path/to/my-app.jar
```

### Python jobs

```bash
docker exec flumen_spark_master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /path/to/my_script.py
```

## Ivy Cache

Spark automatically downloads dependencies on first use:

```bash
# Packages are cached in named volume
docker exec flumen_spark_master ls -la /opt/spark/.ivy2/jars/
```

Common packages:
- `delta-spark_2.13-4.0.0.jar` - Delta Lake core
- `delta-storage-4.0.0.jar` - Delta storage layer
- `postgresql-42.7.1.jar` - PostgreSQL JDBC driver
- `hadoop-aws-3.3.6.jar` - S3A filesystem
- `aws-java-sdk-bundle-1.12.367.jar` - AWS SDK

## Web Interfaces

Access Spark UIs after running `make up-tier1`:

- **Spark Master UI**: http://localhost:8080
  - Cluster status and worker information
  - Running and completed applications
  - Resource allocation and utilization

- **Spark Worker UI**: Not exposed (workers communicate internally)

## Troubleshooting

### Workers not connecting to Master

Check network connectivity:
```bash
docker exec flumen_spark_worker1 nc -zv spark-master 7077
```

Verify Master is healthy:
```bash
make health-spark-master
docker exec flumen_spark_master curl -sf http://localhost:8080/
```

### JAR dependency download issues

Check Ivy cache permissions:
```bash
docker exec flumen_spark_master ls -la /opt/spark/.ivy2/
```

Clear Ivy cache and restart:
```bash
docker volume rm flumen_spark_ivy
make restart
make health-spark-master
```

### S3A connection errors

Verify MinIO is accessible:
```bash
docker exec flumen_spark_master curl -I http://minio:9000
```

Check S3A configuration:
```bash
docker exec flumen_spark_master cat /opt/spark/conf/spark-defaults.conf | grep s3a
```

### Hive Metastore connection errors

Verify Hive Metastore is healthy:
```bash
make health-hive
docker exec flumen_spark_master nc -zv hive-metastore 9083
```

Check hive-site.xml is present:
```bash
docker exec flumen_spark_master ls -la /opt/spark/conf/hive-site.xml
```

### Job execution failures

View application logs:
```bash
make logs-spark
# or
docker logs flumen_spark_master
docker logs flumen_spark_worker1
docker logs flumen_spark_worker2
```

Check worker resources in Master UI:
- http://localhost:8080
- Verify workers have available cores and memory

## Storage Location

All Spark data is written to MinIO under:
```
s3a://lakehouse/warehouse/
├── database1.db/
│   ├── table1/
│   │   ├── _delta_log/
│   │   └── part-00000-*.parquet
│   └── table2/
└── database2.db/
    └── table3/
```

Delta Lake metadata is stored in `_delta_log/` directories:
```
table/_delta_log/
├── 00000000000000000000.json  # Initial transaction
├── 00000000000000000001.json  # Second transaction
└── _last_checkpoint             # Checkpoint pointer
```

## Performance Tips

### Partition your data

```sql
CREATE TABLE events (
  event_id BIGINT,
  event_time TIMESTAMP,
  user_id STRING
)
USING DELTA
PARTITIONED BY (DATE(event_time))
LOCATION 's3a://lakehouse/warehouse/events';
```

### Use Z-ordering

```sql
OPTIMIZE my_table ZORDER BY (user_id, date);
```

### Vacuum old versions

```sql
-- Remove files older than 7 days
VACUUM my_table RETAIN 168 HOURS;
```

### Analyze tables

```sql
ANALYZE TABLE my_table COMPUTE STATISTICS;
```

## Compatibility

Spark 4.0.1 with Delta Lake 4.0 is compatible with:
- **Hive Metastore**: 2.x, 3.x, 4.x (using Thrift protocol)
- **Parquet**: All versions
- **Delta Lake**: 2.x, 3.x, 4.x (forward compatible)
- **Python**: 3.8+
- **Scala**: 2.13.x
- **Java**: 11, 17

## Upgrade Notes

When upgrading Delta Lake versions:

1. Check compatibility: https://docs.delta.io/latest/releases.html
2. Update `DELTA_VERSION` in `.env`
3. Regenerate configuration: `make config-spark`
4. Clear Ivy cache: `docker volume rm flumen_spark_ivy`
5. Restart cluster: `make restart`

Delta Lake maintains backward compatibility for reading older table versions.
