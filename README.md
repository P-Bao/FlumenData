# FlumenData

Esse [README](./README_PT.md) também está disponível em portugues.

FlumenData is an open-source **Lakehouse environment** designed to replicate a complete modern data platform using only open-source technologies.  
It provides a **modular, fully containerized, and reproducible** stack — from storage and governance to orchestration and observability — that can be started with a single command.

## 🚀 Goal

To offer a production-grade, reproducible environment for data engineering and analytics teams to experiment, test, and learn modern data platform concepts.

## 🧩 Architecture Overview

FlumenData is structured into independent service tiers:
- **Tier 0 – Foundation:** PostgreSQL, Valkey, MinIO  
- **Tier 1 – Data & Governance:** Spark, Unity Catalog  
- **Tier 2 – Development & ML:** JupyterLab, dbt, MLflow  
- **Tier 3 – Orchestration & BI:** Airflow, Trino, Superset  
- **Tier 4 – Observability & Access:** Prometheus, Grafana, NGINX

Each service includes healthchecks, persistent volumes, and static configurations in `/config/`.

## ⚙️ Getting Started

```bash
# Initialize environment
make init
```

This command will automatically:
- Create required folders and volumes.
- Generate all configuration files in /config/.
- Start the full stack using Docker Compose.

## 📁 Project Structure
```bash
FlumenData/
├── config/         # Static configuration files
├── docker/         # Dockerfiles and entrypoints
├── docs/           # MkDocs documentation (EN + PT)
├── storage/        # Persistent storage
├── workspace/      # Notebooks, ETL/ELT jobs
└── docker-compose.yml
```

## 📖 Documentation
All documentation is maintained in both English and Portuguese under /docs/.

🧠 FlumenData — Open, reproducible, and modern Lakehouse for everyone.

---

## ✅ Tier 0 Validation (PostgreSQL, Valkey, MinIO)

After `make init`, you can validate each service with:

```bash
# PostgreSQL
make health-postgres && make test-postgres && make persist-postgres

# Valkey
make config-valkey && make health-valkey && make test-valkey && make persist-valkey

# MinIO
make config-minio && make health-minio && make test-minio && make persist-minio
```
