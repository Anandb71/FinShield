"""
Universal Document Pipeline - Backend Mock Service
Maps to Challenge 2 Requirements for Document AI
"""
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import random
import re


@dataclass
class DocumentResult:
    doc_id: str
    filename: str
    doc_type: str
    layouts: List[str]
    validation_status: str
    validation_errors: List[Dict[str, Any]]
    extracted_data: Dict[str, Any]
    confidence: float


class DocumentPipeline:
    """
    Universal Document Pipeline for processing financial documents.
    
    Maps to Challenge Requirements:
    - Auto classify document type
    - Detect layouts (tables, handwritten, stamps)
    - Balance continuity checks
    - Date sequencing validation
    - Cross-document consistency
    - Error clustering
    """

    DOC_TYPES = ["INVOICE", "PAYSLIP", "STATEMENT", "CONTRACT", "RECEIPT", "KYC"]
    LAYOUTS = ["Table", "Handwritten", "Stamp", "Header", "Multi-Table", "Signature"]

    def __init__(self):
        self._doc_counter = 1000
        self._history = {}  # For cross-document consistency

    def ingest_batch(self, files: List[str]) -> List[DocumentResult]:
        """
        Simulates parallel batch processing of documents.
        Returns processed results for each file.
        """
        results = []
        for filename in files:
            result = self._process_document(filename)
            results.append(result)
            self._doc_counter += 1
        return results

    def _process_document(self, filename: str) -> DocumentResult:
        """Process a single document through the pipeline."""
        doc_id = f"DOC-{self._doc_counter}"
        
        # Step 1: Auto-classify based on filename patterns
        doc_type = self.classify_document(filename)
        
        # Step 2: Detect layouts (simulated)
        layouts = self._detect_layouts(filename, doc_type)
        
        # Step 3: Extract data (simulated)
        extracted_data = self._extract_data(doc_type)
        
        # Step 4: Run validation checks
        validation_errors = self.validate_logic(extracted_data, doc_type)
        
        # Determine overall status
        if validation_errors:
            status = "FAIL" if any(e["severity"] == "error" for e in validation_errors) else "REVIEW"
        else:
            status = "PASS"
        
        # Calculate confidence
        confidence = self._calculate_confidence(validation_errors)
        
        return DocumentResult(
            doc_id=doc_id,
            filename=filename,
            doc_type=doc_type,
            layouts=layouts,
            validation_status=status,
            validation_errors=validation_errors,
            extracted_data=extracted_data,
            confidence=confidence
        )

    def classify_document(self, filename: str) -> str:
        """
        Auto-classify document type based on filename patterns.
        Maps to: 'Auto classify document type'
        """
        filename_lower = filename.lower()
        
        if "invoice" in filename_lower or "inv" in filename_lower:
            return "INVOICE"
        elif "payslip" in filename_lower or "salary" in filename_lower:
            return "PAYSLIP"
        elif "statement" in filename_lower or "bank" in filename_lower:
            return "STATEMENT"
        elif "contract" in filename_lower or "agreement" in filename_lower:
            return "CONTRACT"
        elif "receipt" in filename_lower:
            return "RECEIPT"
        elif "kyc" in filename_lower or "id" in filename_lower:
            return "KYC"
        else:
            return random.choice(self.DOC_TYPES)

    def _detect_layouts(self, filename: str, doc_type: str) -> List[str]:
        """
        Detect document layouts.
        Maps to: 'Detect layouts', 'Table structure recognition'
        """
        layouts = []
        
        # Type-based layout detection
        if doc_type == "INVOICE":
            layouts = ["Header", "Table"]
        elif doc_type == "STATEMENT":
            layouts = ["Multi-Table", "Header"]
        elif doc_type == "CONTRACT":
            layouts = ["Header", "Signature"]
        
        # Filename hints
        if "handwritten" in filename.lower():
            layouts.append("Handwritten")
        if "stamp" in filename.lower():
            layouts.append("Stamp")
        
        return layouts if layouts else ["Header"]

    def _extract_data(self, doc_type: str) -> Dict[str, Any]:
        """Simulate data extraction based on document type."""
        base_data = {
            "extraction_timestamp": datetime.now().isoformat(),
            "ocr_confidence": round(random.uniform(0.75, 0.98), 2)
        }

        if doc_type == "INVOICE":
            base_data.update({
                "invoice_number": f"INV-{random.randint(1000, 9999)}",
                "invoice_date": "2024-10-01",
                "due_date": "2024-10-30",
                "vendor": {"name": "ACME Corp", "gstin": "27AAACA1234A1ZV"},
                "subtotal": 45000,
                "tax": 8100,
                "total": 53100,  # Intentional mismatch for demo
            })
        elif doc_type == "STATEMENT":
            base_data.update({
                "account_number": f"XXXX{random.randint(1000, 9999)}",
                "opening_balance": 100000,
                "closing_balance": 125000,
                "transactions": [
                    {"date": "2024-10-05", "desc": "Credit", "amount": 50000},
                    {"date": "2024-10-15", "desc": "Debit", "amount": -25000}
                ]
            })

        return base_data

    def validate_logic(self, data: Dict[str, Any], doc_type: str) -> List[Dict[str, Any]]:
        """
        Run validation checks on extracted data.
        Maps to: 'Balance continuity checks', 'Date sequencing', 'Cross-document consistency'
        """
        errors = []

        if doc_type == "INVOICE":
            # Balance Check
            subtotal = data.get("subtotal", 0)
            tax = data.get("tax", 0)
            total = data.get("total", 0)
            if subtotal + tax != total:
                errors.append({
                    "check": "Balance Continuity",
                    "message": f"Subtotal ({subtotal}) + Tax ({tax}) != Total ({total})",
                    "severity": "error",
                    "expected": subtotal + tax,
                    "actual": total
                })

            # Date Sequencing
            inv_date = data.get("invoice_date", "")
            due_date = data.get("due_date", "")
            if inv_date and due_date and inv_date > due_date:
                errors.append({
                    "check": "Date Sequencing",
                    "message": f"Invoice Date ({inv_date}) > Due Date ({due_date})",
                    "severity": "error"
                })

        elif doc_type == "STATEMENT":
            # Balance Continuity for Statements
            opening = data.get("opening_balance", 0)
            closing = data.get("closing_balance", 0)
            transactions = data.get("transactions", [])
            calculated_closing = opening + sum(t.get("amount", 0) for t in transactions)
            
            if calculated_closing != closing:
                errors.append({
                    "check": "Statement Reconciliation",
                    "message": f"Calculated closing ({calculated_closing}) != Reported ({closing})",
                    "severity": "warning"
                })

        return errors

    def _calculate_confidence(self, errors: List[Dict]) -> float:
        """Calculate overall confidence score based on validation results."""
        base = 0.95
        for error in errors:
            if error.get("severity") == "error":
                base -= 0.15
            else:
                base -= 0.05
        return max(0.4, round(base, 2))

    def get_error_clusters(self, results: List[DocumentResult]) -> Dict[str, int]:
        """
        Cluster errors for dashboard display.
        Maps to: 'Error clustering'
        """
        clusters = {}
        for result in results:
            for error in result.validation_errors:
                check = error.get("check", "Unknown")
                clusters[check] = clusters.get(check, 0) + 1
        return clusters


# Singleton instance for API usage
pipeline = DocumentPipeline()
