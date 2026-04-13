from fastapi import APIRouter

from app.api.routes import auth, consultancy, outfits, wardrobe


api_router = APIRouter(prefix="/api")
api_router.include_router(auth.router)
api_router.include_router(wardrobe.router)
api_router.include_router(outfits.router)
api_router.include_router(consultancy.router)
