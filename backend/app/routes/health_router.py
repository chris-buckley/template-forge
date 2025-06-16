"""Health check router."""
from fastapi import APIRouter, status
from pydantic import BaseModel

from app.config import settings


class HealthResponse(BaseModel):
    """Health check response schema."""
    
    status: str
    version: str
    environment: str
    service: str


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
                        "status": "healthy",
                        "version": "0.1.0",
                        "environment": "development",
                        "service": "md-decision-maker-backend"
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
    return HealthResponse(
        status="healthy",
        version=settings.VERSION,
        environment=settings.APP_ENV,
        service=settings.SERVICE_NAME
    )
