"""
FinShield - Document Validation Service

Business logic validation for extracted data.
"""

from typing import Dict, Any, List
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class DocumentValidator:
    """Validate extracted document data."""
    
    def validate(self, doc_type: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate document data based on type.
        
        Args:
            doc_type: Document type
            data: Extracted data
        
        Returns:
            Validation result
        """
        if doc_type == "bank_statement":
            return self.validate_bank_statement(data)
        elif doc_type == "invoice":
            return self.validate_invoice(data)
        elif doc_type == "payslip":
            return self.validate_payslip(data)
        else:
            return {"valid": True, "errors": [], "warnings": []}
    
    def validate_bank_statement(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate bank statement."""
        errors = []
        warnings = []
        
        # Balance continuity
        balance_check = self._check_balance_continuity(data)
        if not balance_check["valid"]:
            errors.append(balance_check["message"])
        
        # Date sequencing
        date_check = self._check_date_sequencing(data.get("transactions", []))
        if not date_check["valid"]:
            warnings.append(date_check["message"])
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings
        }
    
    def validate_invoice(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate invoice."""
        errors = []
        warnings = []
        
        # Amount calculations
        amount_check = self._check_invoice_amounts(data)
        if not amount_check["valid"]:
            warnings.append(amount_check["message"])
        
        # Date validity
        date_check = self._check_invoice_dates(data)
        if not date_check["valid"]:
            errors.append(date_check["message"])
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings
        }
    
    def validate_payslip(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate payslip."""
        errors = []
        warnings = []
        
        # Check gross vs net
        gross = data.get("gross_salary", 0)
        net = data.get("net_salary", 0)
        deductions = data.get("deductions", 0)
        
        if gross > 0 and net > 0:
            expected_net = gross - deductions
            if abs(expected_net - net) > 1:
                warnings.append(f"Net salary mismatch: expected {expected_net}, got {net}")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings
        }
    
    def check_income_plausibility(self, income_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Check income plausibility across multiple records."""
        if not income_data:
            return {"plausible": True, "message": "No data"}
        
        amounts = [r.get("amount", 0) for r in income_data]
        avg = sum(amounts) / len(amounts)
        std_dev = (sum((x - avg) ** 2 for x in amounts) / len(amounts)) ** 0.5
        
        outliers = [amt for amt in amounts if abs(amt - avg) > 2 * std_dev]
        
        if outliers:
            return {
                "plausible": False,
                "message": f"Found {len(outliers)} outlier(s)",
                "outliers": outliers
            }
        
        return {"plausible": True, "message": "Income consistent"}
    
    def _check_balance_continuity(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Check balance continuity."""
        opening = data.get("opening_balance", 0)
        closing = data.get("closing_balance", 0)
        transactions = data.get("transactions", [])
        
        if not transactions:
            return {"valid": True, "message": "No transactions"}
        
        total_credits = sum(t.get("credit", 0) for t in transactions)
        total_debits = sum(t.get("debit", 0) for t in transactions)
        
        calculated = opening + total_credits - total_debits
        diff = abs(calculated - closing)
        
        if diff < 0.01:
            return {"valid": True, "message": "Balance verified"}
        
        return {
            "valid": False,
            "message": f"Balance mismatch: expected {calculated}, got {closing}"
        }
    
    def _check_date_sequencing(self, transactions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Check date sequencing."""
        if len(transactions) < 2:
            return {"valid": True, "message": "Insufficient data"}
        
        dates = []
        for t in transactions:
            date_str = t.get("date", "")
            if date_str:
                try:
                    dates.append(datetime.fromisoformat(date_str))
                except:
                    pass
        
        if not dates:
            return {"valid": True, "message": "No valid dates"}
        
        if dates == sorted(dates):
            return {"valid": True, "message": "Dates in order"}
        
        return {"valid": False, "message": "Dates not in chronological order"}
    
    def _check_invoice_amounts(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Check invoice amounts."""
        line_items = data.get("line_items", [])
        subtotal = data.get("subtotal", 0)
        
        if not line_items:
            return {"valid": True, "message": "No line items"}
        
        calculated = sum(item.get("amount", 0) for item in line_items)
        diff = abs(calculated - subtotal)
        
        if diff < 0.01:
            return {"valid": True, "message": "Amounts correct"}
        
        return {
            "valid": False,
            "message": f"Subtotal mismatch: expected {calculated}, got {subtotal}"
        }
    
    def _check_invoice_dates(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Check invoice dates - handles multiple field name variations."""
        # Check multiple possible field names for the date
        date_field_names = [
            "invoice_date",
            "date", 
            "DATE",
            "document_date",
            "invoice_date_raw",
            "transaction_date"
        ]
        
        invoice_date_str = None
        for field_name in date_field_names:
            if data.get(field_name):
                invoice_date_str = str(data.get(field_name))
                break
        
        if not invoice_date_str:
            return {"valid": False, "message": "Invoice date missing"}
        
        # Clean the date string
        invoice_date_str = invoice_date_str.strip()
        
        # Support multiple formats
        patterns = [
            "%Y-%m-%d",           # ISO: 2022-02-04
            "%d.%m.%Y",           # EU: 04.02.2022
            "%d/%m/%Y",           # UK/IN: 04/02/2022
            "%m/%d/%Y",           # US: 02/04/2022
            "%d-%m-%Y",           # Hyphen: 04-02-2022
            "%B %d, %Y",          # Full: February 4, 2022
            "%b %d, %Y",          # Short: Feb 4, 2022
            "%d %B %Y",           # EU Full: 4 February 2022
            "%d %b %Y",           # EU Short: 4 Feb 2022
            "%Y/%m/%d",           # Alt ISO: 2022/02/04
        ]
        
        parsed_date = None
        for fmt in patterns:
            try:
                parsed_date = datetime.strptime(invoice_date_str, fmt)
                break
            except ValueError:
                continue
                
        if not parsed_date:
            # Try ISO format as fallback (handles timezone-aware strings)
            try:
                # Remove any trailing timezone info for basic parsing
                clean_date = invoice_date_str.split('T')[0].split(' ')[0]
                parsed_date = datetime.fromisoformat(clean_date)
            except:
                # Still failed - log but don't fail validation entirely
                logger.warning(f"Could not parse date: {invoice_date_str}")
                return {"valid": True, "message": f"Date format unrecognized: {invoice_date_str}"}
        
        if parsed_date > datetime.now():
            return {"valid": False, "message": "Invoice date in future"}
            
        return {"valid": True, "message": "Dates valid"}
