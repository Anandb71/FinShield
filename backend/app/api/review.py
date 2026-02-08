"""
FinShield - Review API

Endpoints for human review and correction capture.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
import logging

from app.services.learning_loop import get_correction_store

logger = logging.getLogger(__name__)

router = APIRouter()


class CorrectionRequest(BaseModel):
    """Correction request model."""
    document_id: str
    field_name: str
    original_value: Any
    corrected_value: Any
    corrected_by: Optional[str] = "user"


@router.get("/queue")
async def get_review_queue() -> Dict[str, Any]:
    """Get documents needing review."""
    # In production: query database for documents with low confidence
    return {
        "queue": [],
        "count": 0,
        "message": "No documents pending review"
    }


@router.post("/{doc_id}/approve")
async def approve_document(doc_id: str) -> Dict[str, str]:
    """Approve document extraction."""
    logger.info(f"Document {doc_id} approved")
    return {"status": "approved", "document_id": doc_id}


@router.post("/{doc_id}/correct")
async def submit_correction(doc_id: str, correction: CorrectionRequest) -> Dict[str, Any]:
    """
    Submit correction for a field.
    
    This captures human corrections for the learning loop
    AND feeds them back to Backboard for continuous improvement.
    """
    try:
        from app.services.backboard_learning import get_learning_enhancer
        
        store = get_correction_store()
        
        correction_id = store.add_correction(
            document_id=correction.document_id,
            field_name=correction.field_name,
            original_value=correction.original_value,
            corrected_value=correction.corrected_value,
            corrected_by=correction.corrected_by
        )
        
        # Feed correction back to Backboard
        enhancer = get_learning_enhancer()
        corrections = store.get_corrections(document_id=correction.document_id)
        await enhancer.update_document_with_corrections(
            document_id=correction.document_id,
            corrections=corrections
        )
        
        return {
            "status": "success",
            "correction_id": correction_id,
            "message": "Correction captured and fed to Backboard for learning"
        }
        
    except Exception as e:
        logger.error(f"Failed to submit correction: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{doc_id}/history")
async def get_correction_history(doc_id: str) -> Dict[str, Any]:
    """Get correction history for a document."""
    store = get_correction_store()
    corrections = store.get_corrections(document_id=doc_id)
    
    return {
        "document_id": doc_id,
        "corrections": corrections,
        "count": len(corrections)
    }


@router.get("/errors/clusters")
async def get_error_clusters() -> Dict[str, Any]:
    """Get error clusters for analysis."""
    store = get_correction_store()
    clusters = store.get_error_clusters()
    
    return {
        "clusters": clusters,
        "total_corrections": len(store.corrections)
    }
