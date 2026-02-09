"""
FinShield - Knowledge Graph API

Read-only access to the JSON knowledge graph produced by the
document intelligence pipeline.
"""

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from app.services.knowledge_graph import get_knowledge_store


router = APIRouter()


@router.get("/documents/{doc_id}", summary="Get knowledge graph for a document")
async def get_document_knowledge(doc_id: str) -> Dict[str, Any]:
    """
    Return the full knowledge graph slice associated with a document.
    """
    store = get_knowledge_store()
    graph = store.get_document_graph(doc_id)
    if not graph:
        raise HTTPException(status_code=404, detail="Knowledge graph not found")
    return graph.model_dump()


@router.get("/entities", summary="Search entities in the knowledge graph")
async def search_entities(
    entity_type: Optional[str] = Query(
        default=None,
        description="Filter by node type, e.g. Account, Bank, Employer, Counterparty",
    ),
    q: Optional[str] = Query(
        default=None,
        description="Free-text search across string properties",
    ),
) -> Dict[str, Any]:
    store = get_knowledge_store()
    nodes = store.search_entities(entity_type=entity_type, query=q)
    return {"results": [n.model_dump() for n in nodes]}


@router.get("/graph/overview", summary="Knowledge graph overview metrics")
async def knowledge_overview() -> Dict[str, Any]:
    store = get_knowledge_store()
    return store.graph_overview()

