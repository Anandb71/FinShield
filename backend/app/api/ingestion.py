"""Finsight - Bulk ingestion API."""

import time
from typing import Any, Dict, List
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlmodel import Session

from app.core.config import get_settings
from app.db.session import get_session
from app.db.models import Anomaly, Document, Transaction
from app.services.backboard_client import BackboardClient
from app.services.entity_resolution import resolve_entities
from app.services.excel_normalizer import normalize_excel_statement
from app.services.validation import run_validations
from app.services.storage import save_file
from app.services.file_preprocess import normalize_input
from app.services.quality import score_image_quality
from app.services.layout import detect_layout_flags
from app.services.knowledge_graph import build_graph_from_document, get_knowledge_store, KGNode

router = APIRouter(prefix="/ingestion")

# ── Confidence-adjustment constants ──────────────────────────────────
CONFIDENCE_FRAUD_CAP = 0.12          # max confidence when metadata fraud detected
CONFIDENCE_ERROR_PENALTY = 0.15      # per validation error
CONFIDENCE_CRITICAL_WARN_PENALTY = 0.10  # per critical warning
CONFIDENCE_NORMAL_WARN_PENALTY = 0.03    # per normal warning
CONFIDENCE_INFO_PENALTY = 0.01       # per info warning
CONFIDENCE_FLOOR = 0.10              # absolute minimum confidence


def _persist_transactions(session: Session, doc_id: str, transactions: List[Dict[str, Any]]) -> List[Transaction]:
    """Save extracted transactions to the database."""
    records = []
    for tx in transactions:
        record = Transaction(
            document_id=doc_id,
            row_index=tx.get("row_index", 0),
            date=str(tx.get("date") or ""),
            description=str(tx.get("description") or ""),
            amount=tx.get("amount"),
            tx_type=tx.get("tx_type", "unknown"),
            balance_after=tx.get("balance"),
            merchant_normalized=tx.get("merchant_normalized"),
            category=tx.get("category"),
        )
        session.add(record)
        records.append(record)
    if records:
        session.flush()
    return records


def _persist_anomalies(
    session: Session,
    doc_id: str,
    validation_warnings: List[Dict[str, Any]],
    validation_errors: List[Dict[str, Any]],
    normalizer_anomalies: List[Dict[str, Any]],
) -> List[Anomaly]:
    """Save forensic anomalies to the database."""
    records = []

    # From normalizer (Excel-level anomalies)
    for a in normalizer_anomalies:
        record = Anomaly(
            document_id=doc_id,
            anomaly_type=a.get("type", "unknown"),
            severity=a.get("severity", "warning"),
            description=a.get("description", ""),
            details=a,
            row_index=a.get("row"),
        )
        session.add(record)
        records.append(record)

    # From validation warnings
    type_map = {
        "closing_balance": "balance_discontinuity",
        "balance": "balance_discontinuity",
        "benford": "benford_anomaly",
        "round_numbers": "round_number_syndrome",
        "structuring": "structuring",
        "velocity": "velocity_smurfing",
        "cashflow": "cashflow_anomaly",
        "synthetic": "synthetic_pattern",
        "transactions": "data_quality",
        "date_sequence": "date_sequence_anomaly",
        "metadata_integrity": "metadata_integrity_failure",
    }
    for w in validation_warnings:
        field = w.get("field", "unknown")
        anomaly_type = type_map.get(field, field)
        # Use severity from validation if available, else infer
        severity = w.get("severity", "warning")
        record = Anomaly(
            document_id=doc_id,
            anomaly_type=anomaly_type,
            severity=severity,
            description=str(w.get("message", "")),
            details=w,
        )
        session.add(record)
        records.append(record)

    # From validation errors (always critical)
    for e in validation_errors:
        record = Anomaly(
            document_id=doc_id,
            anomaly_type=type_map.get(e.get("field", ""), "validation_error"),
            severity="critical",
            description=str(e.get("message", "")),
            details=e,
        )
        session.add(record)
        records.append(record)

    if records:
        session.flush()
    return records


