from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Tuple, Optional
import re

from dateutil import parser
from sqlmodel import Session, select

from app.db.models import Document


def _parse_date(value: Any) -> Optional[datetime]:
    if not value:
        return None
    try:
        return parser.parse(str(value))
    except Exception:
        return None


def _safe_number(value: Any) -> Optional[float]:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except Exception:
        return None


def _compare_close(a: Optional[float], b: Optional[float], tolerance: float = 0.01) -> bool:
    if a is None or b is None:
        return False
    return abs(a - b) <= tolerance


def _leading_digit(value: float) -> Optional[int]:
    value = abs(value)
    if value < 1:
        return None
    try:
        return int(str(int(value))[0])
    except Exception:
        return None


def _normalize_counterparty(text: str) -> str:
    if not text:
        return ""
    cleaned = re.sub(r"[^a-zA-Z0-9\s]", " ", text.lower())
    cleaned = re.sub(r"\d+", " ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def _percentile(values: List[float], pct: float) -> Optional[float]:
    if not values:
        return None
    if pct <= 0:
        return min(values)
    if pct >= 100:
        return max(values)
    sorted_vals = sorted(values)
    k = (len(sorted_vals) - 1) * (pct / 100)
    f = int(k)
    c = min(f + 1, len(sorted_vals) - 1)
    if f == c:
        return sorted_vals[f]
    return sorted_vals[f] + (sorted_vals[c] - sorted_vals[f]) * (k - f)


def run_validations(
    doc_type: str,
    extracted: Dict[str, Any],
    session: Session,
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]], Dict[str, Any]]:
    errors: List[Dict[str, Any]] = []
    warnings: List[Dict[str, Any]] = []
    consistency: Dict[str, Any] = {"consistent": True, "issues": []}

    now = datetime.utcnow()
    doc_type = (doc_type or "unknown").lower()

    if doc_type == "invoice":
        subtotal = _safe_number(extracted.get("subtotal"))
        tax = _safe_number(extracted.get("tax"))
        total = _safe_number(extracted.get("total"))
        if subtotal is not None and tax is not None and total is not None:
            if not _compare_close(subtotal + tax, total, tolerance=0.02):
                errors.append({
                    "field": "total",
                    "message": "Subtotal + tax does not match total.",
                    "severity": "critical",
                    "expected": subtotal + tax,
                    "actual": total,
                })
        invoice_date = _parse_date(extracted.get("invoice_date"))
        due_date = _parse_date(extracted.get("due_date"))
        if invoice_date and invoice_date > now:
            warnings.append({
                "field": "invoice_date",
                "message": "Invoice date is in the future.",
                "severity": "info",
            })
        if invoice_date and due_date and due_date < invoice_date:
            errors.append({
                "field": "due_date",
                "message": "Due date is earlier than invoice date.",
                "severity": "critical",
            })

    if doc_type == "bank_statement":
        opening = _safe_number(extracted.get("opening_balance"))
        closing = _safe_number(extracted.get("closing_balance"))
        transactions = extracted.get("transactions") or []
        tx_amounts: List[float] = []
        tx_balances: List[Optional[float]] = []
        tx_dates: List[Optional[datetime]] = []
        tx_date_raw: List[str] = []
        tx_descriptions: List[str] = []
        if opening is not None and closing is not None and transactions:
            tx_total = 0.0
            last_date = None
            for tx in transactions:
                amount = _safe_number(tx.get("amount"))
                if amount is not None:
                    tx_total += amount
                    tx_amounts.append(amount)
                tx_balances.append(_safe_number(tx.get("balance")))
                tx_date = _parse_date(tx.get("date"))
                tx_dates.append(tx_date)
                tx_date_raw.append(str(tx.get("date") or ""))
                tx_descriptions.append(str(tx.get("description") or ""))
                if last_date and tx_date and tx_date < last_date:
                    warnings.append({
                        "field": "transactions",
                        "message": "Transaction dates are not in sequence.",
                        "severity": "info",
                    })
                if tx_date:
                    last_date = tx_date
            if not _compare_close(opening + tx_total, closing, tolerance=0.05):
                issue = {
                    "field": "closing_balance",
                    "message": "Opening balance plus transactions does not match closing balance.",
                    "expected": opening + tx_total,
                    "actual": closing,
                }
                if len(transactions) < 3:
                    issue["severity"] = "info"
                    warnings.append(issue)
                else:
                    issue["severity"] = "critical"
                    errors.append(issue)
        else:
            for tx in transactions:
                amount = _safe_number(tx.get("amount"))
                if amount is not None:
                    tx_amounts.append(amount)
                tx_balances.append(_safe_number(tx.get("balance")))
                tx_dates.append(_parse_date(tx.get("date")))
                tx_date_raw.append(str(tx.get("date") or ""))
                tx_descriptions.append(str(tx.get("description") or ""))

        if transactions:
            # ── Date validation (only flag truly invalid dates, not header text) ──
            invalid_dates = [tx for tx in transactions if tx.get("date") and _parse_date(tx.get("date")) is None]
            if invalid_dates:
                warnings.append({
                    "field": "transactions",
                    "message": "Invalid or impossible transaction date detected.",
                    "severity": "warning",
                    "count": len(invalid_dates),
                })

            # ── Running balance check ──
            running_mismatches = 0
            prev_balance = None
            for tx, balance in zip(transactions, tx_balances):
                amount = _safe_number(tx.get("amount"))
                if prev_balance is not None and amount is not None and balance is not None:
                    if not _compare_close(prev_balance + amount, balance, tolerance=0.05):
                        running_mismatches += 1
                if balance is not None:
                    prev_balance = balance
            if running_mismatches > 0:
                warnings.append({
                    "field": "balance",
                    "message": "Running balance does not reconcile for some rows.",
                    "severity": "warning",
                    "count": running_mismatches,
                })

            # ── Closing balance vs last row ──
            last_balance = next((b for b in reversed(tx_balances) if b is not None), None)
            if closing is not None and last_balance is not None:
                if not _compare_close(last_balance, closing, tolerance=0.05):
                    warnings.append({
                        "field": "closing_balance",
                        "message": "Closing balance does not match last row balance (summary injection).",
                        "severity": "critical",
                        "expected": last_balance,
                        "actual": closing,
                    })

            # ── Closing balance magnitude check ──
            if closing is not None and tx_balances:
                numeric_balances = [b for b in tx_balances if b is not None]
                if numeric_balances:
                    median_balance = sorted(numeric_balances)[len(numeric_balances) // 2]
                    if median_balance != 0 and abs(closing) > abs(median_balance) * 50:
                        warnings.append({
                            "field": "closing_balance",
                            "message": "Closing balance magnitude is far outside the transaction balance range.",
                            "severity": "critical",
                            "median_balance": median_balance,
                            "closing_balance": closing,
                        })

            # ── Benford's Law check ──
            leading_counts = [0] * 9
            for amount in tx_amounts:
                digit = _leading_digit(amount)
                if digit and 1 <= digit <= 9:
                    leading_counts[digit - 1] += 1
            total_leading = sum(leading_counts)
            if total_leading >= 20:
                leading_one_ratio = leading_counts[0] / total_leading if total_leading else 0.0
                if leading_one_ratio < 0.25:
                    warnings.append({
                        "field": "benford",
                        "message": "Benford distribution deviates (leading digit '1' under 25%).",
                        "severity": "warning",
                        "ratio": round(leading_one_ratio, 3),
                    })

            # ── FIX #4: Round-number detector ──
            # Only consider NON-ZERO amounts with actual values.
            # "Round number" = divisible by 100 (not just any integer).
            real_amounts = [amt for amt in tx_amounts if amt != 0]
            if real_amounts:
                round_numbers = [amt for amt in real_amounts if abs(amt) >= 100 and abs(amt) % 100 == 0]
                round_ratio = len(round_numbers) / len(real_amounts)
                if round_ratio > 0.30:
                    warnings.append({
                        "field": "round_numbers",
                        "message": "High frequency of round-number transactions (data-driven anomaly).",
                        "severity": "warning",
                        "ratio": round(round_ratio, 3),
                        "round_count": len(round_numbers),
                        "total_count": len(real_amounts),
                    })

            # ── Structuring detection ──
            positive_amounts = [amt for amt in tx_amounts if amt > 0]
            if positive_amounts:
                high_threshold = _percentile(positive_amounts, 90) or 0
                band = (high_threshold * 0.01) if high_threshold else 0
                structuring_hits = [
                    amt for amt in positive_amounts
                    if high_threshold - band <= amt <= high_threshold
                ]
            else:
                structuring_hits = []
            if len(structuring_hits) >= 3:
                warnings.append({
                    "field": "structuring",
                    "message": "Potential structuring detected (cluster near high-percentile deposit).",
                    "severity": "warning",
                    "count": len(structuring_hits),
                })

            normalized = [_normalize_counterparty(desc) for desc in tx_descriptions]
            velocity_counts: Dict[str, Dict[str, int]] = {}
            small_threshold = _percentile([abs(a) for a in tx_amounts], 30) or 0
            for date_val, desc_norm, amount in zip(tx_dates, normalized, tx_amounts):
                if not date_val or not desc_norm:
                    continue
                key = f"{date_val.date().isoformat()}::{desc_norm}"
                velocity_counts.setdefault(key, {"count": 0, "small": 0})
                velocity_counts[key]["count"] += 1
                if abs(amount) <= small_threshold:
                    velocity_counts[key]["small"] += 1
            velocity_hits = [k for k, v in velocity_counts.items() if v["count"] >= 3 and v["small"] >= 3]
            if velocity_hits:
                warnings.append({
                    "field": "velocity",
                    "message": "High-frequency same-day counterparty payments detected (velocity anomaly).",
                    "severity": "warning",
                    "examples": velocity_hits[:3],
                })

            total_in = sum(amt for amt in tx_amounts if amt > 0)
            total_out = sum(abs(amt) for amt in tx_amounts if amt < 0)
            if total_in > 0 and total_out == 0:
                warnings.append({
                    "field": "cashflow",
                    "message": "Income present with zero expenses (ghost lifestyle pattern).",
                    "severity": "warning",
                })

            negative_balances = [bal for bal in tx_balances if bal is not None and bal < 0]
            if tx_balances:
                negative_ratio = len(negative_balances) / len([b for b in tx_balances if b is not None]) if any(b is not None for b in tx_balances) else 0
                if negative_ratio > 0.5:
                    warnings.append({
                        "field": "cashflow",
                        "message": "Sustained negative balances detected.",
                        "severity": "warning",
                        "ratio": round(negative_ratio, 3),
                    })

            # ── Mixed date format check (only on raw date strings) ──
            date_tokens = [d for d in tx_date_raw if d]
            if date_tokens:
                month_name = any(re.search(r"[A-Za-z]{3}", token) for token in date_tokens)
                numeric_only = any(re.search(r"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}", token) for token in date_tokens)
                if month_name and numeric_only:
                    warnings.append({
                        "field": "transactions",
                        "message": "Mixed date formats detected (possible merge artifact).",
                        "severity": "info",
                    })

            unique_desc = len({d.lower().strip() for d in tx_descriptions if d})
            if tx_descriptions:
                repetition_ratio = 1 - (unique_desc / max(1, len(tx_descriptions)))
                if repetition_ratio > 0.8:
                    warnings.append({
                        "field": "synthetic",
                        "message": "Unusually repetitive transaction descriptions detected (synthetic pattern).",
                        "severity": "warning",
                        "ratio": round(repetition_ratio, 3),
                    })
            if tx_descriptions and unique_desc <= 2 and len(tx_descriptions) >= 10:
                warnings.append({
                    "field": "synthetic",
                    "message": "Very low description diversity detected (synthetic pattern).",
                    "severity": "warning",
                    "unique_descriptions": unique_desc,
                })

        account_number = extracted.get("account_number")
        if account_number:
            previous = _find_previous_statement(session, account_number)
            if previous:
                prev_closing = _safe_number(
                    previous.extracted_fields.get("closing_balance")
                )
                if prev_closing is not None and opening is not None:
                    if not _compare_close(prev_closing, opening, tolerance=0.05):
                        consistency["consistent"] = False
                        consistency["issues"].append({
                            "field": "opening_balance",
                            "message": "Opening balance does not match previous closing balance.",
                            "severity": "critical",
                            "previous_closing": prev_closing,
                            "current_opening": opening,
                        })

    if doc_type == "payslip":
        gross = _safe_number(extracted.get("gross_salary"))
        net = _safe_number(extracted.get("net_salary"))
        deductions = _safe_number(extracted.get("deductions"))
        if gross is not None and net is not None:
            if net > gross:
                errors.append({
                    "field": "net_salary",
                    "message": "Net salary exceeds gross salary.",
                    "severity": "critical",
                })
        if gross is not None and net is not None and deductions is not None:
            if not _compare_close(gross - deductions, net, tolerance=0.05):
                warnings.append({
                    "field": "deductions",
                    "message": "Gross minus deductions does not match net salary.",
                    "severity": "warning",
                })
        if gross is not None and gross <= 0:
            errors.append({
                "field": "gross_salary",
                "message": "Gross salary must be positive.",
                "severity": "critical",
            })

    return errors, warnings, consistency


def _find_previous_statement(session: Session, account_number: str) -> Optional[Document]:
    statement_docs = session.exec(
        select(Document)
        .where(Document.doc_type == "bank_statement")
        .order_by(Document.created_at.desc())
    ).all()

    for doc in statement_docs:
        if doc.extracted_fields.get("account_number") == account_number:
            return doc
    return None
