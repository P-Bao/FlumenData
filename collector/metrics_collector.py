"""
FlumenData Dashboard — Metrics Collector
=========================================
Thu thập metrics từ 3 nguồn:
  1. MinIO S3 API  → storage stats per bucket/layer
  2. Delta Lake    → per-table file stats, operations
  3. Spark REST    → pipeline job health

Cách chạy trong JupyterLab:
    %run collector/metrics_collector.py

Hoặc chạy standalone:
    python collector/metrics_collector.py --once
    python collector/metrics_collector.py --schedule  # chạy mỗi 15 phút
"""

import os
import json
import time
import logging
import argparse
from datetime import datetime, timezone
from typing import Optional

import requests
import psycopg2
from psycopg2.extras import execute_values
from minio import Minio
from minio.error import S3Error

# ── Cấu hình — đọc từ .env (tên biến theo FlumenData .env.example) ──────────

# MinIO — tên biến gốc: MINIO_ROOT_USER / MINIO_ROOT_PASSWORD / MINIO_SERVER_URL
# docker-compose map sang MINIO_ACCESS_KEY / MINIO_SECRET_KEY / MINIO_ENDPOINT
MINIO_ENDPOINT   = os.getenv("MINIO_ENDPOINT",   "http://minio:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin123")
MINIO_SECURE     = os.getenv("MINIO_SECURE", "false").lower() == "true"
# Strip http:// prefix nếu có (MinIO SDK dùng host:port, không dùng URL đầy đủ)
if MINIO_ENDPOINT.startswith(("http://", "https://")):
    MINIO_SECURE   = MINIO_ENDPOINT.startswith("https://")
    MINIO_ENDPOINT = MINIO_ENDPOINT.split("//", 1)[1]

# Bucket chính của lakehouse (từ MINIO_BUCKET trong .env)
MINIO_MAIN_BUCKET = os.getenv("MINIO_BUCKET", "lakehouse")

# Spark — SPARK_MASTER_URL khai báo trực tiếp trong .env dashboard section
SPARK_MASTER_URL = os.getenv("SPARK_MASTER_URL", "http://spark-master:8080")

# PostgreSQL — docker-compose map POSTGRES_* sang PG_*
PG_HOST     = os.getenv("PG_HOST",     "postgres")
PG_PORT     = int(os.getenv("PG_PORT", "5432"))
PG_USER     = os.getenv("PG_USER",     "flumen")
PG_PASSWORD = os.getenv("PG_PASSWORD", "flumen_pass")
PG_DATABASE = os.getenv("PG_DATABASE", "metrics_db")

# Ngưỡng và schedule — từ .env dashboard section
SMALL_FILE_THRESHOLD_BYTES = int(os.getenv("SMALL_FILE_THRESHOLD_BYTES", str(128 * 1024 * 1024)))
SCHEDULE_INTERVAL_SEC      = int(os.getenv("COLLECTOR_INTERVAL_SEC", "900"))


def _parse_patterns(val: str) -> list:
    return [p.strip().lower() for p in val.split(",") if p.strip()]


# Map bucket/prefix → layer — xây từ LAYER_*_PATTERNS trong .env
_bronze = _parse_patterns(os.getenv("LAYER_BRONZE_PATTERNS", "bronze,raw"))
_silver = _parse_patterns(os.getenv("LAYER_SILVER_PATTERNS", "silver,curated"))
_gold   = _parse_patterns(os.getenv("LAYER_GOLD_PATTERNS",   "gold,serving"))

LAYER_MAP = {}
for _p in _bronze: LAYER_MAP[_p] = "bronze"
for _p in _silver: LAYER_MAP[_p] = "silver"
for _p in _gold:   LAYER_MAP[_p] = "gold"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("flumen.collector")


# ── Database helper ──────────────────────────────────────────────────────────
def get_pg_conn():
    return psycopg2.connect(
        host=PG_HOST, port=PG_PORT,
        user=PG_USER, password=PG_PASSWORD,
        dbname=PG_DATABASE
    )


