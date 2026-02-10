"""
FinShield - Knowledge Graph Service

Canonical JSON knowledge graph schema and in-memory storage.

This module defines a generic, Backboard-friendly knowledge graph
representation for financial documents and a simple in-memory store.

Nodes:
    - Document
    - Account
    - Bank
    - Employer
    - Counterparty
    - Invoice
    - Payslip
    - Transaction

Edges:
    - HAS_ACCOUNT
    - EMPLOYED_BY
    - PAYS
    - DERIVED_FROM
    - CROSS_CHECKED_WITH
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from dataclasses import dataclass, field

from pydantic import BaseModel, Field


class KGNode(BaseModel):
    """
    Generic knowledge graph node.

    This keeps the schema flexible while still being explicit about
    core node types via the ``type`` field.
    """

    id: str = Field(..., description="Stable node identifier")
    type: str = Field(
        ...,
        description=(
            "Node type, e.g. Document, Account, Bank, Employer, "
            "Counterparty, Invoice, Payslip, Transaction"
        ),
    )
    properties: Dict[str, Any] = Field(
        default_factory=dict,
        description="Arbitrary structured attributes for this node",
    )


class KGEdge(BaseModel):
    """Directed relationship between two nodes."""

    id: str = Field(..., description="Stable edge identifier")
    type: str = Field(
        ...,
        description=(
            "Edge type, e.g. HAS_ACCOUNT, EMPLOYED_BY, PAYS, "
            "DERIVED_FROM, CROSS_CHECKED_WITH"
        ),
    )
    source_id: str = Field(..., description="Source node id")
    target_id: str = Field(..., description="Target node id")
    properties: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata for the relationship",
    )


class DocumentKnowledgeGraph(BaseModel):
    """
    Knowledge graph slice anchored on a single document.

    This is the main JSON object exposed to the Reviewer UI and
    dashboards for a given document.
    """

    document_id: str = Field(..., description="Primary document identifier")
    nodes: List[KGNode] = Field(
        default_factory=list,
        description="All nodes associated with this document",
    )
    edges: List[KGEdge] = Field(
        default_factory=list,
        description="Relationships between nodes in this slice",
    )


# Extra scalar fields to surface as nodes on the knowledge graph
_ACCOUNT_FIELDS = ("account_number", "ifsc", "micr")
_BALANCE_FIELDS = ("opening_balance", "closing_balance")
_MAX_COUNTERPARTIES = 10  # keep graph readable


def build_graph_from_document(
    document_id: str,
    doc_type: str,
    extracted_fields: Dict[str, Any],
    entity_nodes: List[KGNode],
) -> DocumentKnowledgeGraph:
    nodes: List[KGNode] = [
        KGNode(
            id=document_id,
            type="Document",
            properties={
                "doc_type": doc_type,
            },
        )
    ]
    edges: List[KGEdge] = []
    seen_ids: set[str] = {document_id}

    # ── Resolved entities (vendor, bank, employer, etc.) ──
    for entity in entity_nodes:
        if entity.id not in seen_ids:
            nodes.append(entity)
            seen_ids.add(entity.id)
        edges.append(
            KGEdge(
                id=f"{document_id}->{entity.id}:MENTIONS",
                type="MENTIONS",
                source_id=document_id,
                target_id=entity.id,
                properties={},
            )
        )

    # ── Account info node ──
    acct_props = {
        k: str(extracted_fields[k])
        for k in _ACCOUNT_FIELDS
        if extracted_fields.get(k)
    }
    if acct_props:
        acct_id = f"{document_id}:account"
        acct_label = acct_props.get("account_number", "Account")
        nodes.append(KGNode(id=acct_id, type="Account", properties={"canonical_value": acct_label, **acct_props}))
        seen_ids.add(acct_id)
        edges.append(
            KGEdge(id=f"{document_id}->{acct_id}:HAS_ACCOUNT", type="HAS_ACCOUNT",
                   source_id=document_id, target_id=acct_id, properties={})
        )

    # ── Balance summary node ──
    bal_props = {
        k: extracted_fields[k]
        for k in _BALANCE_FIELDS
        if extracted_fields.get(k) is not None
    }
    if bal_props:
        bal_id = f"{document_id}:balance"
        ob = bal_props.get("opening_balance", "?")
        cb = bal_props.get("closing_balance", "?")
        nodes.append(KGNode(id=bal_id, type="Balance", properties={"canonical_value": f"{ob} → {cb}", **bal_props}))
        seen_ids.add(bal_id)
        edges.append(
            KGEdge(id=f"{document_id}->{bal_id}:HAS_BALANCE", type="HAS_BALANCE",
                   source_id=document_id, target_id=bal_id, properties={})
        )

    # ── Top transaction counterparties ──
    txns = extracted_fields.get("transactions")
    if isinstance(txns, list) and txns:
        from collections import Counter
        merchant_counts: Counter[str] = Counter()
        for txn in txns:
            # Prefer the normalised merchant name; fall back to description
            merchant = (txn.get("merchant_normalized") or "").strip()
            if not merchant:
                merchant = (txn.get("description") or "").strip()
            if merchant and len(merchant) > 1:
                merchant_counts[merchant] += 1
        for merchant, count in merchant_counts.most_common(_MAX_COUNTERPARTIES):
            cp_id = f"{document_id}:cp:{merchant[:40]}"
            if cp_id not in seen_ids:
                nodes.append(KGNode(
                    id=cp_id, type="Counterparty",
                    properties={"canonical_value": merchant, "transaction_count": count},
                ))
                seen_ids.add(cp_id)
                edges.append(
                    KGEdge(id=f"{document_id}->{cp_id}:TRANSACTS_WITH", type="TRANSACTS_WITH",
                           source_id=document_id, target_id=cp_id,
                           properties={"count": count})
                )

    return DocumentKnowledgeGraph(document_id=document_id, nodes=nodes, edges=edges)


@dataclass
class InMemoryKnowledgeGraphStore:
    """
    Simple in-memory knowledge graph store.

    This is the default implementation for local development and
    testing. In production, this can be replaced by a Postgres
    (JSONB) or graph database-backed implementation while keeping
    the same public interface.
    """

    _documents: Dict[str, DocumentKnowledgeGraph] = field(default_factory=dict)

    # ------------------------------------------------------------------
    # Core CRUD
    # ------------------------------------------------------------------
    def upsert_document_graph(self, graph: DocumentKnowledgeGraph) -> None:
        """Create or replace the knowledge graph slice for a document."""
        self._documents[graph.document_id] = graph

    def get_document_graph(self, document_id: str) -> Optional[DocumentKnowledgeGraph]:
        """Return the knowledge graph slice for a document, if any."""
        return self._documents.get(document_id)

    def link_documents(
        self,
        source_document_id: str,
        target_document_id: str,
        edge_type: str = "CROSS_CHECKED_WITH",
        properties: Optional[Dict[str, Any]] = None,
    ) -> None:
        """
        Create a cross-document relationship between two document nodes.

        If the corresponding document graphs do not yet exist, this
        is a no-op; callers should ensure graphs are created first.
        """
        src_graph = self._documents.get(source_document_id)
        tgt_graph = self._documents.get(target_document_id)
        if not src_graph or not tgt_graph:
            return

        # Look up or create document nodes
        def _ensure_doc_node(graph: DocumentKnowledgeGraph) -> KGNode:
            for n in graph.nodes:
                if n.type == "Document" and n.id == graph.document_id:
                    return n
            node = KGNode(
                id=graph.document_id,
                type="Document",
                properties={},
            )
            graph.nodes.append(node)
            return node

        src_node = _ensure_doc_node(src_graph)
        tgt_node = _ensure_doc_node(tgt_graph)

        edge = KGEdge(
            id=f"{src_node.id}->{tgt_node.id}:{edge_type}",
            type=edge_type,
            source_id=src_node.id,
            target_id=tgt_node.id,
            properties=properties or {},
        )
        src_graph.edges.append(edge)

    # ------------------------------------------------------------------
    # Query helpers for dashboards / UI
    # ------------------------------------------------------------------
    def search_entities(
        self,
        entity_type: Optional[str] = None,
        query: Optional[str] = None,
    ) -> List[KGNode]:
        """
        Naive in-memory entity search.

        Args:
            entity_type: Optional node type filter, e.g. 'Account' or 'Employer'
            query: Optional substring match across string properties
        """
        results: List[KGNode] = []
        for graph in self._documents.values():
            for node in graph.nodes:
                if entity_type and node.type != entity_type:
                    continue
                if not query:
                    results.append(node)
                    continue
                # Simple substring match in any string property
                for value in node.properties.values():
                    if isinstance(value, str) and query.lower() in value.lower():
                        results.append(node)
                        break
        return results

    def graph_overview(self) -> Dict[str, Any]:
        """
        Aggregate statistics for dashboards.

        Returns counts by node/edge type and total documents tracked.
        """
        node_counts: Dict[str, int] = {}
        edge_counts: Dict[str, int] = {}

        for graph in self._documents.values():
            for node in graph.nodes:
                node_counts[node.type] = node_counts.get(node.type, 0) + 1
            for edge in graph.edges:
                edge_counts[edge.type] = edge_counts.get(edge.type, 0) + 1

        return {
            "total_documents": len(self._documents),
            "node_counts": node_counts,
            "edge_counts": edge_counts,
        }


_knowledge_store: Optional[InMemoryKnowledgeGraphStore] = None


def get_knowledge_store() -> InMemoryKnowledgeGraphStore:
    """
    Return the process-wide knowledge graph store.

    In production this can be swapped for a database-backed
    implementation while preserving the public interface.
    """
    global _knowledge_store
    if _knowledge_store is None:
        _knowledge_store = InMemoryKnowledgeGraphStore()
    return _knowledge_store

