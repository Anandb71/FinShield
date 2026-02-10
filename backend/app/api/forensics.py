"""
Aegis - Anomalies & Batch Status API

Endpoints:
  GET  /api/anomalies/{doc_id}    - List all anomalies for a document
  GET  /api/anomalies/summary     - Aggregate anomaly stats across all docs
  GET  /api/status/{batch_id}     - Polling endpoint for batch processing status
"""

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from app.db.models import Anomaly, Document, Transaction
from app.db.session import get_session

router = APIRouter()


# ── Anomalies ────────────────────────────────────────────────────────

@router.get("/anomalies/summary", summary="Aggregate anomaly statistics")
async def get_anomaly_summary(
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    anomalies = session.exec(select(Anomaly)).all()
    
    by_type: Dict[str, int] = {}
    by_severity: Dict[str, int] = {"critical": 0, "warning": 0, "info": 0}
    by_document: Dict[str, int] = {}

    for a in anomalies:
        by_type[a.anomaly_type] = by_type.get(a.anomaly_type, 0) + 1
        by_severity[a.severity] = by_severity.get(a.severity, 0) + 1
        by_document[a.document_id] = by_document.get(a.document_id, 0) + 1

    return {
        "total_anomalies": len(anomalies),
        "by_type": by_type,
        "by_severity": by_severity,
        "documents_affected": len(by_document),
        "top_documents": sorted(
            [{"document_id": k, "count": v} for k, v in by_document.items()],
            key=lambda x: x["count"],
            reverse=True,
        )[:10],
    }


@router.get("/anomalies/{doc_id}", summary="Get anomalies for a document")
async def get_document_anomalies(
    doc_id: str,
    severity: Optional[str] = Query(default=None, description="Filter by severity: critical, warning, info"),
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    query = select(Anomaly).where(Anomaly.document_id == doc_id)
    if severity:
        query = query.where(Anomaly.severity == severity)

    anomalies = session.exec(query).all()

    return {
        "document_id": doc_id,
        "filename": doc.filename,
        "anomalies": [
            {
                "id": a.id,
                "type": a.anomaly_type,
                "severity": a.severity,
                "description": a.description,
                "details": a.details,
                "row_index": a.row_index,
                "transaction_id": a.transaction_id,
                "created_at": a.created_at.isoformat(),
            }
            for a in anomalies
        ],
        "count": len(anomalies),
        "by_severity": {
            "critical": sum(1 for a in anomalies if a.severity == "critical"),
            "warning": sum(1 for a in anomalies if a.severity == "warning"),
            "info": sum(1 for a in anomalies if a.severity == "info"),
        },
    }


# ── Transactions ─────────────────────────────────────────────────────

@router.get("/documents/{doc_id}/transactions", summary="Get extracted transactions")
async def get_document_transactions(
    doc_id: str,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    transactions = session.exec(
        select(Transaction).where(Transaction.document_id == doc_id)
    ).all()

    return {
        "document_id": doc_id,
        "transactions": [
            {
                "id": t.id,
                "row_index": t.row_index,
                "date": t.date,
                "description": t.description,
                "amount": t.amount,
                "type": t.tx_type,
                "balance_after": t.balance_after,
                "merchant_normalized": t.merchant_normalized,
                "category": t.category,
                "is_anomaly": t.is_anomaly,
                "anomaly_tags": t.anomaly_tags,
            }
            for t in transactions
        ],
        "count": len(transactions),
    }


# ── Batch Status ─────────────────────────────────────────────────────

@router.get("/status/{batch_id}", summary="Get batch processing status")
async def get_batch_status(
    batch_id: str,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    docs = session.exec(
        select(Document).where(Document.batch_id == batch_id)
    ).all()

    if not docs:
        raise HTTPException(status_code=404, detail="Batch not found")

    total = len(docs)
    completed = sum(1 for d in docs if d.status in ("processed", "review", "failed"))
    processing = sum(1 for d in docs if d.status == "processing")
    failed = sum(1 for d in docs if d.status == "failed")
    review = sum(1 for d in docs if d.status == "review")

    return {
        "batch_id": batch_id,
        "total": total,
        "completed": completed,
        "processing": processing,
        "failed": failed,
        "review": review,
        "progress": round(completed / total, 2) if total > 0 else 0,
        "status": "complete" if completed == total else "processing",
        "documents": [
            {
                "document_id": d.id,
                "filename": d.filename,
                "status": d.status,
                "doc_type": d.doc_type,
                "confidence": d.confidence,
                "processing_time_ms": d.processing_time_ms,
            }
            for d in docs
        ],
    }
