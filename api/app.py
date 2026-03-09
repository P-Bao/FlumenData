from fastapi import FastAPI, UploadFile, File
import boto3
from botocore.client import Config

app = FastAPI()

s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:9000",
    aws_access_key_id="minioadmin",
    aws_secret_access_key="minioadmin123",
    config=Config(signature_version="s3v4"),
    region_name="us-east-1"
)

BUCKET = "lakehouse"

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    key = f"raw/{file.filename}"

    s3.upload_fileobj(
        file.file,
        BUCKET,
        key
    )

    return {
        "message": "Upload successful",
        "bucket": BUCKET,
        "key": key
    }