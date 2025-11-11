# Testing Guide

FlumenData includes comprehensive testing to ensure all components work correctly together.

## Test Architecture

### Test Levels

1. **Health Checks**: Verify services are running
2. **Smoke Tests**: Basic functionality verification
3. **Integration Tests**: Multi-service workflows
4. **Persistence Tests**: Data survives restarts

### Test Organization

```
Testing Hierarchy:
├── make test                  # All tests
│   ├── make test-tier0       # Foundation tests
│   │   ├── make test-postgres
│   │   ├── make test-valkey
│   │   └── make test-minio
│   └── make test-tier1       # Data platform tests
│       ├── make test-hive
│       └── make test-spark
```

## Running Tests

### Complete Test Suite

```bash
# Run all tests
make test
```

**Output:**
```
[test] Running all tests...
[postgres:test] ✓ Connection successful
[postgres:test] ✓ Table creation successful
[postgres:test] ✓ Data insertion successful
[valkey:test] ✓ Connection successful
[valkey:test] ✓ SET/GET operations successful
[minio:test] ✓ Bucket creation successful
[minio:test] ✓ Object upload successful
[hive:test] ✓ Metastore connection successful
[hive:test] ✓ Database creation successful
[spark:test] ✓ SparkPi job completed successfully
[test] All tests passed!
```

### Tier-Specific Tests

```bash
# Test foundation services
make test-tier0

# Test data platform services
make test-tier1
```

### Individual Service Tests

```bash
make test-postgres
make test-valkey
make test-minio
make test-hive
make test-spark
```

## Test Details

### PostgreSQL Tests

**Location:** `makefiles/postgres.mk`

**What it tests:**
```bash
make test-postgres
```

1. **Connection test**: Verify PostgreSQL accepts connections
2. **Table creation**: Create test table
3. **Data insertion**: Insert sample data
4. **Data retrieval**: Query inserted data

**Implementation:**
```makefile
test-postgres:
	@echo "[postgres:test] Testing connection..."
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1" > /dev/null
	@echo "[postgres:test] ✓ Connection successful"

	@echo "[postgres:test] Creating test table..."
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c \
	  "CREATE TABLE IF NOT EXISTS test_table (id SERIAL, data TEXT)"
	@echo "[postgres:test] ✓ Table created"

	@echo "[postgres:test] Inserting data..."
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c \
	  "INSERT INTO test_table (data) VALUES ('test')"
	@echo "[postgres:test] ✓ Data inserted"

	@echo "[postgres:test] Querying data..."
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c \
	  "SELECT * FROM test_table"
	@echo "[postgres:test] ✓ All tests passed"
```

### Valkey Tests

**Location:** `makefiles/valkey.mk`

**What it tests:**
```bash
make test-valkey
```

1. **Connection test**: Verify Valkey accepts connections
2. **SET operation**: Write key-value pair
3. **GET operation**: Retrieve value
4. **Key deletion**: Clean up test data

**Implementation:**
```makefile
test-valkey:
	@echo "[valkey:test] Testing connection..."
	@docker exec flumen_valkey redis-cli PING > /dev/null
	@echo "[valkey:test] ✓ Connection successful"

	@echo "[valkey:test] Testing SET operation..."
	@docker exec flumen_valkey redis-cli SET test_key "test_value"
	@echo "[valkey:test] ✓ SET successful"

	@echo "[valkey:test] Testing GET operation..."
	@docker exec flumen_valkey redis-cli GET test_key | grep "test_value"
	@echo "[valkey:test] ✓ GET successful"

	@echo "[valkey:test] Cleaning up..."
	@docker exec flumen_valkey redis-cli DEL test_key
	@echo "[valkey:test] ✓ All tests passed"
```

### MinIO Tests

**Location:** `makefiles/minio.mk`

**What it tests:**
```bash
make test-minio
```

1. **Connection test**: Verify MinIO API is accessible
2. **Bucket operations**: Create and list buckets
3. **Object operations**: Upload and download objects
4. **Cleanup**: Remove test data

