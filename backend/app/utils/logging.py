"""Logging configuration and utilities."""
import logging
import logging.config
import sys
from typing import Any, Dict

from app.config import settings


def setup_logging() -> None:
    """Configure structured logging for the application."""
    log_config: Dict[str, Any] = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "[%(asctime)s] %(levelname)s in %(module)s: %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "detailed": {
                "format": "[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "json": {
                "format": '{"time": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "module": "%(module)s", "function": "%(funcName)s", "line": %(lineno)d, "message": "%(message)s"}',
                "datefmt": "%Y-%m-%dT%H:%M:%S",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": settings.LOG_LEVEL,
                "formatter": "default" if settings.is_development else "json",
                "stream": sys.stdout,
            },
            "error_file": {
                "class": "logging.StreamHandler",
                "level": "ERROR",
                "formatter": "detailed",
                "stream": sys.stderr,
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
    
    This will be used in future when we implement request correlation.
    """
    
    def filter(self, record: logging.LogRecord) -> bool:
        """Add correlation_id to the log record."""
        # TODO: Get correlation ID from context when implemented
        record.correlation_id = getattr(record, "correlation_id", "N/A")
        return True
