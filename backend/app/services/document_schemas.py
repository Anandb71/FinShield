"""
FinShield - Document Schemas

Defines extraction schemas for different document types.
"""

from typing import Dict, Any, List
from enum import Enum


class DocumentType(str, Enum):
    """Supported document types."""
    INVOICE = "invoice"
    BANK_STATEMENT = "bank_statement"
    CONTRACT = "contract"
    PAYSLIP = "payslip"
    UNKNOWN = "unknown"


# Schema definitions
SCHEMAS = {
    DocumentType.INVOICE: {
        "fields": [
            "invoice_number",
            "vendor_name",
            "vendor_address",
            "total_amount",
            "subtotal",
            "tax",
            "invoice_date",
            "due_date",
            "bill_to",
            "line_items"
        ],
        "required": ["invoice_number", "vendor_name", "total_amount", "invoice_date"]
    },
    
    DocumentType.BANK_STATEMENT: {
        "fields": [
            "account_number",
            "account_holder",
            "bank_name",
            "statement_period",
            "opening_balance",
            "closing_balance",
            "transactions"
        ],
        "required": ["account_number", "opening_balance", "closing_balance", "transactions"]
    },
    
    DocumentType.PAYSLIP: {
        "fields": [
            "employee_name",
            "employee_id",
            "employer_name",
            "pay_period",
            "gross_salary",
            "net_salary",
            "deductions",
            "payment_date"
        ],
        "required": ["employee_name", "employer_name", "gross_salary", "payment_date"]
    },
    
    DocumentType.CONTRACT: {
        "fields": [
            "contract_number",
            "parties",
            "effective_date",
            "expiry_date",
            "terms",
            "payment_terms"
        ],
        "required": ["contract_number", "parties", "effective_date"]
    }
}


def get_schema(doc_type: str) -> Dict[str, Any]:
    """Get schema for document type."""
    return SCHEMAS.get(DocumentType(doc_type), {"fields": [], "required": []})


def get_schema_fields(doc_type: str) -> List[str]:
    """Get list of fields for document type."""
    schema = get_schema(doc_type)
    return schema.get("fields", [])


def get_required_fields(doc_type: str) -> List[str]:
    """Get required fields for document type."""
    schema = get_schema(doc_type)
    return schema.get("required", [])
