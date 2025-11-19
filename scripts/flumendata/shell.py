"""
Shell access commands for FlumenData services
"""

import os
from .utils import Colors, run_command, docker_compose, load_env_file


def shell_postgres():
    """Open PostgreSQL shell"""
    load_env_file()

    postgres_user = os.getenv("POSTGRES_USER", "flumendata")
    postgres_db = os.getenv("POSTGRES_DB", "flumendata")

    print(f"{Colors.BLUE}Opening PostgreSQL shell...{Colors.RESET}")
    print(f"Database: {postgres_db}, User: {postgres_user}\n")

    docker_compose(
        "exec", "postgres",
        "psql", "-U", postgres_user, "-d", postgres_db,
        compose_files=["docker-compose.tier0.yml"],
        check=True
    )


def shell_spark():
    """Open Spark shell"""
    print(f"{Colors.BLUE}Opening Spark shell...{Colors.RESET}")
    print("This may take a moment to start...\n")

    docker_compose(
        "exec", "spark-master",
        "/opt/spark/bin/spark-shell",
        "--master", "spark://spark-master:7077",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        check=True
    )


def shell_pyspark():
    """Open PySpark shell"""
    print(f"{Colors.BLUE}Opening PySpark shell...{Colors.RESET}")
    print("This may take a moment to start...\n")

    docker_compose(
        "exec", "spark-master",
        "/opt/spark/bin/pyspark",
        "--master", "spark://spark-master:7077",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        check=True
    )


def shell_spark_sql():
    """Open Spark SQL shell"""
    print(f"{Colors.BLUE}Opening Spark SQL shell...{Colors.RESET}")
    print("This may take a moment to start...\n")

    docker_compose(
        "exec", "spark-master",
        "/opt/spark/bin/spark-sql",
        "--master", "spark://spark-master:7077",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        check=True
    )


def shell_minio_client():
    """Open MinIO client (mc) shell"""
    load_env_file()

    minio_user = os.getenv("MINIO_ROOT_USER", "admin")
    minio_password = os.getenv("MINIO_ROOT_PASSWORD", "password")
    project_name = os.getenv("COMPOSE_PROJECT_NAME", "flumen")

    print(f"{Colors.BLUE}Opening MinIO Client (mc) shell...{Colors.RESET}")
    print(f"Alias 'flumen' configured for MinIO server\n")
    print(f"{Colors.YELLOW}Example commands:{Colors.RESET}")
    print("  mc ls flumen/              # List buckets")
    print("  mc ls flumen/lakehouse/    # List lakehouse bucket")
    print("  mc mb flumen/mybucket      # Create bucket")
    print("  mc cp file.txt flumen/lakehouse/")
    print()

    run_command([
        "docker", "run", "--rm", "-it",
        "--network", f"{project_name}_default",
        "-e", f"MC_HOST_flumen=http://{minio_user}:{minio_password}@minio:9000",
        "minio/mc:RELEASE.2025-08-13T08-35-41Z"
    ])
