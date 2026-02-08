"""
FinShield API - Audio Analyzer Service

Abstract base class for audio analysis.
Currently mocked - designed for drop-in Hotfoot Audio integration.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional
import random
import uuid


class ThreatLevel(str, Enum):
    """Threat classification levels."""
    SAFE = "safe"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class TacticType(str, Enum):
    """Detected manipulation tactics."""
    URGENCY = "urgency"
    FEAR = "fear"
    AUTHORITY = "authority"
    SCARCITY = "scarcity"
    SOCIAL_PROOF = "social_proof"
    RECIPROCITY = "reciprocity"


@dataclass
class AudioAnalysisResult:
    """Result of audio analysis."""
    analysis_id: str
    timestamp: datetime
    risk_score: float  # 0.0 - 1.0
    threat_level: ThreatLevel
    detected_tactics: list[TacticType]
    transcript_snippet: Optional[str]
    confidence: float
    flags: list[str]

    def to_dict(self) -> dict:
        return {
            "analysis_id": self.analysis_id,
            "timestamp": self.timestamp.isoformat(),
            "risk_score": self.risk_score,
            "threat_level": self.threat_level.value,
            "detected_tactics": [t.value for t in self.detected_tactics],
            "transcript_snippet": self.transcript_snippet,
            "confidence": self.confidence,
            "flags": self.flags,
        }


class AudioAnalyzerBase(ABC):
    """Abstract base class for audio analysis services."""

    @abstractmethod
    async def analyze(self, audio_data: bytes, mime_type: str) -> AudioAnalysisResult:
        """Analyze audio data for fraud indicators."""
        pass

    @abstractmethod
    async def analyze_stream(self, audio_chunk: bytes) -> Optional[AudioAnalysisResult]:
        """Analyze streaming audio chunk (for real-time analysis)."""
        pass


class MockAudioAnalyzer(AudioAnalyzerBase):
    """
    Mock implementation for development/demo.
    Replace with HotfootAudioAnalyzer for production.
    """

    SAMPLE_FLAGS = [
        "Urgency language detected: 'Act now or lose this opportunity'",
        "Authority claim: 'I'm calling from the government'",
        "Fear tactic: 'Your account will be suspended'",
        "Pressure technique: 'This offer expires in 5 minutes'",
        "Request for sensitive info: 'Please confirm your SSN'",
    ]

    SAMPLE_SNIPPETS = [
        "...you must act immediately or your account will be frozen...",
        "...this is your final notice, please provide your bank details...",
        "...congratulations, you've won! Just pay a small processing fee...",
        "...I'm from the IRS and there's a warrant for your arrest...",
    ]

    async def analyze(self, audio_data: bytes, mime_type: str) -> AudioAnalysisResult:
        """Generate mock analysis result."""
        # Simulate processing time variability based on data size
        risk_score = random.uniform(0.1, 0.95)

        # Determine threat level based on risk score
        if risk_score < 0.2:
            threat_level = ThreatLevel.SAFE
        elif risk_score < 0.4:
            threat_level = ThreatLevel.LOW
        elif risk_score < 0.6:
            threat_level = ThreatLevel.MEDIUM
        elif risk_score < 0.8:
            threat_level = ThreatLevel.HIGH
        else:
            threat_level = ThreatLevel.CRITICAL

        # Random tactics detected
        num_tactics = min(int(risk_score * 5) + 1, len(TacticType))
        detected_tactics = random.sample(list(TacticType), num_tactics)

        # Random flags
        num_flags = min(int(risk_score * 4) + 1, len(self.SAMPLE_FLAGS))
        flags = random.sample(self.SAMPLE_FLAGS, num_flags)

        return AudioAnalysisResult(
            analysis_id=str(uuid.uuid4()),
            timestamp=datetime.utcnow(),
            risk_score=round(risk_score, 3),
            threat_level=threat_level,
            detected_tactics=detected_tactics,
            transcript_snippet=random.choice(self.SAMPLE_SNIPPETS) if risk_score > 0.3 else None,
            confidence=round(random.uniform(0.7, 0.98), 2),
            flags=flags,
        )

    async def analyze_stream(self, audio_chunk: bytes) -> Optional[AudioAnalysisResult]:
        """Mock streaming analysis - returns result every ~3 calls."""
        if random.random() > 0.7:
            return await self.analyze(audio_chunk, "audio/wav")
        return None


# Factory function for dependency injection
def get_audio_analyzer() -> AudioAnalyzerBase:
    """
    Get audio analyzer instance.
    
    TODO: Replace with HotfootAudioAnalyzer when API keys are configured:
    
    settings = get_settings()
    if settings.hotfoot_audio_api_key:
        return HotfootAudioAnalyzer(api_key=settings.hotfoot_audio_api_key)
    return MockAudioAnalyzer()
    """
    return MockAudioAnalyzer()
