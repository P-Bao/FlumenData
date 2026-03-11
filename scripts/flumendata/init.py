"""
Initialization commands for FlumenData.
"""

import os
from pathlib import Path
from .utils import Colors, load_env_file, ensure_dir



def set_permissions(root: Path):
    """
    Best-effort permission relax for container writes.
    - Windows: icacls grant current user Full control recursively.
    - POSIX/WSL: call fix_permissions.sh script for docker-based ownership fix.
    """
    try:
        if os.name == "nt":
            user = os.getlogin() if hasattr(os, "getlogin") else os.environ.get("USERNAME")
            if user:
                os.system(f'icacls "{root}" /grant "{user}":(OI)(CI)F /T /C >NUL')
        
        # Check for our helper script to fix Linux-style permissions (useful for WSL/Linux)
        script_path = Path(__file__).parent.parent / "fix_permissions.sh"
        if script_path.exists():
            os.system(f'bash "{script_path}" "{root}"')
    except Exception:
        pass


def init_data_dirs():
    """Initialize all data directories for FlumenData."""
    print(f"{Colors.BLUE}[init] Initializing data directories{Colors.RESET}")

    env_vars = load_env_file()
    data_dir_str = env_vars.get("DATA_DIR") or os.getenv("DATA_DIR", "../flumendata-data")
    data_dir = Path(data_dir_str).resolve()

    if data_dir.exists() and data_dir.is_file():
        print(f"{Colors.RED}[init] ERROR: {data_dir} exists as a file, not a directory!{Colors.RESET}")
        return 1

    print(f"[init] Platform: {os.name}")
    print(f"[init] Data directory: {data_dir_str} -> {data_dir}")
    print()

    ensure_dir(data_dir, "Base directory")

    print("[init] Creating subdirectories...")
    ensure_dir(data_dir / "minio" / "lakehouse", "minio/lakehouse")
    ensure_dir(data_dir / "minio" / "storage", "minio/storage")
    ensure_dir(data_dir / "notebooks" / "_examples", "notebooks")

    set_permissions(data_dir)

    print()
    print(f"{Colors.GREEN}[init] Data directories initialized{Colors.RESET}")
    print()
    print("[init] Data location:")
    print(f"[init]   Configured: {data_dir_str}")
    print(f"[init]   Resolved:   {data_dir}")
    print()
    print("[init] Structure:")
    print("[init]   |- minio/lakehouse     (Delta Lake tables - Bind Mount)")
    print("[init]   |- minio/storage       (staging files - Bind Mount)")
    print("[init]   |- postgres            (PostgreSQL data - Docker Volume)")
    print("[init]   |- superset_home       (Superset data - Docker Volume)")
    print("[init]   `- notebooks/          (your work - Bind Mount)")
    print()
    print(f"[init] Tip: version control notebooks: cd {data_dir}/notebooks && git init")

    return 0


def init_minio():
    """Initialize MinIO buckets."""
    from .utils import run_command

    print("[minio:init] Initializing MinIO...")

    env_vars = load_env_file()
    minio_bucket = env_vars.get("MINIO_BUCKET", "lakehouse")
    minio_storage_bucket = env_vars.get("MINIO_STORAGE_BUCKET", "storage")
    minio_root_user = env_vars.get("MINIO_ROOT_USER", "admin")
    minio_root_password = env_vars.get("MINIO_ROOT_PASSWORD", "password")
    project_name = env_vars.get("COMPOSE_PROJECT_NAME", "flumen")

    print(f"[minio:init] Creating buckets: {minio_bucket} (lakehouse) and {minio_storage_bucket} (staging)...")

    mc_base = [
        "docker", "run", "--rm", "--network", f"{project_name}_default",
        "-e", f"MC_HOST_flumen=http://{minio_root_user}:{minio_root_password}@minio:9000",
        "minio/mc:RELEASE.2025-08-13T08-35-41Z"
    ]

    for bucket in [minio_bucket, minio_storage_bucket]:
        cmd = mc_base + ["mb", f"flumen/{bucket}", "--ignore-existing"]
        run_command(cmd, check=False, capture_output=True)

    print(f"{Colors.GREEN}[minio:init] Buckets ready{Colors.RESET}")
    return 0


def init_hive():
    """Initialize Hive Metastore (placeholder)."""
    print("[hive:init] Metastore ready. Database creation handled via JupyterLab.")
    return 0


def init_superset():
    """Initialize Superset database in PostgreSQL."""
    from .utils import run_command
    import subprocess

    print("[superset:init] Initializing Superset database...")

    env_vars = load_env_file()
    postgres_user = env_vars.get("POSTGRES_USER", "flumen")
    postgres_password = env_vars.get("POSTGRES_PASSWORD", "flumen_pass")
    superset_db_name = env_vars.get("SUPERSET_DB_NAME", "superset")

    create_db_cmd = [
        "docker", "exec", "flumen_postgres",
        "psql", "-U", postgres_user, "-c",
        f"CREATE DATABASE {superset_db_name};"
    ]

    result = subprocess.run(
        create_db_cmd,
        capture_output=True,
        text=True,
        env={**os.environ, "PGPASSWORD": postgres_password}
    )

    if result.returncode == 0:
        print(f"{Colors.GREEN}[superset:init] Database '{superset_db_name}' created{Colors.RESET}")
    elif "already exists" in result.stderr:
        print(f"{Colors.GREEN}[superset:init] Database '{superset_db_name}' already exists{Colors.RESET}")
    else:
        print(f"{Colors.YELLOW}[superset:init] Database creation status: {result.stderr.strip()}{Colors.RESET}")

    return 0
