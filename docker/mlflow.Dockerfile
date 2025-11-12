FROM python:3.11-slim

ARG MLFLOW_VERSION=2.14.1

ENV PIP_NO_CACHE_DIR=1 \
    MLFLOW_HOME=/opt/mlflow \
    MLFLOW_S3_UPLOAD_EXTRA_ARGS='{"ACL": "bucket-owner-full-control"}'

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl && \
    pip install "mlflow==${MLFLOW_VERSION}" psycopg2-binary boto3 && \
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${MLFLOW_HOME}

EXPOSE 5000

CMD ["mlflow", "server"]
