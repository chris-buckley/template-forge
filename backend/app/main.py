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
from app.routes import health_router
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
    description="API for generating documents using LLM with real-time progress streaming",
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/api/docs" if settings.ENABLE_DOCS else None,
    redoc_url="/api/redoc" if settings.ENABLE_DOCS else None,
    openapi_url="/api/openapi.json" if settings.ENABLE_DOCS else None,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add OpenTelemetry instrumentation
try:
    instrument_app(app)
except Exception as e:
    logger.error(f"Failed to instrument app with OpenTelemetry: {e}")
    # Continue without instrumentation

# Include routers
app.include_router(health_router.router)

# TODO: Include other routers


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.is_development,
        log_level=settings.LOG_LEVEL.lower(),
    )
