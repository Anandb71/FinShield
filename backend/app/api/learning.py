"""
FinShield - Learning Loop API

Thin facade over the correction store for analytics-style access
to clustered extraction errors.
"""

from typing import Any, Dict

from fastapi import APIRouter

from app.services.learning_loop import get_correction_store


router = APIRouter()


@router.get("/errors/clusters", summary="Get clustered extraction errors")
async def get_error_clusters() -> Dict[str, Any]:
    """
    Return error clusters aggregated from human corrections.

    This mirrors the data exposed via the review API but under a
    learning-focused namespace for dashboards and analytics.
    """
    store = get_correction_store()
    clusters = store.get_error_clusters()
    return {
        "clusters": clusters,
        "total_corrections": len(store.corrections),
    }

