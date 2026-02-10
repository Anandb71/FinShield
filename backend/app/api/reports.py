"""
FinShield - Automated Report Generation API

Generates comprehensive forensic analysis reports for documents.
Reports include:
  - Document classification & confidence
  - Validation results (errors, warnings, consistency)
  - Anomaly breakdown (by type, severity)
  - Transaction summary & statistics
  - Risk assessment & recommendations
  - Currency & multi-currency metadata
"""

from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import HTMLResponse
from sqlmodel import Session, select

from app.db.models import Anomaly, Document, Transaction
from app.db.session import get_session

router = APIRouter(prefix="/reports")


# ── Risk-level thresholds (data-driven) ──────────────────────────────
RISK_CRITICAL_THRESHOLD = 3   # ≥ N critical anomalies → HIGH risk
RISK_WARNING_THRESHOLD = 5    # ≥ N warnings → MEDIUM risk
CONFIDENCE_HIGH_CUTOFF = 0.80
CONFIDENCE_MEDIUM_CUTOFF = 0.50


def _assess_risk(
    confidence: float,
    critical_count: int,
    warning_count: int,
    error_count: int,
) -> Dict[str, Any]:
    """Compute overall risk level from forensic signals."""
    if critical_count >= RISK_CRITICAL_THRESHOLD or confidence < CONFIDENCE_MEDIUM_CUTOFF:
        level = "HIGH"
        color = "#FF6B6B"
    elif error_count > 0 or warning_count >= RISK_WARNING_THRESHOLD or confidence < CONFIDENCE_HIGH_CUTOFF:
        level = "MEDIUM"
        color = "#FFB86C"
    else:
        level = "LOW"
        color = "#41EAD4"

    recommendations = []
    if critical_count > 0:
        recommendations.append("Critical anomalies detected — manual forensic review required.")
    if error_count > 0:
        recommendations.append("Validation errors present — verify source document authenticity.")
    if warning_count >= RISK_WARNING_THRESHOLD:
        recommendations.append("Multiple warnings — cross-reference with external records.")
    if confidence < CONFIDENCE_MEDIUM_CUTOFF:
        recommendations.append("Very low confidence — consider re-ingestion or alternative source.")
    if not recommendations:
        recommendations.append("No significant issues detected. Document appears clean.")

    return {
        "level": level,
        "color": color,
        "confidence": round(confidence, 3),
        "critical_anomalies": critical_count,
        "warnings": warning_count,
        "errors": error_count,
        "recommendations": recommendations,
    }


def _transaction_stats(transactions: List[Transaction]) -> Dict[str, Any]:
    """Compute transaction statistics."""
    if not transactions:
        return {"count": 0}
    amounts = [t.amount for t in transactions if t.amount is not None]
    credits = [a for a in amounts if a > 0]
    debits = [abs(a) for a in amounts if a < 0]
    return {
        "count": len(transactions),
        "total_credits": round(sum(credits), 2) if credits else 0,
        "total_debits": round(sum(debits), 2) if debits else 0,
        "net_flow": round(sum(amounts), 2) if amounts else 0,
        "avg_transaction": round(sum(abs(a) for a in amounts) / len(amounts), 2) if amounts else 0,
        "max_credit": round(max(credits), 2) if credits else 0,
        "max_debit": round(max(debits), 2) if debits else 0,
        "credit_count": len(credits),
        "debit_count": len(debits),
    }


