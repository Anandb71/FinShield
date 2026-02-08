"""
FinShield API - Health Check Endpoint

Simple health check for service monitoring and Flutter app connection verification.
"""

from datetime import datetime
from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("")
async def health_check():
    """
    Health check endpoint.
    
    Returns service status, version, and timestamp.
    Used by Flutter app to verify backend connectivity.
    """
    return {
        "status": "healthy",
        "service": "finshield-api",
        "version": "0.1.0",
        "timestamp": datetime.utcnow().isoformat(),
        "components": {
            "audio_analyzer": "operational",
            "document_scanner": "operational",
            "context_engine": "operational",
        }
    }


@router.get("/ready")
async def readiness_check():
    """
    Kubernetes-style readiness probe.
    
    Returns whether the service is ready to accept traffic.
    """
    return {"ready": True}


@router.get("/live")
async def liveness_check():
    """
    Kubernetes-style liveness probe.
    
    Returns whether the service is alive and running.
    """
    return {"alive": True}
