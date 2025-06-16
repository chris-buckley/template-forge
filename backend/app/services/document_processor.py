"""Document processing service for handling file uploads and generation."""

import asyncio
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Optional, AsyncGenerator
from pathlib import Path
import tempfile
import json

from fastapi import UploadFile

from app.schemas.generate_schema import FileInfo, GenerationStatus
from app.utils.logging import get_logger

logger = get_logger(__name__)


class DocumentProcessor:
    """Service for processing uploaded documents and managing generation requests."""

    def __init__(self):
        """Initialize document processor."""
        self._active_requests: Dict[str, GenerationStatus] = {}
        self._request_files: Dict[str, List[Path]] = {}
        self._subscribers: Dict[str, List[asyncio.Queue]] = {}

    async def create_request(
        self, files: List[UploadFile], description: str, output_format: str = "markdown"
    ) -> tuple[uuid.UUID, List[FileInfo]]:
        """
        Create a new document generation request.

        Args:
            files: List of uploaded files
            description: What to generate from the documents
            output_format: Desired output format

        Returns:
            Tuple of (request_id, file_info_list)
        """
        request_id = uuid.uuid4()
        file_infos = []
        temp_files = []

        # Save files temporarily
        temp_dir = Path(tempfile.gettempdir()) / "md-decision-maker" / str(request_id)
        temp_dir.mkdir(parents=True, exist_ok=True)

        for file in files:
            # Read file content
            content = await file.read()
            file_size = len(content)

            # Save to temp location
            temp_path = temp_dir / file.filename
            with open(temp_path, "wb") as f:
                f.write(content)
            temp_files.append(temp_path)

            # Create file info
            file_info = FileInfo(
                filename=file.filename, content_type=file.content_type or "application/octet-stream", size=file_size
            )
            file_infos.append(file_info)

            # Reset file position
            await file.seek(0)

        # Store request information
        self._request_files[str(request_id)] = temp_files
        self._active_requests[str(request_id)] = GenerationStatus(
            request_id=request_id,
            status="processing",
            current_step=0,
            total_steps=10,  # Simulated steps
            message="Request accepted, starting processing...",
        )

        # Start processing in background
        asyncio.create_task(self._process_request(str(request_id), description, output_format))

        logger.info(
            "Created generation request",
            extra={
                "request_id": str(request_id),
                "file_count": len(files),
                "total_size": sum(f.size for f in file_infos),
            },
        )

        return request_id, file_infos

    async def _process_request(self, request_id: str, description: str, output_format: str) -> None:
        """
        Process a document generation request (stub implementation).

        This simulates the processing steps that would eventually
        call the LLM service.
        """
        steps = [
            (1, "Validating uploaded files..."),
            (2, "Extracting text from PDF documents..."),
            (3, "Parsing Word documents..."),
            (4, "Reading CSV/Excel data..."),
            (5, "Analyzing document structure..."),
            (6, "Preparing content for LLM..."),
            (7, "Generating document with AI..."),
            (8, "Formatting output..."),
            (9, "Finalizing document..."),
            (10, "Generation complete!"),
        ]

        try:
            for step, message in steps:
                # Update status
                self._active_requests[request_id] = GenerationStatus(
                    request_id=uuid.UUID(request_id),
                    status="processing",
                    current_step=step,
                    total_steps=len(steps),
                    message=message,
                )

                # Emit progress event
                await self._emit_progress(request_id, step, len(steps), message)

                # Simulate processing time
                await asyncio.sleep(2)  # 2 seconds per step

            # Mark as completed
            self._active_requests[request_id] = GenerationStatus(
                request_id=uuid.UUID(request_id),
                status="completed",
                current_step=len(steps),
                total_steps=len(steps),
                message="Document generation completed successfully!",
                completed_at=datetime.now(timezone.utc),
            )

            # Emit completion event
            await self._emit_completion(request_id)

        except Exception as e:
            logger.error("Error processing request", extra={"request_id": request_id, "error": str(e)})

            # Mark as failed
            self._active_requests[request_id] = GenerationStatus(
                request_id=uuid.UUID(request_id),
                status="failed",
                current_step=self._active_requests[request_id].current_step,
                total_steps=len(steps),
                message="Generation failed",
                error=str(e),
            )

            # Emit error event
            await self._emit_error(request_id, str(e))

        finally:
            # Cleanup temporary files
            await self._cleanup_request(request_id)

    async def _emit_progress(self, request_id: str, current_step: int, total_steps: int, message: str) -> None:
        """Emit progress event to all subscribers."""
        if request_id in self._subscribers:
            event_data = {
                "step": current_step,
                "total": total_steps,
                "message": message,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }

            for queue in self._subscribers[request_id]:
                try:
                    await queue.put({"event": "progress", "data": json.dumps(event_data)})
                except asyncio.QueueFull:
                    logger.warning(f"Queue full for subscriber of request {request_id}")

    async def _emit_completion(self, request_id: str) -> None:
        """Emit completion event to all subscribers."""
        if request_id in self._subscribers:
            event_data = {"status": "completed", "timestamp": datetime.now(timezone.utc).isoformat()}

            for queue in self._subscribers[request_id]:
                try:
                    await queue.put({"event": "complete", "data": json.dumps(event_data)})
                except asyncio.QueueFull:
                    pass

    async def _emit_error(self, request_id: str, error: str) -> None:
        """Emit error event to all subscribers."""
        if request_id in self._subscribers:
            event_data = {"error": error, "timestamp": datetime.now(timezone.utc).isoformat()}

            for queue in self._subscribers[request_id]:
                try:
                    await queue.put({"event": "error", "data": json.dumps(event_data)})
                except asyncio.QueueFull:
                    pass

    async def subscribe_to_request(self, request_id: str) -> AsyncGenerator[dict, None]:
        """
        Subscribe to progress updates for a request.

        Yields:
            SSE event dictionaries
        """
        # Create queue for this subscriber
        queue: asyncio.Queue = asyncio.Queue(maxsize=100)

        # Add to subscribers
        if request_id not in self._subscribers:
            self._subscribers[request_id] = []
        self._subscribers[request_id].append(queue)

        try:
            # Send current status immediately
            if request_id in self._active_requests:
                status = self._active_requests[request_id]
                await queue.put(
                    {
                        "event": "status",
                        "data": json.dumps(
                            {
                                "status": status.status,
                                "step": status.current_step,
                                "total": status.total_steps,
                                "message": status.message,
                            }
                        ),
                    }
                )

            # Yield events from queue
            while True:
                try:
                    # Wait for event with timeout for heartbeat
                    event = await asyncio.wait_for(queue.get(), timeout=15.0)
                    yield event

                    # Check if this was the final event
                    if event.get("event") in ["complete", "error"]:
                        break

                except asyncio.TimeoutError:
                    # Send heartbeat
                    yield {
                        "event": "heartbeat",
                        "data": json.dumps({"timestamp": datetime.now(timezone.utc).isoformat()}),
                    }

        finally:
            # Remove from subscribers
            if request_id in self._subscribers:
                self._subscribers[request_id].remove(queue)
                if not self._subscribers[request_id]:
                    del self._subscribers[request_id]

    async def get_request_status(self, request_id: str) -> Optional[GenerationStatus]:
        """Get current status of a request."""
        return self._active_requests.get(request_id)

    async def _cleanup_request(self, request_id: str) -> None:
        """Clean up temporary files and data for a request."""
        # Clean up temp files
        if request_id in self._request_files:
            for file_path in self._request_files[request_id]:
                try:
                    if file_path.exists():
                        file_path.unlink()
                except Exception as e:
                    logger.warning(f"Failed to delete temp file: {e}")

            # Remove directory
            try:
                temp_dir = Path(tempfile.gettempdir()) / "md-decision-maker" / request_id
                if temp_dir.exists():
                    temp_dir.rmdir()
            except Exception as e:
                logger.warning(f"Failed to delete temp directory: {e}")

            del self._request_files[request_id]

        # Keep status in memory for a while (in production, use cache/db)
        # For now, just log
        logger.info(f"Cleaned up request {request_id}")


# Global instance
document_processor = DocumentProcessor()
