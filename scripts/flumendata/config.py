"""
Configuration generation for FlumenData services
"""

from pathlib import Path
from .utils import Colors, render_template, load_env_file


def generate_postgres_config():
    """Generate PostgreSQL initialization scripts"""
    print("[postgres] Generating configurations...")

    templates = [
        ("templates/postgres/01-init-databases.sh", "config/postgres/01-init-databases.sh"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)
            # Make script executable
            output_file = Path(output_path)
            if output_file.exists():
                output_file.chmod(0o755)
        else:
            print(f"{Colors.YELLOW}[postgres] Template not found, skipping: {template_path}{Colors.RESET}")

    print(f"{Colors.GREEN}[postgres] ✓ Config generated{Colors.RESET}")


def generate_minio_config():
    """Generate MinIO configuration files"""
    print("[minio] Generating configurations...")

    templates = [
        ("templates/minio/policy-readonly.json.tpl", "config/minio/policy-readonly.json"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)

    print(f"{Colors.GREEN}[minio] ✓ Config generated{Colors.RESET}")


def generate_hive_config():
    """Generate Hive Metastore configuration files"""
    print("[hive] Generating configurations...")

    render_template(
        "templates/hive/hive-site.xml.tpl",
        "config/hive/hive-site.xml"
    )

    # Copy to Spark config directory
    hive_config = Path("config/hive/hive-site.xml")
    spark_config = Path("config/spark/hive-site.xml")

    if hive_config.exists():
        spark_config.parent.mkdir(parents=True, exist_ok=True)
        spark_config.write_text(hive_config.read_text())
        print("[hive] ✓ hive-site.xml copied to Spark config")

    print(f"{Colors.GREEN}[hive] ✓ Config generated{Colors.RESET}")


def generate_spark_config():
    """Generate Spark configuration files"""
    print("[spark] Generating configurations...")

    templates = [
        ("templates/spark/spark-defaults.conf.tpl", "config/spark/spark-defaults.conf"),
        ("templates/spark/core-site.xml.tpl", "config/spark/core-site.xml"),
        ("templates/spark/spark-env.sh.tpl", "config/spark/spark-env.sh"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)
        else:
            print(f"{Colors.YELLOW}[spark] Template not found, skipping: {template_path}{Colors.RESET}")

    print(f"{Colors.GREEN}[spark] ✓ Config generated{Colors.RESET}")


def generate_jupyterlab_config():
    """Generate JupyterLab configuration files"""
    print("[jupyterlab] Generating configurations...")

    templates = [
        ("templates/jupyterlab/spark-defaults.conf.tpl", "config/jupyterlab/spark-defaults.conf"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)
        else:
            print(f"{Colors.YELLOW}[jupyterlab] Template not found, skipping: {template_path}{Colors.RESET}")

    print(f"{Colors.GREEN}[jupyterlab] ✓ Config generated{Colors.RESET}")


def generate_trino_config():
    """Generate Trino configuration files"""
    print("[trino] Generating configurations...")

    templates = [
        ("templates/trino/config.properties.tpl", "config/trino/config.properties"),
        ("templates/trino/jvm.config.tpl", "config/trino/jvm.config"),
        ("templates/trino/node.properties.tpl", "config/trino/node.properties"),
        ("templates/trino/catalog/hive.properties.tpl", "config/trino/catalog/hive.properties"),
        ("templates/trino/catalog/delta.properties.tpl", "config/trino/catalog/delta.properties"),
        ("templates/trino/catalog/lakehouse.properties.tpl", "config/trino/catalog/lakehouse.properties"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)
        else:
            print(f"{Colors.YELLOW}[trino] Template not found, skipping: {template_path}{Colors.RESET}")

    print(f"{Colors.GREEN}[trino] ✓ Config generated{Colors.RESET}")


def generate_superset_config():
    """Generate Superset configuration files"""
    print("[superset] Generating configurations...")

    templates = [
        ("templates/superset/superset_config.py.tpl", "config/superset/superset_config.py"),
        ("templates/superset/superset.env.tpl", "config/superset/superset.env"),
    ]

    for template_path, output_path in templates:
        if Path(template_path).exists():
            render_template(template_path, output_path)
        else:
            print(f"{Colors.YELLOW}[superset] Template not found, skipping: {template_path}{Colors.RESET}")

    print(f"{Colors.GREEN}[superset] ✓ Config generated{Colors.RESET}")


def generate_all_configs():
    """Generate all configuration files"""
    print(f"{Colors.BLUE}Generating all configurations...{Colors.RESET}\n")

    # Load environment variables
    load_env_file()

    # Generate configs for all services
    generate_postgres_config()
    generate_minio_config()
    generate_hive_config()
    generate_spark_config()
    generate_jupyterlab_config()
    generate_trino_config()
    generate_superset_config()

    print(f"\n{Colors.GREEN}✓ All configurations generated{Colors.RESET}")


# Service mapping
SERVICE_GENERATORS = {
    "postgres": generate_postgres_config,
    "minio": generate_minio_config,
    "hive": generate_hive_config,
    "spark": generate_spark_config,
    "jupyterlab": generate_jupyterlab_config,
    "trino": generate_trino_config,
    "superset": generate_superset_config,
    "all": generate_all_configs,
}
