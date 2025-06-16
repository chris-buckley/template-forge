"""Test health endpoint functionality."""
import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


def test_health_endpoint(client: TestClient):
    """Test the health endpoint returns correct response."""
    response = client.get("/health")
    
    assert response.status_code == 200
    
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data
    assert data["version"] == "0.1.0"


def test_health_endpoint_structure(client: TestClient):
    """Test the health endpoint returns only the required fields."""
    response = client.get("/health")
    
    assert response.status_code == 200
    
    data = response.json()
    # Ensure only the required fields are present
    assert set(data.keys()) == {"status", "version"}
