"""Router for Server-Sent Events streaming endpoints.

Provides real-time progress updates for document generation requests using SSE.
This allows clients to receive push notifications about processing status without polling.
"""

import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sse_starlette.sse import EventSourceResponse

from app.dependencies.auth import verify_password
from app.services.document_processor import document_processor
from app.utils.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()


@router.get(
    "/generate/{request_id}/stream",
    summary="Stream generation progress",
    description="""Connect to Server-Sent Events (SSE) stream for real-time progress updates.
    
    This endpoint establishes a persistent connection that pushes updates to the client
    as the document generation progresses. Use an EventSource client or SSE library
    to consume these events.
    
    **Connection Details**:
    - Content-Type: text/event-stream
    - Keep-alive: Heartbeat events sent every 15 seconds
    - Auto-reconnect: Clients should implement reconnection logic
    
    **Event Types**:
    - `connected`: Initial connection established
    - `status`: Status change notification  
    - `progress`: Processing step update with current/total steps
    - `complete`: Generation finished successfully
    - `error`: Generation failed with error details
    - `heartbeat`: Keep-alive signal
    
    **Client Example (JavaScript)**:
    ```javascript
    const eventSource = new EventSource('/api/v1/generate/{request_id}/stream', {
        headers: { 'Authorization': 'Bearer YOUR_TOKEN' }
    });
    
    eventSource.addEventListener('progress', (event) => {
        const data = JSON.parse(event.data);
        console.log(`Step ${data.step}/${data.total}: ${data.message}`);
    });
    
    eventSource.addEventListener('complete', (event) => {
        console.log('Generation complete!');
        eventSource.close();
    });
    ```
    """,
    response_class=EventSourceResponse,
    responses={
        200: {
            "description": "SSE stream connected",
            "content": {
                "text/event-stream": {
                    "examples": {
                        "connected": {
                            "summary": "Initial connection",
                            "value": 'event: connected\ndata: {"request_id": "123e4567-e89b-12d3-a456-426614174000", "timestamp": "2025-06-16T12:00:00Z"}\n\n',
                        },
                        "progress": {
                            "summary": "Progress update",
                            "value": 'event: progress\ndata: {"step": 3, "total": 10, "message": "Extracting text from documents..."}\n\n',
                        },
                        "complete": {
                            "summary": "Completion event",
                            "value": 'event: complete\ndata: {"status": "completed", "timestamp": "2025-06-16T12:05:00Z"}\n\n',
                        },
                        "error": {
                            "summary": "Error event",
                            "value": 'event: error\ndata: {"error": "Failed to process document", "timestamp": "2025-06-16T12:01:00Z"}\n\n',
                        },
                    }
                }
            },
        },
        404: {
            "description": "Request not found",
            "content": {
                "application/json": {"example": {"detail": "Request 123e4567-e89b-12d3-a456-426614174000 not found"}}
            },
        },
        401: {"description": "Invalid authentication credentials"},
    },
)
async def stream_generation_progress(request_id: str, _: None = Depends(verify_password)) -> EventSourceResponse:
    """
    Stream real-time progress updates for a document generation request.

    This endpoint uses Server-Sent Events (SSE) to push progress updates to the client.

    Event Types:
    - `connected`: Initial connection established
    - `status`: Current status update
    - `progress`: Processing progress update
    - `complete`: Generation completed successfully
    - `error`: Generation failed with error
    - `heartbeat`: Keep-alive signal (every 15 seconds)

    Example event data:
    ```
    event: progress
    data: {"step": 3, "total": 10, "message": "Extracting text from documents..."}

    event: complete
    data: {"status": "completed", "timestamp": "2025-06-16T12:00:00Z"}
    ```
    """
    # Check if request exists
    request_status = await document_processor.get_request_status(request_id)
    if not request_status:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Request {request_id} not found")

    logger.info("Client connected to SSE stream", extra={"request_id": request_id})

    async def event_generator():
        """Generate SSE events for the client."""
        try:
            # Send initial connection event
            yield {
                "event": "connected",
                "data": json.dumps({"request_id": request_id, "timestamp": datetime.now(timezone.utc).isoformat()}),
            }

            # Subscribe to events for this request
            async for event in document_processor.subscribe_to_request(request_id):
                yield event

        except Exception as e:
            logger.error("Error in SSE stream", extra={"request_id": request_id, "error": str(e)}, exc_info=True)
            # Send error event
            yield {
                "event": "error",
                "data": json.dumps(
                    {"error": "Stream error occurred", "timestamp": datetime.now(timezone.utc).isoformat()}
                ),
            }
        finally:
            logger.info("Client disconnected from SSE stream", extra={"request_id": request_id})

    return EventSourceResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "X-Accel-Buffering": "no",  # Disable Nginx buffering
            "Connection": "keep-alive",
        },
    )
