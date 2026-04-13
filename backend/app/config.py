from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Digital Wardrobe API"
    app_env: str = "development"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/digital_wardrobe"
    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_exp_minutes: int = 60
    refresh_token_exp_days: int = 30
    storage_backend: str = "s3"
    s3_bucket_name: str | None = None
    s3_region: str | None = None
    s3_public_base_url: str | None = None
    cloudinary_cloud_name: str | None = None
    cloudinary_api_key: str | None = None
    cloudinary_api_secret: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
