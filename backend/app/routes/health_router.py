"""Health check router."""
import logging

from fastapi import APIRouter, status
from opentelemetry import trace
from pydantic import BaseModel

from app.config import settings

logger = logging.getLogger(__name__)


class HealthResponse(BaseModel):
    """Health check response schema."""
    
    status: str
    version: str


router = APIRouter(
    prefix="",
    tags=["health"],
)


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health Check",
    description="Check if the service is up and running",
    responses={
        200: {
            "description": "Service is healthy",
            "content": {
                "application/json": {
                    "example": {
                        "status": "ok",
                        "version": "0.1.0"
                    }
                }
            }
        }
    }
)
async def health_check() -> HealthResponse:
    """
    Health check endpoint.
    
    Returns basic service information to verify the service is running.
    No authentication required.
    """
    # Get current tracer
    tracer = trace.get_tracer(__name__)
    
    # Create a span for this operation
    with tracer.start_as_current_span(
        "health_check",
        attributes={
            "http.method": "GET",
            "http.route": "/health",
            "service.name": settings.SERVICE_NAME,
            "service.version": settings.VERSION,
        }
    ) as span:
        try:
            # Log the health check
            logger.debug("Health check requested")
            
            # Return the response in the format specified in the plan
            response = HealthResponse(
                status="ok",
                version=settings.VERSION
            )
            
            # Add response attributes to span
            span.set_attribute("health.status", response.status)
            span.set_attribute("health.version", response.version)
            
            return response
        except Exception as e:
            # Record any errors in the span
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            logger.error(f"Health check failed: {e}")
            raise
