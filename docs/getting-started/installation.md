# Installation

This guide will help you install and set up FlumenData on your system.

## Prerequisites

### Required Software

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Make**: GNU Make (usually pre-installed on Linux/macOS)
- **Git**: For cloning the repository

### Hardware Requirements

**Minimum:**
- 4 CPU cores
- 16 GB RAM
- 20 GB free disk space

**Recommended:**
- 8+ CPU cores
- 32 GB RAM
- 50 GB free disk space (for data storage)

### Operating System

FlumenData has been tested on:
- Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+)
- macOS (11.0+)
- Windows (via WSL2)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/lucianomauda/FlumenData.git
cd FlumenData
```

### 2. Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker is running
docker ps
```

### 3. Configure Environment Variables

FlumenData uses a `.env` file for configuration. Create it from the template:

```bash
# If .env.example exists
cp .env.example .env

# Edit with your preferred editor
nano .env
```

If no `.env.example` exists, the Makefile will generate default values. Common variables:

```bash
# PostgreSQL
POSTGRES_USER=flumen
POSTGRES_PASSWORD=flumen123
POSTGRES_DB=flumendata
POSTGRES_PORT=5432

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_BUCKET=lakehouse

# Hive Metastore
HIVE_METASTORE_URI=thrift://hive-metastore:9083

# Spark
SPARK_MASTER_HOST=spark-master
SPARK_MASTER_PORT=7077

# Delta Lake
DELTA_VERSION=4.0.0
SCALA_BINARY_VERSION=2.13
```

### 4. Initialize the Environment

Run the complete initialization process:

```bash
make init
```

This command will:
1. Generate all configuration files
2. Build custom Docker images (Hive, Spark)
3. Start Tier 0 services (PostgreSQL, MinIO)
4. Initialize MinIO buckets
5. Start Tier 1 services (Hive Metastore, Spark cluster)
6. Run health checks
7. Display environment summary

**Expected Output:**
```
[config] Generating all configuration files...
[tier0] Starting foundation services...
[tier0] All services healthy
[minio] Creating lakehouse bucket...
[tier1] Starting data platform services...
[tier1] All services healthy
[summary] Environment is ready!
```

### 5. Verify Installation

Check that all services are running:

```bash
# View all containers
make ps

# Check health status
make health

# Display environment summary
make summary
```

### 6. Access Web Interfaces

Open your browser and visit:

- **Spark Master UI**: http://localhost:8080
- **MinIO Console**: http://localhost:9001
  - Username: `minioadmin`
  - Password: `minioadmin123`

## Post-Installation

### Test the Installation

Run integration tests to verify everything works:

```bash
# Test all services
make test

# Test specific tier
make test-tier0    # PostgreSQL, MinIO
make test-tier1    # Hive Metastore, Spark
```

### Create Your First Database

```bash
# Open Spark SQL shell
make shell-spark-sql

# Create a database
CREATE DATABASE my_database
LOCATION 's3a://lakehouse/warehouse/my_database.db';

# Verify it was created
SHOW DATABASES;
```

## Troubleshooting Installation

### Docker permission denied

If you get permission errors:

```bash
# Add your user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker ps
```

### Port already in use

If ports are already in use, update the `.env` file:

```bash
# Example: Change PostgreSQL port
POSTGRES_PORT=5433

# Regenerate configuration
make config

# Restart services
make restart
```

### Services not starting

Check Docker resources:

```bash
# View Docker resource usage
docker stats

# View Docker system info
docker system info | grep -i "memory\|cpus"
```

Increase Docker Desktop resources if needed:
- Settings → Resources → Memory: 16 GB minimum
- Settings → Resources → CPUs: 4 cores minimum

### Slow initialization

First-time startup downloads Docker images and JAR dependencies:

- **Docker images**: ~2 GB (Spark, Hive, PostgreSQL, MinIO)
- **JAR dependencies**: ~500 MB (Delta Lake, Hadoop AWS, etc.)

Subsequent starts are much faster as everything is cached.

## Next Steps

- [Quick Start Guide](quickstart.md) - Create your first Delta table
- [Architecture Overview](architecture.md) - Understand FlumenData components
- [Configuration Guide](../configuration/environment.md) - Customize your setup

## Uninstallation

To completely remove FlumenData:

```bash
# Stop and remove all containers and volumes
make clean

# Remove Docker images
docker rmi flumendata/hive:standalone-metastore-4.1.0
docker rmi flumendata/spark:4.0.1-health

# Remove cloned directory
cd ..
rm -rf flumendata
```

!!! warning "Data Loss"
    The `make clean` command permanently deletes all data stored in Docker volumes. Export any important data before running this command.
