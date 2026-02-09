from __future__ import annotations

from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[2]
STORAGE_DIR = BASE_DIR / "storage"


def save_file(doc_id: str, filename: str, content: bytes) -> str:
    doc_dir = STORAGE_DIR / doc_id
    doc_dir.mkdir(parents=True, exist_ok=True)
    path = doc_dir / filename
    path.write_bytes(content)
    return str(path)


def read_file(path: str) -> bytes:
    return Path(path).read_bytes()