**Implementation:**
```makefile
test-minio:
	@echo "[minio:test] Testing connection..."
	@docker exec flumen_minio mc alias set local http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
	@echo "[minio:test] ✓ Connection successful"

	@echo "[minio:test] Creating test bucket..."
	@docker exec flumen_minio mc mb local/test-bucket --ignore-existing
	@echo "[minio:test] ✓ Bucket created"

	@echo "[minio:test] Uploading test object..."
	@docker exec flumen_minio sh -c "echo 'test data' | mc pipe local/test-bucket/test-object"
	@echo "[minio:test] ✓ Upload successful"

	@echo "[minio:test] Downloading test object..."
	@docker exec flumen_minio mc cat local/test-bucket/test-object | grep "test data"
	@echo "[minio:test] ✓ Download successful"

	@echo "[minio:test] Cleaning up..."
	@docker exec flumen_minio mc rb local/test-bucket --force
	@echo "[minio:test] ✓ All tests passed"
```

### Hive Metastore Tests

**Location:** `makefiles/hive.mk`

**What it tests:**
```bash
make test-hive
```

1. **Connection test**: Verify Thrift API is accessible
2. **Database creation**: Create test database
3. **Metadata storage**: Verify metadata in PostgreSQL
4. **Cleanup**: Drop test database

**Implementation:**
```makefile
test-hive:
	@echo "[hive:test] Testing connection..."
	@docker exec flumen_spark_master nc -zv hive-metastore 9083
	@echo "[hive:test] ✓ Connection successful"

	@echo "[hive:test] Creating test database..."
	@docker exec flumen_spark_master /opt/spark/bin/spark-sql \
	  -e "CREATE DATABASE IF NOT EXISTS test_db LOCATION 's3a://lakehouse/warehouse/test_db.db'"
	@echo "[hive:test] ✓ Database created"

	@echo "[hive:test] Verifying in PostgreSQL..."
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
	  -c "SELECT * FROM \"DBS\" WHERE \"NAME\" = 'test_db'"
	@echo "[hive:test] ✓ Metadata stored"

	@echo "[hive:test] Cleaning up..."
	@docker exec flumen_spark_master /opt/spark/bin/spark-sql \
	  -e "DROP DATABASE IF EXISTS test_db CASCADE"
	@echo "[hive:test] ✓ All tests passed"
```

### Spark Tests

**Location:** `makefiles/spark.mk`

**What it tests:**
```bash
make test-spark
```

1. **Job submission**: Submit SparkPi example job
2. **Execution**: Verify job completes successfully
3. **Result verification**: Check Pi calculation output

**Implementation:**
```makefile
test-spark:
	@echo "[spark:test] Running SparkPi job..."
	@docker exec flumen_spark_master /opt/spark/bin/spark-submit \
	  --master spark://spark-master:7077 \
	  --class org.apache.spark.examples.SparkPi \
	  /opt/spark/examples/jars/spark-examples_2.13-*.jar \
	  10
	@echo "[spark:test] ✓ Job completed successfully"
```

## Integration Tests

### Delta Lake Integration Test

Create a Python test file:

```python
# test_delta_integration.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Delta Integration Test") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# Create test database
spark.sql("CREATE DATABASE IF NOT EXISTS test_integration")
spark.sql("USE test_integration")

# Create Delta table
spark.sql("""
    CREATE TABLE test_delta (
        id BIGINT,
        value STRING
    ) USING DELTA
    LOCATION 's3a://lakehouse/warehouse/test_integration.db/test_delta'
""")

# Insert data
spark.sql("INSERT INTO test_delta VALUES (1, 'test')")

# Query data
result = spark.sql("SELECT * FROM test_delta").collect()
assert len(result) == 1
assert result[0]['id'] == 1
assert result[0]['value'] == 'test'

# Time travel
spark.sql("INSERT INTO test_delta VALUES (2, 'test2')")
history = spark.sql("DESCRIBE HISTORY test_delta").collect()
assert len(history) >= 2

# Cleanup
spark.sql("DROP DATABASE test_integration CASCADE")

print("✓ All integration tests passed!")
```

**Run the test:**
```bash
docker cp test_delta_integration.py flumen_spark_master:/tmp/
docker exec flumen_spark_master /opt/spark/bin/spark-submit /tmp/test_delta_integration.py
```

### Hive + Spark Integration Test

```python
# test_hive_spark_integration.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Hive Spark Integration") \
    .enableHiveSupport() \
    .getOrCreate()

# Verify Hive catalog
catalog = spark.catalog.currentCatalog()
assert catalog == "spark_catalog"

# Create database in Hive
spark.sql("CREATE DATABASE IF NOT EXISTS hive_test")
databases = [db.name for db in spark.catalog.listDatabases()]
assert "hive_test" in databases

# Create table
spark.sql("""
    CREATE TABLE hive_test.test_table (
        id INT,
        name STRING
    ) USING PARQUET
""")

# Verify table exists
tables = [t.name for t in spark.catalog.listTables("hive_test")]
assert "test_table" in tables

# Insert and query
spark.sql("INSERT INTO hive_test.test_table VALUES (1, 'test')")
result = spark.sql("SELECT * FROM hive_test.test_table").collect()
assert len(result) == 1

# Cleanup
spark.sql("DROP DATABASE hive_test CASCADE")

print("✓ Hive + Spark integration tests passed!")
```

