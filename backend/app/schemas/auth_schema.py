"""
Authentication-related Pydantic schemas.

This module defines the data models used for authentication responses and errors.
"""

from pydantic import BaseModel, ConfigDict, Field


class AuthErrorResponse(BaseModel):
    """Schema for authentication error responses."""

    model_config = ConfigDict(json_schema_extra={"example": {"detail": "Invalid authentication credentials"}})

    detail: str = Field(..., description="Error message describing the authentication failure")


class AuthenticationInfo(BaseModel):
    """Schema for authentication information in responses."""

    model_config = ConfigDict(json_schema_extra={"example": {"authenticated": True, "auth_method": "bearer"}})

    authenticated: bool = Field(..., description="Whether the request is authenticated")
    auth_method: str = Field(default="bearer", description="Authentication method used")
