import os

SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "flumen_superset_secret")
CACHE_CONFIG = {"CACHE_TYPE": "SimpleCache"}
DATA_DIR = "/app/superset_home"
ENABLE_PROXY_FIX = True
RESULTS_BACKEND = None
ROW_LIMIT = 5000
FEATURE_FLAGS = {
    "ALLOW_ADHOC_SUBQUERY": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
}
