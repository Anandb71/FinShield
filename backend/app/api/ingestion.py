"""
FinShield - Ingestion API

Bulk document upload and ingestion endpoints.

These endpoints are designed for the new Reviewer UI but are fully
backed by the universal Backboard-powered document pipeline and the
shared memory/knowledge stores.
"""

from typing import Any, Dict, List

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.services.universal_pipeline import get_pipeline
from app.services.memory_store import get_memory_store


router = APIRouter()


@router.post("/documents", summary="Bulk-ingest financial documents")
async def ingest_documents(
    files: List[UploadFile] = File(..., description="One or more financial documents"),
) -> Dict[str, Any]:
    """
    Ingest one or more financial documents.

    For each file this will:
    - Run the universal Backboard pipeline
    - Persist the full analysis and raw bytes in the memory store
    - Populate the JSON knowledge graph

    Returns a lightweight summary per document suitable for progress UIs.
    """
    if not files:
        raise HTTPException(status_code=400, detail="At least one file is required")

    pipeline = get_pipeline()
    results: List[Dict[str, Any]] = []

    for upload in files:
        content = await upload.read()
        if not content:
            results.append(
                {
                    "filename": upload.filename or "unknown",
                    "status": "failed",
                    "error": "Empty file",
                }
            )
            continue

        analysis = await pipeline.process_document(content, upload.filename or "document.pdf")
        if analysis.get("status") != "success":
            results.append(
                {
                    "filename": upload.filename or "unknown",
                    "status": "failed",
                    "error": analysis.get("error", "Analysis failed"),
                }
            )
            continue

        results.append(
            {
                "document_id": analysis.get("document_id"),
                "filename": analysis.get("filename"),
                "doc_type": analysis.get("classification", {}).get("type"),
                "confidence": analysis.get("classification", {}).get("confidence"),
                "status": "success",
            }
        )

    return {"documents": results}


@router.get("/documents/{doc_id}", summary="Get ingested document status")
async def get_ingested_document(doc_id: str) -> Dict[str, Any]:
    """
    Return a lightweight view of an ingested document suitable for
    progress and status displays in the ingestion UI.
    """
    store = get_memory_store()
    doc = store.get_document(doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    classification = doc.get("classification", {})
    validation = doc.get("validation", {})

    return {
        "document_id": doc.get("document_id", doc_id),
        "filename": doc.get("filename"),
        "doc_type": classification.get("type"),
        "confidence": classification.get("confidence"),
        "status": doc.get("status"),
        "validation": validation,
    }

