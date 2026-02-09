"""
FinShield - Dashboard API

Extraction quality metrics and analytics.
"""

from fastapi import APIRouter
from typing import Dict, Any
import logging

from app.services.learning_loop import get_correction_store
from app.services.knowledge_graph import get_knowledge_store

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/metrics")
async def get_dashboard_metrics() -> Dict[str, Any]:
    """
    Get extraction quality dashboard metrics.
    
    Returns:
        Metrics including accuracy, error rate, processing time, etc.
    """
    store = get_correction_store()
    kg_store = get_knowledge_store()

    # Calculate metrics
    total_corrections = len(store.corrections)
    error_rate = store.get_error_rate()
    error_clusters = store.get_error_clusters()
    kg_overview = kg_store.graph_overview()

    # Mock additional metrics (replace with real data in production)
    metrics = {
        "overview": {
            "total_documents_processed": store.total_processed_count,
            "total_corrections": total_corrections,
            "error_rate": error_rate,
            # In a real app we'd track processing time history
            "avg_processing_time": 1.5,
        },
        "knowledge_graph": kg_overview,
        "accuracy_by_type": {
            "invoice": {"accuracy": 0.95, "count": 0},
            "bank_statement": {"accuracy": 0.92, "count": 0},
            "payslip": {"accuracy": 0.88, "count": 0},
        },
        "error_clusters": error_clusters,
        "trends": {
            "last_7_days": {
                "documents": 0,
                "corrections": total_corrections,
                "error_rate": error_rate,
            }
        },
        "top_error_fields": [
            {"field": field, "count": data["count"]}
            for field, data in sorted(
                error_clusters.items(),
                key=lambda x: x[1]["count"],
                reverse=True,
            )[:5]
        ],
    }

    return metrics


@router.get("/health")
async def dashboard_health() -> Dict[str, str]:
    """Dashboard health check."""
    return {"status": "healthy", "service": "dashboard"}
