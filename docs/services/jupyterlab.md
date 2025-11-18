# JupyterLab

JupyterLab serves as the interactive development environment for FlumenData, providing notebooks, data exploration, and direct integration with the Spark cluster.

## Overview

**Image**: `flumendata/jupyterlab:spark-4.0.1` (custom built)
**Base**: `jupyter/scipy-notebook:python-3.10`
**Port**: 8888 (Web UI)
**Python**: 3.10
**PySpark**: 4.0.1 (matches cluster)
**Delta Lake**: 4.0.0 (matches cluster)

## Architecture

JupyterLab provides:
- **Interactive Notebooks**: Jupyter notebooks with Python, PySpark, and SQL kernels
- **Spark Integration**: Direct connection to FlumenData Spark cluster (client mode)
- **Delta Lake Support**: Read and write Delta tables with ACID guarantees
- **Hive Metastore Access**: Query and manage databases and tables
- **S3/MinIO Integration**: Direct access to data lake storage
- **Data Science Stack**: pandas, matplotlib, seaborn, plotly for analysis and visualization

## Configuration

### Spark Configuration

JupyterLab uses a pre-configured Spark settings file:

```properties
# Connect to FlumenData Spark cluster
spark.master spark://spark-master:7077
spark.submit.deployMode client

# Delta Lake integration
spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension
spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog

# Hive Metastore
spark.hadoop.hive.metastore.uris thrift://hive-metastore:9083
spark.sql.catalogImplementation hive
spark.sql.warehouse.dir s3a://lakehouse/warehouse

# S3A MinIO access
spark.hadoop.fs.s3a.endpoint http://minio:9000
spark.hadoop.fs.s3a.access.key minioadmin
spark.hadoop.fs.s3a.secret.key minioadmin123
```

## Make Commands

```bash
# Build and start
make build-jupyterlab        # Build custom JupyterLab image
make up-tier2                # Start JupyterLab and other Tier 2 services

# Access
make token-jupyterlab        # Get JupyterLab access token
make logs-jupyterlab         # View JupyterLab logs

# Development
make shell-jupyterlab        # Open bash shell
make python-jupyterlab       # Open Python shell

# Testing
make test-jupyterlab         # Test Spark integration
make health-jupyterlab       # Check service health

# Management
make restart-jupyterlab      # Restart service
make down-tier2              # Stop Tier 2 services
```

## Getting Started

### 1. Start JupyterLab

```bash
make up-tier2
```

### 2. Get Access Token

```bash
make token-jupyterlab
```

### 3. Access Web UI

Open http://localhost:8888 and enter the token.

## Using PySpark in Notebooks

### Create Spark Session

```python
from pyspark.sql import SparkSession

# Create Spark session connected to FlumenData cluster
spark = SparkSession.builder \
    .appName("JupyterLab-Notebook") \
    .master("spark://spark-master:7077") \
    .config("spark.submit.deployMode", "client") \
    .config("spark.driver.memory", "2g") \
    .getOrCreate()

# Verify connection
print(f"Spark version: {spark.version}")
print(f"Catalog implementation: {spark.conf.get('spark.sql.catalogImplementation')}")
```

### Working with Databases and Tables

```python
# Show available databases
spark.sql("SHOW DATABASES").show()

# Create a new database
spark.sql("CREATE DATABASE IF NOT EXISTS analytics")

# Use the database
spark.sql("USE analytics")

# Create a Delta table
spark.sql("""
    CREATE TABLE IF NOT EXISTS customers (
        customer_id INT,
        name STRING,
        email STRING,
        country STRING,
        signup_date DATE,
        lifetime_value DECIMAL(10,2)
    ) USING DELTA
    LOCATION 's3a://lakehouse/warehouse/analytics.db/customers'
""")

# Insert sample data
spark.sql("""
    INSERT INTO customers VALUES
    (1, 'Alice Smith', 'alice@example.com', 'USA', '2024-01-15', 1250.50),
    (2, 'Bob Johnson', 'bob@example.com', 'Canada', '2024-02-20', 890.25),
    (3, 'Carol Davis', 'carol@example.com', 'UK', '2024-03-10', 2100.00)
""")

# Query data
df = spark.sql("SELECT * FROM customers WHERE lifetime_value > 1000")
df.show()
```

### DataFrame API

```python
from pyspark.sql.functions import col, avg, count, sum as spark_sum

# Read Delta table as DataFrame
customers_df = spark.table("analytics.customers")

# Data exploration
customers_df.printSchema()
customers_df.describe().show()

# Aggregations
country_stats = customers_df.groupBy("country") \
    .agg(
        count("*").alias("customer_count"),
        avg("lifetime_value").alias("avg_ltv"),
        spark_sum("lifetime_value").alias("total_ltv")
    ) \
    .orderBy(col("total_ltv").desc())

country_stats.show()
```

### Reading and Writing Data

```python
# Read CSV from S3/MinIO
df = spark.read.csv(
    "s3a://lakehouse/raw/sales.csv",
    header=True,
    inferSchema=True
)

# Write as Delta table
df.write.format("delta") \
    .mode("overwrite") \
    .option("mergeSchema", "true") \
    .saveAsTable("analytics.sales")

# Read Delta table
sales_df = spark.read.format("delta").table("analytics.sales")

# Write to Parquet
df.write.parquet("s3a://lakehouse/processed/sales.parquet")
```

### Time Travel with Delta Lake

```python
# View table history
spark.sql("DESCRIBE HISTORY analytics.customers").show(truncate=False)

# Query as of specific timestamp
df_yesterday = spark.read \
    .format("delta") \
    .option("timestampAsOf", "2024-11-09 10:00:00") \
    .table("analytics.customers")

# Query specific version
df_v0 = spark.read \
    .format("delta") \
    .option("versionAsOf", 0) \
    .table("analytics.customers")

# Restore table to previous version
spark.sql("RESTORE TABLE analytics.customers TO VERSION AS OF 2")
```

