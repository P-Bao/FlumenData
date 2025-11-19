# syntax=docker/dockerfile:1.6
# Version is passed from docker-compose build args (sourced from .env)
ARG SUPERSET_VERSION

FROM apache/superset:${SUPERSET_VERSION}

USER root

RUN pip install --no-cache-dir \
        --target /app/.venv/lib/python3.10/site-packages \
        psycopg2-binary \
        sqlalchemy-trino \
        gevent>=24.2.1

USER superset
