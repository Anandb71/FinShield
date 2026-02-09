from __future__ import annotations

import re
from typing import Dict, Any, List

from rapidfuzz import process, fuzz
from sqlmodel import Session, select

from app.db.models import Entity, DocumentEntity


ENTITY_FIELDS = {
    "vendor_name": "vendor",
    "bank_name": "bank",
    "institution_name": "bank",
    "employer_name": "employer",
}


def _normalize(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9\s]", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value


def resolve_entities(
    session: Session,
    doc_id: str,
    extracted_fields: Dict[str, Any],
    threshold: int = 90,
) -> List[Entity]:
    resolved_entities: List[Entity] = []

    for field, entity_type in ENTITY_FIELDS.items():
        raw_value = extracted_fields.get(field)
        if not raw_value:
            continue
        normalized = _normalize(str(raw_value))

        existing = session.exec(
            select(Entity).where(Entity.entity_type == entity_type)
        ).all()

        match = None
        if existing:
            choices = {entity.normalized_value: entity for entity in existing}
            best = process.extractOne(
                normalized,
                choices.keys(),
                scorer=fuzz.ratio,
            )
            if best and best[1] >= threshold:
                match = choices[best[0]]

        if not match:
            match = Entity(
                entity_type=entity_type,
                canonical_value=str(raw_value),
                normalized_value=normalized,
            )
            session.add(match)
            session.commit()
            session.refresh(match)

        link = DocumentEntity(document_id=doc_id, entity_id=match.id)
        session.add(link)
        session.commit()

        resolved_entities.append(match)

    return resolved_entities
