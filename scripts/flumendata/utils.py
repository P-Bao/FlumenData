"""
Utility functions for FlumenData CLI
Handles environment loading, colors, Docker helpers, etc.
"""

import os
import sys
import time
import subprocess
from pathlib import Path
from string import Template
from typing import Optional, Dict, Any


# ANSI color codes for cross-platform terminal output
class Colors:
    """Terminal colors that work on Windows, Linux, and macOS"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    RESET = '\033[0m'

    @staticmethod
    def disable():
        """Disable colors (for non-TTY output)"""
        Colors.RED = ''
        Colors.GREEN = ''
        Colors.YELLOW = ''
        Colors.BLUE = ''
        Colors.RESET = ''


# Detect if output is a TTY (for color support)
if not sys.stdout.isatty():
    Colors.disable()


def load_env_file(env_path: str = ".env") -> Dict[str, str]:
    """
    Load environment variables from .env file

    Args:
        env_path: Path to .env file

    Returns:
        Dictionary of environment variables
    """
    env_file = Path(env_path)
    env_vars = {}

    if not env_file.exists():
        print(f"{Colors.YELLOW}[env] Warning: {env_path} not found{Colors.RESET}")
        return env_vars

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
            key = key.strip()
            env_vars[key] = value
            os.environ[key] = value

    return env_vars


def get_project_root() -> Path:
    """Get the project root directory (where .env is located)"""
    # Assume scripts are in scripts/ subdirectory
    current = Path(__file__).resolve().parent.parent.parent
    return current


def render_template(template_path: str, output_path: str, env_vars: Optional[Dict[str, str]] = None) -> None:
    """
    Render a template file with environment variables
    Uses ${VARIABLE} syntax (same as envsubst)

    Args:
        template_path: Path to .tpl template file
        output_path: Path to write rendered output
        env_vars: Optional dict of environment variables (uses os.environ if not provided)
    """
    template_file = Path(template_path)
    output_file = Path(output_path)

    if not template_file.exists():
        print(f"{Colors.RED}[template] [ERROR] Template not found: {template_path}{Colors.RESET}")
        sys.exit(1)

    try:
        # Read template content
        template_content = template_file.read_text()

        # Use Python's string.Template for ${VARIABLE} syntax
        template = Template(template_content)

        # Use provided env_vars or fall back to os.environ
        variables = env_vars if env_vars is not None else os.environ
        rendered = template.safe_substitute(variables)

        # Convert Windows line endings (CRLF) to Unix (LF) for Docker compatibility
        rendered = rendered.replace('\r\n', '\n')

        # Ensure output directory exists
        output_file.parent.mkdir(parents=True, exist_ok=True)

        # Write rendered content with Unix line endings
        output_file.write_text(rendered, newline='\n')

        print(f"[template] {template_path} → {output_path}")

    except Exception as e:
        print(f"{Colors.RED}[template] [ERROR] Failed to render {template_path}{Colors.RESET}")
        print(f"{Colors.RED}[template]   Error: {e}{Colors.RESET}")
        sys.exit(1)


def run_command(cmd: list, check: bool = True, capture_output: bool = False, **kwargs) -> subprocess.CompletedProcess:
    """
    Run a shell command

    Args:
        cmd: Command as list of strings
        check: Raise exception on non-zero exit code
        capture_output: Capture stdout/stderr
        **kwargs: Additional arguments to subprocess.run

    Returns:
        CompletedProcess instance
    """
    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True,
            **kwargs
        )
        return result
    except subprocess.CalledProcessError as e:
        print(f"{Colors.RED}[ERROR] Command failed: {' '.join(cmd)}{Colors.RESET}")
        if capture_output and e.stderr:
            print(f"{Colors.RED}{e.stderr}{Colors.RESET}")
        sys.exit(e.returncode)
    except FileNotFoundError:
        print(f"{Colors.RED}[ERROR] Command not found: {cmd[0]}{Colors.RESET}")
        print(f"{Colors.YELLOW}Make sure {cmd[0]} is installed and in your PATH{Colors.RESET}")
        sys.exit(1)


def docker_compose(*args, compose_files: Optional[list] = None, check: bool = True, capture_output: bool = False):
    """
    Run docker compose command

    Args:
        *args: Arguments to pass to docker compose
        compose_files: List of compose files to use
        check: Raise exception on non-zero exit code
        capture_output: Capture stdout/stderr

    Returns:
        CompletedProcess instance
    """
    cmd = ["docker", "compose"]

    # Add compose files
    if compose_files:
        for f in compose_files:
            cmd.extend(["-f", f])

    # Add command arguments
    cmd.extend(args)

    return run_command(cmd, check=check, capture_output=capture_output)


def wait_for_healthy(container_name: str, timeout: int = 180) -> bool:
    """
    Wait for a Docker container to become healthy

    Args:
        container_name: Name of the container
        timeout: Maximum time to wait in seconds

    Returns:
        True if healthy, exits with error if timeout
    """
    print(f"[wait] Waiting for {container_name} to become healthy (timeout: {timeout}s)...", end='', flush=True)

    for i in range(timeout):
        try:
            result = run_command(
                ["docker", "inspect", "--format", "{{.State.Health.Status}}", container_name],
                capture_output=True,
                check=False
            )

            status = result.stdout.strip() if result.returncode == 0 else "starting"

            if status == "healthy":
                print(f"\r{Colors.GREEN}[wait] {container_name} is healthy [OK]{Colors.RESET}")
                return True

            # Show progress dots
            if i % 5 == 0:
                print(".", end='', flush=True)

        except Exception:
            pass

        time.sleep(1)

    print(f"\r{Colors.RED}[wait] [ERROR] Timeout: {container_name} is not healthy after {timeout}s{Colors.RESET}")
    sys.exit(1)


def ensure_dir(path: Path, description: str = "") -> None:
    """
    Create directory if it doesn't exist

    Args:
        path: Path to create
        description: Description for logging
    """
    try:
        path.mkdir(parents=True, exist_ok=True)
        if description:
            print(f"[init] [OK] {description}: {path}")
        else:
            print(f"[init] [OK] Created: {path}")
    except Exception as e:
        print(f"{Colors.RED}[init] [ERROR] Failed to create {description}: {path}{Colors.RESET}")
        print(f"{Colors.RED}[init]   Error: {e}{Colors.RESET}")
        raise


def get_compose_files(tier: Optional[Any] = None) -> list:
    """
    Get list of docker-compose files for specified tier(s)

    Args:
        tier: Tier number (0-3), "api", or None for all tiers

    Returns:
        List of compose file paths
    """
    files = []

    if tier is None:
        # All tiers including API
        for t in range(4):
            files.append(f"docker-compose.tier{t}.yml")
        files.append("docker-compose.api.yml")
        files.append("docker-compose.dashboard.yml")
    elif tier == "api":
        files.append("docker-compose.api.yml")
    elif isinstance(tier, int):
        if tier == 0:
            files.append("docker-compose.tier0.yml")
        else:
            # Include all tiers up to specified tier
            for t in range(tier + 1):
                files.append(f"docker-compose.tier{t}.yml")
    
    return files


def print_banner():
    """Print FlumenData banner"""
    print(f"{Colors.BLUE}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║                                                               ║")
    print("║                    F L U M E N D A T A                        ║")
    print("║            Open Source Lakehouse Platform                     ║")
    print("║                                                               ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{Colors.RESET}")
    print()
