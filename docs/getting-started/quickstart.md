# Quick Start

This guide will walk you through creating your first Delta Lake table and running queries in FlumenData.

## Prerequisites

Complete the [Installation](installation.md) guide and verify all services are running:

```bash
python3 flumen health
```

## Step 1: Create a Database

Open the Spark SQL shell:

```bash
python3 flumen shell-spark-sql
```

Create your first database:

```sql
CREATE DATABASE quickstart
LOCATION 's3a://lakehouse/warehouse/quickstart.db';

USE quickstart;

SHOW DATABASES;
```

## Step 2: Create a Delta Table

Create a sample Delta table with customer data:

```sql
CREATE TABLE customers (
  customer_id BIGINT,
  name STRING,
  email STRING,
  signup_date DATE,
  country STRING
) USING DELTA
LOCATION 's3a://lakehouse/warehouse/quickstart.db/customers';
```

Verify the table was created:

```sql
SHOW TABLES;

DESCRIBE EXTENDED customers;
```

## Step 3: Insert Data

Insert sample records:

```sql
INSERT INTO customers VALUES
  (1, 'Alice Johnson', 'alice@example.com', '2024-01-15', 'USA'),
  (2, 'Bob Smith', 'bob@example.com', '2024-02-20', 'Canada'),
  (3, 'Carlos Garcia', 'carlos@example.com', '2024-03-10', 'Mexico'),
  (4, 'Diana Lee', 'diana@example.com', '2024-04-05', 'USA'),
  (5, 'Eva Mueller', 'eva@example.com', '2024-05-12', 'Germany');
```

Verify the data:

```sql
SELECT * FROM customers ORDER BY customer_id;
```

## Step 4: Query Data

Run analytical queries:

```sql
-- Count customers by country
SELECT country, COUNT(*) as total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;

-- Find customers who signed up in Q1 2024
SELECT name, email, signup_date
FROM customers
WHERE signup_date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY signup_date;
```

## Step 5: Update Records

Delta Lake supports ACID updates:

```sql
-- Update a customer's email
UPDATE customers
SET email = 'alice.johnson@newdomain.com'
WHERE customer_id = 1;

-- Verify the update
SELECT * FROM customers WHERE customer_id = 1;
```

## Step 6: Time Travel

Query previous versions of the table:

```sql
-- View table history
DESCRIBE HISTORY customers;

-- Query the original data (before update)
SELECT * FROM customers VERSION AS OF 0;

-- Compare with current version
SELECT * FROM customers;
```

## Step 7: Delete Records

Delete specific records:

```sql
DELETE FROM customers WHERE country = 'Germany';

-- Verify deletion
SELECT * FROM customers ORDER BY customer_id;
```

## Step 8: Create Partitioned Table

Create a partitioned table for better performance:

```sql
CREATE TABLE orders (
  order_id BIGINT,
  customer_id BIGINT,
  amount DECIMAL(10,2),
  order_date DATE,
  status STRING
) USING DELTA
PARTITIONED BY (DATE(order_date))
LOCATION 's3a://lakehouse/warehouse/quickstart.db/orders';
```

Insert partitioned data:

```sql
INSERT INTO orders VALUES
  (101, 1, 150.00, '2024-11-01', 'completed'),
  (102, 2, 75.50, '2024-11-01', 'completed'),
  (103, 3, 200.00, '2024-11-02', 'pending'),
  (104, 1, 320.00, '2024-11-03', 'completed'),
  (105, 4, 95.00, '2024-11-03', 'cancelled');
```

Query with partition pruning:

```sql
-- This query only scans the relevant partition
SELECT * FROM orders
WHERE order_date = '2024-11-01';
```

## Step 9: Join Tables

Perform joins across Delta tables:

```sql
-- Find customer names with their order totals
SELECT
  c.name,
  c.country,
  COUNT(o.order_id) as total_orders,
  SUM(o.amount) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name, c.country
ORDER BY total_spent DESC;
```

## Step 10: Explore with PySpark

Exit Spark SQL (`Ctrl+D`) and open PySpark:

```bash
python3 flumen shell-pyspark
```

Run Python code:

```python
# Read Delta table
df = spark.read.format("delta").table("quickstart.customers")
df.show()

# Filter and transform
from pyspark.sql.functions import year, month

df_with_month = df.withColumn("signup_month", month("signup_date"))
df_with_month.show()

# Write to new Delta table
df_with_month.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("quickstart.customers_with_month")

# Verify
spark.sql("SELECT * FROM quickstart.customers_with_month").show()
```

## Viewing Data in MinIO

Your Delta tables are stored as Parquet files in MinIO:

1. Open MinIO Console: http://localhost:9001
2. Login with: `minioadmin` / `minioadmin123`
3. Navigate to: `lakehouse` → `warehouse` → `quickstart.db`
4. You'll see:
   - `customers/` - Customer data and Delta logs
   - `orders/` - Order data partitioned by date
   - Each table has a `_delta_log/` directory with transaction logs

## Monitoring with Spark UI

View query execution details:

1. Open Spark Master UI: http://localhost:8080
2. Click on "Running Applications" or "Completed Applications"
3. Click on an application to see:
   - DAG visualization
   - Stage details
   - Task execution times
   - Memory usage

## Common Operations Cheat Sheet

```sql
-- List all databases
SHOW DATABASES;

-- Use a database
USE quickstart;

-- List all tables
SHOW TABLES;

-- Describe table structure
DESCRIBE customers;

-- View table history
DESCRIBE HISTORY customers;

-- Optimize table (compaction)
OPTIMIZE customers;

-- Vacuum old files (removes files older than 7 days)
VACUUM customers RETAIN 168 HOURS;

-- Analyze table for query optimization
ANALYZE TABLE customers COMPUTE STATISTICS;

-- Drop table
DROP TABLE IF EXISTS customers;

-- Drop database
DROP DATABASE IF EXISTS quickstart CASCADE;
```

## Clean Up

To remove the quickstart data:

```bash
# In Spark SQL
DROP DATABASE quickstart CASCADE;
```

## Next Steps

Now that you've completed the quickstart:

- [Architecture Overview](architecture.md) - Understand how components work together
- [Hive Metastore](../services/hive.md) - Learn about catalog management
- [Apache Spark](../services/spark.md) - Deep dive into Spark features
- [Configuration](../configuration/environment.md) - Customize your environment

## Troubleshooting

### Table not found error

Ensure you're using the correct database:

```sql
USE quickstart;
SHOW TABLES;
```

### Permission denied on S3A

Verify MinIO credentials in configuration:

```bash
docker exec flumen_spark_master cat /opt/spark/conf/spark-defaults.conf | grep s3a
```

### Slow query performance

Optimize your tables:

```sql
-- Compact small files
OPTIMIZE customers;

-- Z-order for better data skipping
OPTIMIZE customers ZORDER BY (country);
```

### Out of memory errors

Increase Spark worker memory in `docker-compose.tier1.yml` or reduce data size for testing.
