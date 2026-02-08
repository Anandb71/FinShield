
from typing import Dict, Any, List

class DocumentProcessor:
    def __init__(self):
        pass

    async def process_document(self, file_bytes: bytes, filename: str) -> Dict[str, Any]:
        """
        Mock processing for demo. Returns hardcoded data for 'Invoice_1024.pdf' logic.
        """
        # Simulate processing delay?
        # For demo, instant is fine.
        
        return {
            "document_type": "INVOICE",
            "vendor": "ACME Corp",
            "confidence": 0.98,
            "entities": [
                {"label": "Vendor", "value": "ACME Corp", "box": [10, 10, 100, 30], "confidence": 0.99},
                {"label": "Date", "value": "2024-10-24", "box": [400, 10, 100, 30], "confidence": 0.95},
                {"label": "Total", "value": "₹50,000", "box": [400, 500, 100, 30], "confidence": 0.92},
                {"label": "Tax", "value": "₹5,000", "box": [400, 450, 100, 30], "confidence": 0.65}, # Low confidence for "Learning Loop"
            ],
            "tables": [
                {"box": [10, 100, 500, 300], "rows": 5, "cols": 4}
            ],
            "anomalies": [
                {"box": [50, 550, 200, 50], "type": "Handwritten Note", "severity": "medium"}
            ],
            "logic_checks": [
                {"rule": "Math Check (Subtotal + Tax = Total)", "status": "pass"},
                {"rule": "Date Sequence", "status": "pass"},
                {"rule": "Vendor Whitelist", "status": "pass"},
            ]
        }
