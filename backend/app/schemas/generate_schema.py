"""Schema definitions for document generation endpoints."""

from datetime import datetime
from typing import Optional, List, Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, ConfigDict


class GenerateRequest(BaseModel):
    """Request model for document generation."""

    description: str = Field(
        ..., min_length=1, max_length=2000, description="Description of what to generate from the uploaded documents"
    )
    output_format: Optional[Literal["markdown", "pdf", "docx"]] = Field(
        default="markdown", description="Desired output format for the generated document"
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "description": "Generate a comprehensive summary of the quarterly financial report",
                "output_format": "markdown",
            }
        }
    )


class FileInfo(BaseModel):
    """Information about an uploaded file."""

    filename: str = Field(..., description="Original filename")
    content_type: str = Field(..., description="MIME type of the file")
    size: int = Field(..., ge=0, description="File size in bytes")

    @field_validator("size")
    @classmethod
    def validate_size(cls, v: int) -> int:
        """Validate file size is within acceptable limits."""
        max_size = 50 * 1024 * 1024  # 50MB
        if v > max_size:
            raise ValueError(f"File size {v} bytes exceeds maximum allowed size of {max_size} bytes")
        return v


class GenerateResponse(BaseModel):
    """Response model for document generation request."""

    request_id: UUID = Field(..., description="Unique identifier for this generation request")
    status: Literal["accepted", "processing", "completed", "failed"] = Field(
        default="accepted", description="Current status of the generation request"
    )
    stream_url: str = Field(..., description="URL to connect for SSE progress updates")
    files_received: List[FileInfo] = Field(..., description="Information about uploaded files")
    created_at: datetime = Field(..., description="Timestamp when request was created")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "request_id": "123e4567-e89b-12d3-a456-426614174000",
                "status": "accepted",
                "stream_url": "/api/v1/generate/123e4567-e89b-12d3-a456-426614174000/stream",
                "files_received": [{"filename": "report.pdf", "content_type": "application/pdf", "size": 1048576}],
                "created_at": "2025-06-16T12:00:00Z",
            }
        }
    )


class GenerationStatus(BaseModel):
    """Status model for generation progress."""

    request_id: UUID = Field(..., description="Request identifier")
    status: Literal["processing", "completed", "failed"] = Field(..., description="Current status")
    current_step: int = Field(default=0, ge=0, description="Current processing step")
    total_steps: int = Field(default=0, ge=0, description="Total number of steps")
    message: str = Field(default="", description="Current status message")
    error: Optional[str] = Field(default=None, description="Error message if failed")
    completed_at: Optional[datetime] = Field(default=None, description="Completion timestamp")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "request_id": "123e4567-e89b-12d3-a456-426614174000",
                "status": "processing",
                "current_step": 3,
                "total_steps": 10,
                "message": "Extracting text from documents...",
                "error": None,
                "completed_at": None,
            }
        }
    )
