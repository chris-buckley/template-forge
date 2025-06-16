"""Tests for authentication middleware."""

from typing import Dict

import pytest
from fastapi import status
from fastapi.testclient import TestClient

from app.config import settings
from app.main import app


@pytest.fixture
def test_password() -> str:
    """Return the test password."""
    return settings.ACCESS_PASSWORD


@pytest.fixture
def valid_auth_headers(test_password: str) -> Dict[str, str]:
    """Return valid authentication headers."""
    return {"Authorization": f"Bearer {test_password}"}


@pytest.fixture
def invalid_auth_headers() -> Dict[str, str]:
    """Return invalid authentication headers."""
    return {"Authorization": "Bearer invalid-password"}


def test_health_endpoint_no_auth_required() -> None:
    """Test that health endpoint doesn't require authentication."""
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "ok"
    assert data["version"] == settings.VERSION


def test_authenticated_endpoint_without_auth() -> None:
    """Test that authenticated endpoint returns 403 without credentials."""
    client = TestClient(app)
    response = client.get("/api/v1/test/auth")

    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert response.json()["detail"] == "Not authenticated"


def test_authenticated_endpoint_with_invalid_auth(invalid_auth_headers: Dict[str, str]) -> None:
    """Test that authenticated endpoint returns 401 with invalid credentials."""
    client = TestClient(app)
    response = client.get("/api/v1/test/auth", headers=invalid_auth_headers)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    assert response.json()["detail"] == "Invalid authentication credentials"
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_authenticated_endpoint_with_valid_auth(valid_auth_headers: Dict[str, str]) -> None:
    """Test that authenticated endpoint works with valid credentials."""
    client = TestClient(app)
    response = client.get("/api/v1/test/auth", headers=valid_auth_headers)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["authenticated"] is True
    assert data["auth_method"] == "bearer"


def test_auth_with_wrong_scheme() -> None:
    """Test that authentication fails with wrong scheme."""
    client = TestClient(app)
    headers = {"Authorization": f"Basic {settings.ACCESS_PASSWORD}"}
    response = client.get("/api/v1/test/auth", headers=headers)

    assert response.status_code == status.HTTP_403_FORBIDDEN


def test_auth_with_empty_bearer() -> None:
    """Test that authentication fails with empty bearer token."""
    client = TestClient(app)
    headers = {"Authorization": "Bearer "}
    response = client.get("/api/v1/test/auth", headers=headers)

    assert response.status_code == status.HTTP_403_FORBIDDEN


def test_auth_header_case_insensitive(valid_auth_headers: Dict[str, str]) -> None:
    """Test that authorization header is case-insensitive."""
    client = TestClient(app)
    # Use lowercase 'authorization'
    headers = {"authorization": valid_auth_headers["Authorization"]}
    response = client.get("/api/v1/test/auth", headers=headers)

    assert response.status_code == status.HTTP_200_OK


def test_constant_time_comparison() -> None:
    """Test that password comparison is constant-time (indirect test)."""
    # This is more of a code inspection test - we can't directly test timing
    # but we ensure secrets.compare_digest is used in the implementation
    import inspect

    from app.dependencies.auth import verify_password

    source = inspect.getsource(verify_password)
    assert "secrets.compare_digest" in source, "Must use constant-time comparison"
