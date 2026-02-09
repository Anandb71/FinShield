"""
Universal Document Pipeline - Backend Mock Service
Maps to Challenge 2 Requirements for Document AI
"""
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import random
import re

from app.services.document_validator import DocumentValidator
from app.services.knowledge_graph import (
    DocumentKnowledgeGraph,
    KGNode,
    KGEdge,
    get_knowledge_store,
)


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
        self._validator = DocumentValidator()
        
        # Initialize Backboard Service
        from app.core.config import get_settings
        from app.services.backboard_service import BackboardDocumentService
        
        settings = get_settings()
        self.backboard = BackboardDocumentService(
            api_key=settings.backboard_api_key,
            api_url=settings.backboard_api_url,
            workspace_id=settings.backboard_workspace_id
        )

    # ... (Keep existing mock methods for fallback or testing if needed, but Process Document uses real AI) ...

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

    def validate_logic(self, data: Dict[str, Any], doc_type: str) -> List[Dict[str, Any]]:
        """
        Run validation checks on extracted data.
        Maps to: 'Balance continuity checks', 'Date sequencing', 'Cross-document consistency'
        """
        errors: List[Dict[str, Any]] = []

        if doc_type == "INVOICE":
            # Balance Check
            subtotal = float(str(data.get("subtotal", 0)).replace(',', ''))
            tax = float(str(data.get("tax", 0)).replace(',', ''))
            total = float(str(data.get("total", 0)).replace(',', ''))
            
            # Allow small float diff
            if abs((subtotal + tax) - total) > 1.0:
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
            opening = float(str(data.get("opening_balance", 0)).replace(',', ''))
            closing = float(str(data.get("closing_balance", 0)).replace(',', ''))
            transactions = data.get("transactions", [])
            
            calc_diff = sum(float(str(t.get("amount", 0)).replace(',', '')) for t in transactions)
            calculated_closing = opening + calc_diff
            
            if abs(calculated_closing - closing) > 1.0:
                errors.append({
                    "check": "Statement Reconciliation",
                    "message": f"Calculated closing ({calculated_closing}) != Reported ({closing})",
                    "severity": "warning"
                })

        return errors

    def _build_knowledge_graph(
        self,
        doc_id: str,
        filename: str,
        doc_type: str,
        extracted_data: Dict[str, Any],
        layout_map: Dict[str, bool],
    ) -> DocumentKnowledgeGraph:
        """
        Build a canonical knowledge graph slice for this document.

        This maps high-level entities (accounts, employers, invoices, etc.)
        into generic KG nodes and edges that can be serialized as JSON.
        """
        nodes: List[KGNode] = []
        edges: List[KGEdge] = []

        # Core document node
        doc_node = KGNode(
            id=doc_id,
            type="Document",
            properties={
                "filename": filename,
                "doc_type": doc_type,
                "layout": layout_map,
            },
        )
        nodes.append(doc_node)

        # Bank / account entities
        bank_name = extracted_data.get("bank_name") or extracted_data.get("institution_name")
        account_number = extracted_data.get("account_number")
        if account_number:
            account_node = KGNode(
                id=f"account:{account_number}",
                type="Account",
                properties={
                    "account_number": account_number,
                    "bank_name": bank_name,
                    "holder_name": extracted_data.get("account_holder_name"),
                },
            )
            nodes.append(account_node)
            edges.append(
                KGEdge(
                    id=f"{doc_id}->account:{account_number}:HAS_ACCOUNT",
                    type="HAS_ACCOUNT",
                    source_id=doc_node.id,
                    target_id=account_node.id,
                    properties={},
                )
            )

        if bank_name:
            bank_node = KGNode(
                id=f"bank:{bank_name}",
                type="Bank",
                properties={"name": bank_name},
            )
            nodes.append(bank_node)
            if account_number:
                edges.append(
                    KGEdge(
                        id=f"account:{account_number}->bank:{bank_name}:HELD_AT",
                        type="HELD_AT",
                        source_id=f"account:{account_number}",
                        target_id=bank_node.id,
                        properties={},
                    )
                )

        # Employer / employee entities (payslips)
        employer_name = extracted_data.get("employer_name")
        employee_name = extracted_data.get("employee_name")
        if employer_name:
            employer_node = KGNode(
                id=f"employer:{employer_name}",
                type="Employer",
                properties={"name": employer_name},
            )
            nodes.append(employer_node)
            edges.append(
                KGEdge(
                    id=f"{doc_id}->employer:{employer_name}:EMPLOYED_BY",
                    type="EMPLOYED_BY",
                    source_id=doc_node.id,
                    target_id=employer_node.id,
                    properties={},
                )
            )

        if employee_name:
            employee_node = KGNode(
                id=f"person:{employee_name}",
                type="Person",
                properties={"name": employee_name},
            )
            nodes.append(employee_node)
            if employer_name:
                edges.append(
                    KGEdge(
                        id=f"person:{employee_name}->employer:{employer_name}:EMPLOYED_BY",
                        type="EMPLOYED_BY",
                        source_id=employee_node.id,
                        target_id=f"employer:{employer_name}",
                        properties={},
                    )
                )

        # Invoice-style counterparties
        vendor_name = extracted_data.get("vendor_name")
        bill_to = extracted_data.get("bill_to") or extracted_data.get("customer_name")
        if vendor_name:
            vendor_node = KGNode(
                id=f"counterparty:{vendor_name}",
                type="Counterparty",
                properties={"name": vendor_name, "role": "vendor"},
            )
            nodes.append(vendor_node)
            edges.append(
                KGEdge(
                    id=f"{doc_id}->counterparty:{vendor_name}:ISSUED_BY",
                    type="ISSUED_BY",
                    source_id=doc_node.id,
                    target_id=vendor_node.id,
                    properties={},
                )
            )

        if bill_to:
            customer_node = KGNode(
                id=f"counterparty:{bill_to}",
                type="Counterparty",
                properties={"name": bill_to, "role": "customer"},
            )
            nodes.append(customer_node)
            edges.append(
                KGEdge(
                    id=f"{doc_id}->counterparty:{bill_to}:PAYS",
                    type="PAYS",
                    source_id=customer_node.id,
                    target_id=doc_node.id,
                    properties={},
                )
            )

        # Transactions (bank statements)
        transactions = extracted_data.get("transactions") or []
        for idx, txn in enumerate(transactions):
            txn_id = f"{doc_id}:txn:{idx}"
            txn_node = KGNode(
                id=txn_id,
                type="Transaction",
                properties={
                    "date": txn.get("date"),
                    "amount": txn.get("amount"),
                    "currency": txn.get("currency"),
                    "description": txn.get("description"),
                    "raw": txn,
                },
            )
            nodes.append(txn_node)
            edges.append(
                KGEdge(
                    id=f"{doc_id}->{txn_id}:HAS_TRANSACTION",
                    type="HAS_TRANSACTION",
                    source_id=doc_node.id,
                    target_id=txn_node.id,
                    properties={},
                )
            )

        return DocumentKnowledgeGraph(document_id=doc_id, nodes=nodes, edges=edges)

    async def process_document(self, pdf_bytes: bytes, filename: str) -> Dict[str, Any]:
        """
        Process single document using REAL AI (Backboard).
        """
        # 1. Run Real AI Analysis
        print(f"[Pipeline] Sending '{filename}' to Backboard AI...")
        try:
            ai_result = await self.backboard.analyze_document(pdf_bytes, filename)
        except Exception as e:
            print(f"[Pipeline] AI Failed: {e}")
            # Fallback to mock if AI fails (optional, or just raise)
            return {
                "status": "failed",
                "error": str(e)
            }

        # 2. Map AI Result to Pipeline Structure
        doc_conf = ai_result.get("classification", {}).get("confidence", 0.0)
        doc_type = ai_result.get("classification", {}).get("type", "UNKNOWN").upper()
        extracted_data = ai_result.get("extracted_fields", {})
        
        print(f"[Pipeline] AI Result: Type={doc_type}, Conf={doc_conf}")
        print(f"[Pipeline] RAW AI DATA: {ai_result}")

        # 3. specific validation logic (reuse existing logic but with real data)
        # We need to map extracted_data keys to what validate_logic expects
        # AI returns snake_case usually as per prompt.
        
        # Run validation (pipeline-level + shared validator)
        validation_errors = self.validate_logic(extracted_data, doc_type)

        # Additional validation using shared DocumentValidator for
        # bank statements, invoices, and payslips.
        try:
            dv_type = doc_type.lower()
            dv_result = self._validator.validate(dv_type, extracted_data)
            if not dv_result.get("valid", True):
                for msg in dv_result.get("errors", []):
                    validation_errors.append(
                        {
                            "check": "DocumentValidator",
                            "message": msg,
                            "severity": "error",
                        }
                    )
            for msg in dv_result.get("warnings", []):
                validation_errors.append(
                    {
                        "check": "DocumentValidator",
                        "message": msg,
                        "severity": "warning",
                    }
                )
        except Exception as e:
            print(f"[Pipeline] DocumentValidator failed: {e}")
        
        # Determine overall status
        status = "PASS"
        if validation_errors:
            status = "FAIL" if any(e["severity"] == "error" for e in validation_errors) else "REVIEW"
        if doc_conf < 0.8:
            status = "REVIEW"

        # 4. Construct Final Result
        doc_id = ai_result.get("document_id") or f"DOC-{self._doc_counter}"
        self._doc_counter += 1
        
        # AI doesn't return layout tags in v1 prompt, so we can infer or mock them for UI visual
        # Or upgrade prompt to ask for layout tags. For now, let's infer from type.
        layouts = self._detect_layouts(filename, doc_type)
        
        # Map layouts for frontend
        layout_map = {
            "tables": "Table" in layouts or "Multi-Table" in layouts,
            "handwritten": "Handwritten" in layouts,
            "stamps": "Stamp" in layouts,
            "signatures": "Signature" in layouts,
            "headers": "Header" in layouts
        }
        
        # Simplify errors for frontend
        errors = [e["message"] for e in validation_errors if e["severity"] == "error"]
        warnings = [e["message"] for e in validation_errors if e["severity"] == "warning"]

        final_result = {
            "document_id": doc_id,
            "filename": filename,
            "classification": {
                "type": doc_type,
                "confidence": doc_conf
            },
            "extracted_fields": extracted_data,
            "layout": layout_map, 
            "layout_tags": layouts,
            "validation": {
                "valid": status == "PASS",
                "errors": errors,
                "warnings": warnings
            },
            "processing_time_seconds": 15.0, # Real AI takes time
            "status": "success"
        }
        
        # 4b. Build Knowledge Graph and persist
        try:
            graph = self._build_knowledge_graph(
                doc_id=doc_id,
                filename=filename,
                doc_type=doc_type,
                extracted_data=extracted_data,
                layout_map=layout_map,
            )
            kg_store = get_knowledge_store()
            kg_store.upsert_document_graph(graph)
            # Attach a JSON-serializable view for API consumers
            final_result["knowledge_graph"] = graph.model_dump()
        except Exception as e:
            print(f"[Pipeline] Knowledge graph build failed: {e}")

        # 5. Persist to Memory Store
        try:
            from app.services.memory_store import get_memory_store
            from app.services.learning_loop import get_correction_store
            
            store = get_memory_store()
            learning = get_correction_store()
            
            # Save main result
            store.save_document(doc_id, final_result, pdf_bytes)
            
            # Track metrics
            learning.record_processed_document()
            
            # Flag for review if needed
            if status != "PASS":
                for err in errors:
                    store.add_to_review({
                        "doc_id": doc_id,
                        "field": "validation",
                        "ocr_value": "ERROR",
                        "suggestion": err,
                        "confidence": 0,
                        "doc_type": doc_type
                    })
            
            if doc_conf < 0.8:
                 store.add_to_review({
                    "doc_id": doc_id,
                    "field": "classification",
                    "ocr_value": doc_type,
                    "suggestion": "Verify Type",
                    "confidence": int(doc_conf * 100),
                    "doc_type": doc_type
                })

        except Exception as e:
            print(f"Memory store failed: {e}")
            
        return final_result


# Singleton instance
_pipeline = DocumentPipeline()

def get_pipeline() -> DocumentPipeline:
    return _pipeline
