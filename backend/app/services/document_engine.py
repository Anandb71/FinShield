"""
FinShield - Document Engine Service

THIS IS ANUPAM'S FILE - Implement real document processing logic here.

Interface for PDF/document ingestion and analysis.
Current implementation is a mock that returns dummy data.
Replace with Hotfoot Docs + Backboard.io integration.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from dataclasses import dataclass
import random
import uuid


@dataclass
class ExtractedEntity:
    """An entity extracted from a document."""
    entity_type: str  # "amount", "date", "party", "percentage", "term"
    value: str
    page: int
    confidence: float


@dataclass
class DetectedClause:
    """A potentially problematic clause detected in document."""
    clause_id: str
    clause_type: str  # "hidden_fee", "auto_renewal", "penalty", etc.
    text: str
    page: int
    risk_level: str  # "benign", "suspicious", "predatory", "illegal"
    explanation: str


class DocumentEngineBase(ABC):
    """
    Abstract base class for document processing.
    
    Anupam: Implement your Hotfoot Docs + Backboard integration by:
    1. Creating a new class that inherits from this
    2. Implementing the abstract methods
    3. Updating get_document_engine() to return your class
    """

    @abstractmethod
    async def ingest_pdf(self, file_bytes: bytes, filename: str) -> Dict[str, Any]:
        """
        Ingest and analyze a PDF document.
        
        Args:
            file_bytes: Raw PDF file content
            filename: Original filename
            
        Returns:
            Dict with:
            - document_id: str (unique identifier)
            - page_count: int
            - extracted_entities: List[ExtractedEntity]
            - detected_clauses: List[DetectedClause]
            - overall_risk_score: float (0.0 - 1.0)
            - summary: str
        """
        pass

    @abstractmethod
    async def query_document(self, document_id: str, query: str) -> Dict[str, Any]:
        """
        Query a previously ingested document using RAG.
        
        Args:
            document_id: ID from ingest_pdf
            query: Natural language question
            
        Returns:
            Dict with answer, sources, confidence
        """
        pass

    @abstractmethod
    async def cross_reference(
        self,
        document_id: str,
        audio_transcript: str
    ) -> Dict[str, Any]:
        """
        Cross-reference document content with audio transcript.
        
        This is the key RAG feature - find discrepancies between
        what a caller says and what's in the document.
        
        Returns:
            Dict with discrepancies, risk assessment, recommendations
        """
        pass

    @abstractmethod
    async def get_document_summary(self, document_id: str) -> Optional[str]:
        """Get AI-generated summary of document."""
        pass


class MockDocumentEngine(DocumentEngineBase):
    """
    Mock implementation for development/demo.
    
    TODO (Anupam): Replace this with HotfootDocsEngine + BackboardRAG
    """

    SAMPLE_CLAUSES = [
        ("hidden_fee", "Processing fee of $499 applies upon signing", "predatory"),
        ("auto_renewal", "Agreement renews automatically for 2-year terms", "suspicious"),
        ("penalty", "Early termination fee of 20% of remaining balance", "predatory"),
        ("arbitration", "All disputes subject to binding arbitration", "suspicious"),
        ("variable_rate", "Interest rate may adjust without notice", "predatory"),
    ]

    def __init__(self):
        self.documents: Dict[str, Dict] = {}

    async def ingest_pdf(self, file_bytes: bytes, filename: str) -> Dict[str, Any]:
        """
        Mock PDF ingestion.
        
        In production, this would:
        1. Parse PDF with Hotfoot Docs
        2. Extract text and entities
        3. Identify clause types
        4. Store in Backboard.io for RAG queries
        """
        document_id = str(uuid.uuid4())
        file_size = len(file_bytes)
        
        # Simulate document analysis
        page_count = max(1, file_size // 5000)  # Rough estimate
        
        # Generate mock entities
        entities = [
            ExtractedEntity("amount", "$5,000", 1, 0.95),
            ExtractedEntity("amount", "$499", 3, 0.92),
            ExtractedEntity("date", "2024-12-31", 1, 0.98),
            ExtractedEntity("party", "FinCorp Holdings LLC", 1, 0.97),
            ExtractedEntity("percentage", "24.99%", 2, 0.94),
        ]
        
        # Generate mock detected clauses
        num_clauses = random.randint(2, 4)
        selected = random.sample(self.SAMPLE_CLAUSES, num_clauses)
        clauses = [
            DetectedClause(
                clause_id=f"clause_{i}",
                clause_type=clause[0],
                text=clause[1],
                page=random.randint(1, page_count),
                risk_level=clause[2],
                explanation=f"This {clause[0].replace('_', ' ')} clause may result in unexpected obligations.",
            )
            for i, clause in enumerate(selected)
        ]
        
        # Calculate risk based on clauses
        risk_weights = {"benign": 0.1, "suspicious": 0.4, "predatory": 0.7, "illegal": 1.0}
        risk_score = sum(risk_weights.get(c.risk_level, 0.5) for c in clauses) / len(clauses)
        
        # Store for later queries
        self.documents[document_id] = {
            "filename": filename,
            "entities": entities,
            "clauses": clauses,
            "risk_score": risk_score,
        }
        
        return {
            "document_id": document_id,
            "filename": filename,
            "page_count": page_count,
            "file_size_bytes": file_size,
            "extracted_entities": [
                {"type": e.entity_type, "value": e.value, "page": e.page, "confidence": e.confidence}
                for e in entities
            ],
            "detected_clauses": [
                {
                    "clause_id": c.clause_id,
                    "type": c.clause_type,
                    "text": c.text,
                    "page": c.page,
                    "risk_level": c.risk_level,
                    "explanation": c.explanation,
                }
                for c in clauses
            ],
            "overall_risk_score": round(risk_score, 3),
            "summary": f"Document '{filename}' contains {len(clauses)} clauses of concern with overall risk {risk_score:.0%}.",
        }

    async def query_document(self, document_id: str, query: str) -> Dict[str, Any]:
        """Mock document query using RAG."""
        doc = self.documents.get(document_id)
        if not doc:
            return {"error": "Document not found"}
        
        return {
            "query": query,
            "answer": f"Based on the document '{doc['filename']}', the relevant information is... [Mock RAG response - Backboard.io integration pending]",
            "sources": [{"page": 1, "text": "Sample source text..."}],
            "confidence": 0.85,
        }

    async def cross_reference(
        self,
        document_id: str,
        audio_transcript: str
    ) -> Dict[str, Any]:
        """Mock cross-reference between document and audio."""
        doc = self.documents.get(document_id)
        if not doc:
            return {"error": "Document not found"}
        
        # Simulate finding discrepancies
        return {
            "document_id": document_id,
            "transcript_snippet": audio_transcript[:200] if audio_transcript else "",
            "discrepancies": [
                {
                    "type": "fee_mismatch",
                    "caller_claim": "No hidden fees",
                    "document_says": "Processing fee of $499 applies",
                    "risk_level": "high",
                }
            ],
            "recommendation": "⚠️ Caller's claims do not match document terms. Request written clarification.",
            "combined_risk_score": 0.75,
        }

    async def get_document_summary(self, document_id: str) -> Optional[str]:
        """Mock document summary."""
        doc = self.documents.get(document_id)
        if not doc:
            return None
        return f"Summary of {doc['filename']}: This document contains standard financial terms with {len(doc['clauses'])} clauses flagged for review."


# ============================================================================
# FACTORY FUNCTION - Update this to use real implementation
# ============================================================================

def get_document_engine() -> DocumentEngineBase:
    """
    Get document engine instance.
    
    TODO (Anupam): When Hotfoot Docs + Backboard is ready, change to:
    
    from app.core.config import get_settings
    settings = get_settings()
    if settings.hotfoot_docs_api_key and settings.backboard_api_key:
        return HotfootDocsEngine(
            docs_api_key=settings.hotfoot_docs_api_key,
            backboard_key=settings.backboard_api_key,
            workspace_id=settings.backboard_workspace_id,
        )
    return MockDocumentEngine()
    """
    return MockDocumentEngine()
