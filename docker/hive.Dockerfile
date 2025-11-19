# Apache Hive Standalone Metastore with PostgreSQL JDBC driver and AWS S3A support
# Versions are passed from docker-compose build args (sourced from .env)
ARG HIVE_VERSION
ARG POSTGRESQL_JDBC_VERSION
ARG HADOOP_AWS_VERSION
ARG AWS_SDK_BUNDLE_VERSION

FROM apache/hive:standalone-metastore-${HIVE_VERSION}

# Re-declare ARGs after FROM to make them available in this stage
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
