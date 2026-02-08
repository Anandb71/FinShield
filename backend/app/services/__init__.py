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
from app.services.audio_processor import (
    AudioProcessorBase,
    MockAudioProcessor,
    get_audio_processor,
)
from app.services.document_engine import (
    DocumentEngineBase,
    MockDocumentEngine,
    get_document_engine,
)

__all__ = [
    # Audio Analyzer (REST)
    "AudioAnalyzerBase",
    "AudioAnalysisResult",
    "MockAudioAnalyzer",
    "ThreatLevel",
    "TacticType",
    "get_audio_analyzer",
    # Document Scanner (REST)
    "DocumentScannerBase",
    "DocumentAnalysisResult",
    "MockDocumentScanner",
    "ClauseRisk",
    "ClauseType",
    "get_document_scanner",
    # Context Engine (REST)
    "ContextEngineBase",
    "ContextAnalysisResult",
    "MockContextEngine",
    "get_context_engine",
    # Audio Processor (WebSocket - Sreedev)
    "AudioProcessorBase",
    "MockAudioProcessor",
    "get_audio_processor",
    # Document Engine (WebSocket - Anupam)
    "DocumentEngineBase",
    "MockDocumentEngine",
    "get_document_engine",
]

