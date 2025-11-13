# syntax=docker/dockerfile:1.6
ARG SUPERSET_VERSION=5.0.0
FROM apache/superset:${SUPERSET_VERSION}

USER root

RUN pip install --no-cache-dir \
        --target /app/.venv/lib/python3.10/site-packages \
        psycopg2-binary \
        sqlalchemy-trino \
        gevent>=24.2.1

USER superset
