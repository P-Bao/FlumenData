"""
Cleanup and maintenance commands for FlumenData
"""

import os
from pathlib import Path
from .utils import Colors, run_command, docker_compose, load_env_file


def cleanup_postgres():
    """Cleanup PostgreSQL test data"""
    print("[postgres:cleanup] Cleaning up test data...")
    # Implement if you have specific test tables to clean
    print(f"{Colors.GREEN}[postgres:cleanup] ✓ Complete{Colors.RESET}")


def cleanup_minio():
    """Cleanup MinIO test bucket"""
    load_env_file()

    print("[minio:cleanup] Removing test bucket...")

    minio_user = os.getenv("MINIO_ROOT_USER", "admin")
    minio_password = os.getenv("MINIO_ROOT_PASSWORD", "password")
    project_name = os.getenv("COMPOSE_PROJECT_NAME", "flumen")

    mc_cmd = [
        "docker", "run", "--rm", "--network", f"{project_name}_default",
        "-e", f"MC_HOST_flumen=http://{minio_user}:{minio_password}@minio:9000",
        "minio/mc:RELEASE.2025-08-13T08-35-41Z",
        "rb", "flumen/selftest", "--force"
    ]

    run_command(mc_cmd, check=False, capture_output=True)
    print(f"{Colors.GREEN}[minio:cleanup] ✓ Test bucket removed{Colors.RESET}")


def cleanup_spark():
    """Cleanup Spark test data"""
    print("[spark:cleanup] Cleaning up test data...")
    # Implement if you have specific test data to clean
    print(f"{Colors.GREEN}[spark:cleanup] ✓ Complete{Colors.RESET}")


def cleanup_jupyterlab():
    """Cleanup JupyterLab test data"""
    print("[jupyterlab:cleanup] Cleaning up test data...")
    # Implement if needed
    print(f"{Colors.GREEN}[jupyterlab:cleanup] ✓ Complete{Colors.RESET}")


def cleanup_tier(tier: int):
    """Cleanup test data for a tier"""
    if tier == 0:
        print(f"{Colors.BLUE}Cleaning up Tier 0...{Colors.RESET}")
        cleanup_postgres()
        cleanup_minio()
        print(f"{Colors.GREEN}✓ Tier 0 cleanup complete{Colors.RESET}")

    elif tier == 1:
        print(f"{Colors.BLUE}Cleaning up Tier 1...{Colors.RESET}")
        cleanup_spark()
        print(f"{Colors.GREEN}✓ Tier 1 cleanup complete{Colors.RESET}")

    elif tier == 2:
        print(f"{Colors.BLUE}Cleaning up Tier 2...{Colors.RESET}")
        cleanup_jupyterlab()
        print(f"{Colors.GREEN}✓ Tier 2 cleanup complete{Colors.RESET}")


def cleanup_all():
    """Cleanup all test data"""
    print(f"{Colors.BLUE}Cleaning up all test data...{Colors.RESET}\n")

    for tier in range(3):
        cleanup_tier(tier)
        print()

    print(f"{Colors.GREEN}✓ All test data cleaned{Colors.RESET}")


def clean_environment(force: bool = False):
    """
    Stop services and remove volumes (WARNING: deletes all data)

    Args:
        force: Skip confirmation prompt
    """
    if not force:
        print(f"{Colors.RED}WARNING: This will delete all data!{Colors.RESET}")
        response = input("Are you sure? [y/N] ")

        if response.lower() not in ['y', 'yes']:
            print(f"{Colors.YELLOW}Cancelled{Colors.RESET}")
            return

    print(f"{Colors.YELLOW}Stopping services and removing volumes...{Colors.RESET}")

    # Stop and remove volumes in reverse order
    for tier in range(3, -1, -1):
        docker_compose(
            "down", "-v",
            compose_files=[f"docker-compose.tier{tier}.yml"],
            check=False
        )

    # Remove config files
    config_dir = Path("config")
    if config_dir.exists():
        import shutil
        shutil.rmtree(config_dir)
        print("[clean] Removed config directory")

    print(f"{Colors.GREEN}✓ Environment cleaned{Colors.RESET}")


def rebuild_images():
    """Rebuild all custom Docker images"""
    print(f"{Colors.BLUE}Rebuilding custom Docker images...{Colors.RESET}\n")

    images = [
        ("phbao/hive:standalone-metastore-4.1.0", "docker/hive.Dockerfile"),
        ("phbao/spark:4.0.1-health", "docker/spark.Dockerfile"),
        ("phbao/jupyterlab:spark-4.0.1", "docker/jupyterlab.Dockerfile"),
        ("phbao/superset:5.0.0", "docker/superset.Dockerfile"),
    ]

    for image_name, dockerfile in images:
        print(f"[rebuild] Building {image_name}...")
        run_command(
            ["docker", "build", "-t", image_name, "-f", dockerfile, "."],
            check=True
        )

    print(f"\n{Colors.GREEN}✓ All custom images rebuilt{Colors.RESET}")


def prune_docker():
    """Prune unused Docker resources"""
    print(f"{Colors.YELLOW}Pruning unused Docker resources...{Colors.RESET}\n")

    print("[prune] Removing unused containers...")
    run_command(["docker", "container", "prune", "-f"], check=True)

    print("[prune] Removing unused volumes...")
    run_command(["docker", "volume", "prune", "-f"], check=True)

    print("[prune] Removing unused images...")
    run_command(["docker", "image", "prune", "-f"], check=True)

    print(f"\n{Colors.GREEN}✓ Docker cleanup complete{Colors.RESET}")
