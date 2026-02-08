"""
FinShield API - WebSocket Handler

Real-time audio streaming pipeline for fraud detection.
This is the "Nervous System" - connects Flutter mic to Python AI.
"""

import json
import asyncio
from datetime import datetime
from typing import Dict, Optional
from fastapi import WebSocket, WebSocketDisconnect
from dataclasses import dataclass, field

from app.services.audio_processor import get_audio_processor
from app.services.document_engine import get_document_engine


@dataclass
class ClientSession:
    """Active client session metadata."""
    client_id: str
    websocket: WebSocket
    connected_at: datetime = field(default_factory=datetime.utcnow)
    bytes_received: int = 0
    chunks_processed: int = 0
    current_risk_score: float = 0.0
    is_active: bool = True


class ConnectionManager:
    """
    Manages active WebSocket connections.
    
    Handles:
    - Connection lifecycle (connect/disconnect)
    - Broadcasting to multiple clients
    - Session tracking and metrics
    """

    def __init__(self):
        self.active_connections: Dict[str, ClientSession] = {}
        self._lock = asyncio.Lock()

    async def connect(self, client_id: str, websocket: WebSocket) -> ClientSession:
        """Accept and register a new WebSocket connection."""
        await websocket.accept()
        
        session = ClientSession(
            client_id=client_id,
            websocket=websocket,
        )
        
        async with self._lock:
            # Disconnect existing session with same ID if exists
            if client_id in self.active_connections:
                await self.disconnect(client_id)
            self.active_connections[client_id] = session
        
        print(f"🔌 Client connected: {client_id}")
        return session

    async def disconnect(self, client_id: str) -> None:
        """Remove a client connection."""
        async with self._lock:
            if client_id in self.active_connections:
                session = self.active_connections[client_id]
                session.is_active = False
                del self.active_connections[client_id]
                print(f"🔌 Client disconnected: {client_id} (processed {session.chunks_processed} chunks, {session.bytes_received} bytes)")

    async def send_json(self, client_id: str, data: dict) -> bool:
        """Send JSON message to specific client."""
        if client_id in self.active_connections:
            session = self.active_connections[client_id]
            try:
                await session.websocket.send_json(data)
                return True
            except Exception as e:
                print(f"❌ Error sending to {client_id}: {e}")
                return False
        return False

    async def broadcast(self, data: dict) -> None:
        """Send message to all connected clients."""
        for client_id in list(self.active_connections.keys()):
            await self.send_json(client_id, data)

    def get_session(self, client_id: str) -> Optional[ClientSession]:
        """Get session by client ID."""
        return self.active_connections.get(client_id)

    @property
    def connection_count(self) -> int:
        """Number of active connections."""
        return len(self.active_connections)


# Global connection manager instance
manager = ConnectionManager()


async def handle_audio_stream(websocket: WebSocket, client_id: str) -> None:
    """
    Main WebSocket handler for real-time audio streaming.
    
    Protocol:
    1. Client connects with unique client_id
    2. Client streams binary audio chunks (Int16 PCM)
    3. Server processes chunks and returns risk analysis
    4. Loop continues until disconnect
    
    Expected client message: Binary audio data (Int16 PCM)
    Server response: {"status": "listening", "risk_score": 0.0, ...}
    """
    
    # Get service instances (will be filled by Sreedev/Anupam)
    audio_processor = get_audio_processor()
    
    # Connect client
    session = await manager.connect(client_id, websocket)
    
    try:
        # Send initial connection confirmation
        await websocket.send_json({
            "status": "connected",
            "client_id": client_id,
            "message": "FinShield audio stream ready",
            "timestamp": datetime.utcnow().isoformat(),
        })
        
        # Main processing loop
        while session.is_active:
            try:
                # Receive binary audio chunk from Flutter
                audio_chunk = await websocket.receive_bytes()
                chunk_size = len(audio_chunk)
                
                # Update session metrics
                session.bytes_received += chunk_size
                session.chunks_processed += 1
                
                # Log receipt (mock processing for now)
                print(f"📡 [{client_id}] Received {chunk_size} bytes (chunk #{session.chunks_processed})")
                
                # Process audio through the processor (stub for now)
                # TODO: Sreedev will implement real processing
                result = await audio_processor.process_chunk(audio_chunk)
                
                # Update risk score from processor result
                session.current_risk_score = result.get("risk_score", 0.0)
                
                # Send response back to Flutter
                response = {
                    "status": "listening",
                    "risk_score": session.current_risk_score,
                    "threat_level": result.get("threat_level", "safe"),
                    "chunk_id": session.chunks_processed,
                    "bytes_processed": session.bytes_received,
                    "flags": result.get("flags", []),
                    "transcript": result.get("transcript_snippet", ""),
                    "intent": result.get("intent", "UNKNOWN"),
                    "stress_score": result.get("stress_score", 0.0),
                    "timestamp": datetime.utcnow().isoformat(),
                }
                
                await websocket.send_json(response)
                
            except WebSocketDisconnect:
                print(f"📴 Client {client_id} disconnected")
                break
            except Exception as e:
                print(f"❌ Error processing chunk from {client_id}: {e}")
                # Send error but keep connection alive
                await websocket.send_json({
                    "status": "error",
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat(),
                })
                
    finally:
        await manager.disconnect(client_id)


from fastapi import APIRouter

router = APIRouter()

@router.websocket("/ws/stream/{client_id}")
async def websocket_stream(websocket: WebSocket, client_id: str):
    """
    Real-time audio streaming endpoint.
    
    Connect with: ws://localhost:8000/ws/stream/{your_client_id}
    Send: Binary audio data (Int16 PCM format)
    Receive: JSON with risk analysis
    """
    await handle_audio_stream(websocket, client_id)

@router.get("/ws/status")
async def websocket_status():
    """Get WebSocket server status and active connections."""
    return {
        "active_connections": manager.connection_count,
        "clients": [
            {
                "client_id": session.client_id,
                "connected_at": session.connected_at.isoformat(),
                "chunks_processed": session.chunks_processed,
                "bytes_received": session.bytes_received,
                "current_risk_score": session.current_risk_score,
            }
            for session in manager.active_connections.values()
        ]
    }
