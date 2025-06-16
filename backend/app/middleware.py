"""Middleware for request processing and correlation ID tracking."""

import time
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from app.utils.logging import get_logger

logger = get_logger(__name__)


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Middleware to add correlation ID to requests and responses."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process the request and add correlation ID."""
        # Get or generate correlation ID
        correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))

        # Store in request state for access in handlers
        request.state.correlation_id = correlation_id

        # Add to logging context
        import contextvars

        # Create context var for correlation ID
        correlation_id_var = contextvars.ContextVar("correlation_id", default="N/A")
        correlation_id_var.set(correlation_id)

        # Process request
        response = await call_next(request)

        # Add correlation ID to response headers
        response.headers["X-Correlation-ID"] = correlation_id

        return response


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log requests and responses."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Log request details and response status."""
        start_time = time.time()

        # Log request
        logger.info(
            "Request started",
            extra={
                "method": request.method,
                "path": request.url.path,
                "query_params": str(request.url.query),
                "correlation_id": getattr(request.state, "correlation_id", "N/A"),
            },
        )

        # Process request
        response = await call_next(request)

        # Calculate duration
        duration = time.time() - start_time

        # Log response
        logger.info(
            "Request completed",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": round(duration * 1000, 2),
                "correlation_id": getattr(request.state, "correlation_id", "N/A"),
            },
        )

        return response


class SensitiveDataMiddleware(BaseHTTPMiddleware):
    """Middleware to ensure sensitive data is not logged."""

    SENSITIVE_HEADERS = {
        "authorization",
        "x-api-key",
        "x-auth-token",
        "cookie",
        "set-cookie",
    }

    SENSITIVE_FIELDS = {
        "password",
        "api_key",
        "secret",
        "token",
        "access_token",
        "refresh_token",
    }

    @classmethod
    def sanitize_headers(cls, headers: dict) -> dict:
        """Remove sensitive data from headers."""
        sanitized = {}
        for key, value in headers.items():
            if key.lower() in cls.SENSITIVE_HEADERS:
                sanitized[key] = "[REDACTED]"
            else:
                sanitized[key] = value
        return sanitized

    @classmethod
    def sanitize_dict(cls, data: dict) -> dict:
        """Recursively remove sensitive data from dictionaries."""
        if not isinstance(data, dict):
            return data

        sanitized = {}
        for key, value in data.items():
            if any(sensitive in key.lower() for sensitive in cls.SENSITIVE_FIELDS):
                sanitized[key] = "[REDACTED]"
            elif isinstance(value, dict):
                sanitized[key] = cls.sanitize_dict(value)
            elif isinstance(value, list):
                sanitized[key] = [cls.sanitize_dict(item) if isinstance(item, dict) else item for item in value]
            else:
                sanitized[key] = value
        return sanitized
