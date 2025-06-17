"""FastAPI application entry point."""

import logging
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

# Ensure unbuffered output for containerized environments
os.environ.setdefault("PYTHONUNBUFFERED", "1")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.dependencies.telemetry import init_telemetry, instrument_app, shutdown_telemetry
from app.error_handlers import register_exception_handlers
from app.middleware import CorrelationIdMiddleware, LoggingMiddleware
from app.routes import health_router, test_router, generate_router, stream_router
from app.utils.logging import setup_logging

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Handle application startup and shutdown events."""
    # Startup
    logger.info(f"Starting {settings.SERVICE_NAME} v{settings.VERSION}")
    logger.info(f"Environment: {settings.APP_ENV}")
    logger.info(f"Docs enabled: {settings.ENABLE_DOCS}")

    # Initialize telemetry
    try:
        init_telemetry(settings.SERVICE_NAME)
        logger.info("OpenTelemetry initialization successful")
    except Exception as e:
        logger.error(f"Failed to initialize OpenTelemetry: {e}")
        # Continue without telemetry in case of failure

    # TODO: Initialize other services (database, cache, etc.)

    yield

    # Shutdown
    logger.info(f"Shutting down {settings.SERVICE_NAME}")

    # Shutdown telemetry
    try:
        shutdown_telemetry()
    except Exception as e:
        logger.error(f"Error during telemetry shutdown: {e}")


# Create FastAPI application
app = FastAPI(
    title="LLM Document Generation API",
    description="""## Overview
    
    The LLM Document Generation API provides AI-powered document processing and generation capabilities.
    Upload your documents (PDF, Word, CSV, Excel) and describe what you want to generate - the API will
    process your files and create new documents based on your requirements.
    
    ## Key Features
    
    - **Multi-format Support**: Process PDF, DOCX, CSV, and XLSX files
    - **Real-time Updates**: Server-Sent Events (SSE) for live progress tracking
    - **Asynchronous Processing**: Non-blocking document generation
    - **Secure Access**: Password-based authentication
    - **Comprehensive Monitoring**: OpenTelemetry instrumentation and structured logging
    
    ## Authentication
    
    All endpoints (except `/health`) require authentication using a Bearer token:
    
    ```
    Authorization: Bearer YOUR_ACCESS_PASSWORD
    ```
    
    ## Getting Started
    
    1. Check service health: `GET /health`
    2. Upload files for processing: `POST /api/v1/generate`
    3. Connect to SSE stream for real-time updates: `GET /api/v1/generate/{request_id}/stream`
    4. Or poll for status: `GET /api/v1/generate/{request_id}/status`
    
    ## Rate Limits
    
    - Maximum 10 files per request
    - Maximum 50MB per file
    - Maximum 200MB total upload size
    """,
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/api/docs" if settings.ENABLE_DOCS else None,
    redoc_url="/api/redoc" if settings.ENABLE_DOCS else None,
    openapi_url="/api/openapi.json" if settings.ENABLE_DOCS else None,
    openapi_tags=[
        {"name": "health", "description": "Health check endpoints for monitoring service availability"},
        {"name": "generate", "description": "Document generation endpoints for file upload and processing"},
        {"name": "stream", "description": "Server-Sent Events endpoints for real-time progress updates"},
        {"name": "test", "description": "Test endpoints for verifying authentication and configuration"},
    ],
    servers=[{"url": "/", "description": "Current server"}],
)

# Register exception handlers
register_exception_handlers(app)

# Add middleware (order matters - first added is outermost)
# Correlation ID should be first so all other middleware can use it
app.add_middleware(CorrelationIdMiddleware)

# Logging middleware to track requests
app.add_middleware(LoggingMiddleware)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Correlation-ID", "X-Error-ID"],
)

# Add OpenTelemetry instrumentation
try:
    instrument_app(app)
except Exception as e:
    logger.error(f"Failed to instrument app with OpenTelemetry: {e}")
    # Continue without instrumentation

# Include routers
app.include_router(health_router.router)
app.include_router(test_router.router)
app.include_router(generate_router.router, prefix="/api/v1", tags=["generate"])
app.include_router(stream_router.router, prefix="/api/v1", tags=["stream"])


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.is_development,
        log_level=settings.LOG_LEVEL.lower(),
    )
