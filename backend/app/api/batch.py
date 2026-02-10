"""
FinShield - Batch Re-analysis API

Re-runs validation and anomaly detection on stored documents when
forensic rules are updated. Does NOT require re-uploading or re-extracting;
uses the already-stored extracted_fields and file data.

Endpoints:
  POST /api/batch/reanalyze        - Re-analyze all documents (or filtered set)
  POST /api/batch/reanalyze/{id}   - Re-analyze a single document (validation only)
  GET  /api/batch/rules            - Get current rule configuration
  PUT  /api/batch/rules            - Update rule configuration & trigger re-analysis
"""

from __future__ import annotations

import time
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlmodel import Session, select, delete

from app.core.config import get_settings
from app.db.models import Anomaly, Document, Transaction
from app.db.session import get_session
from app.services.validation import run_validations, CURRENCY_PROFILES, DEFAULT_PROFILE
from app.services.excel_normalizer import normalize_excel_statement
from app.services.storage import read_file
from app.api.ingestion import (
    _persist_anomalies,
    CONFIDENCE_ERROR_PENALTY,
    CONFIDENCE_CRITICAL_WARN_PENALTY,
    CONFIDENCE_NORMAL_WARN_PENALTY,
    CONFIDENCE_INFO_PENALTY,
    CONFIDENCE_FLOOR,
    CONFIDENCE_FRAUD_CAP,
)

router = APIRouter(prefix="/batch")


class RuleUpdate(BaseModel):
    """Payload for updating forensic rule thresholds."""
    confidence_error_penalty: Optional[float] = None
    confidence_critical_warn_penalty: Optional[float] = None
    confidence_normal_warn_penalty: Optional[float] = None
    confidence_info_penalty: Optional[float] = None
    confidence_floor: Optional[float] = None
    confidence_fraud_cap: Optional[float] = None
    # Currency profile overrides
    currency_overrides: Optional[Dict[str, Dict[str, float]]] = None
    # Whether to auto-trigger batch re-analysis after update
    auto_reanalyze: bool = True


# In-memory rule overrides (reset on server restart — could persist to DB later)
_rule_overrides: Dict[str, Any] = {}


def _get_effective_rules() -> Dict[str, Any]:
    """Return the current effective rule configuration."""
    return {
        "confidence_error_penalty": _rule_overrides.get("confidence_error_penalty", CONFIDENCE_ERROR_PENALTY),
        "confidence_critical_warn_penalty": _rule_overrides.get("confidence_critical_warn_penalty", CONFIDENCE_CRITICAL_WARN_PENALTY),
        "confidence_normal_warn_penalty": _rule_overrides.get("confidence_normal_warn_penalty", CONFIDENCE_NORMAL_WARN_PENALTY),
        "confidence_info_penalty": _rule_overrides.get("confidence_info_penalty", CONFIDENCE_INFO_PENALTY),
        "confidence_floor": _rule_overrides.get("confidence_floor", CONFIDENCE_FLOOR),
        "confidence_fraud_cap": _rule_overrides.get("confidence_fraud_cap", CONFIDENCE_FRAUD_CAP),
        "currency_profiles": {**CURRENCY_PROFILES, **(_rule_overrides.get("currency_overrides") or {})},
        "default_currency_profile": DEFAULT_PROFILE,
    }


def _recompute_confidence(
    base_confidence: float,
    errors: List[Dict[str, Any]],
    warnings: List[Dict[str, Any]],
    has_metadata_fraud: bool,
) -> float:
    """Recompute confidence using current effective rules."""
    rules = _get_effective_rules()
    confidence = base_confidence

    if has_metadata_fraud:
        confidence = min(confidence, rules["confidence_fraud_cap"])

    penalty = 0.0
    for _ in errors:
        penalty += rules["confidence_error_penalty"]
    for w in warnings:
        sev = w.get("severity", "warning") if isinstance(w, dict) else "warning"
        if sev == "critical":
            penalty += rules["confidence_critical_warn_penalty"]
        elif sev == "warning":
            penalty += rules["confidence_normal_warn_penalty"]
        else:
            penalty += rules["confidence_info_penalty"]

    if penalty > 0:
        confidence = max(rules["confidence_floor"], confidence - penalty)

    return round(confidence, 4)


