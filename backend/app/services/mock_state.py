"""
Mock State Service - In-memory persistence for demo
"""
from typing import Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime
import json


@dataclass
class CorrectionLog:
    doc_id: str
    field: str
    original_value: str
    corrected_value: str
    timestamp: str
    accuracy_gain: float


class GlobalState:
    """
    Singleton state manager for demo persistence.
    Tracks corrections, accuracy gains, and document status.
    """
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        self._initialized = True
        
        self.corrections: list[CorrectionLog] = []
        self.documents: Dict[str, Dict[str, Any]] = {}
        self.total_accuracy_gain: float = 0.0
        self.retrain_triggers: int = 0

    def submit_correction(
        self, 
        doc_id: str, 
        field: str, 
        original_value: str, 
        corrected_value: str
    ) -> Dict[str, Any]:
        """
        Submit a human correction and update state.
        Returns the new validation status for immediate UI update.
        """
        import random
        
        accuracy_gain = round(random.uniform(0.01, 0.05), 4)
        
        correction = CorrectionLog(
            doc_id=doc_id,
            field=field,
            original_value=original_value,
            corrected_value=corrected_value,
            timestamp=datetime.now().isoformat(),
            accuracy_gain=accuracy_gain
        )
        
        self.corrections.append(correction)
        self.total_accuracy_gain += accuracy_gain
        self.retrain_triggers += 1
        
        # Update document in memory
        if doc_id not in self.documents:
            self.documents[doc_id] = {}
        
        self.documents[doc_id][field] = {
            "value": corrected_value,
            "corrected": True,
            "confidence": 100,
            "corrected_at": correction.timestamp
        }
        
        return {
            "success": True,
            "doc_id": doc_id,
            "field": field,
            "new_value": corrected_value,
            "accuracy_gain": accuracy_gain,
            "total_accuracy_gain": round(self.total_accuracy_gain, 4),
            "validation_status": "PASS",  # Flash green
            "retrain_queued": True
        }

    def get_document(self, doc_id: str) -> Optional[Dict[str, Any]]:
        """Get document state with corrections applied."""
        return self.documents.get(doc_id)

    def get_corrections_log(self) -> list[Dict[str, Any]]:
        """Get all corrections for audit trail."""
        return [
            {
                "doc_id": c.doc_id,
                "field": c.field,
                "original": c.original_value,
                "corrected": c.corrected_value,
                "timestamp": c.timestamp,
                "accuracy_gain": c.accuracy_gain
            }
            for c in self.corrections
        ]

    def get_stats(self) -> Dict[str, Any]:
        """Get aggregate stats for dashboard."""
        return {
            "total_corrections": len(self.corrections),
            "total_accuracy_gain": round(self.total_accuracy_gain * 100, 2),
            "retrain_triggers": self.retrain_triggers,
            "documents_corrected": len(self.documents)
        }

    def reset(self):
        """Reset state for demo restart."""
        self.corrections = []
        self.documents = {}
        self.total_accuracy_gain = 0.0
        self.retrain_triggers = 0


# Singleton instance
state = GlobalState()
