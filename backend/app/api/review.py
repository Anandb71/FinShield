"""Finsight - Review & corrections API."""

from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select, delete

from app.db.models import Correction, Document
from app.db.session import get_session
from app.services.backboard_client import BackboardClient
from app.services.file_preprocess import normalize_input
from app.services.layout import detect_layout_flags
from app.services.quality import score_image_quality
from app.services.storage import read_file
from app.services.validation import run_validations
from app.services.learning import build_correction_summary, check_learning_triggers

router = APIRouter(prefix="/review")


class CorrectionRequest(BaseModel):
    document_id: str
    field_name: str
    original_value: Any
    corrected_value: Any
    corrected_by: Optional[str] = "user"


@router.get("/queue")
async def get_review_queue(session: Session = Depends(get_session)) -> Dict[str, Any]:
    queue = session.exec(select(Document).where(Document.status == "review")).all()
    return {
        "queue": [
            {
                "document_id": doc.id,
                "filename": doc.filename,
                "doc_type": doc.doc_type,
                "confidence": doc.confidence,
                "status": doc.status,
                "validation_errors": doc.validation_errors,
                "validation_warnings": doc.validation_warnings,
            }
            for doc in queue
        ],
        "count": len(queue),
        "message": f"{len(queue)} documents pending review",
    }


@router.delete("/queue")
async def clear_review_queue(
    mode: Optional[str] = "mark_processed",
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    docs = session.exec(select(Document).where(Document.status == "review")).all()
    if mode == "purge":
        for doc in docs:
            session.exec(delete(Correction).where(Correction.document_id == doc.id))
            session.delete(doc)
    else:
        for doc in docs:
            doc.status = "processed"
            doc.validation_errors = []
            doc.validation_warnings = []
            session.add(doc)

    session.commit()
    return {
        "cleared": len(docs),
        "mode": mode,
        "message": f"Cleared {len(docs)} review documents",
    }


@router.post("/{doc_id}/approve")
async def approve_document(doc_id: str, session: Session = Depends(get_session)) -> Dict[str, str]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    doc.status = "processed"
    session.add(doc)
    session.commit()
    return {"status": "approved", "document_id": doc_id}


@router.post("/{doc_id}/reanalyze")
async def reanalyze_document(doc_id: str, session: Session = Depends(get_session)) -> Dict[str, Any]:
    doc = session.get(Document, doc_id)
    if not doc or not doc.file_path:
        raise HTTPException(status_code=404, detail="Document not found")

    file_bytes = read_file(doc.file_path)
    normalized = normalize_input(doc.filename, file_bytes)
    quality_metrics = score_image_quality(normalized.normalized_bytes)
    local_layout = detect_layout_flags(normalized.normalized_bytes)

    client = BackboardClient()
    analysis = await client.analyze_document(
        normalized.normalized_bytes,
        normalized.normalized_name,
        mime_type=normalized.normalized_mime,
        fallback_bytes=normalized.original_bytes if normalized.converted else None,
        fallback_filename=normalized.original_name if normalized.converted else None,
        fallback_mime=normalized.original_mime if normalized.converted else None,
    )

    classification = analysis.get("classification", {})
    extracted_fields = analysis.get("extracted_fields", {})
    remote_layout = analysis.get("layout", {})
    layout_flags = {**local_layout, **remote_layout}
    parse_error = analysis.get("parse_error")
    errors, warnings, consistency = run_validations(
        classification.get("type", "unknown"),
        extracted_fields,
        session,
    )
    if parse_error:
        warnings.append({"field": "backboard", "message": parse_error})

    confidence = classification.get("confidence") or 0.0
    image_quality = classification.get("image_quality_score") or quality_metrics.get("score")

    doc.backboard_thread_id = analysis.get("document_id") or doc.backboard_thread_id
    doc.doc_type = classification.get("type", "unknown")
    doc.confidence = confidence
    doc.language = classification.get("language")
    doc.image_quality = image_quality
    doc.layout_flags = layout_flags
    doc.quality_metrics = quality_metrics
    doc.extracted_fields = extracted_fields
    doc.validation_errors = errors
    doc.validation_warnings = warnings
    doc.consistency = consistency

    doc.status = "processed"
    if errors:
        doc.status = "review"
    if classification.get("type") in (None, "unknown"):
        doc.status = "review"

    session.add(doc)
    session.commit()
    session.refresh(doc)

    return {
        "status": "reanalyzed",
        "document_id": doc.id,
        "doc_type": doc.doc_type,
        "confidence": doc.confidence,
        "review_status": doc.status,
        "warnings": doc.validation_warnings,
    }


@router.post("/{doc_id}/reject")
async def reject_document(doc_id: str, session: Session = Depends(get_session)) -> Dict[str, str]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    doc.status = "failed"
    session.add(doc)
    session.commit()
    return {"status": "rejected", "document_id": doc_id}


@router.post("/{doc_id}/correct")
async def submit_correction(
    doc_id: str,
    correction: CorrectionRequest,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    correction_record = Correction(
        document_id=correction.document_id,
        field_name=correction.field_name,
        original_value=str(correction.original_value) if correction.original_value is not None else None,
        corrected_value=str(correction.corrected_value) if correction.corrected_value is not None else None,
        corrected_by=correction.corrected_by,
    )
    session.add(correction_record)
    session.commit()
    session.refresh(correction_record)

    if doc.backboard_thread_id:
        client = BackboardClient()
        summary = build_correction_summary(correction_record)
        try:
            await client.submit_correction(doc.backboard_thread_id, summary)
        except Exception as exc:
            raise HTTPException(status_code=502, detail=str(exc)) from exc

    learning = check_learning_triggers(session)

    return {
        "status": "success",
        "correction_id": correction_record.id,
        "message": "Correction captured and sent to Backboard for learning",
        "learning": learning,
    }


@router.get("/{doc_id}/history")
async def get_correction_history(
    doc_id: str, session: Session = Depends(get_session)
) -> Dict[str, Any]:
    corrections = session.exec(
        select(Correction).where(Correction.document_id == doc_id)
    ).all()
    return {
        "document_id": doc_id,
        "corrections": [
            {
                "field_name": corr.field_name,
                "original_value": corr.original_value,
                "corrected_value": corr.corrected_value,
                "corrected_by": corr.corrected_by,
                "created_at": corr.created_at.isoformat(),
            }
            for corr in corrections
        ],
        "count": len(corrections),
    }
