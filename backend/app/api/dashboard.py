"""Finsight - Dashboard API."""

from datetime import datetime, timedelta, timezone
import math
from typing import Any, Dict, List, Tuple

from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.db.models import Anomaly, Correction, Document, Entity
from app.db.session import get_session
from app.services.learning import cluster_corrections

router = APIRouter(prefix="/dashboard")


@router.get("/metrics")
async def get_dashboard_metrics(session: Session = Depends(get_session)) -> Dict[str, Any]:
    docs = session.exec(select(Document)).all()
    corrections = session.exec(select(Correction)).all()
    entities = session.exec(select(Entity)).all()
    all_anomalies = session.exec(select(Anomaly)).all()

    total_docs = len(docs)
    total_corrections = len(corrections)
    error_rate = (total_corrections / total_docs) if total_docs else 0.0

    # Processing time stats
    processing_times = [d.processing_time_ms for d in docs if d.processing_time_ms is not None]
    avg_processing_time = round(sum(processing_times) / len(processing_times), 1) if processing_times else None
    max_processing_time = max(processing_times) if processing_times else None

    # Anomaly aggregation
    anomaly_by_type: Dict[str, int] = {}
    anomaly_by_severity: Dict[str, int] = {"critical": 0, "warning": 0, "info": 0}
    for a in all_anomalies:
        anomaly_by_type[a.anomaly_type] = anomaly_by_type.get(a.anomaly_type, 0) + 1
        anomaly_by_severity[a.severity] = anomaly_by_severity.get(a.severity, 0) + 1

    accuracy_by_type: Dict[str, Dict[str, float | int]] = {}
    for doc in docs:
        stats = accuracy_by_type.setdefault(
            doc.doc_type or "unknown", {"accuracy": 0.0, "count": 0, "passes": 0}
        )
        stats["count"] = int(stats["count"]) + 1
        if not doc.validation_errors:
            stats["passes"] = int(stats["passes"]) + 1

    for doc_type, stats in accuracy_by_type.items():
        count = int(stats["count"]) or 1
        passes = int(stats.get("passes", 0))
        stats["accuracy"] = passes / count
        stats.pop("passes", None)

    error_clusters = cluster_corrections(session).get("clusters", {})

    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    docs_last_7 = [doc for doc in docs if doc.created_at >= week_ago]
    corrections_last_7 = [corr for corr in corrections if corr.created_at >= week_ago]
    error_rate_7 = (len(corrections_last_7) / len(docs_last_7)) if docs_last_7 else 0.0

    avg_quality = None
    quality_scores = [doc.image_quality for doc in docs if doc.image_quality is not None]
    if quality_scores:
        avg_quality = sum(quality_scores) / len(quality_scores)

    benford_series = _build_benford_series(docs)
    flow_data = _build_money_flow(docs)

    # Status distribution
    status_dist: Dict[str, int] = {}
    for doc in docs:
        status_dist[doc.status] = status_dist.get(doc.status, 0) + 1

    metrics = {
        "overview": {
            "total_documents_processed": total_docs,
            "total_corrections": total_corrections,
            "error_rate": error_rate,
            "avg_processing_time_ms": avg_processing_time,
            "max_processing_time_ms": max_processing_time,
            "avg_quality_score": avg_quality,
        },
        "anomaly_overview": {
            "total_anomalies": len(all_anomalies),
            "by_type": anomaly_by_type,
            "by_severity": anomaly_by_severity,
            "density": round(len(all_anomalies) / total_docs, 2) if total_docs else 0,
        },
        "knowledge_graph": {
            "entities": len(entities),
            "documents": total_docs,
        },
        "accuracy_by_type": accuracy_by_type,
        "error_clusters": error_clusters,
        "quality_distribution": {
            "low": len([q for q in quality_scores if q < 0.4]),
            "medium": len([q for q in quality_scores if 0.4 <= q < 0.75]),
            "high": len([q for q in quality_scores if q >= 0.75]),
        },
        "status_distribution": status_dist,
        "benford": benford_series,
        "money_flow": flow_data,
        "trends": {
            "last_7_days": {
                "documents": len(docs_last_7),
                "corrections": len(corrections_last_7),
                "error_rate": error_rate_7,
            }
        },
        "top_error_fields": [
            {"field": field, "count": data["count"]}
            for field, data in sorted(
                error_clusters.items(),
                key=lambda x: x[1]["count"],
                reverse=True,
            )[:5]
        ],
    }

    return metrics


def _iter_transaction_amounts(docs: List[Document]) -> List[Tuple[float, str]]:
    amounts: List[Tuple[float, str]] = []
    for doc in docs:
        extracted = doc.extracted_fields or {}
        transactions = extracted.get("transactions") or []
        if not isinstance(transactions, list):
            continue
        for tx in transactions:
            if not isinstance(tx, dict):
                continue
            amount = tx.get("amount")
            if amount is None:
                continue
            try:
                value = float(amount)
            except (TypeError, ValueError):
                continue
            description = str(tx.get("description") or "")
            amounts.append((value, description))
    return amounts


def _build_benford_series(docs: List[Document]) -> List[Dict[str, float]]:
    counts = [0] * 9
    amounts = _iter_transaction_amounts(docs)
    for value, _ in amounts:
        value = abs(value)
        if value < 1:
            continue
        first_digit = int(str(int(value))[0])
        if 1 <= first_digit <= 9:
            counts[first_digit - 1] += 1
    total = sum(counts) or 1
    series: List[Dict[str, float]] = []
    for idx, count in enumerate(counts):
        digit = idx + 1
        expected = round(math.log10(1 + 1 / digit), 4)
        observed = round(count / total, 4)
        series.append({"digit": digit, "observed": observed, "expected": expected})
    return series


def _build_money_flow(docs: List[Document]) -> Dict[str, Any]:
    categories = [
        "Income",
        "Expense",
        "Transfers",
        "Fees",
        "Card",
        "ATM",
        "Payments",
        "Interest",
        "Other",
        "Suspicious",
    ]
    nodes = [{"name": name} for name in categories]
    amounts = _iter_transaction_amounts(docs)
    abs_values = sorted(abs(value) for value, _ in amounts if abs(value) > 0)
    threshold = abs_values[int(len(abs_values) * 0.95)] if abs_values else 0.0

    def classify(desc: str, amount: float) -> str:
        lower = desc.lower()
        if not desc or abs(amount) >= threshold:
            return "Suspicious"
        if "fee" in lower or "charge" in lower:
            return "Fees"
        if "card" in lower or "pos" in lower:
            return "Card"
        if "atm" in lower or "cash" in lower:
            return "ATM"
        if "transfer" in lower or "neft" in lower or "imps" in lower:
            return "Transfers"
        if "interest" in lower:
            return "Interest"
        if "payment" in lower or "bill" in lower or "upi" in lower:
            return "Payments"
        if amount >= 0:
            return "Income"
        return "Other"

    totals: Dict[str, float] = {}
    for amount, desc in amounts:
        source_name = "Income" if amount >= 0 else "Expense"
        target_name = classify(desc, amount)
        key = f"{source_name}->{target_name}"
        totals[key] = (totals.get(key, 0.0) + abs(amount))

    def idx(name: str) -> int:
        return categories.index(name)

    links = []
    for key, value in totals.items():
        source_name, target_name = key.split("->")
        if value <= 0:
            continue
        links.append(
            {
                "source": idx(source_name),
                "target": idx(target_name),
                "value": round(value, 2),
            }
        )

    return {"nodes": nodes, "links": links, "suspicious_threshold": threshold}
