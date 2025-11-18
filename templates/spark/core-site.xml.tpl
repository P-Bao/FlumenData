<?xml version="1.0"?>
<!-- Rendered to config/spark/core-site.xml -->
<!-- Hadoop core configuration for Spark with S3A settings -->
<configuration>
  <!-- S3A Connection Timeouts (in milliseconds) -->
  <property>
    <name>fs.s3a.connection.timeout</name>
    <value>60000</value>
    <description>Socket connection timeout in milliseconds</description>
  </property>

  <property>
    <name>fs.s3a.connection.establish.timeout</name>
    <value>30000</value>
    <description>Connection establishment timeout in milliseconds</description>
  </property>

  <property>
    <name>fs.s3a.threads.keepalivetime</name>
    <value>60</value>
    <description>Thread pool keepalive time in seconds (not milliseconds!)</description>
  </property>

  <!-- S3A Performance Settings -->
  <property>
    <name>fs.s3a.attempts.maximum</name>
    <value>10</value>
    <description>Maximum number of retry attempts</description>
  </property>

  <property>
    <name>fs.s3a.retry.limit</name>
    <value>7</value>
    <description>Number of times to retry any operation</description>
  </property>
</configuration>