# ── 1. MinIO Storage Collector ───────────────────────────────────────────────
def collect_minio_stats(conn) -> dict:
    """
    Lấy object count + bytes per bucket từ MinIO.
    Trả về summary dict để log.
    """
    log.info("📦 Collecting MinIO storage stats...")
    client = Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=MINIO_SECURE,
    )

    rows = []
    total_files = 0
    total_bytes = 0

    try:
        buckets = client.list_buckets()
    except S3Error as e:
        log.error(f"MinIO error listing buckets: {e}")
        return {}

    for bucket in buckets:
        name = bucket.name
        file_count = 0
        size_bytes = 0
        small_files = 0

        try:
            objects = client.list_objects(name, recursive=True)
            for obj in objects:
                file_count += 1
                sz = obj.size or 0
                size_bytes += sz
                if sz < SMALL_FILE_THRESHOLD_BYTES:
                    small_files += 1
        except S3Error as e:
            log.warning(f"Cannot list objects in bucket {name}: {e}")
            continue

        avg_size = (size_bytes // file_count) if file_count > 0 else 0

        # Determine layer from bucket name
        layer = "unknown"
        for prefix, lyr in LAYER_MAP.items():
            if prefix in name.lower():
                layer = lyr
                break

        rows.append((
            layer, name,
            file_count, size_bytes,
            small_files, avg_size,
        ))
        total_files += file_count
        total_bytes += size_bytes
        log.info(f"  bucket={name} layer={layer} files={file_count:,} size={size_bytes/1e9:.2f}GB small={small_files:,}")

    if rows:
        with conn.cursor() as cur:
            execute_values(cur, """
                INSERT INTO storage_snapshots
                    (layer, bucket, file_count, size_bytes, small_file_count, avg_file_size_bytes)
                VALUES %s
            """, rows)
        conn.commit()
        log.info(f"✅ MinIO: {len(rows)} buckets saved — total {total_files:,} files, {total_bytes/1e9:.2f} GB")

    return {"buckets": len(rows), "total_files": total_files, "total_bytes": total_bytes}


# ── 2. Delta Lake Table Stats ────────────────────────────────────────────────
def collect_delta_stats(conn, spark=None) -> dict:
    """
    Dùng PySpark để đọc DESCRIBE DETAIL cho từng Delta table.
    Nếu không có spark session, thử import pyspark.
    """
    log.info("🔺 Collecting Delta Lake table stats...")

    if spark is None:
        try:
            from pyspark.sql import SparkSession
            spark = SparkSession.builder \
                .appName("FlumenDashboardCollector") \
                .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
                .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
                .getOrCreate()
        except Exception as e:
            log.error(f"Cannot create SparkSession: {e}")
            return {}

    rows = []
    op_rows = []

    try:
        # Lấy danh sách tất cả databases từ Hive Metastore
        databases = [db.namespace for db in spark.sql("SHOW DATABASES").collect()]
        log.info(f"  Found {len(databases)} databases in metastore")

        for db in databases:
            if db in ("default", "information_schema"):
                continue

            try:
                tables = spark.sql(f"SHOW TABLES IN {db}").collect()
            except Exception as e:
                log.warning(f"  Cannot list tables in {db}: {e}")
                continue

            for tbl in tables:
                tbl_name = tbl.tableName
                full_name = f"{db}.{tbl_name}"

                # Infer layer from database name
                layer = "unknown"
                for prefix, lyr in LAYER_MAP.items():
                    if prefix in db.lower() or prefix in tbl_name.lower():
                        layer = lyr
                        break

                try:
                    detail = spark.sql(f"DESCRIBE DETAIL {full_name}").collect()[0]
                    num_files  = detail.numFiles or 0
                    size_bytes = detail.sizeInBytes or 0
                    location   = detail.location
                    fmt        = detail.format

                    # Partition count
                    try:
                        num_parts = spark.sql(f"SHOW PARTITIONS {full_name}").count()
                    except Exception:
                        num_parts = 0

                    # Delta version
                    delta_version = None
                    last_modified = None
                    try:
                        history = spark.sql(f"DESCRIBE HISTORY {full_name} LIMIT 1").collect()
                        if history:
                            delta_version = history[0].version
                            last_modified = history[0].timestamp
                    except Exception:
                        pass

                    avg_size = (size_bytes // num_files) if num_files > 0 else 0
                    rows.append((
                        db, tbl_name, layer,
                        num_files, size_bytes, num_parts,
                        delta_version,
                        last_modified.replace(tzinfo=timezone.utc) if last_modified else None,
                        fmt, location,
                    ))
                    log.info(f"  {full_name}: files={num_files:,} size={size_bytes/1e9:.3f}GB v={delta_version}")

                    # Collect Delta operation history (last 50 ops)
                    try:
                        hist_df = spark.sql(f"DESCRIBE HISTORY {full_name} LIMIT 50").collect()
                        for h in hist_df:
                            params = h.operationParameters or {}
                            op_rows.append((
                                db, tbl_name,
                                h.version,
                                h.operation,
                                h.timestamp.replace(tzinfo=timezone.utc) if h.timestamp else None,
                                str(h.userName) if h.userName else None,
                                int(params.get("numOutputRows", 0) or 0),
                                int(params.get("numRemovedFiles", 0) or 0),
                                int(params.get("numOutputBytes", 0) or 0),
                            ))
                    except Exception:
                        pass

                except Exception as e:
                    log.warning(f"  Cannot DESCRIBE DETAIL {full_name}: {e}")
                    continue

    except Exception as e:
        log.error(f"Delta stats collection failed: {e}")
        return {}

    with conn.cursor() as cur:
        if rows:
            execute_values(cur, """
                INSERT INTO delta_table_stats
                    (database_name, table_name, layer,
                     num_files, size_bytes, num_partitions,
                     delta_version, last_modified, format, location)
                VALUES %s
            """, rows)

        if op_rows:
            execute_values(cur, """
                INSERT INTO delta_operations
                    (database_name, table_name, version, operation,
                     timestamp, user_name,
                     num_output_files, num_removed_files, num_output_bytes)
                VALUES %s
                ON CONFLICT (database_name, table_name, version) DO NOTHING
            """, op_rows)

    conn.commit()
    log.info(f"✅ Delta: {len(rows)} tables, {len(op_rows)} operations saved")
    return {"tables": len(rows), "operations": len(op_rows)}


# ── 3. Spark Job Metrics (REST API) ──────────────────────────────────────────
def collect_spark_metrics(conn) -> dict:
    """
    Poll Spark Master REST API để lấy job/application metrics.
    Endpoint: http://localhost:8080/api/v1/applications
    """
    log.info("⚡ Collecting Spark pipeline metrics...")

    try:
        resp = requests.get(
            f"{SPARK_MASTER_URL}/api/v1/applications",
            timeout=10,
            params={"status": "completed,failed,running", "limit": 100},
        )
        resp.raise_for_status()
        apps = resp.json()
    except Exception as e:
        log.error(f"Spark REST API error: {e}")
        return {}

    rows = []
    for app in apps:
        app_id   = app.get("id", "")
        app_name = app.get("name", "")
        attempts = app.get("attempts", [{}])
        latest   = attempts[0] if attempts else {}

        status     = "SUCCEEDED" if latest.get("completed") else "RUNNING"
        start_ms   = latest.get("startTime")
        end_ms     = latest.get("endTime")
        duration   = latest.get("duration", 0)

        # Try to get stage/task details
        num_stages = num_tasks = failed_tasks = 0
        shuffle_read = shuffle_write = 0
        try:
            st_resp = requests.get(
                f"{SPARK_MASTER_URL}/api/v1/applications/{app_id}/stages",
                timeout=5
            )
            if st_resp.ok:
                stages = st_resp.json()
                num_stages = len(stages)
                for s in stages:
                    num_tasks    += s.get("numCompleteTasks", 0)
                    failed_tasks += s.get("numFailedTasks", 0)
                    shuffle_read  += s.get("shuffleReadBytes", 0)
                    shuffle_write += s.get("shuffleWriteBytes", 0)
                if failed_tasks > 0:
                    status = "FAILED"
        except Exception:
            pass

        start_dt = datetime.fromtimestamp(start_ms / 1000, tz=timezone.utc) if start_ms else None
        end_dt   = datetime.fromtimestamp(end_ms / 1000, tz=timezone.utc) if end_ms else None

        rows.append((
            app_id, app_name, status,
            start_dt, end_dt, duration,
            num_stages, num_tasks, failed_tasks,
            shuffle_read, shuffle_write,
        ))

    if rows:
        with conn.cursor() as cur:
            execute_values(cur, """
                INSERT INTO pipeline_runs
                    (app_id, app_name, status,
                     start_time, end_time, duration_ms,
                     num_stages, num_tasks, failed_tasks,
                     shuffle_read_bytes, shuffle_write_bytes)
                VALUES %s
            """, rows)
        conn.commit()

    succeeded = sum(1 for r in rows if r[2] == "SUCCEEDED")
    failed    = sum(1 for r in rows if r[2] == "FAILED")
    log.info(f"✅ Spark: {len(rows)} apps — {succeeded} succeeded, {failed} failed")
    return {"apps": len(rows), "succeeded": succeeded, "failed": failed}


# ── 4. Catalog Summary (Hive Metastore via Spark) ────────────────────────────
def collect_catalog_stats(conn, spark=None) -> dict:
    log.info("📚 Collecting Hive catalog summary...")
    if spark is None:
        return {}

    try:
        dbs = spark.sql("SHOW DATABASES").collect()
        db_details = []
        total_tables = 0
        total_partitions = 0

        for db_row in dbs:
            db = db_row.namespace
            if db in ("default", "information_schema"):
                continue
            try:
                tables = spark.sql(f"SHOW TABLES IN {db}").collect()
                tbl_count = len(tables)
                part_count = 0
                for tbl in tables:
                    try:
                        part_count += spark.sql(
                            f"SHOW PARTITIONS {db}.{tbl.tableName}"
                        ).count()
                    except Exception:
                        pass
                db_details.append({
                    "name": db,
                    "table_count": tbl_count,
                    "partition_count": part_count,
                })
                total_tables     += tbl_count
                total_partitions += part_count
            except Exception:
                continue

        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO catalog_snapshots
                    (total_databases, total_tables, total_partitions, databases_detail)
                VALUES (%s, %s, %s, %s)
            """, (
                len(db_details), total_tables, total_partitions,
                json.dumps(db_details),
            ))
        conn.commit()
        log.info(f"✅ Catalog: {len(db_details)} DBs, {total_tables} tables, {total_partitions} partitions")
        return {"databases": len(db_details), "tables": total_tables}

    except Exception as e:
        log.error(f"Catalog collection failed: {e}")
        return {}


# ── Main runner ───────────────────────────────────────────────────────────────
def run_once(spark=None):
    log.info("=" * 60)
    log.info("🚀 FlumenData Metrics Collector — starting collection")
    log.info("=" * 60)

    try:
        conn = get_pg_conn()
    except Exception as e:
        log.error(f"Cannot connect to PostgreSQL metrics_db: {e}")
        log.error("Run: make shell-postgres → \\i sql/01_create_metrics_db.sql")
        return

    summary = {}
    summary["minio"]   = collect_minio_stats(conn)
    summary["spark"]   = collect_spark_metrics(conn)
    summary["delta"]   = collect_delta_stats(conn, spark=spark)
    summary["catalog"] = collect_catalog_stats(conn, spark=spark)

    conn.close()
    log.info("=" * 60)
    log.info(f"✅ Collection complete: {json.dumps(summary, indent=2)}")
    log.info("=" * 60)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FlumenData Metrics Collector")
    parser.add_argument("--once",     action="store_true", help="Run once and exit")
    parser.add_argument("--schedule", action="store_true", help="Run on a schedule (every 15 min)")
    args = parser.parse_args()

    if args.schedule:
        log.info(f"📅 Scheduler mode: running every {SCHEDULE_INTERVAL_SEC // 60} minutes")
        while True:
            run_once()
            log.info(f"💤 Sleeping {SCHEDULE_INTERVAL_SEC // 60} minutes...")
            time.sleep(SCHEDULE_INTERVAL_SEC)
    else:
        run_once()
