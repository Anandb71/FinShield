"""
FinShield API - Legacy Analysis Endpoint (document-only)

This v1 endpoint is kept for basic document analysis compatibility but
no longer exposes any audio-related functionality.
"""

from fastapi import APIRouter, File, UploadFile, HTTPException
from typing import Dict, Any

from app.services.universal_pipeline import get_pipeline


router = APIRouter(prefix="/analyze", tags=["Analysis"])


@router.post("", summary="Analyze a financial document (v1 compatibility)")
async def analyze_document_v1(file: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Analyze a financial document for fraud/predatory patterns.

    This is a thin compatibility wrapper that delegates to the
    universal Backboard-powered document pipeline.
    """
    try:
        content = await file.read()
        pipeline = get_pipeline()
        result = await pipeline.process_document(content, file.filename or "document.pdf")

        if result.get("status") == "failed":
            raise HTTPException(status_code=500, detail=result.get("error", "Analysis failed"))

        return result
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))
