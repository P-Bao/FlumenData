"""
Service-specific helper commands
"""

import os
from .utils import Colors, run_command, docker_compose, load_env_file


def get_jupyterlab_token():
    """Get JupyterLab access token"""
    print(f"{Colors.BLUE}Fetching JupyterLab token...{Colors.RESET}\n")

    result = run_command(
        ["docker", "exec", "flumen_jupyterlab",
         "jupyter", "server", "list"],
        capture_output=True,
        check=False
    )

    if result.returncode == 0:
        output = result.stdout
        print(output)

        # Try to extract token from output
        if "token=" in output:
            for line in output.split('\n'):
                if "token=" in line:
                    token_part = line.split("token=")[1].split()[0]
                    print(f"\n{Colors.GREEN}JupyterLab URL:{Colors.RESET}")
                    print(f"  http://localhost:8888/?token={token_part}")
                    print()
                    break
    else:
        print(f"{Colors.YELLOW}Could not fetch token. Make sure JupyterLab is running.{Colors.RESET}")
        print(f"Run: python3 scripts/flumen up --tier 2")


def init_superset_db():
    """Initialize Superset database"""
    load_env_file()

    print(f"{Colors.BLUE}Initializing Superset database...{Colors.RESET}")

    # Run superset db upgrade
    print("[superset] Running database migrations...")
    docker_compose(
        "exec", "-T", "superset",
        "superset", "db", "upgrade",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml",
                      "docker-compose.tier2.yml", "docker-compose.tier3.yml"],
        check=True
    )

    # Create admin user
    print("[superset] Creating admin user...")
    admin_user = os.getenv("SUPERSET_ADMIN_USER", "admin")
    admin_password = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")
    admin_email = os.getenv("SUPERSET_ADMIN_EMAIL", "admin@flumendata.local")

    docker_compose(
        "exec", "-T", "superset",
        "superset", "fab", "create-admin",
        "--username", admin_user,
        "--firstname", "Admin",
        "--lastname", "User",
        "--email", admin_email,
        "--password", admin_password,
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml",
                      "docker-compose.tier2.yml", "docker-compose.tier3.yml"],
        check=False  # May already exist
    )

    # Initialize Superset
    print("[superset] Initializing Superset...")
    docker_compose(
        "exec", "-T", "superset",
        "superset", "init",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml",
                      "docker-compose.tier2.yml", "docker-compose.tier3.yml"],
        check=True
    )

    print(f"{Colors.GREEN}✓ Superset initialized{Colors.RESET}")
    print(f"\nSuperset URL: http://localhost:8088")
    print(f"Username: {admin_user}")
    print(f"Password: {admin_password}")
