"""
FinShield API - Analysis Endpoint

Main endpoint for analyzing audio recordings and documents for fraud/predatory patterns.
"""

from enum import Enum
from typing import Optional
from fastapi import APIRouter, File, Form, UploadFile, HTTPException, Depends
from pydantic import BaseModel

from app.services import (
    get_audio_analyzer,
    get_document_scanner,
    get_context_engine,
    AudioAnalyzerBase,
    DocumentScannerBase,
    ContextEngineBase,
)


router = APIRouter(prefix="/analyze", tags=["Analysis"])


class AnalysisType(str, Enum):
    """Type of content to analyze."""
    AUDIO = "audio"
    DOCUMENT = "document"
    CROSS_REFERENCE = "cross_reference"


class AnalysisResponse(BaseModel):
    """Standard analysis response."""
    success: bool
    analysis_type: str
    analysis_id: str
    risk_score: float
    threat_level: str
    summary: str
    details: dict


@router.post("", response_model=AnalysisResponse)
async def analyze_content(
    type: AnalysisType = Form(..., description="Type of analysis: audio, document, or cross_reference"),
    file: Optional[UploadFile] = File(None, description="Audio or document file to analyze"),
    audio_analysis_id: Optional[str] = Form(None, description="Previous audio analysis ID for cross-reference"),
    document_analysis_id: Optional[str] = Form(None, description="Previous document analysis ID for cross-reference"),
    audio_analyzer: AudioAnalyzerBase = Depends(get_audio_analyzer),
    document_scanner: DocumentScannerBase = Depends(get_document_scanner),
    context_engine: ContextEngineBase = Depends(get_context_engine),
):
    """
    Analyze audio recordings, documents, or cross-reference previous analyses.
    
    **Analysis Types:**
    - `audio`: Analyze audio recording for fraud indicators (urgency, fear tactics, etc.)
    - `document`: Scan document for predatory clauses and hidden fees
    - `cross_reference`: Cross-reference audio and document analyses using RAG
    
    **Returns:**
    - Risk score (0.0 - 1.0)
    - Threat level classification
    - Detailed analysis with specific flags/clauses detected
    """
    
    if type == AnalysisType.AUDIO:
        if not file:
            raise HTTPException(status_code=400, detail="Audio file required for audio analysis")
        
        content = await file.read()
        result = await audio_analyzer.analyze(content, file.content_type or "audio/wav")
        
        return AnalysisResponse(
            success=True,
            analysis_type="audio",
            analysis_id=result.analysis_id,
            risk_score=result.risk_score,
            threat_level=result.threat_level.value,
            summary=f"Detected {len(result.detected_tactics)} manipulation tactics with {result.confidence:.0%} confidence.",
            details=result.to_dict(),
        )
    
    elif type == AnalysisType.DOCUMENT:
        if not file:
            raise HTTPException(status_code=400, detail="Document file required for document analysis")
        
        content = await file.read()
        result = await document_scanner.analyze(
            content,
            file.content_type or "application/pdf",
            file.filename or "document.pdf"
        )
        
        return AnalysisResponse(
            success=True,
            analysis_type="document",
            analysis_id=result.analysis_id,
            risk_score=result.overall_risk_score,
            threat_level="high" if result.overall_risk_score > 0.7 else "medium" if result.overall_risk_score > 0.4 else "low",
            summary=result.summary,
            details=result.to_dict(),
        )
    
    elif type == AnalysisType.CROSS_REFERENCE:
        if not audio_analysis_id and not document_analysis_id:
            raise HTTPException(
                status_code=400,
                detail="At least one analysis ID (audio or document) required for cross-reference"
            )
        
        result = await context_engine.cross_reference(
            audio_analysis_id=audio_analysis_id,
            document_analysis_id=document_analysis_id,
        )
        
        return AnalysisResponse(
            success=True,
            analysis_type="cross_reference",
            analysis_id=result.analysis_id,
            risk_score=result.combined_risk_score,
            threat_level="critical" if result.combined_risk_score > 0.8 else "high" if result.combined_risk_score > 0.6 else "medium" if result.combined_risk_score > 0.3 else "low",
            summary=result.recommendation,
            details=result.to_dict(),
        )
    
    raise HTTPException(status_code=400, detail=f"Unknown analysis type: {type}")


@router.post("/audio")
async def analyze_audio_quick(
    file: UploadFile = File(..., description="Audio file to analyze"),
    audio_analyzer: AudioAnalyzerBase = Depends(get_audio_analyzer),
):
    """
    Quick audio analysis endpoint.
    
    Shorthand for POST /analyze with type=audio.
    """
    content = await file.read()
    result = await audio_analyzer.analyze(content, file.content_type or "audio/wav")
    return result.to_dict()


@router.post("/document")
async def analyze_document_quick(
    file: UploadFile = File(..., description="Document file to analyze (PDF, DOCX, etc.)"),
    document_scanner: DocumentScannerBase = Depends(get_document_scanner),
):
    """
    Quick document analysis endpoint.
    
    Shorthand for POST /analyze with type=document.
    """
    content = await file.read()
    result = await document_scanner.analyze(
        content,
        file.content_type or "application/pdf",
        file.filename or "document.pdf"
    )
    return result.to_dict()
