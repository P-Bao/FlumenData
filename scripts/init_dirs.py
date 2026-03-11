#!/usr/bin/env python3
"""
Initialize data directories for FlumenData.
Works on Windows, WSL, and Linux (no platform-specific code).
"""

import os
from pathlib import Path


def load_env_file(env_path: str = ".env") -> None:
    """Load environment variables from a .env file if it exists."""
    env_file = Path(env_path)
    if not env_file.exists():
        print(f"[env] Warning: {env_path} not found, using existing environment")
        return

    for line in env_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, value = line.split("=", 1)
            value = value.strip('"').strip("'")
            os.environ[key.strip()] = value


# Load .env file at import time so DATA_DIR is available
load_env_file()


def get_data_dir() -> Path:
    """Resolve DATA_DIR to an absolute Path."""
    data_dir = os.getenv("DATA_DIR", "../data-projects")
    return Path(data_dir).resolve()


def ensure_dir(path: Path, description: str = ""):
    """Create directory if it doesn't exist."""
    try:
        path.mkdir(parents=True, exist_ok=True)
        label = description or "Created"
        print(f"[init] ok  {label}: {path}")
    except Exception as e:
        print(f"[init] ERR Failed to create {description or path}: {e}")
        raise


def init_data_dirs():
    """Initialize all data directories for FlumenData."""
    print("[init] Initializing data directories")

    data_dir = get_data_dir()

    if data_dir.exists() and data_dir.is_file():
        print(f"[init] ERR {data_dir} exists as a file, not a directory!")
        return 1

    print(f"[init] Platform: {os.name}")
    print(f"[init] Data directory: {os.getenv('DATA_DIR')} -> {data_dir}")
    print()

    ensure_dir(data_dir, "Base directory")

    # Subdirectories mapped in docker-compose files
    print("[init] Creating subdirectories...")
    ensure_dir(data_dir / "minio" / "lakehouse", "minio/lakehouse")
    ensure_dir(data_dir / "minio" / "storage", "minio/storage")
    ensure_dir(data_dir / "notebooks" / "_examples", "notebooks")
    ensure_dir(data_dir / "postgres", "postgres (bind mount for DB data)")
    ensure_dir(data_dir / "superset_home", "superset_home (bind mount for Superset)")

    print()
    print("[init] Data directories created successfully")
    print()
    print("[init] Data location:")
    print(f"[init]   Configured: {os.getenv('DATA_DIR')}")
    print(f"[init]   Resolved:   {data_dir}")
    print()
    print("[init] Structure:")
    print("[init]   |- minio/lakehouse     (Delta Lake tables)")
    print("[init]   |- minio/storage       (staging files)")
    print("[init]   |- postgres            (PostgreSQL data)")
    print("[init]   |- superset_home       (Superset configs/db)")
    print("[init]   `- notebooks/          (your work - can git init here!)")
    print()
    print(f"[init] Tip: version control notebooks: cd {data_dir}/notebooks && git init")

    return 0


if __name__ == "__main__":
    import sys

    sys.exit(init_data_dirs())
