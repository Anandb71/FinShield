"""
FinShield - Admin API

Administrative endpoints for learning management and system status.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import Dict, Any, List
import logging

from app.db.session import get_session
from app.db.models import LearningEvent, Correction, Document
from app.services.backboard_learning import get_learning_enhancer
from app.services.learning import cluster_corrections

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin")


@router.post("/learning/sync")
async def sync_learning_to_backboard(
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """
    Manually trigger sync of learning patterns to Backboard.

    Clusters corrections by field, builds learning messages, and
    posts them into the relevant Backboard threads.
    """
    try:
        enhancer = get_learning_enhancer()
        result = await enhancer.sync_learning_patterns(session)
        return {"status": "success", **result}
    except Exception as e:
        logger.error("Learning sync failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/learning/status")
async def get_learning_status(
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """
    Return a snapshot of the learning system's state:
    total corrections, clusters, recent events, error rate.
    """
    corrections: List[Correction] = list(session.exec(select(Correction)).all())
    documents: List[Document] = list(session.exec(select(Document)).all())
    events: List[LearningEvent] = list(
        session.exec(
            select(LearningEvent)
            .order_by(LearningEvent.created_at.desc())  # type: ignore[union-attr]
        ).all()
    )

    total_docs = len(documents)
    total_corrections = len(corrections)
    error_rate = (total_corrections / total_docs) if total_docs else 0.0

    cluster_data = cluster_corrections(session)

    enhancer = get_learning_enhancer()
    ready_to_sync = enhancer.should_auto_sync(session)

    return {
        "total_documents": total_docs,
        "total_corrections": total_corrections,
        "error_rate": round(error_rate, 4),
        "ready_to_sync": ready_to_sync,
        "clusters": cluster_data["clusters"],
        "recent_events": [
            {
                "event_type": e.event_type,
                "payload": e.payload,
                "created_at": e.created_at.isoformat(),
            }
            for e in events[:10]
        ],
    }


@router.get("/health")
async def admin_health() -> Dict[str, str]:
    """Admin health check."""
    return {"status": "healthy", "service": "admin"}
