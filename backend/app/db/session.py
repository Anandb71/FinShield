from __future__ import annotations

from sqlalchemy import text
from sqlmodel import SQLModel, create_engine, Session

from app.core.config import get_settings


settings = get_settings()
engine = create_engine(settings.database_url, echo=False)


def init_db() -> None:
    SQLModel.metadata.create_all(engine)
    _ensure_sqlite_schema()


def _ensure_sqlite_schema() -> None:
    if engine.dialect.name != "sqlite":
        return

    with engine.begin() as conn:
        table_info = conn.execute(text("PRAGMA table_info(document)"))
        existing_columns = {row[1] for row in table_info}

        if not existing_columns:
            return

        column_defs = {
            "backboard_thread_id": "TEXT",
            "batch_id": "TEXT",
            "doc_type": "TEXT",
            "confidence": "REAL",
            "language": "TEXT",
            "image_quality": "REAL",
            "status": "TEXT",
            "layout_flags": "JSON",
            "quality_metrics": "JSON",
            "extracted_fields": "JSON",
            "validation_errors": "JSON",
            "validation_warnings": "JSON",
            "consistency": "JSON",
            "processing_time_ms": "INTEGER",
            "created_at": "DATETIME",
        }

        for column_name, column_type in column_defs.items():
            if column_name in existing_columns:
                continue
            conn.execute(
                text(
                    "ALTER TABLE document ADD COLUMN "
                    f"{column_name} {column_type}"
                )
            )


def get_session():
    session = Session(engine)
    try:
        yield session
    finally:
        session.close()