## Data Analysis and Visualization

### Using pandas

```python
# Convert Spark DataFrame to pandas
pandas_df = spark.table("analytics.customers").toPandas()

# Pandas analysis
print(pandas_df.describe())
print(pandas_df.groupby('country')['lifetime_value'].mean())
```

### Visualization

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Set style
sns.set_theme(style="whitegrid")

# Query data
df = spark.sql("""
    SELECT country, COUNT(*) as customer_count, AVG(lifetime_value) as avg_ltv
    FROM analytics.customers
    GROUP BY country
""").toPandas()

# Create plots
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Bar plot
sns.barplot(data=df, x='country', y='customer_count', ax=ax1)
ax1.set_title('Customers by Country')
ax1.set_ylabel('Customer Count')

# Average LTV
sns.barplot(data=df, x='country', y='avg_ltv', ax=ax2)
ax2.set_title('Average Lifetime Value by Country')
ax2.set_ylabel('Average LTV ($)')

plt.tight_layout()
plt.show()
```

## Direct S3/MinIO Access

Besides Spark, you can also access MinIO directly using boto3 or s3fs:

```python
import boto3
from botocore.client import Config

# Configure S3 client for MinIO
s3 = boto3.client(
    's3',
    endpoint_url='http://minio:9000',
    aws_access_key_id='minioadmin',
    aws_secret_access_key='minioadmin123',
    config=Config(signature_version='s3v4'),
    region_name='us-east-1'
)

# List buckets
buckets = s3.list_buckets()
for bucket in buckets['Buckets']:
    print(f"  {bucket['Name']}")

# List objects in bucket
response = s3.list_objects_v2(Bucket='lakehouse')
for obj in response.get('Contents', []):
    print(f"  {obj['Key']}")
```

Using s3fs for file-like operations:

```python
import s3fs
import pandas as pd

# Create s3fs filesystem
fs = s3fs.S3FileSystem(
    client_kwargs={'endpoint_url': 'http://minio:9000'},
    key='minioadmin',
    secret='minioadmin123'
)

# Read Parquet file
df = pd.read_parquet('s3://lakehouse/data/example.parquet', filesystem=fs)

# Write CSV
df.to_csv('s3://lakehouse/data/output.csv', storage_options={
    'client_kwargs': {'endpoint_url': 'http://minio:9000'},
    'key': 'minioadmin',
    'secret': 'minioadmin123'
})
```

## Database Connectivity

JupyterLab includes PostgreSQL client for direct database access:

```python
import psycopg2
import pandas as pd

# Connect to FlumenData PostgreSQL
conn = psycopg2.connect(
    host="postgres",
    port=5432,
    database="metastore",
    user="postgres",
    password="postgres123"
)

# Query using pandas
df = pd.read_sql("SELECT * FROM metastore.tbls LIMIT 10", conn)
print(df)

conn.close()
```

## Installed Python Packages

JupyterLab comes with a comprehensive data science stack:

**Core:**
- pyspark 4.0.1
- delta-spark 4.0.0

**Data Processing:**
- pandas 2.2.2
- pyarrow 16.1.0

**Visualization:**
- matplotlib 3.9.0
- seaborn 0.13.2
- plotly 5.22.0

**Storage:**
- boto3 1.34.144
- s3fs 2024.6.1

**Database:**
- psycopg2-binary 2.9.9
- sqlalchemy 2.0.31

**Jupyter:**
- jupyterlab-git 0.50.1
- ipywidgets 8.1.3

## Persistent Storage

Notebooks and files are stored in the `flumen_jupyter_notebooks` named volume and persist across container restarts.

Access notebooks at: `/home/jovyan/work`

Shared data directory: `/home/jovyan/shared`

## Troubleshooting

### Cannot connect to Spark cluster

Check Spark master is running:
```bash
make health-spark-master
```

Verify network connectivity:
```bash
docker exec flumen_jupyterlab nc -zv spark-master 7077
```

### Import errors for pyspark

Ensure PySpark is installed:
```bash
docker exec flumen_jupyterlab pip list | grep pyspark
```

Check PYTHONPATH:
```bash
docker exec flumen_jupyterlab env | grep PYTHON
```

### S3A connection issues

Verify MinIO credentials in Spark config:
```bash
docker exec flumen_jupyterlab cat /usr/local/spark/conf/spark-defaults.conf | grep s3a
```

Test MinIO connectivity:
```bash
docker exec flumen_jupyterlab curl -I http://minio:9000
```

### Lost access token

Retrieve token from logs:
```bash
make token-jupyterlab
```

Or from server list:
```bash
docker exec flumen_jupyterlab jupyter server list
```

## Performance Tips

### Spark Driver Memory

For large datasets, increase driver memory:

```python
spark = SparkSession.builder \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "4g") \
    .getOrCreate()
```

### Optimize DataFrame Operations

```python
# Cache frequently used DataFrames
df.cache()

# Use broadcast for small lookup tables
from pyspark.sql.functions import broadcast
result = large_df.join(broadcast(small_df), "key")

# Repartition for better parallelism
df = df.repartition(200)
```

### Close Spark Sessions

Always stop Spark session when done:

```python
spark.stop()
```

## Security Notes

- JupyterLab requires token authentication
- Tokens are randomly generated on container start
- Use `make token-jupyterlab` to retrieve the current token
- Change default MinIO credentials in production
- Use environment-specific `.env` files for different deployments

## Next Steps

- Build dashboards using [Superset](superset.md)
- Query curated tables via [Trino](trino.md)
- Learn about [Delta Lake optimization](spark.md#performance-tips)
