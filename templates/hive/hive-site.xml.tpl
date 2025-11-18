<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Rendered to config/hive/hive-site.xml -->
<!-- Hive Metastore configuration with PostgreSQL backend and MinIO (S3) -->

<configuration>
  <!-- PostgreSQL as Hive Metastore Backend -->
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://postgres:5432/${POSTGRES_DB}</value>
    <description>JDBC connect string for PostgreSQL database</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
    <description>Driver class name for PostgreSQL JDBC driver</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>${POSTGRES_USER}</value>
    <description>PostgreSQL username</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>${POSTGRES_PASSWORD}</value>
    <description>PostgreSQL password</description>
  </property>

  <!-- Metastore Configuration -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>s3a://${MINIO_BUCKET}/warehouse</value>
    <description>Default location for Hive tables in MinIO</description>
  </property>

  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://hive-metastore:9083</value>
    <description>Hive metastore server URI</description>
  </property>

  <property>
    <name>hive.metastore.schema.verification</name>
    <value>false</value>
    <description>Enforce metastore schema version consistency</description>
  </property>

  <property>
    <name>hive.metastore.schema.verification.record.version</name>
    <value>false</value>
  </property>

  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>true</value>
    <description>Auto-create metastore schema</description>
  </property>

  <property>
    <name>datanucleus.fixedDatastore</name>
    <value>false</value>
  </property>

  <property>
    <name>datanucleus.autoCreateTables</name>
    <value>true</value>
  </property>

  <property>
    <name>datanucleus.autoCreateColumns</name>
    <value>true</value>
  </property>

  <!-- S3A Configuration for MinIO -->
  <property>
    <name>fs.s3a.endpoint</name>
    <value>${MINIO_SERVER_URL}</value>
    <description>MinIO endpoint</description>
  </property>

  <property>
    <name>fs.s3a.access.key</name>
    <value>${MINIO_ROOT_USER}</value>
    <description>MinIO access key</description>
  </property>

  <property>
    <name>fs.s3a.secret.key</name>
    <value>${MINIO_ROOT_PASSWORD}</value>
    <description>MinIO secret key</description>
  </property>

  <property>
    <name>fs.s3a.path.style.access</name>
    <value>true</value>
    <description>Enable path-style access for MinIO</description>
  </property>

  <property>
    <name>fs.s3a.connection.ssl.enabled</name>
    <value>false</value>
    <description>Disable SSL for local MinIO</description>
  </property>

  <property>
    <name>fs.s3a.impl</name>
    <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
  </property>

  <property>
    <name>fs.s3a.aws.credentials.provider</name>
    <value>org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider</value>
    <description>Use AWS SDK v1 credentials provider</description>
  </property>

  <!-- MinIO Compatibility -->
  <property>
    <name>fs.s3a.endpoint.region</name>
    <value>us-east-1</value>
    <description>AWS region for MinIO compatibility</description>
  </property>

  <property>
    <name>fs.s3a.change.detection.mode</name>
    <value>none</value>
    <description>Disable change detection for MinIO compatibility</description>
  </property>

  <!-- Performance Tuning -->
  <property>
    <name>fs.s3a.fast.upload</name>
    <value>true</value>
  </property>

  <property>
    <name>fs.s3a.fast.upload.buffer</name>
    <value>disk</value>
  </property>

  <property>
    <name>fs.s3a.block.size</name>
    <value>134217728</value>
  </property>

  <property>
    <name>fs.s3a.multipart.size</name>
    <value>134217728</value>
  </property>

  <property>
    <name>fs.s3a.multipart.purge.age</name>
    <value>86400</value>
    <description>Age in seconds for multipart upload cleanup</description>
  </property>

  <property>
    <name>fs.s3a.connection.maximum</name>
    <value>100</value>
  </property>

  <property>
    <name>fs.s3a.connection.timeout</name>
    <value>60000</value>
  </property>

  <property>
    <name>fs.s3a.connection.establish.timeout</name>
    <value>30000</value>
  </property>

  <property>
    <name>fs.s3a.threads.keepalivetime</name>
    <value>60</value>
    <description>Thread pool keepalive time in seconds</description>
  </property>
</configuration>
