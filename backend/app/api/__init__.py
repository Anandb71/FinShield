"""FinShield API Router"""

from fastapi import APIRouter

from app.api.v1 import router as v1_router
from app.api import documents, review, dashboard, admin, ingestion, knowledge, learning

router = APIRouter(prefix="/api")

# Legacy v1 routes (health + document analysis compatibility)
router.include_router(v1_router)

# Ingestion
router.include_router(
    ingestion.router,
    prefix="/ingestion",
    tags=["ingestion"],
)

# Document Intelligence
router.include_router(
    documents.router,
    prefix="/documents",
    tags=["documents"],
)

# Review & Corrections
router.include_router(
    review.router,
    prefix="/review",
    tags=["review"],
)

# Knowledge Graph
router.include_router(
    knowledge.router,
    prefix="/knowledge",
    tags=["knowledge"],
)

# Dashboard & Metrics
router.include_router(
    dashboard.router,
    prefix="/dashboard",
    tags=["dashboard"],
)

# Learning Loop
router.include_router(
    learning.router,
    prefix="/learning",
    tags=["learning"],
)

# Admin
router.include_router(
    admin.router,
    prefix="/admin",
    tags=["admin"],
)
