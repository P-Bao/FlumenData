# Hive Metastore

Apache Hive Metastore serves as the catalog layer for FlumenData, providing metadata management for the lakehouse.

## Overview

**Image**: `flumendata/hive:standalone-metastore-4.1.0` (custom built)
**Base**: `apache/hive:standalone-metastore-4.1.0`
**Port**: 9083 (Thrift)
**Health**: Process check (`pgrep -f HiveMetaStore`)

## Architecture

The Hive Metastore provides:
- **2-level namespace**: `database.table`
- **PostgreSQL backend**: Metadata stored in PostgreSQL for durability
- **Thrift API**: Standard interface on port 9083
- **S3A integration**: Direct access to MinIO object storage

## Custom Dockerfile

Our custom image adds required JDBC drivers:

```dockerfile
FROM apache/hive:standalone-metastore-4.1.0
USER root

# Download PostgreSQL JDBC driver and AWS S3A libraries
RUN curl -fsSL https://jdbc.postgresql.org/download/postgresql-42.7.1.jar \
    -o /opt/hive/lib/postgresql-jdbc.jar && \
    curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar \
    -o /opt/hive/lib/hadoop-aws.jar && \
    curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.367/aws-java-sdk-bundle-1.12.367.jar \
    -o /opt/hive/lib/aws-java-sdk-bundle.jar

USER hive
```

## Configuration

Configuration is generated from `templates/hive/hive-site.xml.tpl`:

```xml
<configuration>
  <!-- PostgreSQL Backend -->
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://postgres:5432/flumendata</value>
  </property>

  <!-- S3A MinIO Integration -->
  <property>
    <name>fs.s3a.endpoint</name>
    <value>http://minio:9000</value>
  </property>

  <!-- Warehouse Location -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>s3a://lakehouse/warehouse</value>
  </property>
</configuration>
```

## Make Commands

```bash
# Configuration
make config-hive           # Generate hive-site.xml

# Service management
make up-tier1              # Start Hive Metastore
make logs-hive             # View Hive logs

# Health & verification
make health-hive           # Check if Hive is healthy
make verify-hive           # Verify Hive setup and show databases
make test-hive             # Test metastore connectivity
```

## Database Schema

The metastore schema is automatically initialized in PostgreSQL on first startup:

```bash
# View Hive Metastore tables in PostgreSQL
docker exec flumen_postgres psql -U flumen -d flumendata -c "\dt"

# Check Hive version
docker exec flumen_postgres psql -U flumen -d flumendata -c 'SELECT * FROM "VERSION"'
```

Expected output:
```
VER_ID | SCHEMA_VERSION | VERSION_COMMENT
-------+----------------+----------------------------
     1 | 4.1.0          | Hive release version 4.1.0
```

## Creating Databases

Create databases using Spark SQL:

```bash
# Interactive Spark SQL shell
make shell-spark-sql

# Create database
spark-sql> CREATE DATABASE my_database
           LOCATION 's3a://lakehouse/warehouse/my_database.db';

# List databases
spark-sql> SHOW DATABASES;
```

## Verification

Run the verification target to see all databases:

```bash
make verify-hive
```

This displays:
- List of all databases in the metastore
- Metadata database backend (PostgreSQL)
- Storage backend (S3A URI)
- Metastore Thrift URI

## Troubleshooting

### Metastore not starting

Check logs for missing JDBC driver:
```bash
make logs-hive | grep -i "jdbc\|driver\|postgres"
```

### Cannot connect to PostgreSQL

Verify PostgreSQL is healthy and network connectivity:
```bash
make health-postgres
docker exec flumen_hive_metastore nc -zv postgres 5432
```

### Tables not visible in Spark

Ensure Spark configuration includes hive-site.xml:
```bash
docker exec flumen_spark_master ls -l /opt/spark/conf/hive-site.xml
```

## Storage Location

All table data is stored in MinIO under:
```
s3a://lakehouse/warehouse/
├── database1.db/
│   ├── table1/
│   └── table2/
└── database2.db/
    └── table3/
```

## Compatibility

The Hive Metastore is compatible with:
- Apache Spark 2.x, 3.x, 4.x
- Presto / Trino
- Apache Impala
- AWS Athena (with Glue Data Catalog sync)
- Any tool supporting Hive Metastore Thrift protocol
