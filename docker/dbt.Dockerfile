FROM python:3.11-slim AS base

ARG DBT_CORE_VERSION=1.7.14
ARG DBT_ADAPTERS="dbt-postgres==1.7.14"

ENV PIP_NO_CACHE_DIR=1 \
    DBT_PROFILES_DIR=/root/.dbt

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        libpq-dev \
        unixodbc-dev && \
    pip install --upgrade pip && \
    pip install "dbt-core==${DBT_CORE_VERSION}" ${DBT_ADAPTERS} && \
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

CMD ["tail", "-f", "/dev/null"]
