"""
FinShield - Backboard Document Intelligence Service

Complete document intelligence using Backboard.io API.
Handles OCR, classification, extraction, and knowledge graph.
"""

import httpx
import base64
from typing import Dict, Any, List, Optional
import logging
from io import BytesIO

logger = logging.getLogger(__name__)


class BackboardDocumentService:
    """Backboard.io client for complete document intelligence."""
    
    def __init__(self, api_key: str, api_url: str, workspace_id: Optional[str] = None):
        """
        Initialize Backboard service.
        
        Args:
            api_key: Backboard API key
            api_url: Backboard API URL
            workspace_id: Optional workspace ID
        """
        self.api_key = api_key
        self.api_url = api_url.rstrip("/")
        self.workspace_id = workspace_id
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
    
    async def analyze_document(
        self,
        pdf_bytes: bytes,
        filename: str,
        doc_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Complete document analysis using Backboard.
        
        Steps:
        1. OCR and text extraction
        2. Document classification
        3. Layout detection
        4. Entity extraction
        5. Store in knowledge graph
        
        Args:
            pdf_bytes: PDF file bytes
            filename: Original filename
            doc_type: Optional document type hint
        
        Returns:
            Complete analysis result
        """
        try:
            # Encode PDF to base64
            pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                # Step 1: Upload and analyze document
                payload = {
                    "file": pdf_base64,
                    "filename": filename,
                    "workspace_id": self.workspace_id
                }
                
                response = await client.post(
                    f"{self.api_url}/documents/analyze",
                    headers=self.headers,
                    json=payload
                )
                response.raise_for_status()
                result = response.json()
                
                return {
                    "document_id": result.get("document_id"),
                    "text_content": result.get("content", ""),
                    "classification": result.get("classification", {}),
                    "layout": result.get("layout", {}),
                    "entities": result.get("entities", {}),
                    "tables": result.get("tables", []),
                    "status": "success"
                }
                
        except Exception as e:
            logger.error(f"Backboard document analysis failed: {e}")
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def extract_with_schema(
        self,
        pdf_bytes: bytes,
        doc_type: str,
        schema_fields: List[str]
    ) -> Dict[str, Any]:
        """
        Schema-aware extraction using Backboard prompts.
        
        Args:
            pdf_bytes: PDF file bytes
            doc_type: Document type (invoice, bank_statement, etc.)
            schema_fields: List of fields to extract
        
        Returns:
            Extracted fields
        """
        try:
            # First analyze the document
            analysis = await self.analyze_document(pdf_bytes, f"{doc_type}.pdf", doc_type)
            
            if analysis["status"] == "failed":
                return analysis
            
            # Build extraction prompt
            prompt = f"""
            Extract the following fields from this {doc_type}:
            {', '.join(schema_fields)}
            
            Return as JSON with exact field names.
            """
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                payload = {
                    "document_id": analysis["document_id"],
                    "query": prompt,
                    "workspace_id": self.workspace_id
                }
                
                response = await client.post(
                    f"{self.api_url}/query",
                    headers=self.headers,
                    json=payload
                )
                response.raise_for_status()
                result = response.json()
                
                return {
                    "extracted_fields": result.get("answer", {}),
                    "confidence": result.get("confidence", 0.0),
                    "sources": result.get("sources", []),
                    "status": "success"
                }
                
        except Exception as e:
            logger.error(f"Schema extraction failed: {e}")
            return {"status": "failed", "error": str(e)}
    
    async def store_document(
        self,
        doc_id: str,
        content: str,
        metadata: Dict[str, Any]
    ) -> bool:
        """
        Store document in Backboard knowledge graph.
        
        Args:
            doc_id: Document ID
            content: Document text content
            metadata: Document metadata (type, entities, etc.)
        
        Returns:
            True if successful
        """
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                payload = {
                    "doc_id": doc_id,
                    "content": content,
                    "metadata": metadata,
                    "workspace_id": self.workspace_id
                }
                
                response = await client.post(
                    f"{self.api_url}/documents/ingest",
                    headers=self.headers,
                    json=payload
                )
                response.raise_for_status()
                logger.info(f"Stored document {doc_id} in knowledge graph")
                return True
                
        except Exception as e:
            logger.error(f"Failed to store document: {e}")
            return False
    
    async def query_knowledge_graph(
        self,
        query: str,
        doc_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Query Backboard knowledge graph.
        
        Args:
            query: Natural language query
            doc_id: Optional document ID for context
        
        Returns:
            Query result with answer and sources
        """
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                payload = {
                    "query": query,
                    "workspace_id": self.workspace_id
                }
                
                if doc_id:
                    payload["doc_id"] = doc_id
                
                response = await client.post(
                    f"{self.api_url}/query",
                    headers=self.headers,
                    json=payload
                )
                response.raise_for_status()
                result = response.json()
                
                return {
                    "answer": result.get("answer", ""),
                    "sources": result.get("sources", []),
                    "confidence": result.get("confidence", 0.0)
                }
                
        except Exception as e:
            logger.error(f"Knowledge graph query failed: {e}")
            return {"answer": "", "sources": [], "confidence": 0.0}
    
    async def check_consistency(
        self,
        doc_id: str,
        field_name: str,
        field_value: Any
    ) -> Dict[str, Any]:
        """
        Check cross-document consistency.
        
        Args:
            doc_id: Current document ID
            field_name: Field to check
            field_value: Value to verify
        
        Returns:
            Consistency check result
        """
        query = f"Are there any documents where {field_name} conflicts with '{field_value}'? List any contradictions."
        
        result = await self.query_knowledge_graph(query, doc_id)
        
        # Parse result
        answer_lower = result["answer"].lower()
        has_conflict = any(word in answer_lower for word in ["conflict", "contradiction", "different", "mismatch"])
        
        return {
            "consistent": not has_conflict,
            "explanation": result["answer"],
            "conflicting_docs": result["sources"] if has_conflict else []
        }
    
    async def resolve_entity(
        self,
        entity_type: str,
        entity_value: str
    ) -> Dict[str, Any]:
        """
        Resolve entity across documents (deduplication).
        
        Args:
            entity_type: Type of entity (vendor, employer, bank_account)
            entity_value: Entity value
        
        Returns:
            Canonical entity and similar matches
        """
        query = f"Find all documents mentioning {entity_type}: '{entity_value}'. Include similar variations."
        
        result = await self.query_knowledge_graph(query)
        
        return {
            "canonical_value": entity_value,
            "similar_entities": result["sources"],
            "document_count": len(result["sources"])
        }
