from dataclasses import dataclass
from uuid import UUID, uuid4

from app.config import settings


@dataclass
class UploadTarget:
    provider: str
    upload_url: str
    public_url: str
    method: str
    fields: dict[str, str]
    storage_key: str


class StorageService:
    def create_upload_target(self, *, user_id: UUID, filename: str, content_type: str) -> UploadTarget:
        raise NotImplementedError


class S3StorageService(StorageService):
    def create_upload_target(self, *, user_id: UUID, filename: str, content_type: str) -> UploadTarget:
        del content_type
        storage_key = f"users/{user_id}/uploads/{uuid4()}/{filename}"
        base = settings.s3_public_base_url or "https://s3.amazonaws.com"
        bucket = settings.s3_bucket_name or "digital-wardrobe-assets"
        return UploadTarget(
            provider="s3",
            upload_url=f"{base}/{bucket}/{storage_key}",
            public_url=f"{base}/{bucket}/{storage_key}",
            method="PUT",
            fields={},
            storage_key=storage_key,
        )


class CloudinaryStorageService(StorageService):
    def create_upload_target(self, *, user_id: UUID, filename: str, content_type: str) -> UploadTarget:
        del content_type
        cloud_name = settings.cloudinary_cloud_name or "demo"
        storage_key = f"users/{user_id}/{uuid4()}-{filename}"
        return UploadTarget(
            provider="cloudinary",
            upload_url=f"https://api.cloudinary.com/v1_1/{cloud_name}/image/upload",
            public_url=f"https://res.cloudinary.com/{cloud_name}/image/upload/{storage_key}",
            method="POST",
            fields={"folder": f"users/{user_id}", "public_id": storage_key},
            storage_key=storage_key,
        )


def get_storage_service() -> StorageService:
    if settings.storage_backend == "cloudinary":
        return CloudinaryStorageService()
    return S3StorageService()
