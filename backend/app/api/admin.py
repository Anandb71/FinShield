"""
FinShield - Admin API

Administrative endpoints for learning management.
"""

from fastapi import APIRouter, HTTPException
from typing import Dict, Any
import logging

from app.services.backboard_learning import get_learning_enhancer

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/learning/sync")
async def sync_learning_to_backboard() -> Dict[str, Any]:
    """
    Manually trigger sync of learning patterns to Backboard.
    
    This creates learning examples from error clusters
    and stores them in Backboard for future reference.
    """
    try:
        enhancer = get_learning_enhancer()
        success = await enhancer.create_learning_examples()
        
        if success:
            return {
                "status": "success",
                "message": "Learning patterns synced to Backboard"
            }
        else:
            raise HTTPException(status_code=500, detail="Sync failed")
            
    except Exception as e:
        logger.error(f"Learning sync failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def admin_health() -> Dict[str, str]:
    """Admin health check."""
    return {"status": "healthy", "service": "admin"}
