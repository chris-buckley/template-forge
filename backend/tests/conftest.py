"""Shared test fixtures and configuration."""

import os
import pytest
from typing import Dict

# Set test environment variables
os.environ["APP_ENV"] = "test"
os.environ["ACCESS_PASSWORD"] = "test-password-123"
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4317"
os.environ["LOG_LEVEL"] = "DEBUG"


@pytest.fixture
def auth_headers() -> Dict[str, str]:
    """Provide valid authentication headers for tests."""
    return {"Authorization": f"Bearer {os.environ['ACCESS_PASSWORD']}"}


@pytest.fixture
def test_env_vars(monkeypatch):
    """Set up test environment variables."""
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("ACCESS_PASSWORD", "test-password-123")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317")
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")
    yield
