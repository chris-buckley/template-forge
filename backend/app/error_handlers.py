"""Global exception handlers for the FastAPI application."""

import traceback
from typing import Any, Dict

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import ValidationError as PydanticValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.exceptions import BaseAPIException
from app.middleware import SensitiveDataMiddleware
from app.utils.logging import get_logger

logger = get_logger(__name__)


def create_error_response(
    request: Request,
    status_code: int,
    error_code: str,
    message: str,
    details: Dict[str, Any] | None = None,
) -> JSONResponse:
    """
    Create a standardized error response.

    Args:
        request: The request object
        status_code: HTTP status code
        error_code: Machine-readable error code
        message: Human-readable error message
        details: Additional error details

    Returns:
        JSONResponse with error details
    """
    error_id = str(request.state.correlation_id) if hasattr(request.state, "correlation_id") else "N/A"

    response_content = {
        "error": {
            "code": error_code,
            "message": message,
            "details": details or {},
            "error_id": error_id,
        }
    }

    # Sanitize the response to ensure no sensitive data is leaked
    sanitized_content = SensitiveDataMiddleware.sanitize_dict(response_content)

    return JSONResponse(
        status_code=status_code,
        content=sanitized_content,
        headers={"X-Error-ID": error_id},
    )


async def handle_base_api_exception(request: Request, exc: BaseAPIException) -> JSONResponse:
    """Handle custom API exceptions."""
    logger.error(
        f"API Exception: {exc.message}",
        extra={
            "error_code": exc.error_code,
            "status_code": exc.status_code,
            "details": exc.details,
            "path": request.url.path,
            "method": request.method,
        },
        exc_info=True,
    )

    return create_error_response(
        request=request,
        status_code=exc.status_code,
        error_code=exc.error_code,
        message=exc.message,
        details=exc.details,
    )


async def handle_request_validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Handle FastAPI request validation errors."""
    logger.warning(
        "Request validation error",
        extra={
            "errors": exc.errors(),
            "body": exc.body,
            "path": request.url.path,
            "method": request.method,
        },
    )

    # Format validation errors
    formatted_errors = []
    for error in exc.errors():
        formatted_errors.append(
            {
                "field": ".".join(str(loc) for loc in error["loc"]),
                "message": error["msg"],
                "type": error["type"],
            }
        )

    return create_error_response(
        request=request,
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        error_code="VALIDATION_ERROR",
        message="Request validation failed",
        details={"validation_errors": formatted_errors},
    )


async def handle_pydantic_validation_error(request: Request, exc: PydanticValidationError) -> JSONResponse:
    """Handle Pydantic validation errors."""
    logger.warning(
        "Pydantic validation error",
        extra={
            "errors": exc.errors(),
            "path": request.url.path,
            "method": request.method,
        },
    )

    # Format validation errors
    formatted_errors = []
    for error in exc.errors():
        formatted_errors.append(
            {
                "field": ".".join(str(loc) for loc in error["loc"]),
                "message": error["msg"],
                "type": error["type"],
            }
        )

    return create_error_response(
        request=request,
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        error_code="VALIDATION_ERROR",
        message="Data validation failed",
        details={"validation_errors": formatted_errors},
    )


async def handle_starlette_http_exception(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    """Handle Starlette HTTP exceptions."""
    logger.warning(
        f"HTTP Exception: {exc.detail}",
        extra={
            "status_code": exc.status_code,
            "path": request.url.path,
            "method": request.method,
        },
    )

    # Map common HTTP status codes to error codes
    error_code_mapping = {
        400: "BAD_REQUEST",
        401: "UNAUTHORIZED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        405: "METHOD_NOT_ALLOWED",
        408: "REQUEST_TIMEOUT",
        409: "CONFLICT",
        429: "TOO_MANY_REQUESTS",
        500: "INTERNAL_SERVER_ERROR",
        502: "BAD_GATEWAY",
        503: "SERVICE_UNAVAILABLE",
        504: "GATEWAY_TIMEOUT",
    }

    error_code = error_code_mapping.get(exc.status_code, "HTTP_ERROR")

    return create_error_response(
        request=request,
        status_code=exc.status_code,
        error_code=error_code,
        message=str(exc.detail),
    )


async def handle_generic_exception(request: Request, exc: Exception) -> JSONResponse:
    """Handle any unhandled exceptions."""
    # Log the full traceback
    logger.error(
        f"Unhandled exception: {str(exc)}",
        extra={
            "exception_type": type(exc).__name__,
            "path": request.url.path,
            "method": request.method,
            "traceback": traceback.format_exc(),
        },
        exc_info=True,
    )

    # In production, don't expose internal error details
    if hasattr(request.app.state, "settings") and request.app.state.settings.is_production:
        message = "An internal error occurred. Please try again later."
        details = {}
    else:
        message = f"Internal server error: {str(exc)}"
        details = {"exception_type": type(exc).__name__}

    return create_error_response(
        request=request,
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code="INTERNAL_ERROR",
        message=message,
        details=details,
    )


def register_exception_handlers(app: FastAPI) -> None:
    """
    Register all exception handlers with the FastAPI app.

    Args:
        app: The FastAPI application instance
    """
    # Custom exceptions
    app.add_exception_handler(BaseAPIException, handle_base_api_exception)

    # FastAPI/Pydantic exceptions
    app.add_exception_handler(RequestValidationError, handle_request_validation_error)
    app.add_exception_handler(PydanticValidationError, handle_pydantic_validation_error)

    # Starlette exceptions
    app.add_exception_handler(StarletteHTTPException, handle_starlette_http_exception)

    # Generic exception handler (catch-all)
    app.add_exception_handler(Exception, handle_generic_exception)

    logger.info("Exception handlers registered")
