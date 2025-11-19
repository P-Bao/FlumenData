#!/usr/bin/env python3
"""
Render configuration templates for FlumenData services
Replaces envsubst - works identically on all platforms
"""

import os
import sys
from pathlib import Path
from string import Template


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


def render_template(template_path: str, output_path: str) -> None:
    """
    Render a template file with environment variables
    Uses ${VARIABLE} syntax (same as envsubst) for compatibility with existing templates

    Args:
        template_path: Path to .tpl template file
        output_path: Path to write rendered output
    """
    template_file = Path(template_path)
    output_file = Path(output_path)

    # Check if template exists
    if not template_file.exists():
        print(f"[template] ✗ Template not found: {template_path}")
        sys.exit(1)

    try:
        # Read template content
        template_content = template_file.read_text()

        # Use Python's string.Template for ${VARIABLE} syntax (same as envsubst)
        template = Template(template_content)

        # safe_substitute replaces variables but leaves unknown ones as-is
        # substitute would raise KeyError for missing variables
        rendered = template.safe_substitute(os.environ)

        # Ensure output directory exists
        output_file.parent.mkdir(parents=True, exist_ok=True)

        # Write rendered content (Python handles line endings automatically)
        output_file.write_text(rendered)

        print(f"[template] {template_path} → {output_path}")

    except Exception as e:
        print(f"[template] ✗ Failed to render {template_path}")
        print(f"[template]   Error: {e}")
        sys.exit(1)


def render_minio_configs():
    """Render all MinIO configuration templates"""
    print("[minio] Generating configurations...")

    render_template(
        "templates/minio/policy-readonly.json.tpl",
        "config/minio/policy-readonly.json"
    )

    print("[minio] ✓ Config generated")


def render_hive_configs():
    """Render all Hive configuration templates"""
    print("[hive] Generating configurations...")

    render_template(
        "templates/hive/hive-site.xml.tpl",
        "config/hive/hive-site.xml"
    )

    # Copy to Spark config directory
    hive_config = Path("config/hive/hive-site.xml")
    spark_config = Path("config/spark/hive-site.xml")

    spark_config.parent.mkdir(parents=True, exist_ok=True)
    spark_config.write_text(hive_config.read_text())

    print("[hive] ✓ Config generated")
    print("[hive] ✓ hive-site.xml copied to Spark config")


def main():
    """Main entry point for configuration rendering"""
    if len(sys.argv) < 2:
        print("Usage: python3 render_config.py <service>")
        print("Services: minio, hive, all")
        sys.exit(1)

    service = sys.argv[1]

    if service == "minio":
        render_minio_configs()
    elif service == "hive":
        render_hive_configs()
    elif service == "all":
        render_minio_configs()
        render_hive_configs()
    else:
        print(f"Unknown service: {service}")
        sys.exit(1)


if __name__ == "__main__":
    main()