def _reanalyze_single(doc: Document, session: Session) -> Dict[str, Any]:
    """Re-run validation on a single document using stored extracted_fields."""
    t0 = time.monotonic()

    extracted_fields = dict(doc.extracted_fields or {})
    original_confidence = doc.confidence

    # Re-run Excel normalization if the stored file is Excel
    is_excel = doc.filename.lower().endswith((".xlsx", ".xls", ".csv"))
    normalizer_anomalies: List[Dict[str, Any]] = []
    has_metadata_fraud = False

    if is_excel and doc.file_path:
        try:
            file_bytes = read_file(doc.file_path)
            excel_result = normalize_excel_statement(file_bytes, doc.filename)
            normalizer_anomalies = excel_result.detected_anomalies

            # Re-merge normalizer data
            if excel_result.transactions and len(excel_result.transactions) > len(extracted_fields.get("transactions") or []):
                extracted_fields["transactions"] = excel_result.transactions
            if excel_result.opening_balance is not None:
                extracted_fields["opening_balance"] = excel_result.opening_balance
            if excel_result.closing_balance is not None:
                extracted_fields["closing_balance"] = excel_result.closing_balance
            if excel_result.metadata_discrepancy:
                extracted_fields["metadata_discrepancy"] = excel_result.metadata_discrepancy
                has_metadata_fraud = True
            if excel_result.currency:
                extracted_fields["currency"] = excel_result.currency
        except Exception:
            pass  # Keep existing data if re-normalization fails

    # Check metadata_discrepancy from stored fields too
    if extracted_fields.get("metadata_discrepancy"):
        has_metadata_fraud = True

    # Re-run validation with latest rules
    errors, warnings, consistency = run_validations(
        doc.doc_type,
        extracted_fields,
        session,
    )

    # Recompute confidence
    base_confidence = original_confidence
    # If there was a prior backboard confidence, try to recover it
    # (use 0.85 as a reasonable base when we can't determine original)
    if has_metadata_fraud:
        base_confidence = 0.85
    new_confidence = _recompute_confidence(base_confidence, errors, warnings, has_metadata_fraud)

    # Determine new status
    settings = get_settings()
    status = "processed"
    review_reasons = []
    if errors:
        status = "review"
        review_reasons.append("validation_errors")
    if new_confidence < settings.review_confidence_threshold:
        status = "review"
        review_reasons.append("low_confidence")
    if any(a.get("severity") == "critical" for a in normalizer_anomalies):
        status = "review"
        review_reasons.append("critical_anomaly_detected")

    # Update document
    doc.extracted_fields = extracted_fields
    doc.validation_errors = errors
    doc.validation_warnings = warnings
    doc.consistency = consistency
    doc.confidence = new_confidence
    doc.status = status
    session.add(doc)

    # Clear old anomalies and re-persist
    old_anomalies = session.exec(
        select(Anomaly).where(Anomaly.document_id == doc.id)
    ).all()
    for a in old_anomalies:
        session.delete(a)
    session.flush()

    _persist_anomalies(session, doc.id, warnings, errors, normalizer_anomalies)

    processing_ms = int((time.monotonic() - t0) * 1000)

    return {
        "document_id": doc.id,
        "filename": doc.filename,
        "previous_confidence": round(original_confidence, 3),
        "new_confidence": round(new_confidence, 3),
        "previous_status": doc.status,
        "new_status": status,
        "errors": len(errors),
        "warnings": len(warnings),
        "anomalies": len(normalizer_anomalies) + len(warnings) + len(errors),
        "review_reasons": review_reasons,
        "reanalysis_time_ms": processing_ms,
    }


@router.get("/rules", summary="Get current forensic rule configuration")
async def get_rules() -> Dict[str, Any]:
    """Returns the current effective forensic rule configuration."""
    return {
        "rules": _get_effective_rules(),
        "overrides_active": bool(_rule_overrides),
    }


