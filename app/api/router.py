from fastapi import APIRouter

from app.api.v1 import auth, menu, nutrition, allergy, report, settings

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(menu.router)
api_router.include_router(nutrition.router)
api_router.include_router(allergy.router)
api_router.include_router(report.router)
api_router.include_router(settings.router)
