"""Tests for document generation endpoints."""

from uuid import UUID

import pytest
from fastapi import status
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.asyncio
async def test_generate_document_success(auth_headers: dict):
    """Test successful document generation request."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create test files
        pdf_content = b"%PDF-1.4 test content"
        csv_content = b"name,value\ntest,123"

        files = [
            ("files", ("test.pdf", pdf_content, "application/pdf")),
            ("files", ("data.csv", csv_content, "text/csv")),
        ]

        data = {"description": "Generate a summary of these documents", "output_format": "markdown"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_202_ACCEPTED

        result = response.json()
        assert "request_id" in result
        assert UUID(result["request_id"])  # Valid UUID
        assert result["status"] == "accepted"
        assert result["stream_url"].endswith("/stream")
        assert len(result["files_received"]) == 2

        # Check file info
        pdf_info = next(f for f in result["files_received"] if f["filename"] == "test.pdf")
        assert pdf_info["content_type"] == "application/pdf"
        assert pdf_info["size"] == len(pdf_content)

        csv_info = next(f for f in result["files_received"] if f["filename"] == "data.csv")
        assert csv_info["content_type"] == "text/csv"
        assert csv_info["size"] == len(csv_content)


@pytest.mark.asyncio
async def test_generate_document_no_auth():
    """Test document generation without authentication."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [("files", ("test.pdf", b"content", "application/pdf"))]
        data = {"description": "Test"}

        response = await client.post("/api/v1/generate", files=files, data=data)

        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.asyncio
async def test_generate_document_invalid_auth(auth_headers: dict):
    """Test document generation with invalid authentication."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [("files", ("test.pdf", b"content", "application/pdf"))]
        data = {"description": "Test"}

        # Use wrong password
        wrong_headers = {"Authorization": "Bearer wrong-password"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=wrong_headers)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.asyncio
async def test_generate_document_no_files(auth_headers: dict):
    """Test document generation without files."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        data = {"description": "Test without files"}

        response = await client.post("/api/v1/generate", data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_generate_document_invalid_file_type(auth_headers: dict):
    """Test document generation with invalid file type."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [("files", ("test.exe", b"MZ\x90\x00", "application/x-msdownload"))]
        data = {"description": "Test with invalid file"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        error_data = response.json()
        assert "error" in error_data
        assert "not allowed" in error_data["error"]["message"]


@pytest.mark.skip(reason="File content validation is not implemented in file upload flow")
@pytest.mark.asyncio
async def test_generate_document_file_content_mismatch(auth_headers: dict):
    """Test document generation with file content not matching extension."""
    # TODO: Implement file content validation in the document processor
    # Currently, the file validation only checks extensions and MIME types
    # but doesn't validate actual file content after upload
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Send a file with .pdf extension but not PDF content
        files = [("files", ("fake.pdf", b"This is not a PDF", "application/pdf"))]
        data = {"description": "Test with fake PDF"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "content does not match extension" in response.json()["detail"]


@pytest.mark.asyncio
async def test_generate_document_too_many_files(auth_headers: dict):
    """Test document generation with too many files."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create 11 files (limit is 10)
        files = []
        for i in range(11):
            files.append(("files", (f"file{i}.csv", b"data", "text/csv")))

        data = {"description": "Test with many files"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        error_data = response.json()
        assert "error" in error_data
        assert "Maximum 10 files" in error_data["error"]["message"]


@pytest.mark.asyncio
async def test_generate_document_empty_description(auth_headers: dict):
    """Test document generation with empty description."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [("files", ("test.pdf", b"%PDF-1.4", "application/pdf"))]
        data = {"description": ""}  # Empty description

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_generate_document_invalid_output_format(auth_headers: dict):
    """Test document generation with invalid output format."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [("files", ("test.pdf", b"%PDF-1.4", "application/pdf"))]
        data = {
            "description": "Test",
            "output_format": "invalid",  # Invalid format
        }

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_generate_document_all_valid_formats(auth_headers: dict):
    """Test document generation with all valid file formats."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        files = [
            ("files", ("doc.pdf", b"%PDF-1.4 content", "application/pdf")),
            (
                "files",
                ("doc.docx", b"PK\x03\x04", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
            ),
            ("files", ("data.csv", b"col1,col2\nval1,val2", "text/csv")),
            (
                "files",
                ("sheet.xlsx", b"PK\x03\x04", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
            ),
        ]

        data = {"description": "Process all document types", "output_format": "pdf"}

        response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert response.status_code == status.HTTP_202_ACCEPTED
        result = response.json()
        assert len(result["files_received"]) == 4


@pytest.mark.asyncio
async def test_get_generation_status(auth_headers: dict):
    """Test getting generation request status."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # First create a request
        files = [("files", ("test.pdf", b"%PDF-1.4", "application/pdf"))]
        data = {"description": "Test"}

        create_response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert create_response.status_code == status.HTTP_202_ACCEPTED
        request_id = create_response.json()["request_id"]

        # Get status
        status_response = await client.get(f"/api/v1/generate/{request_id}/status", headers=auth_headers)

        assert status_response.status_code == status.HTTP_200_OK
        status_data = status_response.json()
        assert status_data["request_id"] == request_id
        assert status_data["status"] in ["processing", "completed", "failed"]
        assert "current_step" in status_data
        assert "total_steps" in status_data
        assert "message" in status_data


@pytest.mark.asyncio
async def test_get_generation_status_not_found(auth_headers: dict):
    """Test getting status for non-existent request."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        fake_id = "12345678-1234-1234-1234-123456789012"

        response = await client.get(f"/api/v1/generate/{fake_id}/status", headers=auth_headers)

        assert response.status_code == status.HTTP_404_NOT_FOUND
        error_data = response.json()
        assert "error" in error_data
        assert "not found" in error_data["error"]["message"].lower()
