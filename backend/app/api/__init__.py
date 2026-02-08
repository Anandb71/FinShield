"""FinShield API Router"""

from fastapi import APIRouter

from app.api.v1 import router as v1_router
from app.api import documents, review, dashboard, admin

router = APIRouter(prefix="/api")

router.include_router(v1_router)

# Document Intelligence
router.include_router(
    documents.router,
    prefix="/documents",
    tags=["documents"]
)

# Review & Corrections
router.include_router(
    review.router,
    prefix="/review",
    tags=["review"]
)

# Dashboard & Metrics
router.include_router(
    dashboard.router,
    prefix="/dashboard",
    tags=["dashboard"]
)

# Admin & Learning
router.include_router(
    admin.router,
    prefix="/admin",
    tags=["admin"]
)
