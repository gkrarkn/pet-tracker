from fastapi import FastAPI

from app.api.router import api_router
from app.config import settings


app = FastAPI(title=settings.app_name)
app.include_router(api_router)


@app.get("/health", tags=["system"])
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "environment": settings.app_env}