## Persistence Tests

Verify data survives container restarts:

### PostgreSQL Persistence

```bash
make persist-postgres
```

**What it does:**
1. Insert test data
2. Restart PostgreSQL container
3. Verify data still exists

### MinIO Persistence

```bash
make persist-minio
```

**What it does:**
1. Upload test object
2. Restart MinIO container
3. Verify object still exists

### Spark Persistence

```bash
make persist-spark
```

**What it does:**
1. Restart Spark cluster
2. Verify workers reconnect to master
3. Submit test job

## Writing New Tests

### Test Template

```makefile
# makefiles/myservice.mk

test-myservice:
	@echo "[myservice:test] Starting tests..."

	# Test 1: Connection
	@echo "[myservice:test] Testing connection..."
	@docker exec flumen_myservice command-to-test-connection
	@echo "[myservice:test] ✓ Connection successful"

	# Test 2: Basic operation
	@echo "[myservice:test] Testing basic operation..."
	@docker exec flumen_myservice command-to-test-operation
	@echo "[myservice:test] ✓ Operation successful"

	# Test 3: Data verification
	@echo "[myservice:test] Verifying data..."
	@docker exec flumen_myservice command-to-verify | grep "expected"
	@echo "[myservice:test] ✓ Data verified"

	# Cleanup
	@echo "[myservice:test] Cleaning up..."
	@docker exec flumen_myservice command-to-cleanup
	@echo "[myservice:test] ✓ All tests passed"

.PHONY: test-myservice
```

### Best Practices

1. **Always cleanup**: Remove test data after tests
2. **Check exit codes**: Use `set -e` in shell commands
3. **Descriptive output**: Use emoji and colors
4. **Independent tests**: Don't depend on test execution order
5. **Idempotent**: Tests should be runnable multiple times

### Example: Comprehensive Test

```makefile
test-comprehensive:
	@set -e; \
	echo "$(BLUE)[test] Starting comprehensive test suite$(NC)"; \
	\
	echo "$(YELLOW)[test] Phase 1: Health checks$(NC)"; \
	$(MAKE) health; \
	\
	echo "$(YELLOW)[test] Phase 2: Service tests$(NC)"; \
	$(MAKE) test-tier0; \
	$(MAKE) test-tier1; \
	\
	echo "$(YELLOW)[test] Phase 3: Integration tests$(NC)"; \
	docker cp test_integration.py flumen_spark_master:/tmp/; \
	docker exec flumen_spark_master /opt/spark/bin/spark-submit /tmp/test_integration.py; \
	\
	echo "$(YELLOW)[test] Phase 4: Persistence tests$(NC)"; \
	$(MAKE) persist-postgres; \
	$(MAKE) persist-minio; \
	\
	echo "$(GREEN)[test] ✓ All comprehensive tests passed!$(NC)"

.PHONY: test-comprehensive
```

## Continuous Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          docker --version
          docker compose version

      - name: Initialize environment
        run: make init

      - name: Run health checks
        run: make health

      - name: Run tests
        run: make test

      - name: Show logs on failure
        if: failure()
        run: make logs
```

## Troubleshooting Tests

### Test Failures

**View detailed logs:**
```bash
make logs | grep ERROR
```

**Run individual test with verbose output:**
```bash
docker exec -it flumen_spark_master /opt/spark/bin/spark-submit \
  --verbose \
  /tmp/test_integration.py
```

### Common Issues

**Issue:** Tests pass locally but fail in CI
- **Cause:** Timing issues, resource constraints
- **Solution:** Increase health check timeouts, add delays

**Issue:** Intermittent test failures
- **Cause:** Race conditions, async operations
- **Solution:** Add explicit waits, check dependencies

**Issue:** Cleanup doesn't run
- **Cause:** Test fails before cleanup
- **Solution:** Use trap in bash or try/finally in Python

## Next Steps

- [Contributing Guide](contributing.md) - Learn how to contribute
- [Architecture](../getting-started/architecture.md) - Understand system design
- [Commands Reference](../configuration/commands.md) - Available commands
