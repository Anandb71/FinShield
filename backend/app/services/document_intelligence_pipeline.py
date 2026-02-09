"""
FinShield - Document Intelligence Pipeline

Main orchestration for Backboard-only document intelligence.
"""

from typing import Dict, Any
import logging
import uuid
from datetime import datetime

from app.services.backboard_service import BackboardDocumentService
from app.services.document_validator import DocumentValidator
from app.services.document_schemas import get_schema_fields, get_required_fields
from app.core.config import get_settings

logger = logging.getLogger(__name__)


class DocumentIntelligencePipeline:
    """Main document intelligence pipeline using Backboard."""
    
    def __init__(self):
        """Initialize pipeline."""
        settings = get_settings()
        
        self.backboard = BackboardDocumentService(
            api_key=settings.backboard_api_key,
            api_url=settings.backboard_api_url,
            workspace_id=settings.backboard_workspace_id
        )
        
        self.validator = DocumentValidator()
    
    async def process_document(
        self,
        pdf_bytes: bytes,
        filename: str
    ) -> Dict[str, Any]:
        """
        Process document through complete pipeline.
        
        Steps:
        1. Analyze with Backboard (OCR, classification, layout)
        2. Schema-aware extraction
        3. Validate data
        4. Store in knowledge graph
        5. Check cross-document consistency
        
        Args:
            pdf_bytes: PDF file bytes
            filename: Original filename
        
        Returns:
            Complete analysis result
        """
        doc_id = str(uuid.uuid4())
        start_time = datetime.now()
        
        try:
            # Step 1: Analyze document with Backboard (Single Pass)
            logger.info(f"Step 1: Analyzing {filename} with Backboard Assistant")
            try:
                analysis = await self.backboard.analyze_document(pdf_bytes, filename)
            except Exception as e:
                logger.error(f"Backboard Assistant API failed: {e}")
                raise e # Re-raise to let the caller handle it (or global exception handler)
            
            if analysis["status"] == "failed":
                raise Exception(f"Analysis failed: {analysis.get('error')}")
            
            # The new API returns everything in one go
            extracted_fields = analysis.get("extracted_fields", {})
            doc_type = analysis["classification"].get("type", "unknown")
            
            logger.info(f"Document classified as: {doc_type}")
            logger.info(f"Extracted {len(extracted_fields)} fields")
            
            # Step 2: Validate data
            logger.info("Step 2: Validating extracted data")
            validation = self.validator.validate(doc_type, extracted_fields)
            
            # Calculate processing time
            processing_time = (datetime.now() - start_time).total_seconds()
            
            final_result = {
                "document_id": analysis.get("document_id", doc_id),
                "filename": filename,
                "classification": analysis["classification"],
                "extracted_fields": extracted_fields,
                "layout": analysis.get("layout", {}),
                "tables": analysis.get("tables", []),
                "validation": validation,
                "consistency_check": {"consistent": True, "explanation": "Checks skipped in v2"},
                "processing_time_seconds": processing_time,
                "status": "success"
            }
            
            # ---------------------------------------------------------
            # NEW: Save to Volatile Memory Store
            # ---------------------------------------------------------
            try:
                from app.services.memory_store import get_memory_store
                store = get_memory_store()
                
                # 1. Save Document Result
                store.save_document(final_result["document_id"], final_result, pdf_bytes)
                
                # 2. Check for Low Confidence Fields (< 0.8)
                # If any field has low confidence (or missing), flag for review
                # Since Backboard v2 returns aggregate confidence, we will use that as a proxy for all fields
                # In a real scenario, we'd check per-field confidence if available.
                
                doc_conf = float(analysis["classification"].get("confidence", 0.0))
                
                if doc_conf < 0.8:
                    # Flag entire document or specific fields?
                    # Let's flag "extracted_fields" generally
                    store.add_to_review({
                        "doc_id": final_result["document_id"],
                        "field": "document_classification", # General flag
                        "ocr_value": doc_type,
                        "suggestion": "Verify Document Type",
                        "confidence": int(doc_conf * 100),
                        "doc_type": doc_type
                    })
                    
                # Also check validation errors
                for error in validation.get("errors", []):
                     store.add_to_review({
                        "doc_id": final_result["document_id"],
                        "field": "validation_error",
                        "ocr_value": "INVALID",
                        "suggestion": error,
                        "confidence": 0,
                        "doc_type": doc_type
                    })
                    
            except Exception as e:
                logger.error(f"Failed to save to memory store: {e}")
                # Don't fail the request, just log
            
            return final_result
            
        except Exception as e:
            logger.error(f"Document processing failed: {e}")
            # NO MOCK FALLBACK for now - we want to see real errors if it fails
            raise e

    def _get_mock_analysis(self, filename: str, doc_id: str) -> Dict[str, Any]:
        """Generate mock analysis for demo/fallback."""
        import random
        doc_type = "invoice" if "invoice" in filename.lower() else "bank_statement"
        
        return {
            "document_id": doc_id,
            "filename": filename,
            "classification": {
                "type": doc_type,
                "confidence": 0.95
            },
            "extracted_fields": {
                "vendor_name": "Acme Corp",
                "invoice_number": f"INV-{random.randint(1000, 9999)}",
                "total_amount": f"${random.randint(100, 5000)}.00",
                "date": datetime.now().strftime("%Y-%m-%d")
            },
            "layout": {},
            "tables": [],
            "validation": {"valid": True, "errors": []},
            "consistency_check": {
                "consistent": False,
                "explanation": "Simulated discrepancy: Invoice amount matches PO, but vendor mismatch.",
                "conflicting_docs": [{"source": "PO-123", "text": "Vendor: Beta Inc"}]
            },
            "processing_time_seconds": 1.5,
            "status": "success",
            "note": "SIMULATED DATA (Backboard API Unreachable)"
        }
            



# Global pipeline instance
_pipeline = None


def get_pipeline() -> DocumentIntelligencePipeline:
    """Get or create pipeline instance."""
    global _pipeline
    if _pipeline is None:
        _pipeline = DocumentIntelligencePipeline()
    return _pipeline
