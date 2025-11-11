# Apache Hive Standalone Metastore 4.1.0 with PostgreSQL JDBC driver and AWS S3A support
FROM apache/hive:standalone-metastore-4.1.0

USER root

# Download required JARs using curl-minimal (already installed)
RUN curl -fsSL https://jdbc.postgresql.org/download/postgresql-42.7.1.jar \
    -o /opt/hive/lib/postgresql-jdbc.jar && \
    curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar \
    -o /opt/hive/lib/hadoop-aws.jar && \
    curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.367/aws-java-sdk-bundle-1.12.367.jar \
    -o /opt/hive/lib/aws-java-sdk-bundle.jar

USER hive

WORKDIR /opt/hive
