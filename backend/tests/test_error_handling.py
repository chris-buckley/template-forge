"""Tests for error handling and logging functionality."""

import logging
from typing import Any, Dict

from fastapi.testclient import TestClient

from app.exceptions import (
    AuthenticationError,
    ValidationError,
    ResourceNotFoundError,
    ProcessingError,
    RateLimitError,
    ExternalServiceError,
)
from app.main import app
from app.utils.logging import correlation_id_var, SensitiveDataFilter

# Fixture for test client
client = TestClient(app)


def test_correlation_id_middleware(client: TestClient) -> None:
    """Test that correlation ID is added to requests and responses."""
    # Test with provided correlation ID
    correlation_id = "test-correlation-123"
    response = client.get("/health", headers={"X-Correlation-ID": correlation_id})

    assert response.status_code == 200
    assert response.headers.get("X-Correlation-ID") == correlation_id

    # Test without provided correlation ID (should generate one)
    response = client.get("/health")
    assert response.status_code == 200
    assert "X-Correlation-ID" in response.headers
    assert len(response.headers["X-Correlation-ID"]) > 0


def test_base_api_exception_handler(client: TestClient) -> None:
    """Test handling of custom API exceptions."""

    # Create a test endpoint that raises our custom exception
    @app.get("/test-error")
    def raise_error():
        raise ValidationError("Test validation error", details={"field": "test_field"})

    response = client.get("/test-error")
    assert response.status_code == 422

    error_data = response.json()
    assert "error" in error_data
    assert error_data["error"]["code"] == "VALIDATION_FAILED"
    assert error_data["error"]["message"] == "Test validation error"
    assert error_data["error"]["details"]["field"] == "test_field"
    assert "error_id" in error_data["error"]


def test_authentication_error_handler(client: TestClient) -> None:
    """Test authentication error handling."""

    @app.get("/test-auth-error")
    def raise_auth_error():
        raise AuthenticationError("Invalid credentials")

    response = client.get("/test-auth-error")
    assert response.status_code == 401

    error_data = response.json()
    assert error_data["error"]["code"] == "AUTH_FAILED"
    assert error_data["error"]["message"] == "Invalid credentials"


def test_resource_not_found_error_handler(client: TestClient) -> None:
    """Test resource not found error handling."""

    @app.get("/test-not-found")
    def raise_not_found():
        raise ResourceNotFoundError("Document", "doc123")

    response = client.get("/test-not-found")
    assert response.status_code == 404

    error_data = response.json()
    assert error_data["error"]["code"] == "RESOURCE_NOT_FOUND"
    assert "doc123" in error_data["error"]["message"]
    assert error_data["error"]["details"]["resource_type"] == "Document"


def test_processing_error_handler(client: TestClient) -> None:
    """Test processing error handling."""

    @app.get("/test-processing-error")
    def raise_processing_error():
        raise ProcessingError("Failed to process document", details={"step": "parsing"})

    response = client.get("/test-processing-error")
    assert response.status_code == 500

    error_data = response.json()
    assert error_data["error"]["code"] == "PROCESSING_FAILED"
    assert error_data["error"]["details"]["step"] == "parsing"


def test_rate_limit_error_handler(client: TestClient) -> None:
    """Test rate limit error handling."""

    @app.get("/test-rate-limit")
    def raise_rate_limit():
        raise RateLimitError("Too many requests", retry_after=60)

    response = client.get("/test-rate-limit")
    assert response.status_code == 429

    error_data = response.json()
    assert error_data["error"]["code"] == "RATE_LIMIT_EXCEEDED"
    assert error_data["error"]["details"]["retry_after"] == 60


def test_external_service_error_handler(client: TestClient) -> None:
    """Test external service error handling."""

    @app.get("/test-external-error")
    def raise_external_error():
        raise ExternalServiceError("Azure AI", "Service temporarily unavailable")

    response = client.get("/test-external-error")
    assert response.status_code == 502

    error_data = response.json()
    assert error_data["error"]["code"] == "EXTERNAL_SERVICE_ERROR"
    assert error_data["error"]["details"]["service"] == "Azure AI"


def test_request_validation_error(client: TestClient) -> None:
    """Test request validation error handling."""
    # The generate endpoint expects multipart form data
    response = client.post(
        "/api/v1/generate",
        json={"invalid": "data"},  # Wrong content type
        headers={"Authorization": "Bearer test-password"},
    )

    # Should get validation error
    assert response.status_code == 422
    error_data = response.json()
    assert error_data["error"]["code"] == "VALIDATION_ERROR"


def test_generic_exception_handler(client: TestClient) -> None:
    """Test handling of unexpected exceptions."""

    @app.get("/test-generic-error")
    def raise_generic_error():
        raise RuntimeError("Unexpected error occurred")

    response = client.get("/test-generic-error")
    assert response.status_code == 500

    error_data = response.json()
    assert error_data["error"]["code"] == "INTERNAL_ERROR"
    assert "error_id" in error_data["error"]


def test_sensitive_data_filter() -> None:
    """Test that sensitive data is filtered from logs."""
    filter = SensitiveDataFilter()

    # Test password in message
    record = logging.LogRecord(
        name="test", level=logging.INFO, pathname="", lineno=0, msg="User password is secret123", args=(), exc_info=None
    )
    filter.filter(record)
    assert record.msg == "[SENSITIVE DATA REDACTED]"

    # Test API key in attribute
    record = logging.LogRecord(
        name="test", level=logging.INFO, pathname="", lineno=0, msg="Normal message", args=(), exc_info=None
    )
    record.api_key = "sk-1234567890"
    filter.filter(record)
    assert record.api_key == "[REDACTED]"

    # Test normal message passes through
    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname="",
        lineno=0,
        msg="This is a normal log message",
        args=(),
        exc_info=None,
    )
    assert filter.filter(record) is True
    assert record.msg == "This is a normal log message"


def test_logging_middleware(client: TestClient, caplog) -> None:
    """Test that requests are logged properly."""
    with caplog.at_level(logging.INFO):
        response = client.get("/health")
        assert response.status_code == 200

        # Check that request was logged
        assert any("Request started" in record.message for record in caplog.records)
        assert any("Request completed" in record.message for record in caplog.records)

        # Check for correlation ID in logs
        completed_logs = [r for r in caplog.records if "Request completed" in r.message]
        assert len(completed_logs) > 0
        assert hasattr(completed_logs[0], "correlation_id")


def test_correlation_id_context() -> None:
    """Test correlation ID context variable."""
    # Test default value
    assert correlation_id_var.get() == "N/A"

    # Test setting value
    test_id = "test-correlation-456"
    token = correlation_id_var.set(test_id)
    assert correlation_id_var.get() == test_id

    # Test resetting
    correlation_id_var.reset(token)
    assert correlation_id_var.get() == "N/A"


def test_error_response_headers(client: TestClient) -> None:
    """Test that error responses include proper headers."""

    @app.get("/test-error-headers")
    def raise_error():
        raise ValidationError("Test error")

    response = client.get("/test-error-headers")
    assert response.status_code == 422
    assert "X-Error-ID" in response.headers
    assert response.headers["X-Error-ID"] != "N/A"


# Cleanup test endpoints
def teardown_module(module):
    """Remove test endpoints after tests complete."""
    # Note: In FastAPI, routes are immutable once created
    # The test endpoints will be cleaned up when the app instance is destroyed
    pass
