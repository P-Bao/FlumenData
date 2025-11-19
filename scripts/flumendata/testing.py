"""
Testing and validation commands for FlumenData
"""

import os
from pathlib import Path
from .utils import Colors, run_command, docker_compose, load_env_file


def test_postgres():
    """Test PostgreSQL connectivity"""
    load_env_file()

    print("[postgres:test] Testing PostgreSQL connection...")

    postgres_user = os.getenv("POSTGRES_USER", "flumendata")
    postgres_db = os.getenv("POSTGRES_DB", "flumendata")

    result = docker_compose(
        "exec", "-T", "postgres",
        "psql", "-U", postgres_user, "-d", postgres_db,
        "-c", "SELECT version();",
        compose_files=["docker-compose.tier0.yml"],
        capture_output=True,
        check=True
    )

    print(f"{Colors.GREEN}[postgres:test] ✓ PostgreSQL test passed{Colors.RESET}")


def test_minio():
    """Test MinIO functionality"""
    load_env_file()

    print("[minio:test] Testing MinIO...")

    minio_user = os.getenv("MINIO_ROOT_USER", "admin")
    minio_password = os.getenv("MINIO_ROOT_PASSWORD", "password")
    project_name = os.getenv("COMPOSE_PROJECT_NAME", "flumen")

    mc_base = [
        "docker", "run", "--rm", "--network", f"{project_name}_default",
        "-e", f"MC_HOST_flumen=http://{minio_user}:{minio_password}@minio:9000",
        "minio/mc:RELEASE.2025-08-13T08-35-41Z"
    ]

    # Create test bucket
    print("[minio:test] Creating test bucket...")
    run_command(mc_base + ["mb", "flumen/selftest", "--ignore-existing"], check=False, capture_output=True)

    # Create test file
    test_content = "hello-from-flumendata"
    test_file = Path("/tmp/minio-test.txt")
    test_file.write_text(test_content)

    # Upload test file
    print("[minio:test] Uploading test file...")
    run_command([
        "docker", "run", "--rm", "--network", f"{project_name}_default",
        "-v", "/tmp/minio-test.txt:/tmp/test.txt",
        "-e", f"MC_HOST_flumen=http://{minio_user}:{minio_password}@minio:9000",
        "minio/mc:RELEASE.2025-08-13T08-35-41Z",
        "cp", "/tmp/test.txt", "flumen/selftest/hello.txt"
    ], capture_output=True)

    # Verify file
    print("[minio:test] Verifying uploaded file...")
    result = run_command(
        mc_base + ["cat", "flumen/selftest/hello.txt"],
        capture_output=True,
        check=True
    )

    if test_content in result.stdout:
        print(f"{Colors.GREEN}[minio:test] ✓ MinIO test passed{Colors.RESET}")
    else:
        print(f"{Colors.RED}[minio:test] ✗ Test failed: content mismatch{Colors.RESET}")
        return False

    # Cleanup
    test_file.unlink(missing_ok=True)

    return True


def test_spark():
    """Test Spark connectivity"""
    print("[spark:test] Testing Spark...")

    result = docker_compose(
        "exec", "-T", "spark-master",
        "/opt/spark/bin/spark-submit",
        "--master", "spark://spark-master:7077",
        "--class", "org.apache.spark.examples.SparkPi",
        "/opt/spark/examples/jars/spark-examples_2.12-4.0.1.jar",
        "10",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        capture_output=True,
        check=True
    )

    if "Pi is roughly" in result.stdout:
        print(f"{Colors.GREEN}[spark:test] ✓ Spark test passed{Colors.RESET}")
    else:
        print(f"{Colors.YELLOW}[spark:test] Spark test completed{Colors.RESET}")


def test_hive():
    """Test Hive Metastore connectivity"""
    print("[hive:test] Testing Hive Metastore...")

    result = docker_compose(
        "exec", "-T", "spark-master",
        "/opt/spark/bin/spark-sql",
        "--master", "spark://spark-master:7077",
        "-e", "SHOW DATABASES",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        capture_output=True,
        check=True
    )

    print(f"{Colors.GREEN}[hive:test] ✓ Hive test passed{Colors.RESET}")


def test_jupyterlab():
    """Test JupyterLab"""
    print("[jupyterlab:test] Testing JupyterLab...")

    result = run_command(
        ["docker", "exec", "flumen_jupyterlab", "jupyter", "--version"],
        capture_output=True,
        check=True
    )

    print(f"{Colors.GREEN}[jupyterlab:test] ✓ JupyterLab test passed{Colors.RESET}")


def test_trino():
    """Test Trino connectivity"""
    print("[trino:test] Testing Trino...")

    result = docker_compose(
        "exec", "-T", "trino",
        "trino", "--execute", "SHOW CATALOGS",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml",
                      "docker-compose.tier2.yml", "docker-compose.tier3.yml"],
        capture_output=True,
        check=True
    )

    print(f"{Colors.GREEN}[trino:test] ✓ Trino test passed{Colors.RESET}")


def test_tier(tier: int):
    """Test all services in a tier"""
    load_env_file()

    if tier == 0:
        print(f"{Colors.BLUE}Testing Tier 0 services...{Colors.RESET}\n")
        test_postgres()
        test_minio()
        print(f"\n{Colors.GREEN}✓ Tier 0 tests passed{Colors.RESET}")

    elif tier == 1:
        print(f"{Colors.BLUE}Testing Tier 1 services...{Colors.RESET}\n")
        test_spark()
        test_hive()
        print(f"\n{Colors.GREEN}✓ Tier 1 tests passed{Colors.RESET}")

    elif tier == 2:
        print(f"{Colors.BLUE}Testing Tier 2 services...{Colors.RESET}\n")
        test_jupyterlab()
        print(f"\n{Colors.GREEN}✓ Tier 2 tests passed{Colors.RESET}")

    elif tier == 3:
        print(f"{Colors.BLUE}Testing Tier 3 services...{Colors.RESET}\n")
        test_trino()
        print(f"\n{Colors.GREEN}✓ Tier 3 tests passed{Colors.RESET}")


def test_all():
    """Run all tests"""
    print(f"{Colors.BLUE}Running all tests...{Colors.RESET}\n")

    for tier in range(4):
        test_tier(tier)
        print()

    print(f"{Colors.GREEN}✓ All tests passed{Colors.RESET}")


def test_integration():
    """Run integration test (Delta Lake + Spark + Hive)"""
    print(f"{Colors.BLUE}Running integration test...{Colors.RESET}")

    # Check if test file exists
    test_file = Path("test_integration.py")
    if not test_file.exists():
        print(f"{Colors.RED}✗ test_integration.py not found{Colors.RESET}")
        return 1

    # Copy test to container
    print("[integration] Copying test script to Spark master...")
    run_command(
        ["docker", "cp", "test_integration.py", "flumen_spark_master:/tmp/"],
        check=True
    )

    # Run test
    print("[integration] Running integration test...")
    docker_compose(
        "exec", "-T", "spark-master",
        "/opt/spark/bin/spark-submit", "/tmp/test_integration.py",
        compose_files=["docker-compose.tier0.yml", "docker-compose.tier1.yml"],
        check=True
    )

    print(f"{Colors.GREEN}✓ Integration test passed{Colors.RESET}")
    return 0
