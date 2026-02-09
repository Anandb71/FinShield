from __future__ import annotations

from datetime import datetime
from typing import Optional, Any, List
from uuid import uuid4

from sqlalchemy import Column, JSON
from sqlmodel import Field, SQLModel


class Document(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    filename: str
    file_path: Optional[str] = None
    batch_id: Optional[str] = None
    backboard_thread_id: Optional[str] = None
    doc_type: str = "unknown"
    confidence: float = 0.0
    language: Optional[str] = None
    image_quality: Optional[float] = None
    status: str = "processing"  # processing | processed | review | failed
    layout_flags: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    quality_metrics: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    extracted_fields: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    validation_errors: list[dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSON))
    validation_warnings: list[dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSON))
    consistency: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    processing_time_ms: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Transaction(SQLModel, table=True):
    """Extracted transaction row from a bank statement."""
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    document_id: str = Field(index=True)
    row_index: int = 0
    date: Optional[str] = None
    description: Optional[str] = None
    amount: Optional[float] = None
    tx_type: str = "unknown"  # debit | credit | unknown
    balance_after: Optional[float] = None
    merchant_normalized: Optional[str] = None
    category: Optional[str] = None
    is_anomaly: bool = False
    anomaly_tags: list[str] = Field(default_factory=list, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Anomaly(SQLModel, table=True):
    """Forensic anomaly log entry."""
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    document_id: str = Field(index=True)
    transaction_id: Optional[str] = None
    anomaly_type: str  # balance_discontinuity, structuring, velocity, benford, summary_injection, merge_artifact, synthetic
    severity: str = "warning"  # critical | warning | info
    description: str = ""
    details: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    row_index: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Correction(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    document_id: str = Field(index=True)
    field_name: str
    original_value: Optional[str] = None
    corrected_value: Optional[str] = None
    corrected_by: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Entity(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    entity_type: str
    canonical_value: str
    normalized_value: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DocumentEntity(SQLModel, table=True):
    document_id: str = Field(primary_key=True)
    entity_id: str = Field(primary_key=True)


class LearningEvent(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    event_type: str
    payload: dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)
