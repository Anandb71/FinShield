"""
FinShield - Review API

Endpoints for human review and correction capture.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
import logging

from app.services.learning_loop import get_correction_store
from app.services.memory_store import get_memory_store
from app.services.knowledge_graph import get_knowledge_store

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
    store = get_memory_store()
    queue = store.get_review_queue()
    
    return {
        "queue": queue,
        "count": len(queue),
        "message": f"{len(queue)} documents pending review"
    }


@router.post("/{doc_id}/approve")
async def approve_document(doc_id: str) -> Dict[str, str]:
    """Approve document extraction."""
    from app.services.memory_store import get_memory_store
    
    # In a real app we'd mark the doc as verified in DB
    # Here we just remove from the queue
    store = get_memory_store()
    
    # We need to know WHICH field to approve, but the current API only sends doc_id
    # So we'll clear ALL review items for this doc_id
    queue = store.get_review_queue()
    to_remove = [item for item in queue if item["doc_id"] == doc_id]
    
    for item in to_remove:
        store.remove_from_review(doc_id, item["field"])
        
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

        # Optionally create/refresh learning examples for high-volume patterns
        await enhancer.create_learning_examples()

        # Update knowledge graph slice with corrected value on the document node
        try:
            kg_store = get_knowledge_store()
            graph = kg_store.get_document_graph(correction.document_id)
            if graph:
                for node in graph.nodes:
                    if node.type == "Document" and node.id == correction.document_id:
                        node.properties[correction.field_name] = correction.corrected_value
                kg_store.upsert_document_graph(graph)
        except Exception as kg_exc:
            logger.error(f"Failed to update knowledge graph with correction: {kg_exc}")

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
