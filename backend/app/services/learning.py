from __future__ import annotations

from typing import Any, Dict, List

from sqlmodel import Session, select

from app.core.config import get_settings
from app.db.models import Correction, LearningEvent, Document


def build_correction_summary(correction: Correction) -> str:
    return (
        "Human correction received:\n"
        f"Document ID: {correction.document_id}\n"
        f"Field: {correction.field_name}\n"
        f"Original: {correction.original_value}\n"
        f"Corrected: {correction.corrected_value}\n"
        "Please use this correction for future extractions."
    )


def cluster_corrections(session: Session, limit: int = 5) -> Dict[str, Any]:
    corrections = session.exec(select(Correction)).all()
    clusters: Dict[str, Dict[str, Any]] = {}

    for corr in corrections:
        cluster = clusters.setdefault(
            corr.field_name,
            {"count": 0, "examples": []},
        )
        cluster["count"] += 1
        if len(cluster["examples"]) < limit:
            cluster["examples"].append(
                {
                    "original": corr.original_value,
                    "corrected": corr.corrected_value,
                    "document_id": corr.document_id,
                }
            )

    return {
        "clusters": clusters,
        "total_corrections": len(corrections),
    }


def check_learning_triggers(session: Session) -> Dict[str, Any]:
    settings = get_settings()
    corrections = session.exec(select(Correction)).all()
    documents = session.exec(select(Document)).all()

    total_docs = len(documents)
    total_corrections = len(corrections)
    error_rate = (total_corrections / total_docs) if total_docs else 0.0

    events: list[LearningEvent] = []
    if total_corrections >= getattr(settings, "learning_corrections_threshold", 100):
        events.append(
            LearningEvent(
                event_type="correction_threshold",
                payload={"total_corrections": total_corrections},
            )
        )

    if error_rate >= getattr(settings, "learning_error_rate_threshold", 0.1):
        events.append(
            LearningEvent(
                event_type="error_rate_threshold",
                payload={"error_rate": error_rate},
            )
        )

    for event in events:
        session.add(event)
    if events:
        session.commit()

    return {
        "events": [
            {"event_type": e.event_type, "payload": e.payload, "created_at": e.created_at.isoformat()}
            for e in events
        ],
        "total_corrections": total_corrections,
        "error_rate": error_rate,
    }
