"""Common Pydantic schemas used across the application."""

from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class TimestampMixin(BaseModel):
    """Mixin for models that need timestamp fields."""

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class RequestBase(BaseModel):
    """Base schema for API requests."""

    model_config = ConfigDict(
        # Forbid extra fields to prevent accidental data exposure
        extra="forbid",
        # Use Enum values instead of names
        use_enum_values=True,
        # Populate models from attributes (useful for ORM integration)
        from_attributes=True,
    )


class ResponseBase(BaseModel):
    """Base schema for API responses."""

    model_config = ConfigDict(
        # Use Enum values instead of names
        use_enum_values=True,
        # Populate models from attributes (useful for ORM integration)
        from_attributes=True,
    )


class FileUploadRequest(RequestBase):
    """Schema for file upload requests."""

    description: str = Field(
        ..., min_length=1, max_length=1000, description="Description of what to generate from the uploaded file"
    )

    @field_validator("description")
    def validate_description(cls, v: str) -> str:
        """Ensure description is not just whitespace."""
        if not v.strip():
            raise ValueError("Description cannot be empty or just whitespace")
        return v.strip()


class ProcessingStatus(BaseModel):
    """Schema for processing status updates."""

    step: int = Field(..., ge=1, description="Current processing step")
    total_steps: int = Field(..., ge=1, description="Total number of steps")
    message: str = Field(..., description="Human-readable status message")
    percentage: float = Field(ge=0, le=100, description="Progress percentage")

    @field_validator("percentage")
    @classmethod
    def calculate_percentage(cls, v: float) -> float:
        """Validate percentage is within bounds."""
        if not 0 <= v <= 100:
            raise ValueError("Percentage must be between 0 and 100")
        return v


class ErrorResponse(BaseModel):
    """Standard error response schema."""

    detail: str = Field(..., description="Error message")
    status_code: Optional[int] = Field(None, description="HTTP status code")
    error_type: Optional[str] = Field(None, description="Error type for debugging")


class SuccessResponse(BaseModel):
    """Standard success response schema."""

    message: str = Field(..., description="Success message")
    data: Optional[Dict[str, Any]] = Field(None, description="Additional response data")
