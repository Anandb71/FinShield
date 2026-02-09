"""
FinShield / Finsight - Core Configuration

Environment-driven settings for the new build.
"""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings


BASE_DIR = Path(__file__).resolve().parents[2]
ROOT_DIR = BASE_DIR.parent
BACKEND_ENV = BASE_DIR / ".env"
ROOT_ENV = ROOT_DIR / ".env"


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # API Configuration
    app_name: str = "Finsight API"
    app_version: str = "1.0.0"
    debug: bool = True

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS Configuration
    cors_origins: list[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*",
        "http://10.0.2.2:*",
    ]

    # Backboard.io Configuration (Document Intelligence + Knowledge Graph)
    backboard_api_key: str = ""
    backboard_api_url: str = "https://app.backboard.io/api"
    backboard_workspace_id: str = ""
    backboard_llm_provider: str = "openai"
    backboard_model_name: str = "gpt-4o"
    backboard_max_retries: int = 3
    backboard_retry_delay_seconds: float = 2.0
    backboard_retry_max_delay_seconds: float = 12.0

    # Storage
    database_url: str = "sqlite:///./finsight.db"

    # Review thresholds
    review_confidence_threshold: float = 0.8
    review_quality_threshold: float = 0.7

    # Learning triggers
    learning_corrections_threshold: int = 100
    learning_error_rate_threshold: float = 0.1

    # Upload constraints
    max_upload_mb: int = 25

    # Dataset ingestion
    dataset_path: str = ""

    # OCR
    tesseract_cmd: str = ""
    ocr_lang: str = "eng"
    ocr_psm: int = 6
    ocr_oem: int = 1
    ocr_preserve_interword_spaces: int = 1
    ocr_char_whitelist: str = ""

    class Config:
        env_file = (str(ROOT_ENV), str(BACKEND_ENV))
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()
