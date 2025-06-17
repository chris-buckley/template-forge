"""Logging configuration and utilities."""

import contextvars
import json
import logging
import logging.config
import sys
from datetime import datetime, timezone
from typing import Any, Dict

from app.config import settings

# Context variable for correlation ID
correlation_id_var: contextvars.ContextVar[str] = contextvars.ContextVar("correlation_id", default="N/A")


def setup_logging() -> None:
    """Configure structured logging for the application."""
    log_config: Dict[str, Any] = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "[%(asctime)s] %(levelname)s [%(correlation_id)s] %(module)s: %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "detailed": {
                "format": "[%(asctime)s] %(levelname)s [%(correlation_id)s] [%(name)s.%(funcName)s:%(lineno)d] %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "json": {
                "()": "app.utils.logging.StructuredFormatter",
            },
        },
        "filters": {
            "correlation_id": {
                "()": "app.utils.logging.CorrelationIdFilter",
            },
            "sensitive_data": {
                "()": "app.utils.logging.SensitiveDataFilter",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": settings.LOG_LEVEL,
                "formatter": "default" if settings.is_development else "json",
                "stream": sys.stdout,
                "filters": ["correlation_id", "sensitive_data"],
            },
            "error_file": {
                "class": "logging.StreamHandler",
                "level": "ERROR",
                "formatter": "detailed",
                "stream": sys.stderr,
                "filters": ["correlation_id", "sensitive_data"],
            },
        },
        "root": {
            "level": settings.LOG_LEVEL,
            "handlers": ["console", "error_file"],
        },
        "loggers": {
            "uvicorn": {
                "level": settings.LOG_LEVEL,
                "handlers": ["console"],
                "propagate": False,
            },
            "uvicorn.error": {
                "level": "INFO",
                "handlers": ["console"],
                "propagate": False,
            },
            "uvicorn.access": {
                "handlers": ["console"],
                "level": "INFO" if settings.is_development else "WARNING",
                "propagate": False,
            },
            "fastapi": {
                "level": settings.LOG_LEVEL,
                "handlers": ["console"],
                "propagate": False,
            },
            "app": {
                "level": settings.LOG_LEVEL,
                "handlers": ["console"],
                "propagate": False,
            },
            "opentelemetry": {
                "level": "INFO" if settings.is_development else "WARNING",
                "handlers": ["console"],
                "propagate": False,
            },
        },
    }

    logging.config.dictConfig(log_config)

    # Log initial configuration
    logger = logging.getLogger(__name__)
    logger.info(f"Logging configured with level: {settings.LOG_LEVEL}")
    logger.info(f"Log format: {'default' if settings.is_development else 'json'}")


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger instance with the given name.

    Args:
        name: Logger name (typically __name__)

    Returns:
        Configured logger instance
    """
    return logging.getLogger(name)


class CorrelationIdFilter(logging.Filter):
    """
    Logging filter to add correlation ID to log records.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        """Add correlation_id to the log record."""
        record.correlation_id = correlation_id_var.get()
        return True


class StructuredFormatter(logging.Formatter):
    """
    Custom JSON formatter for structured logging.
    """

    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON."""
        # Base log structure
        log_obj = {
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "correlation_id": getattr(record, "correlation_id", "N/A"),
            "service_name": settings.SERVICE_NAME,
            "environment": settings.APP_ENV,
        }

        # Add exception info if present
        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)

        # Add custom fields from extra
        if hasattr(record, "extra_fields"):
            for key, value in record.extra_fields.items():
                if key not in log_obj:
                    log_obj[key] = value

        # Add any extra fields directly on the record
        for key, value in record.__dict__.items():
            if key not in [
                "name",
                "msg",
                "args",
                "created",
                "filename",
                "funcName",
                "levelname",
                "levelno",
                "lineno",
                "module",
                "msecs",
                "pathname",
                "process",
                "processName",
                "relativeCreated",
                "thread",
                "threadName",
                "exc_info",
                "exc_text",
                "stack_info",
                "getMessage",
                "correlation_id",
                "extra_fields",
            ] and not key.startswith("_"):
                log_obj[key] = value

        return json.dumps(log_obj, ensure_ascii=False)


class SensitiveDataFilter(logging.Filter):
    """
    Filter to remove sensitive data from logs.
    """

    SENSITIVE_PATTERNS = [
        "password",
        "api_key",
        "secret",
        "token",
        "authorization",
        "access_token",
        "refresh_token",
        "private_key",
        "credential",
    ]

    def filter(self, record: logging.LogRecord) -> bool:
        """Remove sensitive data from log records."""
        # Check message
        message = record.getMessage().lower()
        for pattern in self.SENSITIVE_PATTERNS:
            if pattern in message:
                # Log a warning about attempted sensitive data logging
                record.msg = "[SENSITIVE DATA REDACTED]"
                record.args = ()
                break

        # Check extra fields
        for attr_name in dir(record):
            if not attr_name.startswith("_"):
                attr_value = getattr(record, attr_name, None)
                if isinstance(attr_value, str):
                    for pattern in self.SENSITIVE_PATTERNS:
                        if pattern in attr_name.lower():
                            setattr(record, attr_name, "[REDACTED]")
                            break

        return True
