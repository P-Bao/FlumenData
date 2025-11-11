# JupyterLab with PySpark 4.0.1 integration for FlumenData
# Build custom image to match FlumenData Spark cluster versions (Python 3.10 to match Spark workers)
FROM jupyter/scipy-notebook:python-3.10

# Build arguments for version consistency
ARG HADOOP_AWS_VERSION=3.3.6
ARG AWS_SDK_BUNDLE_VERSION=1.12.772
ARG POSTGRESQL_JDBC_VERSION=42.7.4
ARG DELTA_VERSION=4.0.0
ARG SCALA_BINARY_VERSION=2.13

USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    vim \
    postgresql-client \
    openjdk-17-jre-headless \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Spark 4.0.1
ENV SPARK_VERSION=4.0.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/usr/local/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.9-src.zip

RUN cd /tmp && \
    curl -O https://mirrors.sonic.net/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    chown -R ${NB_UID}:${NB_GID} ${SPARK_HOME}

USER ${NB_UID}

# Install Python libraries matching FlumenData versions
RUN pip install --no-cache-dir \
    # PySpark 4.0.1 (matches cluster)
    pyspark==4.0.1 \
    # Delta Lake 4.0.0 (matches cluster)
    delta-spark==4.0.0 \
    # AWS/S3/MinIO connectivity
    boto3==1.34.144 \
    s3fs==2024.6.1 \
    # Database connectors
    psycopg2-binary==2.9.9 \
    sqlalchemy==2.0.31 \
    # Data manipulation and analysis
    pandas==2.2.2 \
    pyarrow==16.1.0 \
    # Visualization
    matplotlib==3.9.0 \
    seaborn==0.13.2 \
    plotly==5.22.0 \
    # Jupyter extensions
    jupyterlab-git==0.50.1 \
    ipywidgets==8.1.3

# Download JARs matching FlumenData cluster versions
RUN mkdir -p /home/jovyan/.ivy2/jars && \
    cd /home/jovyan/.ivy2/jars && \
    curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar && \
    curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar && \
    curl -O https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRESQL_JDBC_VERSION}/postgresql-${POSTGRESQL_JDBC_VERSION}.jar && \
    curl -O https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_BINARY_VERSION}/${DELTA_VERSION}/delta-spark_${SCALA_BINARY_VERSION}-${DELTA_VERSION}.jar && \
    curl -O https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar

# Create directories for Spark and Jupyter configuration
RUN mkdir -p /home/jovyan/.sparkmagic && \
    mkdir -p /home/jovyan/.jupyter && \
    mkdir -p /usr/local/spark/conf

# Copy Jupyter configuration to disable token authentication
COPY --chown=${NB_UID}:${NB_GID} templates/jupyterlab/jupyter_server_config.py /home/jovyan/.jupyter/jupyter_server_config.py

# Copy Hadoop core-site.xml to fix S3A timeout issues
COPY --chown=${NB_UID}:${NB_GID} templates/jupyterlab/core-site.xml /usr/local/spark/conf/core-site.xml

# Copy log4j2 configuration to suppress warnings
COPY --chown=${NB_UID}:${NB_GID} templates/jupyterlab/log4j2.properties /usr/local/spark/conf/log4j2.properties

# Set work directory
WORKDIR /home/jovyan/work

# Default command
CMD ["start-notebook.sh"]
