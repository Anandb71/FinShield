"""
FinShield API - Core Configuration

Central configuration management using Pydantic Settings.
Supports environment variables and .env files.
"""

from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # API Configuration
    app_name: str = "FinShield API"
    app_version: str = "0.1.0"
    debug: bool = True

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS Configuration (for Flutter app)
    cors_origins: list[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*",
        "http://10.0.2.2:*",  # Android emulator
    ]

    # AI Service Configuration (placeholders for Hotfoot/Backboard)
    hotfoot_audio_api_key: str = ""
    hotfoot_docs_api_key: str = ""
    backboard_api_key: str = ""
    backboard_workspace_id: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()
