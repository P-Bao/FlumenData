from typing import Any
from datetime import datetime, date
import os

import trino
from fastapi import APIRouter, HTTPException

router = APIRouter()

TRINO_HOST = os.getenv("TRINO_HOST", "trino")
TRINO_PORT = int(os.getenv("TRINO_PORT", "8080"))
TRINO_USER = os.getenv("TRINO_USER", "trino")
TRINO_CATALOG = os.getenv("TRINO_CATALOG", "hive")
TRINO_SCHEMA = os.getenv("TRINO_SCHEMA", "public")

VIEWS = {
    "kpi": "v_kpi_summary",
    "files_by_layer": "v_files_by_layer",
    "storage": "v_dashboard_storage",
    "top_tables": "v_top_tables",
    "pipeline": "v_pipeline_health_hourly",
    "operations": "v_delta_operations",
    "small_files": "v_small_files_tables",
}

def run_query(sql: str) -> list[dict[str, Any]]:
    conn = trino.dbapi.connect(
        host=TRINO_HOST,
        port=TRINO_PORT,
        user=TRINO_USER,
        catalog=TRINO_CATALOG,
        schema=TRINO_SCHEMA,
    )
    try:
        cur = conn.cursor()
        cur.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = []
        for row in cur.fetchall():
            record = {}
            for col, val in zip(cols, row):
                if isinstance(val, (datetime, date)):
                    record[col] = val.isoformat()
                else:
                    record[col] = val
            rows.append(record)
        return rows
    finally:
        conn.close()


@router.get("/metrics/")
def metrics_index():
    return {
        "endpoints": {slug: f"/metrics/{slug}" for slug in VIEWS}
    }

@router.get("/metrics/{slug}")
def metrics_view(slug: str):
    if slug not in VIEWS:
        raise HTTPException(
            status_code=404,
            detail={"error": f"View '{slug}' không tồn tại.", "available": list(VIEWS.keys())},
        )
    try:
        rows = run_query(f"SELECT * FROM {VIEWS[slug]}")
        return {"view": VIEWS[slug], "count": len(rows), "rows": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail={"error": str(e)})
