from fastapi import APIRouter, UploadFile, File
import boto3
from botocore.client import Config

router = APIRouter()

s3 = boto3.client(
    "s3",
    endpoint_url="http://minio:9000",
    aws_access_key_id="minioadmin",
    aws_secret_access_key="minioadmin123",
    config=Config(signature_version="s3v4"),
    region_name="us-east-1"
)

BUCKET = "lakehouse"

@router.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    key = f"bronze/{file.filename}"

    s3.upload_fileobj(file.file, BUCKET, key)

    return {"message": "Upload successful", "bucket": BUCKET, "key": key}