from __future__ import annotations

import json
from typing import Any

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Database
    database_url: str = "postgresql+asyncpg://juro:password@localhost:5432/juro_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Security
    secret_key: str = "change-me-to-a-random-32-byte-hex-string"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # PHI Encryption
    phi_encryption_key: str = "change-me-to-a-base64-encoded-32-byte-key"

    # Email
    smtp_host: str = "smtp.example.com"
    smtp_port: int = 587
    smtp_user: str = "noreply@example.com"
    smtp_password: str = ""
    smtp_tls: bool = True

    # App
    app_env: str = "development"
    app_title: str = "JURO API"
    app_version: str = "1.0.0"
    cors_origins: list[str] = ["http://localhost:3000"]

    # Recipe Scraper
    recipe_scraper_user_agent: str = "JURO/1.0"
    recipe_cache_ttl_seconds: int = 604800

    # Menu CSP
    menu_duplicate_avoid_days: int = 7

    @classmethod
    def _parse_cors(cls, v: Any) -> list[str]:
        if isinstance(v, str):
            return json.loads(v)
        return v


settings = Settings()
