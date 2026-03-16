# Run (dev): python -m uvicorn main:app --host 0.0.0.0 --port 8000

from fastapi import FastAPI
from upload import router as upload_router
from metrics import router as metrics_router

app = FastAPI(root_path="/datalake")

app.include_router(upload_router)
app.include_router(metrics_router)