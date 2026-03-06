"""
Docker Compose operations for FlumenData
"""

import os
import subprocess
from .utils import Colors, docker_compose, get_compose_files, load_env_file


def create_network():
    """Create FlumenData Docker network if it doesn't exist"""
    network_name = "flumendata_default"

    # Check if network exists
    result = subprocess.run(
        ["docker", "network", "ls", "--filter", f"name={network_name}", "--format", "{{.Name}}"],
        capture_output=True,
        text=True,
        check=False
    )

    if network_name in result.stdout:
        print(f"{Colors.GREEN}✓ Network '{network_name}' already exists{Colors.RESET}")
    else:
        # Create network
        subprocess.run(
            ["docker", "network", "create", network_name],
            check=True
        )
        print(f"{Colors.GREEN}✓ Created network '{network_name}'{Colors.RESET}")


def up_services(tier: int = None, services: list = None, build: bool = False):
    """
    Start services for specified tier and all tiers below it

    Args:
        tier: Tier number (0-3) or None for all tiers
        services: Optional list of specific services to start
        build: Force build images before starting
    """
    load_env_file()

    if tier is not None:
        # Start all tiers from 0 to specified tier (cascading)
        tier_name = f"tiers 0-{tier}"
        print(f"{Colors.BLUE}[{tier_name}] Starting services (cascading)...{Colors.RESET}")

        # Get compose files for all tiers 0 to tier
        compose_files = []
        for t in range(tier + 1):
            compose_files.append(f"docker-compose.tier{t}.yml")
    else:
        # Start all tiers (0-3)
        tier_name = "all tiers (0-3)"
        print(f"{Colors.BLUE}[{tier_name}] Starting services...{Colors.RESET}")
        compose_files = get_compose_files(None)

    if not build:
        # Check if containers exist
        check_cmd = ["ps", "-q"]
        if services:
            check_cmd.extend(services)
        
        result = docker_compose(*check_cmd, compose_files=compose_files, capture_output=True, check=False)
        if result.returncode == 0 and result.stdout.strip():
            print(f"{Colors.YELLOW}[{tier_name}] Containers already exist. Starting existing containers...{Colors.RESET}")
            start_cmd = ["start"]
            if services:
                start_cmd.extend(services)
            docker_compose(*start_cmd, compose_files=compose_files)
            print(f"{Colors.GREEN}✓ {tier_name.capitalize()} services started{Colors.RESET}")
            return

    cmd = ["up", "-d"]

    if build:
        cmd.append("--build")

    if services:
        cmd.extend(services)

    docker_compose(*cmd, compose_files=compose_files)

    print(f"{Colors.GREEN}✓ {tier_name.capitalize()} services started{Colors.RESET}")


def down_services():
    """Stop all services"""
    print(f"{Colors.YELLOW}Stopping all services...{Colors.RESET}")

    # Stop in reverse order (tier 3 -> tier 0)
    for tier in range(3, -1, -1):
        docker_compose("down", compose_files=[f"docker-compose.tier{tier}.yml"], check=False)

    print(f"{Colors.GREEN}✓ All services stopped{Colors.RESET}")


def restart_services():
    """Restart all services"""
    print(f"{Colors.YELLOW}Restarting all services...{Colors.RESET}")
    compose_files = get_compose_files(None)
    docker_compose("restart", compose_files=compose_files)
    print(f"{Colors.GREEN}✓ All services restarted{Colors.RESET}")


def show_logs(tier: int = None, service: str = None, follow: bool = True):
    """
    Show service logs

    Args:
        tier: Tier number (0-3) or None for all
        service: Specific service name or None for all
        follow: Follow log output
    """
    compose_files = get_compose_files(tier)
    cmd = ["logs"]

    if follow:
        cmd.append("-f")

    if service:
        cmd.append(service)

    docker_compose(*cmd, compose_files=compose_files)


def show_status():
    """Show status of all containers"""
    compose_files = get_compose_files(None)
    docker_compose("ps", compose_files=compose_files)


def show_summary():
    """Show environment summary"""
    load_env_file()

    minio_bucket = os.getenv("MINIO_BUCKET", "lakehouse")
    minio_storage_bucket = os.getenv("MINIO_STORAGE_BUCKET", "storage")
    trino_port = os.getenv("TRINO_PORT", "8085")
    superset_port = os.getenv("SUPERSET_PORT", "8088")

    print()
    print(f"{Colors.BLUE}╔══════════════════════════════════════════════════════════════╗{Colors.RESET}")
    print(f"{Colors.BLUE}║              FlumenData Environment Summary                  ║{Colors.RESET}")
    print(f"{Colors.BLUE}╚══════════════════════════════════════════════════════════════╝{Colors.RESET}")
    print()
    print(f"{Colors.YELLOW}Tier 0 - Foundation Services:{Colors.RESET}")
    print("  • PostgreSQL    → http://localhost:5432")
    print("  • MinIO API     → http://localhost:9000")
    print("  • MinIO Console → http://localhost:9001")
    print()
    print(f"{Colors.YELLOW}Tier 1 - Data Platform:{Colors.RESET}")
    print("  • Spark Master    → http://localhost:8080")
    print("  • Hive Metastore  → thrift://localhost:9083")
    print()
    print(f"{Colors.YELLOW}Tier 2 - Analytics & Development:{Colors.RESET}")
    print("  • JupyterLab      → http://localhost:8888")
    print()
    print(f"{Colors.YELLOW}Tier 3 - SQL & BI:{Colors.RESET}")
    print(f"  • Trino           → http://localhost:{trino_port}")
    print(f"  • Superset        → http://localhost:{superset_port}")
    print()
    print(f"{Colors.YELLOW}Lakehouse Architecture:{Colors.RESET}")
    print("  • Catalog       : Hive Metastore (2-level: database.table)")
    print("  • Table Format  : Delta Lake 4.0 (with time travel)")
    print("  • Compute       : Apache Spark 4.0.1 (1 Master + 2 Workers)")
    print("  • Metadata DB   : PostgreSQL")
    print(f"  • Storage       : s3a://{minio_bucket}/warehouse (Delta tables)")
    print(f"  • Files         : s3a://{minio_storage_bucket} (ingest-ready assets)")
    print()
    print(f"{Colors.GREEN}Quick Commands:{Colors.RESET}")
    print("  python3 flumen logs          - View all logs")
    print("  python3 flumen health        - Check all health")
    print("  python3 flumen ps            - Show container status")
    print()
    print(f"{Colors.RED}⚠️  FIRST-TIME USERS - IMPORTANT:{Colors.RESET}")
    print(f"{Colors.YELLOW}When you run the quickstart notebook for the FIRST time,{Colors.RESET}")
    print(f"{Colors.YELLOW}Spark will download Hive dependencies (~267 JARs, ~300MB).{Colors.RESET}")
    print(f"{Colors.YELLOW}This takes 3-5 minutes but only happens ONCE.{Colors.RESET}")
    print()
    print(f"{Colors.GREEN}📓 Try it now: http://localhost:8888 → _examples/01_quickstart.ipynb{Colors.RESET}")
    print()
