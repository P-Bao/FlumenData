-- ============================================================
-- FlumenData Dashboard — Trino Views
-- Kết nối Superset → Trino → PostgreSQL metrics_db
--
-- 1. Thêm PostgreSQL connector vào Trino:
--    Tạo file: docker/trino/catalog/metrics.properties
--    connector.name=postgresql
--    connection-url=jdbc:postgresql://postgres:5432/metrics_db
--    connection-user=admin
--    connection-password=admin123
--
-- 2. Superset connection string:
--    trino://trino@localhost:8082/hive/public
-- ============================================================

CREATE SCHEMA IF NOT EXISTS hive.public;

-- ── View 1: Storage tổng quan theo layer ────────────────────
CREATE OR REPLACE VIEW hive.public.v_dashboard_storage AS
SELECT
    layer,
    bucket,
    file_count,
    size_bytes,
    ROUND(CAST(size_bytes AS DOUBLE) / 1073741824, 2)   AS size_gb,
    small_file_count,
    CASE WHEN file_count > 0
         THEN ROUND(100.0 * small_file_count / file_count, 1)
         ELSE 0.0 END                                   AS small_file_pct,
    ROUND(CAST(size_bytes AS DOUBLE) / NULLIF(file_count, 0) / 1048576, 1) AS avg_file_mb,
    captured_at
FROM metrics.public.storage_snapshots
WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.storage_snapshots);


-- ── View 2: File count summary per layer (cho bar chart) ────
CREATE OR REPLACE VIEW hive.public.v_files_by_layer AS
SELECT
    layer,
    SUM(file_count)       AS total_files,
    SUM(size_bytes)       AS total_bytes,
    ROUND(CAST(SUM(size_bytes) AS DOUBLE) / 1073741824, 2) AS total_gb,
    SUM(small_file_count) AS small_files,
    ROUND(100.0 * SUM(small_file_count) / NULLIF(SUM(file_count),0), 1) AS small_pct
FROM hive.public.v_dashboard_storage
GROUP BY layer
ORDER BY
    CASE layer
        WHEN 'bronze' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold'   THEN 3
        ELSE 4
    END;


-- ── View 3: Top tables theo dung lượng ──────────────────────
CREATE OR REPLACE VIEW hive.public.v_top_tables AS
SELECT
    database_name,
    table_name,
    layer,
    num_files,
    ROUND(CAST(size_bytes AS DOUBLE) / 1073741824, 3)  AS size_gb,
    num_partitions,
    delta_version,
    ROUND(CAST(size_bytes AS DOUBLE) / NULLIF(num_files,0) / 1048576, 1) AS avg_file_mb,
    last_modified,
    captured_at
FROM metrics.public.delta_table_stats
WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.delta_table_stats)
ORDER BY size_bytes DESC
LIMIT 50;


-- ── View 4: Pipeline health theo giờ ────────────────────────
CREATE OR REPLACE VIEW hive.public.v_pipeline_health_hourly AS
SELECT
    DATE_TRUNC('hour', captured_at)          AS hour,
    COUNT(*)                                  AS total_runs,
    SUM(CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE 0 END) AS succeeded,
    SUM(CASE WHEN status = 'FAILED'    THEN 1 ELSE 0 END) AS failed,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                         AS success_rate_pct,
    ROUND(AVG(CAST(duration_ms AS DOUBLE)) / 60000, 1) AS avg_duration_min,
    SUM(failed_tasks)                         AS total_failed_tasks
FROM metrics.public.pipeline_runs
WHERE captured_at >= NOW() - INTERVAL '7' DAY
GROUP BY DATE_TRUNC('hour', captured_at)
ORDER BY hour DESC;


-- ── View 5: Delta operations timeline ───────────────────────
CREATE OR REPLACE VIEW hive.public.v_delta_operations AS
SELECT
    DATE_TRUNC('day', timestamp)  AS op_day,
    operation,
    COUNT(*)                       AS op_count,
    SUM(num_output_files)          AS files_written,
    SUM(num_removed_files)         AS files_removed,
    ROUND(CAST(SUM(num_output_bytes) AS DOUBLE) / 1073741824, 2) AS gb_written
FROM metrics.public.delta_operations
WHERE timestamp >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', timestamp), operation
ORDER BY op_day DESC, op_count DESC;


-- ── View 6: Small files alert per table ─────────────────────
CREATE OR REPLACE VIEW hive.public.v_small_files_tables AS
SELECT
    database_name,
    table_name,
    layer,
    num_files,
    ROUND(CAST(size_bytes AS DOUBLE) / 1073741824, 3) AS size_gb,
    ROUND(CAST(size_bytes AS DOUBLE) / NULLIF(num_files,0) / 1048576, 1) AS avg_file_mb,
    CASE
        WHEN (CAST(size_bytes AS DOUBLE) / NULLIF(num_files,0)) < 134217728 THEN '⚠️ small_files'
        ELSE '✅ ok'
    END AS status
FROM metrics.public.delta_table_stats
WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.delta_table_stats)
  AND num_files > 0
ORDER BY avg_file_mb ASC;


-- ── View 7: KPI summary (cho Big Number cards) ──────────────
CREATE OR REPLACE VIEW hive.public.v_kpi_summary AS
SELECT
    (SELECT SUM(file_count) FROM metrics.public.storage_snapshots
     WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.storage_snapshots))
        AS total_files,

    (SELECT ROUND(CAST(SUM(size_bytes) AS DOUBLE) / 1099511627776, 2)
     FROM metrics.public.storage_snapshots
     WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.storage_snapshots))
        AS total_size_tb,

    (SELECT COUNT(DISTINCT database_name || '.' || table_name)
     FROM metrics.public.delta_table_stats
     WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.delta_table_stats))
        AS total_tables,

    (SELECT SUM(small_file_count) FROM metrics.public.storage_snapshots
     WHERE captured_at = (SELECT MAX(captured_at) FROM metrics.public.storage_snapshots))
        AS total_small_files,

    (SELECT ROUND(
        100.0 * SUM(CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),
     1)
     FROM metrics.public.pipeline_runs
     WHERE captured_at >= NOW() - INTERVAL '24' HOUR)
        AS pipeline_success_rate_24h,

    (SELECT total_tables FROM metrics.public.catalog_snapshots
     ORDER BY captured_at DESC LIMIT 1)
        AS catalog_tables,

    (SELECT total_partitions FROM metrics.public.catalog_snapshots
     ORDER BY captured_at DESC LIMIT 1)
        AS catalog_partitions;
