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
            # Step 1: Analyze document with Backboard
            logger.info(f"Step 1: Analyzing {filename} with Backboard")
            analysis = await self.backboard.analyze_document(pdf_bytes, filename)
            
            if analysis["status"] == "failed":
                return {
                    "document_id": doc_id,
                    "filename": filename,
                    "error": analysis.get("error"),
                    "status": "failed"
                }
            
            doc_type = analysis["classification"].get("type", "unknown")
            logger.info(f"Document classified as: {doc_type}")
            
            # Step 2: Schema-aware extraction
            logger.info(f"Step 2: Extracting fields for {doc_type}")
            schema_fields = get_schema_fields(doc_type)
            
            extraction = await self.backboard.extract_with_schema(
                pdf_bytes,
                doc_type,
                schema_fields
            )
            
            if extraction["status"] == "failed":
                return {
                    "document_id": doc_id,
                    "filename": filename,
                    "error": extraction.get("error"),
                    "status": "failed"
                }
            
            extracted_fields = extraction["extracted_fields"]
            logger.info(f"Extracted {len(extracted_fields)} fields")
            
            # Step 3: Validate data
            logger.info("Step 3: Validating extracted data")
            validation = self.validator.validate(doc_type, extracted_fields)
            logger.info(f"Validation: {'PASSED' if validation['valid'] else 'FAILED'}")
            
            # Step 4: Store in knowledge graph
            logger.info("Step 4: Storing in knowledge graph")
            await self.backboard.store_document(
                doc_id=doc_id,
                content=analysis["text_content"],
                metadata={
                    "type": doc_type,
                    "filename": filename,
                    "entities": extracted_fields
                }
            )
            
            # Step 5: Check cross-document consistency
            logger.info("Step 5: Checking consistency")
            consistency_check = {"consistent": True, "explanation": "No checks performed"}
            
            if "vendor_name" in extracted_fields:
                consistency_check = await self.backboard.check_consistency(
                    doc_id=doc_id,
                    field_name="vendor_name",
                    field_value=extracted_fields["vendor_name"]
                )
            elif "employer_name" in extracted_fields:
                consistency_check = await self.backboard.check_consistency(
                    doc_id=doc_id,
                    field_name="employer_name",
                    field_value=extracted_fields["employer_name"]
                )
            
            # Calculate processing time
            processing_time = (datetime.now() - start_time).total_seconds()
            
            return {
                "document_id": doc_id,
                "filename": filename,
                "classification": {
                    "type": doc_type,
                    "confidence": analysis["classification"].get("confidence", 0.0)
                },
                "extracted_fields": extracted_fields,
                "layout": analysis["layout"],
                "tables": analysis["tables"],
                "validation": validation,
                "consistency_check": consistency_check,
                "processing_time_seconds": processing_time,
                "status": "success"
            }
            
        except Exception as e:
            logger.error(f"Document processing failed: {e}")
            return {
                "document_id": doc_id,
                "filename": filename,
                "error": str(e),
                "status": "failed"
            }


# Global pipeline instance
_pipeline = None


def get_pipeline() -> DocumentIntelligencePipeline:
    """Get or create pipeline instance."""
    global _pipeline
    if _pipeline is None:
        _pipeline = DocumentIntelligencePipeline()
    return _pipeline
