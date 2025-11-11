# Rendered to config/jupyterlab/spark-defaults.conf
# Spark configuration for JupyterLab to connect to FlumenData cluster

# === Master Connection ===
spark.master spark://spark-master:7077
spark.submit.deployMode client

# === Application Configuration ===
spark.app.name JupyterLab-FlumenData
spark.driver.memory 2g
spark.executor.memory 2g
spark.executor.cores 2

# Set Ivy cache and suppress warnings
spark.jars.ivy /home/jovyan/.ivy2
spark.driver.extraJavaOptions -Duser.home=/home/jovyan -Daws.java.v1.disableDeprecationAnnouncement=true

# === PySpark Configuration ===
# Configure Python paths for driver (JupyterLab) and executors (Spark workers)
spark.pyspark.python /usr/bin/python3
spark.pyspark.driver.python python3

# === Delta Lake Configuration ===
spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension
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
spark.hadoop.fs.s3a.aws.credentials.provider org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider

# MinIO compatibility
spark.hadoop.fs.s3a.endpoint.region us-east-1
spark.hadoop.fs.s3a.change.detection.mode none

# S3A timeouts and performance (numeric values in milliseconds/bytes, not duration strings)
spark.hadoop.fs.s3a.connection.timeout 60000
spark.hadoop.fs.s3a.connection.establish.timeout 30000
spark.hadoop.fs.s3a.connection.request.timeout 60000
spark.hadoop.fs.s3a.attempts.maximum 10
spark.hadoop.fs.s3a.retry.limit 5
spark.hadoop.fs.s3a.retry.throttle.limit 20
spark.hadoop.fs.s3a.retry.throttle.interval 500
spark.hadoop.fs.s3a.readahead.range 65536
spark.hadoop.fs.s3a.socket.send.buffer 8192
spark.hadoop.fs.s3a.socket.recv.buffer 8192
spark.hadoop.fs.s3a.paging.maximum 5000
spark.hadoop.fs.s3a.threads.max 10
spark.hadoop.fs.s3a.threads.keepalivetime 60000
spark.hadoop.fs.s3a.max.total.tasks 5
spark.hadoop.fs.s3a.multipart.purge true
spark.hadoop.fs.s3a.committer.threads 8

# === JAR Dependencies ===
spark.jars /home/jovyan/.ivy2/jars/hadoop-aws-${HADOOP_AWS_VERSION}.jar,/home/jovyan/.ivy2/jars/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar,/home/jovyan/.ivy2/jars/postgresql-${POSTGRESQL_JDBC_VERSION}.jar,/home/jovyan/.ivy2/jars/delta-spark_2.13-${DELTA_VERSION}.jar,/home/jovyan/.ivy2/jars/delta-storage-${DELTA_VERSION}.jar

# === Performance Configuration ===
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
