"""Application configuration management."""

from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",  # Ignore extra fields from env
    )

    # Application Settings
    APP_ENV: str = "development"
    SERVICE_NAME: str = "md-decision-maker-backend"
    VERSION: str = "0.1.0"
    LOG_LEVEL: str = "INFO"

    # API Settings
    API_V1_STR: str = "/api/v1"

    # Security
    ACCESS_PASSWORD: str

    # CORS Settings - stored as string, parsed to list
    ALLOWED_ORIGINS_STR: str = "http://localhost:3000,http://localhost:3001"

    # Azure Configuration (for future use)
    AZURE_FOUNDRY_ENDPOINT: str = ""
    AZURE_FOUNDRY_API_KEY: str = ""
    OTEL_EXPORTER_OTLP_ENDPOINT: str = ""

    # Feature Flags
    ENABLE_DOCS: bool = True

    @property
    def ALLOWED_ORIGINS(self) -> List[str]:
        """Parse comma-separated origins."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS_STR.split(",") if origin.strip()]

    @property
    def is_development(self) -> bool:
        """Check if running in development mode."""
        return self.APP_ENV == "development"

    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return self.APP_ENV == "production"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()  # type: ignore[call-arg]


# Create a global settings instance
settings = get_settings()
