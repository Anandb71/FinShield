"""
FinShield - Document Intelligence API

API endpoints for document analysis.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from typing import Dict, Any
import logging

from app.services.document_intelligence_pipeline import get_pipeline

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/analyze")
async def analyze_document(file: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Analyze document using Backboard ML pipeline.
    
    Process:
    1. OCR and text extraction
    2. Auto-classify document type
    3. Layout detection (tables, headers, stamps)
    4. Schema-aware extraction
    5. Validation
    6. Store in knowledge graph
    7. Cross-document consistency check
    
    Returns:
        Complete analysis with extracted fields and validation
    """
    try:
        file_bytes = await file.read()
        logger.info(f"Received: {file.filename} ({len(file_bytes)} bytes)")
        
        pipeline = get_pipeline()
        result = await pipeline.process_document(file_bytes, file.filename)
        
        if result["status"] == "failed":
            raise HTTPException(status_code=500, detail=result.get("error"))
        
        return result
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check."""
    return {"status": "healthy", "service": "document-intelligence"}