@router.post("/documents", summary="Bulk-ingest financial documents")
async def ingest_documents(
    files: List[UploadFile] = File(...),
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    if not files:
        raise HTTPException(status_code=400, detail="At least one file is required")

    settings = get_settings()
    client = BackboardClient()
    results: List[Dict[str, Any]] = []
    batch_id = str(uuid4())

    for upload in files:
        t0 = time.monotonic()
        content = await upload.read()
        if not content:
            results.append(
                {"filename": upload.filename or "unknown", "status": "failed", "error": "Empty file"}
            )
            continue

        if len(content) > settings.max_upload_mb * 1024 * 1024:
            results.append(
                {"filename": upload.filename or "unknown", "status": "failed", "error": "File too large"}
            )
            continue

        debug_log: List[str] = []
        review_reasons: List[str] = []
        normalizer_anomalies: List[Dict[str, Any]] = []
        debug_log.append(f"received: {upload.filename or 'unknown'} ({len(content)} bytes)")
        debug_log.append(f"batch_id: {batch_id}")

        # ── Excel-first path: use the normalization worker ──────────
        is_excel = (upload.filename or "").lower().endswith((".xlsx", ".xls", ".csv"))
        excel_result = None
        if is_excel:
            debug_log.append("route: Excel Parser Queue (normalization worker)")
            excel_result = normalize_excel_statement(content, upload.filename or "")
            debug_log.extend(excel_result.repair_log)
            normalizer_anomalies = excel_result.detected_anomalies
            if normalizer_anomalies:
                debug_log.append(f"normalizer_anomalies: {len(normalizer_anomalies)}")
        else:
            debug_log.append("route: OCR Queue (Backboard intelligence)")

        # ── FIX #7: Only run image QA on non-Excel files ──
        if is_excel:
            quality_metrics: Dict[str, Any] = {"score": None, "skipped": True, "reason": "excel_file"}
            debug_log.append("image_qa: skipped (Excel file)")
        else:
            quality_metrics = score_image_quality(content)
        local_layout = detect_layout_flags(content)
        normalized = normalize_input(upload.filename or "document", content)
        debug_log.append(
            f"normalized: {normalized.normalized_name} ({normalized.normalized_mime})"
            + (" [converted]" if normalized.converted else "")
        )
        debug_log.append(f"backboard_model: {settings.backboard_model_name}")

        try:
            analysis = await client.analyze_document(
                normalized.normalized_bytes,
                normalized.normalized_name,
                mime_type=normalized.normalized_mime,
                fallback_bytes=normalized.original_bytes if normalized.converted else None,
                fallback_filename=normalized.original_name if normalized.converted else None,
                fallback_mime=normalized.original_mime if normalized.converted else None,
            )
        except Exception as exc:
            results.append(
                {
                    "filename": upload.filename or "unknown",
                    "status": "failed",
                    "error": str(exc),
                    "debug_log": debug_log + [f"backboard_error: {exc}"],
                }
            )
            continue

        classification = analysis.get("classification", {})
        # Ensure extracted_fields is a mutable plain dict (some backends return special objects)
        extracted_fields = dict(analysis.get("extracted_fields", {}))
        remote_layout = analysis.get("layout", {})
        layout_flags = {**local_layout, **remote_layout}
        backboard_thread_id = analysis.get("document_id")
        parse_error = analysis.get("parse_error")
        debug_log.append(
            f"classification: {classification.get('type', 'unknown')}"
            f" (confidence={classification.get('confidence')})"
        )
        debug_log.append("confidence_source: backboard")
        if parse_error:
            debug_log.append(f"parse_error: {parse_error}")

        # ── FIX #8: Merge Excel normalizer data — prefer normalizer when it
        #    extracts more transactions than Backboard ──
        if excel_result and excel_result.transactions:
            backboard_txns = extracted_fields.get("transactions") or []
            if len(excel_result.transactions) > len(backboard_txns):
                # Keep ALL normalizer fields (tx_type, row_index, cheque_no, etc.)
                extracted_fields["transactions"] = excel_result.transactions
                debug_log.append(
                    f"using normalizer transactions ({len(excel_result.transactions)}) "
                    f"over backboard ({len(backboard_txns)})"
                )
            # Normalizer balances take priority over Backboard for Excel files
            if excel_result.opening_balance is not None:
                extracted_fields["opening_balance"] = excel_result.opening_balance
            if excel_result.closing_balance is not None:
                extracted_fields["closing_balance"] = excel_result.closing_balance

            # Pass metadata discrepancy to frontend for dynamic integrity display
            if excel_result.metadata_discrepancy:
                extracted_fields["metadata_discrepancy"] = excel_result.metadata_discrepancy

            # Pass detected currency for multi-currency support
            if excel_result.currency:
                extracted_fields["currency"] = excel_result.currency

        if classification.get("type") == "bank_statement":
            opening_balance = extracted_fields.get("opening_balance")
            closing_balance = extracted_fields.get("closing_balance")
            transactions = extracted_fields.get("transactions") or []
            tx_total = 0.0
            for tx in transactions:
                try:
                    tx_total += float(tx.get("amount") or 0)
                except (TypeError, ValueError):
                    continue
            debug_log.append(
                "flow_summary: opening="
                + str(opening_balance)
                + ", closing="
                + str(closing_balance)
                + ", tx_count="
                + str(len(transactions))
                + ", tx_total="
                + str(round(tx_total, 2))
            )

        errors, warnings, consistency = run_validations(
            classification.get("type", "unknown"),
            extracted_fields,
            session,
        )
        if parse_error:
            warnings.append({"field": "backboard", "message": parse_error})

        debug_log.append(f"validation_errors: {len(errors)} | warnings: {len(warnings)}")
        if warnings:
            warning_msgs = []
            for warn in warnings:
                if isinstance(warn, dict):
                    warning_msgs.append(str(warn.get("message") or warn))
                else:
                    warning_msgs.append(str(warn))
            debug_log.append(f"warning_messages: {', '.join(warning_msgs)}")

        confidence = classification.get("confidence") or 0.0

        # ── Metadata Integrity Check: massive penalty for header fraud ──
        if excel_result and excel_result.metadata_discrepancy:
            disc = excel_result.metadata_discrepancy
            debug_log.append(
                f"METADATA INTEGRITY FAILURE: header_closing={disc['header_closing']}, "
                f"calculated_closing={disc['calculated_closing']}, "
                f"discrepancy={disc['discrepancy']:,.2f}, ratio={disc['ratio']:.1f}x"
            )
            # This is a fraud signal — slam confidence to near zero
            confidence = min(confidence, CONFIDENCE_FRAUD_CAP)
            debug_log.append(f"confidence_slammed_to: {confidence} (metadata fraud)")
            # Also inject as a validation error so it shows in the UI
            errors.append({
                "field": "metadata_integrity",
                "message": (
                    f"FRAUD: Header closing balance ({disc['header_closing']:,.2f}) "
                    f"does not match calculated balance ({disc['calculated_closing']:,.2f}). "
                    f"Discrepancy: {disc['discrepancy']:,.2f}"
                ),
                "severity": "critical",
            })

        # ── FIX #9: Penalize confidence based on validation issues ──
        confidence_penalty = 0.0
        for e in errors:
            confidence_penalty += CONFIDENCE_ERROR_PENALTY
        for w in warnings:
            sev = w.get("severity", "warning") if isinstance(w, dict) else "warning"
            if sev == "critical":
                confidence_penalty += CONFIDENCE_CRITICAL_WARN_PENALTY
            elif sev == "warning":
                confidence_penalty += CONFIDENCE_NORMAL_WARN_PENALTY
            else:
                confidence_penalty += CONFIDENCE_INFO_PENALTY
        if confidence_penalty > 0:
            original_confidence = confidence
            confidence = max(CONFIDENCE_FLOOR, confidence - confidence_penalty)
            debug_log.append(
                f"confidence_adjusted: {original_confidence:.2f} -> {confidence:.2f} "
                f"(penalty={confidence_penalty:.2f} from {len(errors)} errors, {len(warnings)} warnings)"
            )

        image_quality = classification.get("image_quality_score") or quality_metrics.get("score")
        status = "processed"
        if errors:
            status = "review"
            review_reasons.append("validation_errors")
        if confidence < settings.review_confidence_threshold:
            status = "review"
            review_reasons.append(
                f"low_confidence<{settings.review_confidence_threshold}"
            )
        if image_quality is not None and image_quality < settings.review_quality_threshold:
            status = "review"
            review_reasons.append(
                f"low_quality<{settings.review_quality_threshold}"
            )
        if classification.get("type") in (None, "unknown"):
            status = "review"
            review_reasons.append("unknown_type")

        if status == "processed" and warnings:
            review_reasons.append("warnings_present")

        if normalizer_anomalies:
            has_critical = any(a.get("severity") == "critical" for a in normalizer_anomalies)
            if has_critical:
                status = "review"
                review_reasons.append("critical_anomaly_detected")

        if review_reasons:
            debug_log.append(f"review_reasons: {', '.join(review_reasons)}")
        else:
            debug_log.append("review_reasons: none")

        processing_time_ms = int((time.monotonic() - t0) * 1000)
        debug_log.append(f"processing_time: {processing_time_ms}ms")

        doc = Document(
            filename=normalized.normalized_name,
            batch_id=batch_id,
            backboard_thread_id=backboard_thread_id,
            doc_type=classification.get("type", "unknown"),
            confidence=confidence,
            language=classification.get("language"),
            image_quality=image_quality,
            status=status,
            layout_flags=layout_flags,
            quality_metrics=quality_metrics,
            extracted_fields=extracted_fields,
            validation_errors=errors,
            validation_warnings=warnings,
            consistency=consistency,
            processing_time_ms=processing_time_ms,
        )
        doc.file_path = save_file(doc.id, doc.filename, normalized.normalized_bytes)
        session.add(doc)
        session.commit()
        session.refresh(doc)

        # Persist transactions to DB
        tx_list = extracted_fields.get("transactions") or []
        if tx_list:
            _persist_transactions(session, doc.id, tx_list)

        # Persist anomalies to DB
        _persist_anomalies(session, doc.id, warnings, errors, normalizer_anomalies)
        session.commit()

        entities = resolve_entities(session, doc.id, extracted_fields)
        entity_nodes = [
            KGNode(
                id=entity.id,
                type=entity.entity_type,
                properties={"canonical_value": entity.canonical_value},
            )
            for entity in entities
        ]
        graph = build_graph_from_document(doc.id, doc.doc_type, extracted_fields, entity_nodes)
        get_knowledge_store().upsert_document_graph(graph)

        results.append(
            {
                "document_id": doc.id,
                "filename": doc.filename,
                "doc_type": doc.doc_type,
                "confidence": doc.confidence,
                "status": status,
                "layout": layout_flags,
                "quality_metrics": quality_metrics,
                "error": parse_error,
                "debug_log": debug_log,
                "review_reasons": review_reasons,
                "processing_time_ms": processing_time_ms,
                "validation": {
                    "errors": errors,
                    "warnings": warnings,
                },
                "anomalies_count": len(normalizer_anomalies) + len(warnings) + len(errors),
            }
        )

    return {"batch_id": batch_id, "documents": results}

