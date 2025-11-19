"""
Verification commands for FlumenData services
"""

import time
import sys
from .utils import Colors, run_command, load_env_file
import os


def verify_hive():
    """Verify Hive Metastore setup"""
    load_env_file()

    minio_bucket = os.getenv("MINIO_BUCKET", "lakehouse")

    print(f"{Colors.YELLOW}════════════════════════════════════════════════{Colors.RESET}")
    print(f"{Colors.YELLOW}   Downloading Spark Dependencies               {Colors.RESET}")
    print(f"{Colors.YELLOW}════════════════════════════════════════════════{Colors.RESET}")
    print()
    print(f"{Colors.YELLOW}PLEASE WAIT: This may take a few minutes...{Colors.RESET}")
    print()

    # Run spark-sql to show databases
    print("[hive:verify] Preparing Spark SQL environment", end='', flush=True)

    try:
        result = run_command(
            ["docker", "exec", "flumen_spark_master",
             "/opt/spark/bin/spark-sql",
             "--master", "spark://spark-master:7077",
             "-e", "SHOW DATABASES"],
            capture_output=True,
            check=True
        )

        print(f"\r[hive:verify] Preparing Spark SQL environment {Colors.GREEN}DONE{Colors.RESET}")
        print()

        print(f"{Colors.BLUE}════════════════════════════════════════════════{Colors.RESET}")
        print(f"{Colors.BLUE}   Hive Metastore - Lakehouse Structure         {Colors.RESET}")
        print(f"{Colors.BLUE}════════════════════════════════════════════════{Colors.RESET}")
        print()
        print(f"{Colors.YELLOW}🗄️  Metadata Database:{Colors.RESET} PostgreSQL")
        print(f"{Colors.YELLOW}💾 Storage Backend:{Colors.RESET} s3a://{minio_bucket}/warehouse")
        print(f"{Colors.YELLOW}🔗 Metastore URI:{Colors.RESET} thrift://hive-metastore:9083")
        print()
        print(f"{Colors.GREEN}════════════════════════════════════════════════{Colors.RESET}")
        print(f"{Colors.GREEN}✓ Verification complete{Colors.RESET}")
        print(f"{Colors.GREEN}════════════════════════════════════════════════{Colors.RESET}")

    except Exception as e:
        print(f"\r[hive:verify] {Colors.RED}✗ Failed{Colors.RESET}")
        print(f"{Colors.RED}Error: {e}{Colors.RESET}")
        sys.exit(1)
