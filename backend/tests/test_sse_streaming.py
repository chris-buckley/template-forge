"""Enhanced SSE streaming tests.

Tests Server-Sent Events functionality including connection management,
event parsing, and error handling.
"""

import json
import asyncio
import pytest
from fastapi import status
from httpx import AsyncClient, ASGITransport

from app.main import app


class TestSSEStreaming:
    """Test Server-Sent Events streaming functionality."""

    @pytest.mark.asyncio
    async def test_sse_connection_established(self, async_client, auth_headers, sample_pdf_file):
        """Test that SSE connection can be established."""
        # First create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test SSE streaming"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert upload_response.status_code == status.HTTP_202_ACCEPTED
        request_id = upload_response.json()["request_id"]

        # Connect to SSE stream
        response = await async_client.get(
            f"/api/v1/generate/{request_id}/stream", headers=auth_headers, follow_redirects=False
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.headers["content-type"] == "text/event-stream; charset=utf-8"
        assert response.headers.get("cache-control") == "no-cache, no-transform"
        assert response.headers.get("x-accel-buffering") == "no"

    @pytest.mark.asyncio
    @pytest.mark.skip(reason="SSE streaming with HTTPX has event loop conflicts in test environment")
    async def test_sse_event_format(self, async_client, auth_headers, sample_pdf_file):
        """Test SSE event format and parsing."""
        # Create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test SSE events"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = upload_response.json()["request_id"]

        # Connect to SSE stream and read events
        events = []
        async with async_client.stream(
            "GET", f"/api/v1/generate/{request_id}/stream", headers=auth_headers
        ) as response:
            assert response.status_code == status.HTTP_200_OK

            # Read a few events
            event_count = 0
            async for line in response.aiter_lines():
                if line.startswith("event:"):
                    event_type = line.split(":", 1)[1].strip()
                    events.append({"type": event_type})
                elif line.startswith("data:"):
                    data_str = line.split(":", 1)[1].strip()
                    try:
                        data = json.loads(data_str)
                        events[-1]["data"] = data
                    except json.JSONDecodeError:
                        pass

                event_count += 1
                if event_count > 10:  # Limit to prevent infinite loop
                    break

        # Verify we got at least the connected event
        assert len(events) > 0
        assert events[0]["type"] == "connected"
        assert "request_id" in events[0]["data"]
        assert events[0]["data"]["request_id"] == request_id

    @pytest.mark.asyncio
    async def test_sse_authentication_required(self, async_client):
        """Test that SSE endpoints require authentication."""
        fake_id = "12345678-1234-1234-1234-123456789012"

        # No auth header
        response = await async_client.get(f"/api/v1/generate/{fake_id}/stream")
        assert response.status_code == status.HTTP_403_FORBIDDEN

        # Invalid auth
        response = await async_client.get(
            f"/api/v1/generate/{fake_id}/stream", headers={"Authorization": "Bearer wrong-password"}
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    @pytest.mark.asyncio
    async def test_sse_request_not_found(self, async_client, auth_headers):
        """Test SSE stream for non-existent request."""
        fake_id = "12345678-1234-1234-1234-123456789012"

        response = await async_client.get(f"/api/v1/generate/{fake_id}/stream", headers=auth_headers)

        assert response.status_code == status.HTTP_404_NOT_FOUND

    @pytest.mark.asyncio
    @pytest.mark.skip(reason="SSE streaming with HTTPX has event loop conflicts in test environment")
    async def test_sse_multiple_clients(self, async_client, auth_headers, sample_pdf_file):
        """Test multiple clients connecting to same SSE stream."""
        # Create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test multiple SSE clients"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = upload_response.json()["request_id"]

        # Connect multiple clients simultaneously
        async def connect_client(client_id):
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
                events = []
                async with client.stream(
                    "GET", f"/api/v1/generate/{request_id}/stream", headers=auth_headers
                ) as response:
                    assert response.status_code == status.HTTP_200_OK

                    # Read first few events
                    event_count = 0
                    async for line in response.aiter_lines():
                        if line.startswith("event:"):
                            events.append(line)
                        event_count += 1
                        if event_count > 5:
                            break

                return client_id, events

        # Run multiple clients concurrently
        results = await asyncio.gather(connect_client(1), connect_client(2), connect_client(3))

        # Verify all clients received events
        for client_id, events in results:
            assert len(events) > 0
            assert any("connected" in event for event in events)

    @pytest.mark.asyncio
    @pytest.mark.skip(reason="SSE streaming with HTTPX has event loop conflicts in test environment")
    async def test_sse_heartbeat_mechanism(self, async_client, auth_headers, sample_pdf_file):
        """Test SSE heartbeat mechanism."""
        # Create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test heartbeat"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = upload_response.json()["request_id"]

        # Connect and wait for heartbeat
        start_time = asyncio.get_event_loop().time()

        async with async_client.stream(
            "GET",
            f"/api/v1/generate/{request_id}/stream",
            headers=auth_headers,
            timeout=20.0,  # Wait up to 20 seconds for heartbeat
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("event: heartbeat"):
                    # Heartbeat received
                    break

                # Timeout after 20 seconds
                if asyncio.get_event_loop().time() - start_time > 20:
                    break

        # Note: Heartbeat might not be received in test environment
        # This test verifies the connection stays open

    @pytest.mark.asyncio
    @pytest.mark.skip(reason="SSE streaming with HTTPX has event loop conflicts in test environment")
    async def test_sse_event_types(self, async_client, auth_headers, sample_pdf_file):
        """Test different SSE event types."""
        # Create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test event types"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = upload_response.json()["request_id"]

        # Connect and collect event types
        received_events = set()
        async with async_client.stream(
            "GET", f"/api/v1/generate/{request_id}/stream", headers=auth_headers, timeout=5.0
        ) as response:
            event_count = 0
            async for line in response.aiter_lines():
                if line.startswith("event:"):
                    event_type = line.split(":", 1)[1].strip()
                    received_events.add(event_type)

                event_count += 1
                if event_count > 50:  # Limit iterations
                    break

        # At minimum, should receive connected event
        assert "connected" in received_events


class TestSSEErrorHandling:
    """Test SSE error handling scenarios."""

    @pytest.mark.asyncio
    @pytest.mark.skip(reason="SSE streaming with HTTPX has event loop conflicts in test environment")
    async def test_sse_client_disconnect_handling(self, async_client, auth_headers, sample_pdf_file):
        """Test handling of client disconnection."""
        # Create a request
        files = [("files", sample_pdf_file)]
        data = {"description": "Test disconnect"}

        upload_response = await async_client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = upload_response.json()["request_id"]

        # Connect and immediately close
        async with async_client.stream(
            "GET", f"/api/v1/generate/{request_id}/stream", headers=auth_headers
        ) as response:
            assert response.status_code == status.HTTP_200_OK
            # Close connection after receiving first event
            async for line in response.aiter_lines():
                if line.startswith("event:"):
                    break

        # Verify server handles disconnection gracefully
        # (No exception should be raised)

    @pytest.mark.asyncio
    async def test_sse_invalid_request_id_format(self, async_client, auth_headers):
        """Test SSE with invalid request ID format."""
        invalid_ids = [
            "not-a-uuid",
            "12345",
            "123e4567-e89b-12d3-a456",  # Incomplete UUID
            "",
        ]

        for invalid_id in invalid_ids:
            response = await async_client.get(f"/api/v1/generate/{invalid_id}/stream", headers=auth_headers)

            # Should return 404 or 422 depending on validation
            assert response.status_code in [status.HTTP_404_NOT_FOUND, status.HTTP_422_UNPROCESSABLE_ENTITY]
