#!/usr/bin/env python3
"""
Initialize data directories for FlumenData
Works identically on Windows, WSL, and Linux - no platform-specific code needed
"""

import os
from pathlib import Path


def load_env_file(env_path: str = ".env") -> None:
    """Load environment variables from .env file"""
    env_file = Path(env_path)
    if not env_file.exists():
        print(f"[env] Warning: {env_path} not found, using existing environment")
        return

    for line in env_file.read_text().splitlines():
        line = line.strip()
        # Skip comments and empty lines
        if not line or line.startswith("#"):
            continue
        # Parse KEY=VALUE
        if "=" in line:
            key, value = line.split("=", 1)
            # Remove quotes if present
            value = value.strip('"').strip("'")
            os.environ[key.strip()] = value


# Load .env file at module import
load_env_file()


def get_data_dir() -> Path:
    """Get DATA_DIR from environment and resolve to absolute path"""
    data_dir = os.getenv("DATA_DIR", "../data-projects")

    # Resolve to absolute path (handles symlinks, relative paths, etc.)
    # Works on Windows (C:\), WSL (/mnt/d/), and Linux (/home/)
    resolved = Path(data_dir).resolve()

    return resolved


def ensure_dir(path: Path, description: str = ""):
    """Create directory if it doesn't exist"""
    try:
        path.mkdir(parents=True, exist_ok=True)
        if description:
            print(f"[init] ✓ {description}: {path}")
        else:
            print(f"[init] ✓ Created: {path}")
    except Exception as e:
        print(f"[init] ✗ Failed to create {description}: {path}")
        print(f"[init]   Error: {e}")
        raise


def init_data_dirs():
    """Initialize all data directories for FlumenData"""
    print("[init] Initializing data directories")

    # Get base data directory
    data_dir = get_data_dir()

    # Check if it's a file (error condition)
    if data_dir.exists() and data_dir.is_file():
        print(f"[init] ✗ ERROR: {data_dir} exists as a file, not a directory!")
        return 1

    print(f"[init] Platform: {os.name}")
    print(f"[init] Data directory: {os.getenv('DATA_DIR')} → {data_dir}")
    print()

    # Create base directory
    ensure_dir(data_dir, "Base directory")

    # Create subdirectories
    print("[init] Creating subdirectories...")
    ensure_dir(data_dir / "minio" / "lakehouse", "minio/lakehouse")
    ensure_dir(data_dir / "minio" / "storage", "minio/storage")
    ensure_dir(data_dir / "notebooks" / "_examples", "notebooks")

    print()
    print("[init] ✓ Data directories created successfully")
    print()
    print("[init] Data location:")
    print(f"[init]   Configured: {os.getenv('DATA_DIR')}")
    print(f"[init]   Resolved:   {data_dir}")
    print()
    print("[init] Structure:")
    print("[init]   ├── minio/lakehouse     (Delta Lake tables)")
    print("[init]   ├── minio/storage       (staging files)")
    print("[init]   └── notebooks/          (your work - can git init here!)")
    print()
    print(f"[init] 💡 Version control notebooks: cd {data_dir}/notebooks && git init")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(init_data_dirs())
