"""
Authentication dependency for FastAPI endpoints.

This module provides password-based authentication using FastAPI's dependency injection system.
It uses constant-time comparison to prevent timing attacks and reads the password from environment variables.
"""

import secrets
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.config import settings


# Create the security scheme
security = HTTPBearer(scheme_name="Password Authentication", description="Use the ACCESS_PASSWORD as the bearer token")


async def verify_password(credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)]) -> None:
    """
    Verify the provided password against the configured password.

    This function performs constant-time comparison to prevent timing attacks.
    It reads the expected password from the ACCESS_PASSWORD environment variable.

    Args:
        credentials: The HTTP Bearer credentials from the request

    Raises:
        HTTPException: 401 Unauthorized if the password is invalid
    """
    provided_password = credentials.credentials
    expected_password = settings.ACCESS_PASSWORD

    # Constant-time comparison to prevent timing attacks
    if not secrets.compare_digest(provided_password, expected_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
