"""FastAPI application entry point."""
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

# Ensure unbuffered output for containerized environments
os.environ.setdefault("PYTHONUNBUFFERED", "1")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes import health_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Handle application startup and shutdown events."""
    # Startup
    print(f"Starting {settings.SERVICE_NAME} v{settings.VERSION}")
    print(f"Environment: {settings.APP_ENV}")
    print(f"Docs enabled: {settings.ENABLE_DOCS}")
    
    # TODO: Initialize telemetry
    # TODO: Initialize other services
    
    yield
    
    # Shutdown
    print(f"Shutting down {settings.SERVICE_NAME}")
    # TODO: Cleanup tasks here


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

# TODO: Add OpenTelemetry instrumentation

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
