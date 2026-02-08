"""
FinShield - Enhanced Learning with Backboard

Feeds human corrections back to Backboard for continuous improvement.
"""

import logging
from typing import Dict, Any, List
from app.services.backboard_service import BackboardDocumentService
from app.services.learning_loop import get_correction_store
from app.core.config import get_settings

logger = logging.getLogger(__name__)


class BackboardLearningEnhancer:
    """Enhance Backboard learning with human corrections."""
    
    def __init__(self):
        """Initialize learning enhancer."""
        settings = get_settings()
        self.backboard = BackboardDocumentService(
            api_key=settings.backboard_api_key,
            api_url=settings.backboard_api_url,
            workspace_id=settings.backboard_workspace_id
        )
    
    async def update_document_with_corrections(
        self,
        document_id: str,
        corrections: List[Dict[str, Any]]
    ) -> bool:
        """
        Update Backboard document with corrected values.
        
        This creates a "corrected version" in the knowledge graph
        so future queries learn from human corrections.
        
        Args:
            document_id: Document ID
            corrections: List of corrections
        
        Returns:
            True if successful
        """
        try:
            # Build corrected metadata
            corrected_fields = {}
            for correction in corrections:
                field_name = correction["field_name"]
                corrected_value = correction["corrected_value"]
                corrected_fields[field_name] = corrected_value
            
            # Store corrected version in Backboard
            correction_doc_id = f"{document_id}_corrected"
            
            # Create a summary of corrections for Backboard
            correction_summary = f"""
            This is a corrected version of document {document_id}.
            Human reviewer made the following corrections:
            {self._format_corrections(corrections)}
            
            Corrected fields: {corrected_fields}
            """
            
            await self.backboard.store_document(
                doc_id=correction_doc_id,
                content=correction_summary,
                metadata={
                    "type": "correction",
                    "original_document_id": document_id,
                    "corrected_fields": corrected_fields,
                    "correction_count": len(corrections)
                }
            )
            
            logger.info(f"Stored corrections for {document_id} in Backboard")
            return True
            
        except Exception as e:
            logger.error(f"Failed to update Backboard with corrections: {e}")
            return False
    
    async def create_learning_examples(self) -> bool:
        """
        Create learning examples from error clusters.
        
        Analyzes common errors and stores them as training examples
        in Backboard for future reference.
        """
        try:
            store = get_correction_store()
            clusters = store.get_error_clusters()
            
            # Create a learning document for each error cluster
            for field_name, cluster_data in clusters.items():
                if cluster_data["count"] < 3:
                    continue  # Skip low-frequency errors
                
                # Build learning example
                examples = cluster_data["examples"]
                learning_content = f"""
                Common extraction error pattern for field: {field_name}
                
                This field has been corrected {cluster_data["count"]} times.
                
                Examples of corrections:
                {self._format_examples(examples)}
                
                Pattern: When extracting {field_name}, pay attention to these common mistakes.
                """
                
                await self.backboard.store_document(
                    doc_id=f"learning_pattern_{field_name}",
                    content=learning_content,
                    metadata={
                        "type": "learning_pattern",
                        "field_name": field_name,
                        "error_count": cluster_data["count"]
                    }
                )
            
            logger.info(f"Created learning examples for {len(clusters)} error patterns")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create learning examples: {e}")
            return False
    
    def _format_corrections(self, corrections: List[Dict[str, Any]]) -> str:
        """Format corrections for readability."""
        lines = []
        for c in corrections:
            lines.append(
                f"- {c['field_name']}: '{c['original_value']}' → '{c['corrected_value']}'"
            )
        return "\n".join(lines)
    
    def _format_examples(self, examples: List[Dict[str, Any]]) -> str:
        """Format examples for readability."""
        lines = []
        for i, ex in enumerate(examples, 1):
            lines.append(
                f"{i}. Wrong: '{ex['original']}' → Correct: '{ex['corrected']}'"
            )
        return "\n".join(lines)


# Global instance
_learning_enhancer = None


def get_learning_enhancer() -> BackboardLearningEnhancer:
    """Get or create learning enhancer."""
    global _learning_enhancer
    if _learning_enhancer is None:
        _learning_enhancer = BackboardLearningEnhancer()
    return _learning_enhancer
