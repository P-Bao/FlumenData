-- ============================================================
-- FlumenData Dashboard — Metrics Database Schema
-- Run via: make shell-postgres → \i /path/01_create_metrics_db.sql
-- ============================================================

CREATE DATABASE metrics_db;
\c metrics_db;

-- ── Storage snapshots (MinIO + Delta) ───────────────────────
CREATE TABLE IF NOT EXISTS storage_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    layer           TEXT NOT NULL,          -- bronze | silver | gold | all
    bucket          TEXT NOT NULL,
    file_count      BIGINT NOT NULL DEFAULT 0,
    size_bytes      BIGINT NOT NULL DEFAULT 0,
    small_file_count BIGINT NOT NULL DEFAULT 0,  -- < 128 MB
    avg_file_size_bytes BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_storage_snapshots_layer_ts ON storage_snapshots(layer, captured_at DESC);

-- ── Delta table stats (per table) ───────────────────────────
CREATE TABLE IF NOT EXISTS delta_table_stats (
    id              BIGSERIAL PRIMARY KEY,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    database_name   TEXT NOT NULL,
    table_name      TEXT NOT NULL,
    layer           TEXT,                   -- inferred from db name or path
    num_files       BIGINT NOT NULL DEFAULT 0,
    size_bytes      BIGINT NOT NULL DEFAULT 0,
    num_partitions  INT NOT NULL DEFAULT 0,
    delta_version   BIGINT,
    last_modified   TIMESTAMPTZ,
    format          TEXT DEFAULT 'delta',
    location        TEXT
);

CREATE INDEX idx_delta_stats_table_ts ON delta_table_stats(database_name, table_name, captured_at DESC);

-- ── Pipeline / Spark job runs ────────────────────────────────
CREATE TABLE IF NOT EXISTS pipeline_runs (
    id              BIGSERIAL PRIMARY KEY,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    app_id          TEXT NOT NULL,
    app_name        TEXT,
    status          TEXT NOT NULL,          -- SUCCEEDED | FAILED | RUNNING
    start_time      TIMESTAMPTZ,
    end_time        TIMESTAMPTZ,
    duration_ms     BIGINT,
    num_stages      INT DEFAULT 0,
    num_tasks       INT DEFAULT 0,
    failed_tasks    INT DEFAULT 0,
    shuffle_read_bytes  BIGINT DEFAULT 0,
    shuffle_write_bytes BIGINT DEFAULT 0
);

CREATE INDEX idx_pipeline_runs_status_ts ON pipeline_runs(status, captured_at DESC);

-- ── Delta operation history (WRITE/OPTIMIZE/VACUUM/MERGE) ────
CREATE TABLE IF NOT EXISTS delta_operations (
    id              BIGSERIAL PRIMARY KEY,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    database_name   TEXT NOT NULL,
    table_name      TEXT NOT NULL,
    version         BIGINT NOT NULL,
    operation       TEXT NOT NULL,          -- WRITE | OPTIMIZE | VACUUM | MERGE
    timestamp       TIMESTAMPTZ,
    user_name       TEXT,
    num_output_files BIGINT DEFAULT 0,
    num_removed_files BIGINT DEFAULT 0,
    num_output_bytes  BIGINT DEFAULT 0
);

CREATE UNIQUE INDEX idx_delta_ops_uniq ON delta_operations(database_name, table_name, version);

-- ── Catalog summary (Hive Metastore) ────────────────────────
CREATE TABLE IF NOT EXISTS catalog_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_databases INT DEFAULT 0,
    total_tables    INT DEFAULT 0,
    total_partitions BIGINT DEFAULT 0,
    databases_detail JSONB          -- [{name, table_count, partition_count}]
);

-- ── Convenience views ────────────────────────────────────────

CREATE OR REPLACE VIEW v_storage_by_layer AS
SELECT
    layer,
    bucket,
    file_count,
    size_bytes,
    ROUND(size_bytes::numeric / 1073741824, 2)   AS size_gb,
    small_file_count,
    CASE WHEN file_count > 0
         THEN ROUND(100.0 * small_file_count / file_count, 1)
         ELSE 0 END                              AS small_file_pct,
    avg_file_size_bytes / 1048576                AS avg_file_size_mb,
    captured_at
FROM storage_snapshots
WHERE captured_at = (SELECT MAX(captured_at) FROM storage_snapshots);


CREATE OR REPLACE VIEW v_pipeline_health AS
SELECT
    DATE_TRUNC('hour', captured_at) AS hour,
    COUNT(*)                         AS total_runs,
    SUM(CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE 0 END) AS succeeded,
    SUM(CASE WHEN status = 'FAILED'    THEN 1 ELSE 0 END) AS failed,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),
    1) AS success_rate_pct,
    ROUND(AVG(duration_ms)::numeric / 60000, 1)  AS avg_duration_min
FROM pipeline_runs
WHERE captured_at >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', captured_at)
ORDER BY hour DESC;


CREATE OR REPLACE VIEW v_top_tables_by_size AS
SELECT
    database_name,
    table_name,
    layer,
    num_files,
    ROUND(size_bytes::numeric / 1073741824, 3)  AS size_gb,
    num_partitions,
    delta_version,
    last_modified,
    captured_at
FROM delta_table_stats
WHERE captured_at = (SELECT MAX(captured_at) FROM delta_table_stats)
ORDER BY size_bytes DESC;


CREATE OR REPLACE VIEW v_small_files_alert AS
SELECT
    database_name,
    table_name,
    num_files,
    ROUND(size_bytes::numeric / 1073741824, 3) AS size_gb,
    -- estimate small files per table via avg: if avg < 128MB flag it
    ROUND((size_bytes::numeric / NULLIF(num_files,0)) / 1048576, 1) AS avg_file_mb,
    CASE
        WHEN (size_bytes::numeric / NULLIF(num_files,0)) < 134217728 THEN 'small_files'
        ELSE 'ok'
    END AS status,
    captured_at
FROM delta_table_stats
WHERE captured_at = (SELECT MAX(captured_at) FROM delta_table_stats)
  AND num_files > 0
ORDER BY avg_file_mb ASC;

\echo '✅  metrics_db schema created successfully'
