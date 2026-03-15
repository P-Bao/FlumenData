"""
Health check commands for FlumenData services
"""

from .utils import Colors, wait_for_healthy, run_command, load_env_file


def check_postgres_health():
    """Check PostgreSQL health"""
    wait_for_healthy("flumen_postgres", timeout=180)


def check_minio_health():
    """Check MinIO health"""
    wait_for_healthy("flumen_minio", timeout=180)


def check_hive_health():
    """Check Hive Metastore health"""
    wait_for_healthy("flumen_hive_metastore", timeout=180)


def check_spark_master_health():
    """Check Spark Master health"""
    wait_for_healthy("flumen_spark_master", timeout=180)


def check_spark_workers_health():
    """Check Spark Workers health"""
    wait_for_healthy("flumen_spark_worker1", timeout=180)
    wait_for_healthy("flumen_spark_worker2", timeout=180)


def check_jupyterlab_health():
    """Check JupyterLab health"""
    wait_for_healthy("flumen_jupyterlab", timeout=180)


def check_trino_health():
    """Check Trino health"""
    wait_for_healthy("flumen_trino", timeout=180)


def check_superset_health():
    """Check Superset health"""
    wait_for_healthy("flumen_superset", timeout=180)


def check_api_health():
    """Check API health"""
    # Specifically wait for flumen_upload_api
    wait_for_healthy("flumen_upload_api", timeout=120)


def check_tier_health(tier: int):
    """
    Check health of all services in a tier

    Args:
        tier: Tier number (0-3)
    """
    load_env_file()

    if tier == 0:
        print(f"{Colors.BLUE}Checking Tier 0 health...{Colors.RESET}")
        check_postgres_health()
        check_minio_health()
        print(f"{Colors.GREEN}✓ Tier 0 healthy{Colors.RESET}")

    elif tier == 1:
        print(f"{Colors.BLUE}Checking Tier 1 health...{Colors.RESET}")
        check_hive_health()
        check_spark_master_health()
        check_spark_workers_health()
        print(f"{Colors.GREEN}✓ Tier 1 healthy{Colors.RESET}")

    elif tier == 2:
        print(f"{Colors.BLUE}Checking Tier 2 health...{Colors.RESET}")
        check_jupyterlab_health()
        print(f"{Colors.GREEN}✓ Tier 2 healthy{Colors.RESET}")

    elif tier == 3:
        print(f"{Colors.BLUE}Checking Tier 3 health...{Colors.RESET}")
        check_trino_health()
        check_superset_health()
        print(f"{Colors.GREEN}✓ Tier 3 healthy{Colors.RESET}")

    elif tier == "api":
        print(f"{Colors.BLUE}Checking API Tier health...{Colors.RESET}")
        check_api_health()
        print(f"{Colors.GREEN}✓ API Tier healthy{Colors.RESET}")


def check_all_health():
    """Check health of all services"""
    print(f"{Colors.BLUE}Checking all services health...{Colors.RESET}\n")

    for tier in range(4):
        check_tier_health(tier)
        print()
    
    check_tier_health("api")
    print()

    print(f"{Colors.GREEN}✓ All services healthy{Colors.RESET}")
