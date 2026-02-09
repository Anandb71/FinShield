"""Finsight - Document Intelligence API."""

from typing import Any, Dict

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.responses import Response
from sqlmodel import Session

from app.core.config import get_settings
from app.db.session import get_session
from app.db.models import Document
from app.services.backboard_client import BackboardClient
from app.services.entity_resolution import resolve_entities
from app.services.storage import save_file, read_file
from app.services.file_preprocess import normalize_input
from app.services.quality import score_image_quality
from app.services.layout import detect_layout_flags
from app.services.knowledge_graph import build_graph_from_document, get_knowledge_store, KGNode
from app.services.validation import run_validations

router = APIRouter(prefix="/documents")


@router.post("/analyze")
async def analyze_document(
    file: UploadFile = File(...),
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    settings = get_settings()

    if not file.filename:
        raise HTTPException(status_code=400, detail="Filename is required.")

    content = await file.read()
    max_bytes = settings.max_upload_mb * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=413, detail="File too large.")

    quality_metrics = score_image_quality(content)
    local_layout = detect_layout_flags(content)
    normalized = normalize_input(file.filename, content)

    client = BackboardClient()
    try:
        result = await client.analyze_document(
            normalized.normalized_bytes,
            normalized.normalized_name,
            mime_type=normalized.normalized_mime,
            fallback_bytes=normalized.original_bytes if normalized.converted else None,
            fallback_filename=normalized.original_name if normalized.converted else None,
            fallback_mime=normalized.original_mime if normalized.converted else None,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    classification = result.get("classification", {})
    extracted_fields = result.get("extracted_fields", {})
    remote_layout = result.get("layout", {})
    layout_flags = {**local_layout, **remote_layout}
    parse_error = result.get("parse_error")
    backboard_thread_id = result.get("document_id")

    errors, warnings, consistency = run_validations(
        classification.get("type", "unknown"),
        extracted_fields,
        session,
    )
    if parse_error:
        warnings.append({"field": "backboard", "message": parse_error})

    confidence = classification.get("confidence") or 0.0
    image_quality = classification.get("image_quality_score") or quality_metrics.get("score")
    status = "processed"
    if errors:
        status = "review"
    if confidence < settings.review_confidence_threshold:
        status = "review"
    if image_quality is not None and image_quality < settings.review_quality_threshold:
        status = "review"
    if classification.get("type") in (None, "unknown"):
        status = "review"

    doc = Document(
        filename=normalized.normalized_name,
        backboard_thread_id=backboard_thread_id,
        doc_type=classification.get("type", "unknown"),
        confidence=confidence,
        language=classification.get("language"),
        image_quality=image_quality,
        status=status,
        layout_flags=layout_flags,
        quality_metrics=quality_metrics,
        extracted_fields=extracted_fields,
        validation_errors=errors,
        validation_warnings=warnings,
        consistency=consistency,
    )
    doc.file_path = save_file(doc.id, normalized.normalized_name, normalized.normalized_bytes)
    session.add(doc)
    session.commit()
    session.refresh(doc)

    entities = resolve_entities(session, doc.id, extracted_fields)
    entity_nodes = [
        KGNode(
            id=entity.id,
            type=entity.entity_type,
            properties={"canonical_value": entity.canonical_value},
        )
        for entity in entities
    ]
    graph = build_graph_from_document(doc.id, doc.doc_type, extracted_fields, entity_nodes)
    get_knowledge_store().upsert_document_graph(graph)

    return {
        "document_id": doc.id,
        "filename": doc.filename,
        "classification": classification,
        "extracted_fields": extracted_fields,
        "layout": layout_flags,
        "quality_metrics": quality_metrics,
        "validation": {"valid": len(errors) == 0, "errors": errors, "warnings": warnings},
        "consistency_check": consistency,
        "status": status,
        "error": parse_error,
    }


@router.get("/{doc_id}")
async def get_document(doc_id: str, session: Session = Depends(get_session)) -> Dict[str, Any]:
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    graph = get_knowledge_store().get_document_graph(doc.id)

    return {
        "document_id": doc.id,
        "filename": doc.filename,
        "classification": {
            "type": doc.doc_type,
            "confidence": doc.confidence,
            "language": doc.language,
            "image_quality_score": doc.image_quality,
        },
        "layout": doc.layout_flags,
        "quality_metrics": doc.quality_metrics,
        "extracted_fields": doc.extracted_fields,
        "validation": {
            "valid": len(doc.validation_errors) == 0,
            "errors": doc.validation_errors,
            "warnings": doc.validation_warnings,
        },
        "consistency_check": doc.consistency,
        "status": doc.status,
        "knowledge_graph": graph.model_dump() if graph else None,
    }


@router.get("/{doc_id}/file")
async def get_document_file(doc_id: str, session: Session = Depends(get_session)):
    doc = session.get(Document, doc_id)
    if not doc or not doc.file_path:
        raise HTTPException(status_code=404, detail="File not found")

    content = read_file(doc.file_path)
    media_type = "application/pdf" if doc.filename.lower().endswith(".pdf") else "application/octet-stream"
    return Response(content=content, media_type=media_type)
