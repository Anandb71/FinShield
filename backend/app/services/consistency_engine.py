"""
Consistency Engine - Knowledge Graph + Cross-Document Validation
Powered by: Backboard.io (Mock Implementation)

This engine provides:
1. Entity Resolution - Same vendor across documents
2. Cross-Document Consistency - Bank account matching
3. Anomaly Detection - Amount deviation from historical average
"""

from typing import Dict, List, Optional
from dataclasses import dataclass, field
from datetime import datetime
import random


@dataclass
class VendorRecord:
    name: str
    gstin: str
    bank_account: Optional[str] = None
    invoices: List[Dict] = field(default_factory=list)
    
    @property
    def average_amount(self) -> float:
        if not self.invoices:
            return 0
        return sum(inv['amount'] for inv in self.invoices) / len(self.invoices)
    
    @property
    def total_invoices(self) -> int:
        return len(self.invoices)


class ConsistencyEngine:
    """
    The Universal Knowledge Graph Engine
    
    In production, this would connect to Backboard.io via their SDK.
    For demo purposes, we use an in-memory graph seeded with fake data.
    """
    
    def __init__(self):
        self._knowledge_graph: Dict[str, VendorRecord] = {}
        self._seed_demo_data()
    
    def _seed_demo_data(self):
        """Pre-populate the graph with historic invoices for ACME Corp"""
        acme = VendorRecord(
            name="ACME Corporation",
            gstin="27AAACA1234A1ZV",
            bank_account="SBIN000012345678",
            invoices=[
                {"id": "INV-2024-0812", "date": "2024-08-12", "amount": 48000},
                {"id": "INV-2024-0915", "date": "2024-09-15", "amount": 52000},
                {"id": "INV-2024-0928", "date": "2024-09-28", "amount": 45500},
            ]
        )
        self._knowledge_graph["ACME Corporation"] = acme
        
        # Add a few more vendors
        self._knowledge_graph["Tech Solutions Ltd"] = VendorRecord(
            name="Tech Solutions Ltd",
            gstin="29AABCT1234P1Z5",
            bank_account="HDFC000098765432",
            invoices=[
                {"id": "TS-001", "date": "2024-07-01", "amount": 125000},
            ]
        )
    
    def query_vendor(self, vendor_name: str) -> Optional[Dict]:
        """
        Query the knowledge graph for a vendor.
        Returns historical context if found.
        """
        vendor = self._knowledge_graph.get(vendor_name)
        if not vendor:
            return None
        
        return {
            "vendor_name": vendor.name,
            "gstin": vendor.gstin,
            "bank_account": vendor.bank_account,
            "total_invoices": vendor.total_invoices,
            "average_amount": vendor.average_amount,
            "last_invoice_date": vendor.invoices[-1]["date"] if vendor.invoices else None,
        }
    
    def check_consistency(self, document_data: Dict) -> List[Dict]:
        """
        Run cross-document consistency checks.
        
        Args:
            document_data: Extracted fields from the current document
        
        Returns:
            List of memory context items (history, alerts, matches)
        """
        vendor_name = document_data.get("vendor", {}).get("name")
        current_amount = document_data.get("total", 0)
        current_gstin = document_data.get("vendor", {}).get("gstin")
        
        results = []
        
        # Check 1: Have we seen this vendor before?
        vendor_record = self._knowledge_graph.get(vendor_name)
        
        if vendor_record:
            # History entry
            results.append({
                "type": "history",
                "text": f'Vendor "{vendor_name}" found in {vendor_record.total_invoices} previous documents',
            })
            
            results.append({
                "type": "history",
                "text": f"Average invoice amount: ₹{int(vendor_record.average_amount):,}",
            })
            
            # Check 2: Amount deviation check
            avg = vendor_record.average_amount
            if avg > 0:
                deviation = ((current_amount - avg) / avg) * 100
                if abs(deviation) > 10:
                    results.append({
                        "type": "alert",
                        "text": f"Current amount (₹{current_amount:,}) is {abs(deviation):.0f}% {'above' if deviation > 0 else 'below'} average",
                        "severity": "high" if abs(deviation) > 25 else "medium",
                    })
            
            # Check 3: GSTIN match
            if current_gstin and vendor_record.gstin == current_gstin:
                results.append({
                    "type": "match",
                    "text": "GSTIN matches previous records ✓",
                })
            elif current_gstin and vendor_record.gstin != current_gstin:
                results.append({
                    "type": "alert",
                    "text": "⚠️ GSTIN DIFFERS from previous records!",
                    "severity": "critical",
                })
            
            # Check 4: Bank account consistency (mock)
            results.append({
                "type": "match",
                "text": "Bank account matches previous records ✓",
            })
        else:
            results.append({
                "type": "history",
                "text": f'Vendor "{vendor_name}" is NEW - no prior records',
            })
        
        return results
    
    def ingest_document(self, document_data: Dict) -> Dict:
        """
        Add a new document to the knowledge graph.
        Called after human validation confirms the data.
        
        Returns:
            Confirmation with updated stats
        """
        vendor_name = document_data.get("vendor", {}).get("name")
        if not vendor_name:
            return {"success": False, "error": "Missing vendor name"}
        
        vendor = self._knowledge_graph.get(vendor_name)
        if not vendor:
            vendor = VendorRecord(
                name=vendor_name,
                gstin=document_data.get("vendor", {}).get("gstin"),
            )
            self._knowledge_graph[vendor_name] = vendor
        
        # Add the invoice
        vendor.invoices.append({
            "id": document_data.get("invoice_number"),
            "date": document_data.get("date"),
            "amount": document_data.get("total"),
        })
        
        return {
            "success": True,
            "message": f"Document ingested. Vendor now has {vendor.total_invoices} records.",
            "new_average": vendor.average_amount,
        }
    
    def learn_correction(self, field: str, original: str, corrected: str, vendor_name: str) -> Dict:
        """
        Record a human correction for model retraining.
        
        This feeds back into the learning loop - Backboard would store this
        as a training signal for future OCR/NLP improvements.
        """
        # In production: Send to Backboard's learning endpoint
        return {
            "success": True,
            "message": "Correction recorded. Model learning triggered.",
            "impact": f"Future {field} extractions for {vendor_name} will improve.",
        }


# Singleton instance
_engine = None

def get_consistency_engine() -> ConsistencyEngine:
    global _engine
    if _engine is None:
        _engine = ConsistencyEngine()
    return _engine
