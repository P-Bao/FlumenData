# Rendered to config/spark/spark-defaults.conf
# Spark configuration with Delta Lake 4.0, Hive Metastore, and MinIO (S3A)

# === JAR Dependencies ===
spark.jars.packages io.delta:delta-spark_${SCALA_BINARY_VERSION}:${DELTA_VERSION},org.postgresql:postgresql:${POSTGRESQL_JDBC_VERSION},org.apache.hadoop:hadoop-aws:${HADOOP_AWS_VERSION},com.amazonaws:aws-java-sdk-bundle:${AWS_SDK_BUNDLE_VERSION}

# Ivy cache
spark.jars.ivy /opt/spark/.ivy2

# Set user.home for Ivy when downloading Hive JARs
spark.driver.extraJavaOptions -Duser.home=/opt/spark

# === SQL Extensions ===
spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension

# === Default Catalog (Delta Lake with Hive Metastore) ===
spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog

# === Hive Metastore Configuration ===
spark.hadoop.hive.metastore.uris ${HIVE_METASTORE_URI}
spark.sql.catalogImplementation hive
spark.sql.warehouse.dir s3a://${MINIO_BUCKET}/warehouse

# Enable Hive support with Maven-downloaded JARs for compatibility
spark.sql.hive.metastore.version 4.0.0
spark.sql.hive.metastore.jars maven

# === S3A (MinIO) Configuration ===
spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.endpoint ${MINIO_SERVER_URL}
spark.hadoop.fs.s3a.access.key ${MINIO_ROOT_USER}
spark.hadoop.fs.s3a.secret.key ${MINIO_ROOT_PASSWORD}
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.connection.ssl.enabled false

# S3A credentials provider (use AWS SDK v1)
spark.hadoop.fs.s3a.aws.credentials.provider org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider

# MinIO compatibility settings
spark.hadoop.fs.s3a.endpoint.region us-east-1
spark.hadoop.fs.s3a.change.detection.mode none

# S3A performance tuning
spark.hadoop.fs.s3a.fast.upload true
spark.hadoop.fs.s3a.fast.upload.buffer disk
spark.hadoop.fs.s3a.block.size 134217728
spark.hadoop.fs.s3a.multipart.size 134217728
spark.hadoop.fs.s3a.multipart.threshold 268435456
spark.hadoop.fs.s3a.multipart.purge.age 86400
spark.hadoop.fs.s3a.connection.maximum 100
spark.hadoop.fs.s3a.connection.timeout 60000
spark.hadoop.fs.s3a.connection.establish.timeout 30000

# === Delta Lake Configuration ===
# Time travel support
spark.databricks.delta.retentionDurationCheck.enabled false
spark.databricks.delta.properties.defaults.enableChangeDataFeed true

# === Performance Configuration ===
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
spark.sql.files.maxPartitionBytes 134217728

# === Shuffle Configuration ===
spark.sql.shuffle.partitions 200
