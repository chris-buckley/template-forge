"""Custom exception classes for the application."""

from typing import Any, Dict, Optional


class BaseAPIException(Exception):
    """Base exception class for all API exceptions."""

    def __init__(
        self,
        message: str,
        status_code: int = 500,
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        """
        Initialize the base API exception.

        Args:
            message: Human-readable error message
            status_code: HTTP status code
            error_code: Machine-readable error code for client handling
            details: Additional error details
        """
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.error_code = error_code or self.__class__.__name__
        self.details = details or {}


class AuthenticationError(BaseAPIException):
    """Raised when authentication fails."""

    def __init__(self, message: str = "Authentication failed") -> None:
        super().__init__(message=message, status_code=401, error_code="AUTH_FAILED")


class ValidationError(BaseAPIException):
    """Raised when request validation fails."""

    def __init__(self, message: str = "Validation failed", details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message=message, status_code=422, error_code="VALIDATION_FAILED", details=details)


class FileValidationError(ValidationError):
    """Raised when file validation fails."""

    def __init__(self, message: str = "File validation failed", details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message=message, details=details)
        self.error_code = "FILE_VALIDATION_FAILED"


class ResourceNotFoundError(BaseAPIException):
    """Raised when a requested resource is not found."""

    def __init__(self, resource_type: str, resource_id: str, message: Optional[str] = None) -> None:
        msg = message or f"{resource_type} with ID '{resource_id}' not found"
        super().__init__(
            message=msg,
            status_code=404,
            error_code="RESOURCE_NOT_FOUND",
            details={"resource_type": resource_type, "resource_id": resource_id},
        )


class ProcessingError(BaseAPIException):
    """Raised when document processing fails."""

    def __init__(self, message: str = "Processing failed", details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message=message, status_code=500, error_code="PROCESSING_FAILED", details=details)


class RateLimitError(BaseAPIException):
    """Raised when rate limit is exceeded."""

    def __init__(
        self,
        message: str = "Rate limit exceeded",
        retry_after: Optional[int] = None,
    ) -> None:
        details = {"retry_after": retry_after} if retry_after else {}
        super().__init__(message=message, status_code=429, error_code="RATE_LIMIT_EXCEEDED", details=details)


class ExternalServiceError(BaseAPIException):
    """Raised when an external service call fails."""

    def __init__(
        self,
        service_name: str,
        message: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        msg = message or f"External service '{service_name}' error"
        error_details = {"service": service_name}
        if details:
            error_details.update(details)
        super().__init__(message=msg, status_code=502, error_code="EXTERNAL_SERVICE_ERROR", details=error_details)


class ConfigurationError(BaseAPIException):
    """Raised when there's a configuration issue."""

    def __init__(self, message: str = "Configuration error", details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message=message, status_code=500, error_code="CONFIGURATION_ERROR", details=details)