@router.put("/rules", summary="Update forensic rules and optionally trigger batch re-analysis")
async def update_rules(
    update: RuleUpdate,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """Update forensic rule thresholds. Optionally triggers batch re-analysis."""
    global _rule_overrides

    # Apply overrides
    if update.confidence_error_penalty is not None:
        _rule_overrides["confidence_error_penalty"] = update.confidence_error_penalty
    if update.confidence_critical_warn_penalty is not None:
        _rule_overrides["confidence_critical_warn_penalty"] = update.confidence_critical_warn_penalty
    if update.confidence_normal_warn_penalty is not None:
        _rule_overrides["confidence_normal_warn_penalty"] = update.confidence_normal_warn_penalty
    if update.confidence_info_penalty is not None:
        _rule_overrides["confidence_info_penalty"] = update.confidence_info_penalty
    if update.confidence_floor is not None:
        _rule_overrides["confidence_floor"] = update.confidence_floor
    if update.confidence_fraud_cap is not None:
        _rule_overrides["confidence_fraud_cap"] = update.confidence_fraud_cap
    if update.currency_overrides:
        _rule_overrides["currency_overrides"] = update.currency_overrides

    result: Dict[str, Any] = {
        "status": "rules_updated",
        "effective_rules": _get_effective_rules(),
    }

    # Auto-trigger batch re-analysis if requested
    if update.auto_reanalyze:
        docs = session.exec(select(Document)).all()
        reanalysis_results = []
        for doc in docs:
            try:
                r = _reanalyze_single(doc, session)
                reanalysis_results.append(r)
            except Exception as exc:
                reanalysis_results.append({
                    "document_id": doc.id,
                    "filename": doc.filename,
                    "error": str(exc),
                })
        session.commit()

        confidence_changes = [
            r for r in reanalysis_results
            if "new_confidence" in r and r.get("previous_confidence") != r.get("new_confidence")
        ]
        status_changes = [
            r for r in reanalysis_results
            if "new_status" in r and r.get("previous_status") != r.get("new_status")
        ]

        result["reanalysis"] = {
            "total_documents": len(docs),
            "reanalyzed": len(reanalysis_results),
            "confidence_changed": len(confidence_changes),
            "status_changed": len(status_changes),
            "documents": reanalysis_results,
        }

    return result


@router.post("/reanalyze", summary="Batch re-analyze all documents")
async def batch_reanalyze(
    doc_type: Optional[str] = Query(default=None, description="Filter by doc_type"),
    status_filter: Optional[str] = Query(default=None, description="Filter by status (review, processed, etc.)"),
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """Re-run validation and anomaly detection on all (or filtered) documents."""
    t0 = time.monotonic()

    query = select(Document)
    if doc_type:
        query = query.where(Document.doc_type == doc_type)
    if status_filter:
        query = query.where(Document.status == status_filter)

    docs = session.exec(query).all()
    if not docs:
        return {"status": "no_documents", "message": "No documents match the filter criteria."}

    results: List[Dict[str, Any]] = []
    for doc in docs:
        try:
            r = _reanalyze_single(doc, session)
            results.append(r)
        except Exception as exc:
            results.append({
                "document_id": doc.id,
                "filename": doc.filename,
                "error": str(exc),
            })

    session.commit()

    total_ms = int((time.monotonic() - t0) * 1000)

    return {
        "status": "batch_reanalysis_complete",
        "total_documents": len(docs),
        "total_time_ms": total_ms,
        "results": results,
        "summary": {
            "errors_found": sum(r.get("errors", 0) for r in results if "errors" in r),
            "warnings_found": sum(r.get("warnings", 0) for r in results if "warnings" in r),
            "status_changed": sum(
                1 for r in results
                if r.get("previous_status") and r.get("new_status") and r["previous_status"] != r["new_status"]
            ),
        },
    }


@router.post("/reanalyze/{doc_id}", summary="Re-analyze a single document")
async def reanalyze_single_document(
    doc_id: str,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """Re-run validation on a single document using latest rules."""
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    result = _reanalyze_single(doc, session)
    session.commit()

    return {"status": "reanalyzed", **result}
