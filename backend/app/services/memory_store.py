"""
FinShield - Volatile Session Memory Store

Holds analysis results, file bytes, and review items in memory.
This bridges the gap between:
1. Analysis Pipeline (Producer)
2. Review API (Consumer)
3. Inspector API (Consumer)
"""

from typing import Dict, Any, List, Optional
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class MemoryStore:
    """Singleton in-memory store."""
    
    def __init__(self):
        # Maps doc_id -> Analysis Result Dict
        self.documents: Dict[str, Dict[str, Any]] = {}
        
        # Maps doc_id -> PDF Bytes (Volatile!)
        # In production this would be S3/Blob Storage
        self.files: Dict[str, bytes] = {}
        
        # List of items needing review
        self.review_queue: List[Dict[str, Any]] = []
        
        # Max file cache (to prevent RAM explosion in demo)
        self.max_files = 20

    def save_document(self, doc_id: str, result: Dict[str, Any], file_bytes: bytes):
        """Save analysis result and file."""
        self.documents[doc_id] = result
        
        # Manage file cache size
        if len(self.files) >= self.max_files:
            # Remove oldest
            oldest = next(iter(self.files))
            del self.files[oldest]
            
        self.files[doc_id] = file_bytes
        logger.info(f"[MEMORY] Saved document {doc_id} (Total: {len(self.documents)})")

    def get_document(self, doc_id: str) -> Optional[Dict[str, Any]]:
        """Get analysis result."""
        return self.documents.get(doc_id)

    def get_file(self, doc_id: str) -> Optional[bytes]:
        """Get file bytes."""
        return self.files.get(doc_id)

    def add_to_review(self, item: Dict[str, Any]):
        """Add item to review queue."""
        # Check if already exists to avoid duplicates
        for existing in self.review_queue:
            if existing["doc_id"] == item["doc_id"] and existing["field"] == item["field"]:
                return

        self.review_queue.append(item)
        logger.info(f"[MEMORY] Added to review queue: {item['doc_id']} - {item['field']}")

    def get_review_queue(self) -> List[Dict[str, Any]]:
        """Get current queue."""
        return self.review_queue

    def remove_from_review(self, doc_id: str, field: str):
        """Remove item from queue."""
        self.review_queue = [
            i for i in self.review_queue 
            if not (i["doc_id"] == doc_id and i["field"] == field)
        ]
        logger.info(f"[MEMORY] Removed from review: {doc_id} - {field}")
        
    def clear(self):
        """Clear all data."""
        self.documents.clear()
        self.files.clear()
        self.review_queue.clear()


# Global Instance
_store = MemoryStore()

def get_memory_store() -> MemoryStore:
    """Get global memory store."""
    return _store
