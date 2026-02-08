"""
Reconciliation Engine - Multi-Document Payment Verification
The killer feature for Challenge 2: Cross-document consistency

This engine:
1. Matches invoice amounts to bank statement transactions
2. Detects "Ghost Invoices" - invoices with no corresponding payment
3. Supports fuzzy matching for small discrepancies
4. Logs manual reconciliations for model retraining
"""

from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class BankTransaction:
    id: str
    description: str
    amount: float
    date: str
    category: str = "payment"


@dataclass 
class ReconciliationResult:
    matched: bool
    transaction: Optional[BankTransaction]
    confidence: float
    match_type: str  # "exact", "fuzzy", "manual", "none"
    discrepancy: float = 0.0


class ReconciliationEngine:
    """
    Multi-Document Payment Verification Engine
    
    Compares invoices against bank statements to verify payments
    and detect anomalies (ghost invoices, duplicate payments, etc.)
    """
    
    def __init__(self):
        self._manual_matches: Dict[str, str] = {}  # invoice_id -> transaction_id
        self._retraining_queue: List[Dict] = []
    
    def get_demo_bank_statement(self) -> List[BankTransaction]:
        """
        Returns mock bank statement for demo purposes.
        In production, this would query a bank API or parsed statement.
        """
        return [
            BankTransaction(
                id="TXN-001",
                description="TechCorp Inc",
                amount=12000,
                date="2024-10-01",
                category="vendor_payment"
            ),
            BankTransaction(
                id="TXN-002", 
                description="ACME Corporation",
                amount=55000,  # Matches our demo invoice total
                date="2024-10-05",
                category="vendor_payment"
            ),
            BankTransaction(
                id="TXN-003",
                description="Uber Ride",
                amount=450,
                date="2024-10-06", 
                category="expense"
            ),
            BankTransaction(
                id="TXN-004",
                description="AWS Hosting",
                amount=8500,
                date="2024-10-08",
                category="infrastructure"
            ),
            BankTransaction(
                id="TXN-005",
                description="Office Supplies Co",
                amount=3200,
                date="2024-10-10",
                category="expense"
            ),
        ]
    
    def find_payment_match(
        self,
        invoice_amount: float,
        invoice_vendor: str,
        bank_transactions: List[BankTransaction],
        tolerance: float = 0.02  # 2% tolerance for fuzzy matching
    ) -> ReconciliationResult:
        """
        Smart Match algorithm:
        1. First try exact amount match
        2. Then try fuzzy match within tolerance
        3. Then try vendor name match
        4. Return best match or "no match"
        """
        
        # Priority 1: Exact amount match
        for txn in bank_transactions:
            if txn.amount == invoice_amount:
                return ReconciliationResult(
                    matched=True,
                    transaction=txn,
                    confidence=1.0,
                    match_type="exact"
                )
        
        # Priority 2: Fuzzy amount match (within tolerance)
        for txn in bank_transactions:
            diff = abs(txn.amount - invoice_amount)
            if diff <= invoice_amount * tolerance:
                return ReconciliationResult(
                    matched=True,
                    transaction=txn,
                    confidence=0.85,
                    match_type="fuzzy",
                    discrepancy=diff
                )
        
        # Priority 3: Vendor name match (partial)
        invoice_vendor_lower = invoice_vendor.lower()
        for txn in bank_transactions:
            if invoice_vendor_lower in txn.description.lower():
                return ReconciliationResult(
                    matched=True,
                    transaction=txn,
                    confidence=0.70,
                    match_type="vendor_match",
                    discrepancy=abs(txn.amount - invoice_amount)
                )
        
        # No match found - Ghost Invoice detected
        return ReconciliationResult(
            matched=False,
            transaction=None,
            confidence=0.0,
            match_type="none"
        )
    
    def force_match(
        self,
        invoice_id: str,
        transaction_id: str,
        invoice_amount: float,
        transaction_amount: float
    ) -> Dict:
        """
        Human-in-the-loop forced reconciliation.
        Logs the match for model retraining.
        """
        self._manual_matches[invoice_id] = transaction_id
        
        # Queue for retraining
        self._retraining_queue.append({
            "type": "manual_reconciliation",
            "invoice_id": invoice_id,
            "transaction_id": transaction_id,
            "invoice_amount": invoice_amount,
            "transaction_amount": transaction_amount,
            "discrepancy": abs(invoice_amount - transaction_amount),
            "timestamp": datetime.now().isoformat()
        })
        
        return {
            "success": True,
            "message": "Manual reconciliation logged for retraining",
            "match_id": f"{invoice_id}:{transaction_id}",
            "queue_size": len(self._retraining_queue)
        }
    
    def get_reconciliation_summary(
        self,
        invoice_data: Dict,
        bank_transactions: List[BankTransaction]
    ) -> Dict:
        """
        Full reconciliation summary for the UI.
        """
        invoice_amount = invoice_data.get("total", 0)
        invoice_vendor = invoice_data.get("vendor", {}).get("name", "")
        
        result = self.find_payment_match(
            invoice_amount,
            invoice_vendor,
            bank_transactions
        )
        
        return {
            "invoice_amount": invoice_amount,
            "invoice_vendor": invoice_vendor,
            "matched": result.matched,
            "confidence": result.confidence,
            "match_type": result.match_type,
            "matched_transaction": {
                "id": result.transaction.id,
                "description": result.transaction.description,
                "amount": result.transaction.amount,
                "date": result.transaction.date,
            } if result.transaction else None,
            "discrepancy": result.discrepancy,
            "status": "PAYMENT VERIFIED" if result.matched else "GHOST INVOICE - NO PAYMENT FOUND"
        }


# Singleton
_engine = None

def get_reconciliation_engine() -> ReconciliationEngine:
    global _engine
    if _engine is None:
        _engine = ReconciliationEngine()
    return _engine
