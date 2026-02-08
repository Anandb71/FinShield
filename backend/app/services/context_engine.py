"""
FinShield API - Context Engine Service

Abstract base class for RAG-based context analysis.
Currently mocked - designed for drop-in Backboard.io integration.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import random
import uuid


@dataclass
class ContextMatch:
    """A matched context from knowledge base."""
    source_type: str  # "audio" or "document"
    source_id: str
    relevance_score: float
    matched_text: str
    metadata: dict


@dataclass
class ContextAnalysisResult:
    """Result of cross-referencing audio against documents."""
    analysis_id: str
    timestamp: datetime
    query_summary: str
    matches: list[ContextMatch]
    combined_risk_score: float
    recommendation: str
    reasoning: str

    def to_dict(self) -> dict:
        return {
            "analysis_id": self.analysis_id,
            "timestamp": self.timestamp.isoformat(),
            "query_summary": self.query_summary,
            "matches": [
                {
                    "source_type": m.source_type,
                    "source_id": m.source_id,
                    "relevance_score": m.relevance_score,
                    "matched_text": m.matched_text,
                    "metadata": m.metadata,
                }
                for m in self.matches
            ],
            "combined_risk_score": self.combined_risk_score,
            "recommendation": self.recommendation,
            "reasoning": self.reasoning,
        }


class ContextEngineBase(ABC):
    """Abstract base class for RAG context engine."""

    @abstractmethod
    async def cross_reference(
        self,
        audio_analysis_id: Optional[str],
        document_analysis_id: Optional[str],
        query: Optional[str] = None,
    ) -> ContextAnalysisResult:
        """Cross-reference audio and document analyses."""
        pass

    @abstractmethod
    async def store_context(self, source_type: str, source_id: str, content: str, metadata: dict) -> bool:
        """Store context for future retrieval."""
        pass


class MockContextEngine(ContextEngineBase):
    """
    Mock implementation for development/demo.
    Replace with BackboardContextEngine for production.
    """

    SAMPLE_RECOMMENDATIONS = [
        "🚨 HIGH ALERT: Caller claims match predatory patterns found in uploaded documents. Do not proceed.",
        "⚠️ CAUTION: Some claims made during call contradict terms in the contract. Request clarification.",
        "✅ LOW RISK: No significant discrepancies found between call content and document terms.",
        "🔍 REVIEW NEEDED: Unable to verify caller's claims. Request written documentation before proceeding.",
    ]

    SAMPLE_REASONING = [
        "The caller mentioned an 'urgent processing fee' which matches the hidden fee clause identified in Section 4.2 of the uploaded agreement.",
        "Cross-referencing the claimed 'limited time offer' with the contract shows no such provision exists.",
        "The interest rate quoted verbally differs from the variable rate terms in the signed document.",
        "Caller's identity claims could not be verified against the listed parties in the contract.",
    ]

    async def cross_reference(
        self,
        audio_analysis_id: Optional[str],
        document_analysis_id: Optional[str],
        query: Optional[str] = None,
    ) -> ContextAnalysisResult:
        """Generate mock cross-reference analysis."""
        risk_score = random.uniform(0.1, 0.95)

        # Generate mock matches
        matches = []
        if audio_analysis_id:
            matches.append(ContextMatch(
                source_type="audio",
                source_id=audio_analysis_id,
                relevance_score=random.uniform(0.6, 0.95),
                matched_text="...you must pay the processing fee today...",
                metadata={"timestamp_seconds": random.randint(30, 300)},
            ))
        if document_analysis_id:
            matches.append(ContextMatch(
                source_type="document",
                source_id=document_analysis_id,
                relevance_score=random.uniform(0.7, 0.98),
                matched_text="Section 4.2: Non-refundable processing fee of $499",
                metadata={"page": random.randint(1, 10), "clause_type": "hidden_fee"},
            ))

        # Select recommendation based on risk
        if risk_score > 0.7:
            recommendation = self.SAMPLE_RECOMMENDATIONS[0]
        elif risk_score > 0.4:
            recommendation = self.SAMPLE_RECOMMENDATIONS[1]
        elif risk_score > 0.2:
            recommendation = self.SAMPLE_RECOMMENDATIONS[3]
        else:
            recommendation = self.SAMPLE_RECOMMENDATIONS[2]

        return ContextAnalysisResult(
            analysis_id=str(uuid.uuid4()),
            timestamp=datetime.utcnow(),
            query_summary=query or "Cross-reference audio call with uploaded documents",
            matches=matches,
            combined_risk_score=round(risk_score, 3),
            recommendation=recommendation,
            reasoning=random.choice(self.SAMPLE_REASONING),
        )

    async def store_context(self, source_type: str, source_id: str, content: str, metadata: dict) -> bool:
        """Mock context storage - always succeeds."""
        return True


# Factory function for dependency injection
def get_context_engine() -> ContextEngineBase:
    """
    Get context engine instance.
    
    TODO: Replace with BackboardContextEngine when API keys are configured:
    
    settings = get_settings()
    if settings.backboard_api_key:
        return BackboardContextEngine(
            api_key=settings.backboard_api_key,
            workspace_id=settings.backboard_workspace_id,
        )
    return MockContextEngine()
    """
    return MockContextEngine()
