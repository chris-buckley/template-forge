"""Shared test fixtures and configuration."""

import os
import pytest
import pytest_asyncio
from typing import Dict, Tuple
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport

# Set test environment variables before importing app
os.environ["APP_ENV"] = "test"
os.environ["ACCESS_PASSWORD"] = "test-password-123"
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4317"
os.environ["LOG_LEVEL"] = "DEBUG"
os.environ["ENABLE_DOCS"] = "true"  # Enable docs for testing

from app.main import app


@pytest.fixture
def auth_headers() -> Dict[str, str]:
    """Provide valid authentication headers for tests."""
    return {"Authorization": f"Bearer {os.environ['ACCESS_PASSWORD']}"}


@pytest.fixture
def invalid_auth_headers() -> Dict[str, str]:
    """Provide invalid authentication headers for tests."""
    return {"Authorization": "Bearer wrong-password"}


@pytest.fixture
def test_env_vars(monkeypatch):
    """Set up test environment variables."""
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("ACCESS_PASSWORD", "test-password-123")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317")
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")
    yield


@pytest.fixture
def client() -> TestClient:
    """Create test client for synchronous tests."""
    return TestClient(app)


@pytest_asyncio.fixture
async def async_client() -> AsyncClient:
    """Create async test client for asynchronous tests."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest.fixture
def sample_pdf_file() -> Tuple[str, bytes, str]:
    """Create a sample PDF file for testing."""
    # Minimal valid PDF structure
    pdf_content = b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R >>\nendobj\nxref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000058 00000 n\n0000000115 00000 n\ntrailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n164\n%%EOF"
    return ("test.pdf", pdf_content, "application/pdf")


@pytest.fixture
def sample_csv_file() -> Tuple[str, bytes, str]:
    """Create a sample CSV file for testing."""
    csv_content = b"name,age,department\nJohn Doe,30,Engineering\nJane Smith,25,Marketing\nBob Johnson,35,Sales\n"
    return ("data.csv", csv_content, "text/csv")


@pytest.fixture
def sample_docx_file() -> Tuple[str, bytes, str]:
    """Create a sample DOCX file for testing."""
    # Minimal DOCX is a ZIP file with specific structure
    # This is a simplified version - real DOCX has more structure
    docx_content = b"PK\x03\x04\x14\x00\x00\x00\x08\x00"  # ZIP header
    return ("document.docx", docx_content, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")


@pytest.fixture
def sample_xlsx_file() -> Tuple[str, bytes, str]:
    """Create a sample XLSX file for testing."""
    # Minimal XLSX is also a ZIP file
    xlsx_content = b"PK\x03\x04\x14\x00\x00\x00\x08\x00"  # ZIP header
    return ("spreadsheet.xlsx", xlsx_content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")


@pytest.fixture
def large_file() -> Tuple[str, bytes, str]:
    """Create a large file that exceeds size limits."""
    # Create 51MB file (limit is 50MB)
    large_content = b"A" * (51 * 1024 * 1024)
    return ("large.pdf", large_content, "application/pdf")


@pytest.fixture
def invalid_file() -> Tuple[str, bytes, str]:
    """Create an invalid file type for testing."""
    exe_content = b"MZ\x90\x00"  # EXE header
    return ("malware.exe", exe_content, "application/x-msdownload")
