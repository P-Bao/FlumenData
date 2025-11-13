# FlumenData

> A reproducible, Docker Compose-based open-source **Lakehouse** environment.
> Start everything with a single command: `make init`.

[Este README também está disponível em Português](./README_PT.md)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue.svg)](https://www.docker.com/)
[![Spark](https://img.shields.io/badge/Spark-4.0.1-E25A1C.svg)](https://spark.apache.org/)
[![Delta Lake](https://img.shields.io/badge/Delta%20Lake-4.0.0-00ADD8.svg)](https://delta.io/)

## 🎯 Overview

FlumenData is an **open-source lakehouse platform** that combines the best of data lakes and data warehouses. Built with Docker Compose, it provides a complete, reproducible environment for modern data engineering and analytics.

**Current Status:**
- ✅ **Tier 0 (Foundation)**: PostgreSQL, Valkey, MinIO - validated and stable
- ✅ **Tier 1 (Data Platform)**: Apache Spark 4.0.1, Hive Metastore 4.1.0, Delta Lake 4.0 - operational

## ✨ Key Features

- **ACID Transactions**: Delta Lake provides ACID guarantees on object storage
- **Time Travel**: Query historical versions of your data
- **Schema Evolution**: Adapt schemas without breaking existing pipelines
- **S3-Compatible Storage**: MinIO for scalable object storage
- **Hive Metastore**: Industry-standard catalog with 2-level namespace
- **Distributed Compute**: Apache Spark cluster (1 Master + 2 Workers)
- **One Command Setup**: `make init` starts the entire platform

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Tier 1 - Data Platform"
        SPARK[Apache Spark 4.0.1<br/>Master + 2 Workers]
        HIVE[Hive Metastore 4.1.0<br/>Catalog Service]
    end

    subgraph "Tier 0 - Foundation"
        POSTGRES[PostgreSQL 17.6<br/>Metadata Store]
        VALKEY[Valkey 9.0<br/>Cache Layer]
        MINIO[MinIO<br/>Object Storage]
    end

    subgraph "Data Layer"
        DELTA[Delta Lake 4.0<br/>ACID Tables]
    end

    SPARK --> HIVE
    SPARK --> DELTA
    DELTA --> MINIO
    HIVE --> POSTGRES
    HIVE --> MINIO
    SPARK --> VALKEY
    SPARK --> MINIO
```

### Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Storage** | MinIO | 2025-09-07 | S3-compatible object storage |
| **Storage** | Delta Lake | 4.0.0 | ACID table format with time travel |
| **Metadata** | Hive Metastore | 4.1.0 | Centralized catalog |
| **Metadata** | PostgreSQL | 17.6 | Metadata backend |
| **Compute** | Apache Spark | 4.0.1 | Distributed query engine |
| **Cache** | Valkey | 9.0.0 | In-memory cache |

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- GNU Make
- 8 GB RAM minimum (16 GB recommended)
- 20 GB free disk space

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/flumendata/flumendata.git
cd flumendata

# 2. Initialize the environment
make init

# 3. Verify all services are healthy
make health

# 4. View environment summary
make summary
```

### Your First Query

```bash
# Open Spark SQL shell
make shell-spark-sql

# Create a database
CREATE DATABASE quickstart
LOCATION 's3a://lakehouse/warehouse/quickstart.db';

# Create a Delta table
CREATE TABLE quickstart.customers (
  id BIGINT,
  name STRING,
  email STRING
) USING DELTA;

# Insert data
INSERT INTO quickstart.customers VALUES
  (1, 'Alice', 'alice@example.com'),
  (2, 'Bob', 'bob@example.com');

# Query data
SELECT * FROM quickstart.customers;
```

## 📊 Web Interfaces

After running `make init`, access:

- **Spark Master UI**: http://localhost:8080 - Cluster status and job monitoring
- **MinIO Console**: http://localhost:9001 - Object storage management
  - Username: `minioadmin`
  - Password: `minioadmin123`
- **JupyterLab**: http://localhost:8888 - Data exploration notebooks (`make token-jupyterlab` to fetch the access token)
- **MLflow Tracking UI**: http://localhost:${MLFLOW_PORT} - Experiment tracking dashboard
- **Superset**: http://localhost:${SUPERSET_PORT} - BI dashboards (login: `admin` / `admin123`)

## 📖 Documentation

Comprehensive documentation is available in both English and Portuguese:

- **English**: [docs/en/](docs/en/index.md)
- **Portuguese**: [docs/pt/](docs/pt/index.md)

Key documentation pages:
- [Installation Guide](docs/en/getting-started/installation.md)
- [Quick Start Tutorial](docs/en/getting-started/quickstart.md)
- [Architecture Deep Dive](docs/en/getting-started/architecture.md)
- [Hive Metastore](docs/en/services/hive.md)
- [Apache Spark](docs/en/services/spark.md)
- [Apache Superset](docs/en/services/superset.md)
- [Configuration](docs/en/configuration/environment.md)
- [Make Commands Reference](docs/en/configuration/commands.md)
- [Contributing Guide](docs/en/development/contributing.md)

## 🛠️ Common Commands

```bash
# Service Management
make init              # Complete initialization
make up                # Start all services
make up-tier2          # Start analytics & ML services
make up-tier3          # Start orchestration & BI services
make build-superset    # Build Superset image with drivers
make down              # Stop all services
make restart           # Restart all services

# Health Checks
make health            # Check all services
make health-tier0      # Check foundation services
make health-tier1      # Check data platform services
make health-tier2      # Check analytics & ML services
make health-tier3      # Check orchestration & BI services

# Testing
make test              # Run all tests
make test-tier0        # Test Tier 0 services
make test-tier1        # Test Tier 1 services
make test-tier2        # Test Tier 2 services
make test-tier3        # Test Tier 3 services

# Interactive Shells
make shell-spark       # Spark Scala shell
make shell-pyspark     # PySpark Python shell
make shell-spark-sql   # Spark SQL shell
make shell-postgres    # PostgreSQL shell
make sql-trino         # Trino CLI shell
make mc                # MinIO client

# Maintenance
make logs              # View all logs
make summary           # Environment overview
make reset             # Reset and reinitialize
make clean             # Remove everything (DESTRUCTIVE)
```

## 📁 Project Structure

```
FlumenData/
├── config/                     # Generated configuration (DO NOT EDIT)
├── docker/                     # Custom Dockerfiles
│   ├── hive.Dockerfile        # Hive Metastore + PostgreSQL JDBC
│   ├── spark.Dockerfile       # Spark with health checks
│   └── superset.Dockerfile    # Superset with psycopg2 + sqlalchemy-trino
├── docs/                       # MkDocs Material documentation
│   ├── en/                    # English documentation
│   └── pt/                    # Portuguese documentation
├── makefiles/                  # Service-specific Makefiles
│   ├── postgres.mk
│   ├── valkey.mk
│   ├── minio.mk
│   ├── hive.mk
│   ├── spark.mk
│   ├── jupyterlab.mk
│   ├── dbt.mk
│   ├── mlflow.mk
│   ├── trino.mk
│   └── superset.mk
├── templates/                  # Configuration templates
│   ├── hive/
│   ├── spark/
│   ├── minio/
│   ├── valkey/
│   ├── jupyterlab/
│   ├── dbt/
│   ├── mlflow/
│   ├── trino/
│   └── superset/
├── .env                        # Environment variables (not in git)
├── docker-compose.tier0.yml    # Foundation services
├── docker-compose.tier1.yml    # Data platform services
├── docker-compose.tier2.yml    # Analytics & development services
├── docker-compose.tier3.yml    # Orchestration & BI services
├── Makefile                    # Main orchestration
├── mkdocs.yml                 # Documentation configuration
└── README.md                   # This file
```

## 🎓 Use Cases

FlumenData is perfect for:

- **Learning**: Understand modern data lakehouse architecture hands-on
- **Development**: Build and test data pipelines locally
- **Prototyping**: Experiment with Delta Lake and Spark
- **Training**: Teach data engineering concepts
- **POCs**: Prove concepts before production deployment

## 🔄 Roadmap

- ✅ **Tier 0 – Foundation**: PostgreSQL, Valkey, MinIO
- ✅ **Tier 1 – Data Platform**: Spark, Hive Metastore, Delta Lake
- ✅ **Tier 2 – Development & ML**: JupyterLab, dbt, MLflow
- 🔄 **Tier 3 – Orchestration & BI**: Trino, Superset (Airflow coming next)
- 📋 **Tier 4 – Observability**: Prometheus, Grafana

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/en/development/contributing.md) for details.

Key guidelines:
- All code and comments in English
- Update both EN and PT documentation
- Run `make test` before submitting
- Follow existing code structure

## 📝 Conventions

- **Configuration Management**: Always edit templates in `templates/`, never edit generated files in `config/`
- **Service Requirements**: Every service must have healthcheck, named volumes, and static config
- **Documentation**: Maintained in both English and Portuguese
- **Commits**: Use conventional commits format (e.g., `feat(spark): add Delta Lake 4.0 support`)

## 🐛 Troubleshooting

### Services not starting

```bash
# Check Docker resources
docker stats

# View logs
make logs

# Verify health
make health
```

### Configuration issues

```bash
# Regenerate all configs
make config

# Restart services
make restart
```

### Data issues

```bash
# Complete reset (keeps data)
make reset

# Nuclear option (deletes everything)
make clean
```

For more troubleshooting tips, see the [documentation](docs/en/getting-started/installation.md#troubleshooting-installation).

## 📄 License

FlumenData is licensed under the [Apache License 2.0](LICENSE).

## 🙏 Acknowledgments

FlumenData builds on amazing open-source projects:
- [Apache Spark](https://spark.apache.org/)
- [Delta Lake](https://delta.io/)
- [Apache Hive](https://hive.apache.org/)
- [MinIO](https://min.io/)
- [PostgreSQL](https://www.postgresql.org/)
- [Valkey](https://valkey.io/)

## 📧 Contact

- **Issues**: https://github.com/flumendata/flumendata/issues
- **Discussions**: https://github.com/flumendata/flumendata/discussions

---

**FlumenData** - Open, reproducible, and modern Lakehouse for everyone 🚀
