"""
Test router for authenticated endpoints.

This router provides test endpoints to verify authentication is working correctly.
"""

import logging
from typing import Annotated

from fastapi import APIRouter, Depends, status
from opentelemetry import trace

from app.dependencies.auth import verify_password
from app.schemas.auth_schema import AuthenticationInfo

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1",
    tags=["test"],
)


@router.get(
    "/test/auth",
    response_model=AuthenticationInfo,
    status_code=status.HTTP_200_OK,
    summary="Test Authentication",
    description="Test endpoint to verify authentication is working",
    responses={
        200: {
            "description": "Authentication successful",
            "content": {"application/json": {"example": {"authenticated": True, "auth_method": "bearer"}}},
        },
        401: {
            "description": "Authentication failed",
            "content": {"application/json": {"example": {"detail": "Invalid authentication credentials"}}},
        },
    },
)
async def verify_authentication(_: Annotated[None, Depends(verify_password)]) -> AuthenticationInfo:
    """
    Test endpoint that requires authentication.

    This endpoint verifies that the authentication middleware is working correctly.
    It requires a valid ACCESS_PASSWORD to be provided as a Bearer token.

    Returns:
        AuthenticationInfo: Confirmation that authentication was successful
    """
    # Get current tracer
    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span(
        "test_authentication",
        attributes={
            "http.method": "GET",
            "http.route": "/api/v1/test/auth",
        },
    ) as span:
        logger.info("Authenticated request to test endpoint")

        response = AuthenticationInfo(authenticated=True, auth_method="bearer")

        span.set_attribute("auth.authenticated", response.authenticated)
        span.set_attribute("auth.method", response.auth_method)

        return response
