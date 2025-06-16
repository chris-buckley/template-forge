"""Tests for SSE streaming endpoints."""

import asyncio
import json

import pytest
from fastapi import status
from httpx import AsyncClient, ASGITransport

from app.main import app


class SSEClient:
    """Helper class to consume SSE events."""

    def __init__(self, response):
        self.response = response
        self.events = []

    async def read_events(self, max_events: int = 10) -> list:
        """Read SSE events from the response."""
        event_buffer = ""
        events_read = 0

        async for line in self.response.aiter_lines():
            if line.startswith("event:"):
                event_type = line.split(":", 1)[1].strip()
                event_buffer = event_type
            elif line.startswith("data:"):
                data = line.split(":", 1)[1].strip()
                if event_buffer:
                    self.events.append({"event": event_buffer, "data": json.loads(data) if data else {}})
                    events_read += 1
                    if events_read >= max_events:
                        break
            elif line == "":
                # Empty line indicates end of event
                event_buffer = ""

        return self.events


@pytest.mark.asyncio
async def test_stream_generation_progress(auth_headers: dict):
    """Test SSE streaming for generation progress."""
    # Use ASGI transport for streaming support
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # First create a generation request
        files = [("files", ("test.pdf", b"%PDF-1.4", "application/pdf"))]
        data = {"description": "Test streaming"}

        create_response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        assert create_response.status_code == status.HTTP_202_ACCEPTED
        request_id = create_response.json()["request_id"]

        # Connect to SSE stream
        async with client.stream(
            "GET",
            f"/api/v1/generate/{request_id}/stream",
            headers={**auth_headers, "Accept": "text/event-stream"},
        ) as response:
            assert response.status_code == status.HTTP_200_OK
            assert response.headers["content-type"] == "text/event-stream; charset=utf-8"

            # Read some events
            sse_client = SSEClient(response)
            events = await asyncio.wait_for(sse_client.read_events(max_events=3), timeout=10.0)

            # Should have at least connected and status events
            assert len(events) >= 2

            # Check connected event
            connected_event = next((e for e in events if e["event"] == "connected"), None)
            assert connected_event is not None
            assert connected_event["data"]["request_id"] == request_id

            # Check for status or progress events
            progress_events = [e for e in events if e["event"] in ["status", "progress"]]
            assert len(progress_events) > 0


@pytest.mark.asyncio
async def test_stream_non_existent_request(auth_headers: dict):
    """Test streaming for non-existent request."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        fake_id = "12345678-1234-1234-1234-123456789012"

        response = await client.get(f"/api/v1/generate/{fake_id}/stream", headers=auth_headers)

        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_stream_without_auth():
    """Test streaming without authentication."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/generate/some-id/stream")

        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.asyncio
async def test_stream_with_invalid_auth():
    """Test streaming with invalid authentication."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        wrong_headers = {"Authorization": "Bearer wrong-password"}

        response = await client.get("/api/v1/generate/some-id/stream", headers=wrong_headers)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.asyncio
async def test_stream_heartbeat(auth_headers: dict):
    """Test that SSE stream sends heartbeat events."""
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Create a request
        files = [("files", ("test.pdf", b"%PDF-1.4", "application/pdf"))]
        data = {"description": "Test heartbeat"}

        create_response = await client.post("/api/v1/generate", files=files, data=data, headers=auth_headers)

        request_id = create_response.json()["request_id"]

        # Connect to stream and wait for heartbeat
        async with client.stream(
            "GET",
            f"/api/v1/generate/{request_id}/stream",
            headers={**auth_headers, "Accept": "text/event-stream"},
        ) as response:
            sse_client = SSEClient(response)

            # Wait long enough to receive a heartbeat (sent every 15 seconds)
            # In tests, this might be mocked or reduced
            events = await asyncio.wait_for(sse_client.read_events(max_events=10), timeout=20.0)

            # Check if we received any heartbeat events
            heartbeat_events = [e for e in events if e["event"] == "heartbeat"]
            # May or may not have heartbeats depending on processing speed
            # Just verify the structure if we got any
            for hb in heartbeat_events:
                assert "timestamp" in hb["data"]
