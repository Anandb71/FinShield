"""Finsight API Router"""

from fastapi import APIRouter

from app.api import health, documents, ingestion, review, dashboard, learning, knowledge, forensics

router = APIRouter(prefix="/api")

router.include_router(health.router, tags=["health"])
router.include_router(documents.router, tags=["documents"])
router.include_router(ingestion.router, tags=["ingestion"])
router.include_router(review.router, tags=["review"])
router.include_router(dashboard.router, tags=["dashboard"])
router.include_router(learning.router, tags=["learning"])
router.include_router(knowledge.router, prefix="/knowledge", tags=["knowledge"])
router.include_router(forensics.router, prefix="/forensics", tags=["forensics"])
