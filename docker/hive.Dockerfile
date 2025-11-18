# Apache Hive Standalone Metastore 4.1.0 with PostgreSQL JDBC driver and AWS S3A support
ARG POSTGRESQL_JDBC_VERSION=42.7.4
ARG HADOOP_AWS_VERSION=3.3.6
ARG AWS_SDK_BUNDLE_VERSION=1.12.772
FROM apache/hive:standalone-metastore-4.1.0
ARG POSTGRESQL_JDBC_VERSION
ARG HADOOP_AWS_VERSION
ARG AWS_SDK_BUNDLE_VERSION

USER root

# Download required JARs using curl-minimal (already installed)
RUN curl -fsSL https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar \
    -o /opt/hive/lib/postgresql-jdbc.jar && \
    curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar \
    -o /opt/hive/lib/hadoop-aws.jar && \
    curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar \
    -o /opt/hive/lib/aws-java-sdk-bundle.jar

USER hive

WORKDIR /opt/hive
