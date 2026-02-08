"""FinShield Services Module"""

from app.services.audio_analyzer import (
    AudioAnalyzerBase,
    AudioAnalysisResult,
    MockAudioAnalyzer,
    ThreatLevel,
    TacticType,
    get_audio_analyzer,
)
from app.services.document_scanner import (
    DocumentScannerBase,
    DocumentAnalysisResult,
    MockDocumentScanner,
    ClauseRisk,
    ClauseType,
    get_document_scanner,
)
from app.services.context_engine import (
    ContextEngineBase,
    ContextAnalysisResult,
    MockContextEngine,
    get_context_engine,
)

__all__ = [
    # Audio
    "AudioAnalyzerBase",
    "AudioAnalysisResult",
    "MockAudioAnalyzer",
    "ThreatLevel",
    "TacticType",
    "get_audio_analyzer",
    # Document
    "DocumentScannerBase",
    "DocumentAnalysisResult",
    "MockDocumentScanner",
    "ClauseRisk",
    "ClauseType",
    "get_document_scanner",
    # Context
    "ContextEngineBase",
    "ContextAnalysisResult",
    "MockContextEngine",
    "get_context_engine",
]
