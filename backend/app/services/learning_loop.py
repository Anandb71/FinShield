"""
FinShield - Learning Loop Database Models

Captures human corrections for continuous improvement.
"""

from datetime import datetime
from typing import Dict, Any, List, Optional
import json
import logging

logger = logging.getLogger(__name__)


class CorrectionStore:
    """In-memory correction store (replace with database in production)."""
    
    def __init__(self):
        """Initialize correction store."""
        self.corrections: List[Dict[str, Any]] = []
    
    def add_correction(
        self,
        document_id: str,
        field_name: str,
        original_value: Any,
        corrected_value: Any,
        corrected_by: str = "user"
    ) -> str:
        """
        Add a correction.
        
        Args:
            document_id: Document ID
            field_name: Field that was corrected
            original_value: Original extracted value
            corrected_value: Corrected value
            corrected_by: User who made correction
        
        Returns:
            Correction ID
        """
        correction_id = f"corr_{len(self.corrections) + 1}"
        
        correction = {
            "id": correction_id,
            "document_id": document_id,
            "field_name": field_name,
            "original_value": original_value,
            "corrected_value": corrected_value,
            "corrected_by": corrected_by,
            "created_at": datetime.now().isoformat()
        }
        
        self.corrections.append(correction)
        logger.info(f"Added correction {correction_id} for {document_id}.{field_name}")
        
        # Check retraining triggers
        self._check_retraining_triggers()
        
        return correction_id
    
    def get_corrections(
        self,
        document_id: Optional[str] = None,
        field_name: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get corrections with optional filters."""
        results = self.corrections
        
        if document_id:
            results = [c for c in results if c["document_id"] == document_id]
        
        if field_name:
            results = [c for c in results if c["field_name"] == field_name]
        
        return results
    
    def get_error_clusters(self) -> Dict[str, Any]:
        """
        Cluster errors by field name and error type.
        
        Returns:
            Error clusters with counts
        """
        clusters = {}
        
        for correction in self.corrections:
            field = correction["field_name"]
            
            if field not in clusters:
                clusters[field] = {
                    "count": 0,
                    "examples": []
                }
            
            clusters[field]["count"] += 1
            if len(clusters[field]["examples"]) < 5:
                clusters[field]["examples"].append({
                    "original": correction["original_value"],
                    "corrected": correction["corrected_value"]
                })
        
        return clusters
    
    def get_error_rate(self) -> float:
        """Calculate overall error rate."""
        if not self.corrections:
            return 0.0
        
        # Assuming each correction represents one error
        # In production, track total documents processed
        total_documents = len(set(c["document_id"] for c in self.corrections))
        return len(self.corrections) / max(total_documents, 1)
    
    def _check_retraining_triggers(self):
        """Check if retraining should be triggered."""
        correction_count = len(self.corrections)
        error_rate = self.get_error_rate()
        
        # Trigger conditions
        if correction_count >= 100:
            logger.warning(f"Retraining trigger: {correction_count} corrections accumulated")
            self._trigger_retraining("correction_threshold")
        
        if error_rate > 0.1:
            logger.warning(f"Retraining trigger: Error rate {error_rate:.2%} exceeds threshold")
            self._trigger_retraining("error_rate_threshold")
    
    def _trigger_retraining(self, reason: str):
        """Trigger model retraining."""
        logger.info(f"Retraining triggered: {reason}")
        # In production: send to ML pipeline, create retraining job, etc.
        # For now, just log


# Global correction store
_correction_store = None


def get_correction_store() -> CorrectionStore:
    """Get or create correction store."""
    global _correction_store
    if _correction_store is None:
        _correction_store = CorrectionStore()
    return _correction_store
