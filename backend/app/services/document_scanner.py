"""
FinShield API - Document Scanner Service

Abstract base class for document analysis.
Currently mocked - designed for drop-in Hotfoot Docs integration.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional
import random
import uuid


class ClauseRisk(str, Enum):
    """Risk level for contract clauses."""
    BENIGN = "benign"
    SUSPICIOUS = "suspicious"
    PREDATORY = "predatory"
    ILLEGAL = "illegal"


class ClauseType(str, Enum):
    """Types of problematic clauses."""
    HIDDEN_FEE = "hidden_fee"
    PENALTY_CLAUSE = "penalty_clause"
    AUTO_RENEWAL = "auto_renewal"
    ARBITRATION_WAIVER = "arbitration_waiver"
    LIABILITY_WAIVER = "liability_waiver"
    DATA_SHARING = "data_sharing"
    VARIABLE_RATE = "variable_rate"
    PREPAYMENT_PENALTY = "prepayment_penalty"


@dataclass
class ExtractedClause:
    """A clause extracted from document."""
    clause_id: str
    clause_type: ClauseType
    risk_level: ClauseRisk
    text: str
    page_number: int
    explanation: str


@dataclass
class DocumentAnalysisResult:
    """Result of document analysis."""
    analysis_id: str
    timestamp: datetime
    document_type: str
    overall_risk_score: float  # 0.0 - 1.0
    extracted_clauses: list[ExtractedClause]
    entities: dict[str, list[str]]  # e.g., {"amounts": ["$500", "$1000"], "dates": ["2024-01-01"]}
    summary: str
    red_flags: list[str]

    def to_dict(self) -> dict:
        return {
            "analysis_id": self.analysis_id,
            "timestamp": self.timestamp.isoformat(),
            "document_type": self.document_type,
            "overall_risk_score": self.overall_risk_score,
            "extracted_clauses": [
                {
                    "clause_id": c.clause_id,
                    "clause_type": c.clause_type.value,
                    "risk_level": c.risk_level.value,
                    "text": c.text,
                    "page_number": c.page_number,
                    "explanation": c.explanation,
                }
                for c in self.extracted_clauses
            ],
            "entities": self.entities,
            "summary": self.summary,
            "red_flags": self.red_flags,
        }


class DocumentScannerBase(ABC):
    """Abstract base class for document scanning services."""

    @abstractmethod
    async def analyze(self, document_data: bytes, mime_type: str, filename: str) -> DocumentAnalysisResult:
        """Analyze document for predatory clauses."""
        pass


class MockDocumentScanner(DocumentScannerBase):
    """
    Mock implementation for development/demo.
    Replace with HotfootDocsScanner for production.
    """

    SAMPLE_CLAUSES = [
        ("Section 4.2: A non-refundable processing fee of $499 will be charged upon signing.", ClauseType.HIDDEN_FEE, ClauseRisk.PREDATORY),
        ("This agreement automatically renews for successive 2-year terms unless cancelled 90 days prior.", ClauseType.AUTO_RENEWAL, ClauseRisk.SUSPICIOUS),
        ("Borrower waives all rights to jury trial and agrees to binding arbitration.", ClauseType.ARBITRATION_WAIVER, ClauseRisk.PREDATORY),
        ("Interest rate may adjust quarterly based on market conditions with no cap.", ClauseType.VARIABLE_RATE, ClauseRisk.PREDATORY),
        ("Early repayment incurs a penalty of 5% of remaining balance.", ClauseType.PREPAYMENT_PENALTY, ClauseRisk.SUSPICIOUS),
        ("We reserve the right to share your data with affiliated third parties.", ClauseType.DATA_SHARING, ClauseRisk.SUSPICIOUS),
    ]

    SAMPLE_RED_FLAGS = [
        "⚠️ Hidden fee structure detected in fine print",
        "⚠️ Aggressive auto-renewal with short cancellation window",
        "⚠️ Rights waiver may limit legal recourse",
        "⚠️ Variable rate with no ceiling protection",
        "⚠️ Early exit penalties above market standard",
    ]

    DOC_TYPES = ["loan_agreement", "credit_card_terms", "lease_agreement", "insurance_policy", "investment_contract"]

    async def analyze(self, document_data: bytes, mime_type: str, filename: str) -> DocumentAnalysisResult:
        """Generate mock document analysis."""
        risk_score = random.uniform(0.2, 0.9)

        # Generate random extracted clauses
        num_clauses = random.randint(2, 5)
        extracted_clauses = []
        for i, (text, clause_type, risk_level) in enumerate(random.sample(self.SAMPLE_CLAUSES, min(num_clauses, len(self.SAMPLE_CLAUSES)))):
            extracted_clauses.append(ExtractedClause(
                clause_id=f"clause_{i+1}",
                clause_type=clause_type,
                risk_level=risk_level,
                text=text,
                page_number=random.randint(1, 15),
                explanation=f"This {clause_type.value.replace('_', ' ')} clause may result in unexpected costs or obligations.",
            ))

        # Mock entity extraction
        entities = {
            "amounts": [f"${random.randint(100, 10000)}" for _ in range(random.randint(2, 5))],
            "dates": ["2024-01-15", "2024-06-30", "2025-01-01"][:random.randint(1, 3)],
            "parties": ["FinCorp International LLC", "Borrower"],
            "percentages": [f"{random.uniform(3, 29):.1f}%" for _ in range(random.randint(1, 3))],
        }

        # Red flags based on risk
        num_flags = min(int(risk_score * 4) + 1, len(self.SAMPLE_RED_FLAGS))
        red_flags = random.sample(self.SAMPLE_RED_FLAGS, num_flags)

        return DocumentAnalysisResult(
            analysis_id=str(uuid.uuid4()),
            timestamp=datetime.utcnow(),
            document_type=random.choice(self.DOC_TYPES),
            overall_risk_score=round(risk_score, 3),
            extracted_clauses=extracted_clauses,
            entities=entities,
            summary=f"Analysis of '{filename}' identified {len(extracted_clauses)} clauses of concern with an overall risk score of {risk_score:.0%}.",
            red_flags=red_flags,
        )


# Factory function for dependency injection
def get_document_scanner() -> DocumentScannerBase:
    """
    Get document scanner instance.
    
    TODO: Replace with HotfootDocsScanner when API keys are configured:
    
    settings = get_settings()
    if settings.hotfoot_docs_api_key:
        return HotfootDocsScanner(api_key=settings.hotfoot_docs_api_key)
    return MockDocumentScanner()
    """
    return MockDocumentScanner()