@router.get("/{doc_id}", summary="Generate forensic analysis report (JSON)")
async def generate_report(
    doc_id: str,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """Generate a comprehensive forensic analysis report for a document."""
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    anomalies = session.exec(
        select(Anomaly).where(Anomaly.document_id == doc_id)
    ).all()

    transactions = session.exec(
        select(Transaction).where(Transaction.document_id == doc_id)
    ).all()

    # Anomaly breakdown
    anomaly_by_type: Dict[str, int] = {}
    anomaly_by_severity: Dict[str, int] = {"critical": 0, "warning": 0, "info": 0}
    anomaly_details: List[Dict[str, Any]] = []
    for a in anomalies:
        anomaly_by_type[a.anomaly_type] = anomaly_by_type.get(a.anomaly_type, 0) + 1
        anomaly_by_severity[a.severity] = anomaly_by_severity.get(a.severity, 0) + 1
        anomaly_details.append({
            "type": a.anomaly_type,
            "severity": a.severity,
            "description": a.description,
            "row_index": a.row_index,
        })

    tx_stats = _transaction_stats(transactions)

    risk = _assess_risk(
        doc.confidence,
        anomaly_by_severity.get("critical", 0),
        anomaly_by_severity.get("warning", 0),
        len(doc.validation_errors or []),
    )

    # Extract currency if present
    currency = (doc.extracted_fields or {}).get("currency", "Unknown")

    report = {
        "report_id": f"RPT-{doc.id[:8].upper()}",
        "generated_at": datetime.utcnow().isoformat(),
        "document": {
            "id": doc.id,
            "filename": doc.filename,
            "doc_type": doc.doc_type,
            "status": doc.status,
            "confidence": round(doc.confidence, 3),
            "language": doc.language,
            "image_quality": doc.image_quality,
            "processing_time_ms": doc.processing_time_ms,
            "created_at": doc.created_at.isoformat(),
            "currency": currency,
        },
        "risk_assessment": risk,
        "validation": {
            "errors": doc.validation_errors or [],
            "warnings": doc.validation_warnings or [],
            "consistency": doc.consistency or {},
            "error_count": len(doc.validation_errors or []),
            "warning_count": len(doc.validation_warnings or []),
        },
        "anomalies": {
            "total": len(anomalies),
            "by_type": anomaly_by_type,
            "by_severity": anomaly_by_severity,
            "details": anomaly_details,
        },
        "transactions": tx_stats,
        "extracted_fields": {
            k: v for k, v in (doc.extracted_fields or {}).items()
            if k != "transactions"  # Don't include full txn list in report summary
        },
    }

    return report


@router.get("/{doc_id}/html", summary="Generate downloadable HTML report")
async def generate_html_report(
    doc_id: str,
    session: Session = Depends(get_session),
) -> HTMLResponse:
    """Generate a styled HTML forensic report suitable for printing/PDF export."""
    doc = session.get(Document, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    anomalies = session.exec(
        select(Anomaly).where(Anomaly.document_id == doc_id)
    ).all()

    transactions = session.exec(
        select(Transaction).where(Transaction.document_id == doc_id)
    ).all()

    anomaly_by_severity: Dict[str, int] = {"critical": 0, "warning": 0, "info": 0}
    for a in anomalies:
        anomaly_by_severity[a.severity] = anomaly_by_severity.get(a.severity, 0) + 1

    tx_stats = _transaction_stats(transactions)
    risk = _assess_risk(
        doc.confidence,
        anomaly_by_severity.get("critical", 0),
        anomaly_by_severity.get("warning", 0),
        len(doc.validation_errors or []),
    )
    currency = (doc.extracted_fields or {}).get("currency", "—")

    # Build anomaly rows
    anomaly_rows = ""
    for a in anomalies:
        sev_color = {"critical": "#FF6B6B", "warning": "#FFB86C", "info": "#9B8CFF"}.get(a.severity, "#ccc")
        anomaly_rows += f"""
        <tr>
          <td><span style="color:{sev_color};font-weight:bold">{a.severity.upper()}</span></td>
          <td>{a.anomaly_type}</td>
          <td>{a.description}</td>
          <td>{a.row_index or '—'}</td>
        </tr>"""

    # Build validation error rows
    error_rows = ""
    for e in (doc.validation_errors or []):
        error_rows += f"""
        <tr>
          <td style="color:#FF6B6B">ERROR</td>
          <td>{e.get('field', '—')}</td>
          <td>{e.get('message', '—')}</td>
        </tr>"""

    # Build validation warning rows
    for w in (doc.validation_warnings or []):
        sev = w.get("severity", "warning") if isinstance(w, dict) else "warning"
        sev_color = {"critical": "#FF6B6B", "warning": "#FFB86C", "info": "#9B8CFF"}.get(sev, "#ccc")
        error_rows += f"""
        <tr>
          <td><span style="color:{sev_color}">{sev.upper()}</span></td>
          <td>{w.get('field', '—') if isinstance(w, dict) else '—'}</td>
          <td>{w.get('message', str(w)) if isinstance(w, dict) else str(w)}</td>
        </tr>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>FinShield Forensic Report — {doc.filename}</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: 'Segoe UI', system-ui, sans-serif; background: #0C0F1A; color: #E0E0E0; padding: 40px; }}
  .container {{ max-width: 900px; margin: 0 auto; }}
  h1 {{ color: #41EAD4; font-size: 28px; margin-bottom: 4px; }}
  h2 {{ color: #9B8CFF; font-size: 18px; margin: 32px 0 12px; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 8px; }}
  .subtitle {{ color: rgba(255,255,255,0.6); font-size: 13px; margin-bottom: 24px; }}
  .risk-badge {{ display: inline-block; padding: 6px 20px; border-radius: 20px; font-weight: bold; font-size: 16px; }}
  .grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }}
  .card {{ background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; padding: 16px; }}
  .card-label {{ font-size: 12px; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 1px; }}
  .card-value {{ font-size: 22px; font-weight: bold; margin-top: 4px; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 8px; }}
  th {{ text-align: left; font-size: 12px; color: rgba(255,255,255,0.5); text-transform: uppercase; padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.1); }}
  td {{ padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.05); font-size: 13px; }}
  .rec {{ background: rgba(65,234,212,0.08); border-left: 3px solid #41EAD4; padding: 10px 14px; margin: 6px 0; border-radius: 6px; font-size: 13px; }}
  .footer {{ margin-top: 40px; text-align: center; color: rgba(255,255,255,0.3); font-size: 12px; }}
  @media print {{ body {{ background: white; color: #222; }} .card {{ border-color: #ddd; }} }}
</style>
</head>
<body>
<div class="container">
  <h1>🛡️ FinShield Forensic Report</h1>
  <p class="subtitle">Report ID: RPT-{doc.id[:8].upper()} &nbsp;|&nbsp; Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}</p>

  <h2>Document Overview</h2>
  <div class="grid">
    <div class="card">
      <div class="card-label">Filename</div>
      <div class="card-value" style="font-size:16px">{doc.filename}</div>
    </div>
    <div class="card">
      <div class="card-label">Document Type</div>
      <div class="card-value">{doc.doc_type}</div>
    </div>
    <div class="card">
      <div class="card-label">Confidence</div>
      <div class="card-value">{doc.confidence:.1%}</div>
    </div>
    <div class="card">
      <div class="card-label">Currency</div>
      <div class="card-value">{currency}</div>
    </div>
    <div class="card">
      <div class="card-label">Status</div>
      <div class="card-value">{doc.status.upper()}</div>
    </div>
    <div class="card">
      <div class="card-label">Processing Time</div>
      <div class="card-value">{doc.processing_time_ms or '—'} ms</div>
    </div>
  </div>

  <h2>Risk Assessment</h2>
  <div style="margin-bottom:16px">
    <span class="risk-badge" style="background:{risk['color']}20;color:{risk['color']};border:1px solid {risk['color']}">{risk['level']} RISK</span>
  </div>
  <div class="grid">
    <div class="card">
      <div class="card-label">Critical Anomalies</div>
      <div class="card-value" style="color:#FF6B6B">{risk['critical_anomalies']}</div>
    </div>
    <div class="card">
      <div class="card-label">Warnings</div>
      <div class="card-value" style="color:#FFB86C">{risk['warnings']}</div>
    </div>
  </div>
  <h3 style="color:rgba(255,255,255,0.7);font-size:14px;margin:16px 0 8px">Recommendations</h3>
  {''.join(f'<div class="rec">{r}</div>' for r in risk['recommendations'])}

  <h2>Transaction Summary</h2>
  <div class="grid">
    <div class="card">
      <div class="card-label">Total Transactions</div>
      <div class="card-value">{tx_stats.get('count', 0)}</div>
    </div>
    <div class="card">
      <div class="card-label">Net Flow</div>
      <div class="card-value">{tx_stats.get('net_flow', 0):,.2f}</div>
    </div>
    <div class="card">
      <div class="card-label">Total Credits ({tx_stats.get('credit_count', 0)})</div>
      <div class="card-value" style="color:#41EAD4">{tx_stats.get('total_credits', 0):,.2f}</div>
    </div>
    <div class="card">
      <div class="card-label">Total Debits ({tx_stats.get('debit_count', 0)})</div>
      <div class="card-value" style="color:#FF6B6B">{tx_stats.get('total_debits', 0):,.2f}</div>
    </div>
  </div>

  <h2>Validation Results</h2>
  <table>
    <thead><tr><th>Severity</th><th>Field</th><th>Message</th></tr></thead>
    <tbody>
      {error_rows if error_rows else '<tr><td colspan="3" style="color:#41EAD4">✓ No validation issues</td></tr>'}
    </tbody>
  </table>

  <h2>Anomaly Log ({len(anomalies)} total)</h2>
  <table>
    <thead><tr><th>Severity</th><th>Type</th><th>Description</th><th>Row</th></tr></thead>
    <tbody>
      {anomaly_rows if anomaly_rows else '<tr><td colspan="4" style="color:#41EAD4">✓ No anomalies detected</td></tr>'}
    </tbody>
  </table>

  <div class="footer">
    <p>FinShield — AI-Powered Financial Document Forensics</p>
    <p>This report was auto-generated. Always verify findings with original source documents.</p>
  </div>
</div>
</body>
</html>"""

    return HTMLResponse(content=html, media_type="text/html")


@router.get("/batch/{batch_id}", summary="Generate batch summary report")
async def generate_batch_report(
    batch_id: str,
    session: Session = Depends(get_session),
) -> Dict[str, Any]:
    """Generate an aggregate report for all documents in a batch."""
    docs = session.exec(
        select(Document).where(Document.batch_id == batch_id)
    ).all()
    if not docs:
        raise HTTPException(status_code=404, detail="Batch not found")

    all_anomalies = session.exec(
        select(Anomaly).where(
            Anomaly.document_id.in_([d.id for d in docs])  # type: ignore
        )
    ).all()

    anomaly_by_severity: Dict[str, int] = {"critical": 0, "warning": 0, "info": 0}
    for a in all_anomalies:
        anomaly_by_severity[a.severity] = anomaly_by_severity.get(a.severity, 0) + 1

    doc_summaries = []
    total_errors = 0
    total_warnings = 0
    for doc in docs:
        n_err = len(doc.validation_errors or [])
        n_warn = len(doc.validation_warnings or [])
        total_errors += n_err
        total_warnings += n_warn
        doc_summaries.append({
            "document_id": doc.id,
            "filename": doc.filename,
            "doc_type": doc.doc_type,
            "confidence": round(doc.confidence, 3),
            "status": doc.status,
            "errors": n_err,
            "warnings": n_warn,
            "currency": (doc.extracted_fields or {}).get("currency", "Unknown"),
        })

    avg_confidence = sum(d.confidence for d in docs) / len(docs) if docs else 0

    return {
        "report_id": f"BATCH-{batch_id[:8].upper()}",
        "generated_at": datetime.utcnow().isoformat(),
        "batch_id": batch_id,
        "summary": {
            "total_documents": len(docs),
            "avg_confidence": round(avg_confidence, 3),
            "total_errors": total_errors,
            "total_warnings": total_warnings,
            "total_anomalies": len(all_anomalies),
            "anomalies_by_severity": anomaly_by_severity,
            "status_distribution": {
                status: sum(1 for d in docs if d.status == status)
                for status in set(d.status for d in docs)
            },
        },
        "documents": doc_summaries,
    }
