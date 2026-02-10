"""Aegis - Learning Loop API."""

from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.db.session import get_session
from app.services.learning import cluster_corrections, check_learning_triggers

router = APIRouter(prefix="/learning")


@router.get("/errors/clusters")
async def get_error_clusters(session: Session = Depends(get_session)):
    return cluster_corrections(session)


@router.post("/triggers")
async def trigger_learning(session: Session = Depends(get_session)):
    return check_learning_triggers(session)

