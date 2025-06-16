"""Routes package."""

from app.routes import health_router, test_router, generate_router, stream_router

__all__ = ["health_router", "test_router", "generate_router", "stream_router"]
