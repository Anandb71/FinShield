"""
FinShield - Enhanced Learning with Backboard

Feeds human corrections back to Backboard's persistent thread memory
so the AI improves on future extractions.  Uses the *real* BackboardClient
(Assistants API) and the SQLModel Correction table — NOT the dead
in-memory CorrectionStore or the stubbed BackboardDocumentService.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlmodel import Session, select

from app.db.models import Correction, Document, LearningEvent
from app.services.backboard_client import BackboardClient

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Minimum gap between identical learning-sync events (avoids flooding)
# ---------------------------------------------------------------------------
_LEARNING_COOLDOWN = timedelta(hours=1)
_MIN_CLUSTER_SIZE = 1  # learn from every correction immediately


class BackboardLearningEnhancer:
    """Push human corrections and error-pattern summaries into Backboard."""

    def __init__(self) -> None:
        self._client = BackboardClient()
        self._patterns_loaded = False

    # ------------------------------------------------------------------
    # 0.  Load cached patterns from DB on first use (survives restarts)
    # ------------------------------------------------------------------
    def _ensure_patterns_loaded(self, session: Session) -> None:
        """Load the latest learning patterns into the prompt cache if not done."""
        if self._patterns_loaded:
            return
        self._patterns_loaded = True

        # Find the most recent learning_sync event and re-build from corrections
        corrections: List[Correction] = list(session.exec(select(Correction)).all())
        if not corrections:
            return

        clusters: Dict[str, Dict[str, Any]] = {}
        for c in corrections:
            bucket = clusters.setdefault(c.field_name, {"count": 0, "examples": []})
            bucket["count"] += 1
            if len(bucket["examples"]) < 5:
                bucket["examples"].append({
                    "original": c.original_value,
                    "corrected": c.corrected_value,
                })

        pattern_lines: list[str] = []
        for field_name, data in clusters.items():
            if data["count"] < _MIN_CLUSTER_SIZE:
                continue
            examples_text = "; ".join(
                f"'{ex['original']}' → '{ex['corrected']}'" for ex in data["examples"]
            )
            pattern_lines.append(
                f"• Field '{field_name}' corrected {data['count']}x. "
                f"Examples: {examples_text}"
            )

        if pattern_lines:
            import app.services.backboard_client as _bc
            _bc._learned_patterns = "\n".join(pattern_lines)
            logger.info(
                "Loaded %d learning patterns from DB into prompt cache",
                len(pattern_lines),
            )

    # ------------------------------------------------------------------
    # 1.  Push a single document's corrections into its Backboard thread
    # ------------------------------------------------------------------
    async def push_document_corrections(
        self,
        doc: Document,
        corrections: List[Correction],
    ) -> bool:
        """Post a correction summary into the document's Backboard thread."""
        if not doc.backboard_thread_id:
            logger.warning(
                "Document %s has no Backboard thread — skipping learning push",
                doc.id,
            )
            return False

        summary_lines = [
            f"LEARNING UPDATE — {len(corrections)} human correction(s) for document {doc.id}:",
        ]
        for c in corrections:
            summary_lines.append(
                f"  • Field '{c.field_name}': was '{c.original_value}' → "
                f"corrected to '{c.corrected_value}'"
            )
        summary_lines.append(
            "\nPlease incorporate these corrections when analysing similar "
            "documents in the future."
        )
        summary = "\n".join(summary_lines)

        try:
            await self._client.submit_correction(doc.backboard_thread_id, summary)
            logger.info("Pushed %d corrections to thread %s", len(corrections), doc.backboard_thread_id)
            return True
        except Exception as exc:
            logger.error("Failed to push corrections to Backboard: %s", exc)
            return False

    # ------------------------------------------------------------------
    # 2.  Cluster-based learning: find common mistake patterns → teach AI
    # ------------------------------------------------------------------
    async def sync_learning_patterns(self, session: Session) -> Dict[str, Any]:
        """
        Analyse all corrections, cluster by field, and:
        1. Build a learning-pattern string that gets injected into every
           future LLM prompt (via backboard_client._learned_patterns).
        2. Post each pattern into affected Backboard threads (best-effort).
        """
        corrections: List[Correction] = list(session.exec(select(Correction)).all())
        if not corrections:
            return {"synced": 0, "message": "No corrections to learn from"}

        # Build clusters -----------------------------------------------
        clusters: Dict[str, Dict[str, Any]] = {}
        for c in corrections:
            bucket = clusters.setdefault(
                c.field_name, {"count": 0, "examples": []}
            )
            bucket["count"] += 1
            if len(bucket["examples"]) < 5:
                bucket["examples"].append(
                    {
                        "original": c.original_value,
                        "corrected": c.corrected_value,
                        "document_id": c.document_id,
                    }
                )

        # ---- Build prompt-injection string ---------------------------
        pattern_lines: list[str] = []
        significant_clusters = {
            k: v for k, v in clusters.items() if v["count"] >= _MIN_CLUSTER_SIZE
        }
        for field_name, data in significant_clusters.items():
            examples_text = "; ".join(
                f"'{ex['original']}' → '{ex['corrected']}'"
                for ex in data["examples"]
            )
            pattern_lines.append(
                f"• Field '{field_name}' corrected {data['count']}x. "
                f"Examples: {examples_text}"
            )

        # Update the global prompt cache so every new document sees this
        import app.services.backboard_client as _bc
        _bc._learned_patterns = "\n".join(pattern_lines)
        logger.info(
            "Updated prompt learning cache: %d patterns, %d chars",
            len(pattern_lines),
            len(_bc._learned_patterns),
        )

        # ---- Also post to affected threads (best-effort) -------------
        synced = 0
        for field_name, data in significant_clusters.items():
            examples_text = "\n".join(
                f"  {i}. Wrong: '{ex['original']}' → Correct: '{ex['corrected']}'"
                for i, ex in enumerate(data["examples"], 1)
            )
            learning_msg = (
                f"LEARNING PATTERN — common extraction mistake for field '{field_name}'.\n"
                f"This field has been corrected {data['count']} time(s).\n\n"
                f"Examples:\n{examples_text}\n\n"
                f"When extracting '{field_name}', pay close attention to "
                f"these patterns and avoid the same mistakes."
            )

            try:
                doc_ids_affected = {ex["document_id"] for ex in data["examples"]}
                for doc_id in doc_ids_affected:
                    doc = session.get(Document, doc_id)
                    if doc and doc.backboard_thread_id:
                        await self._client.submit_correction(
                            doc.backboard_thread_id, learning_msg
                        )
                synced += 1
            except Exception as exc:
                logger.error("Learning sync failed for field '%s': %s", field_name, exc)

        # Record a learning event
        event = LearningEvent(
            event_type="learning_sync",
            payload={
                "clusters_synced": synced,
                "total_corrections": len(corrections),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )
        session.add(event)
        session.commit()

        logger.info("Learning sync complete: %d patterns pushed to Backboard", synced)
        return {
            "synced": synced,
            "total_corrections": len(corrections),
            "clusters": {
                k: {"count": v["count"], "examples": v["examples"]}
                for k, v in clusters.items()
                if v["count"] >= _MIN_CLUSTER_SIZE
            },
        }

    # ------------------------------------------------------------------
    # 3.  Check cooldown so we don't re-sync every single correction
    # ------------------------------------------------------------------
    def should_auto_sync(self, session: Session) -> bool:
        """Return True if enough time has passed since the last sync."""
        last_sync = session.exec(
            select(LearningEvent)
            .where(LearningEvent.event_type == "learning_sync")
            .order_by(LearningEvent.created_at.desc())  # type: ignore[union-attr]
        ).first()
        if last_sync is None:
            return True
        now = datetime.now(timezone.utc)
        # Ensure created_at is timezone-aware for comparison
        sync_time = last_sync.created_at.replace(tzinfo=timezone.utc) if last_sync.created_at.tzinfo is None else last_sync.created_at
        return now - sync_time > _LEARNING_COOLDOWN


# ---------------------------------------------------------------------------
# Singleton
# ---------------------------------------------------------------------------
_learning_enhancer: Optional[BackboardLearningEnhancer] = None


def get_learning_enhancer() -> BackboardLearningEnhancer:
    global _learning_enhancer
    if _learning_enhancer is None:
        _learning_enhancer = BackboardLearningEnhancer()
    return _learning_enhancer
