"""Common Pydantic schemas used across the application."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class TimestampMixin(BaseModel):
    """Mixin for models that need timestamp fields."""
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class RequestBase(BaseModel):
    """Base schema for API requests."""
    
    class Config:
        # Forbid extra fields to prevent accidental data exposure
        extra = "forbid"
        # Use Enum values instead of names
        use_enum_values = True
        # Populate models from attributes (useful for ORM integration)
        from_attributes = True


class ResponseBase(BaseModel):
    """Base schema for API responses."""
    
    class Config:
        # Use Enum values instead of names
        use_enum_values = True
        # Populate models from attributes (useful for ORM integration)
        from_attributes = True


class FileUploadRequest(RequestBase):
    """Schema for file upload requests."""
    
    description: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="Description of what to generate from the uploaded file"
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
    def calculate_percentage(cls, v: float, values: dict) -> float:
        """Calculate percentage from step and total if not provided."""
        if "step" in values and "total_steps" in values:
            return (values["step"] / values["total_steps"]) * 100
        return v
