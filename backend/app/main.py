"""
FinShield API - Main Application

FastAPI application factory with CORS configuration for Flutter mobile app.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.api import router as api_router
from app.sockets import router as websocket_router


def create_app() -> FastAPI:
    """Application factory."""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="🛡️ FinShield - The Financial Flight Recorder API",
        docs_url="/docs",
        redoc_url="/redoc",
        debug=settings.debug,
    )

    # Configure CORS for Flutter app
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Allow all origins for development
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include REST API routes
    app.include_router(api_router)
    
    # Include WebSocket routes
    app.include_router(websocket_router)

    @app.get("/")
    async def root():
        """Root endpoint - API information."""
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "status": "operational",
            "docs": "/docs",
            "health": "/api/v1/health",
            "websocket": "/ws/stream/{client_id}",
        }

    return app


# Create application instance
app = create_app()
