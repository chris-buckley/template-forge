"""OpenTelemetry instrumentation setup."""
import logging
from typing import Any, Dict, Optional

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.propagate import set_global_textmap
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.trace import Status, StatusCode

from app.config import settings

logger = logging.getLogger(__name__)

# Global tracer instance
tracer: Optional[trace.Tracer] = None


def init_telemetry(service_name: str) -> None:
    """
    Initialize OpenTelemetry with OTLP exporter.
    
    Args:
        service_name: The name of the service for tracing
    """
    global tracer
    
    # Create resource attributes
    resource = Resource.create({
        "service.name": service_name,
        "service.version": settings.VERSION,
        "deployment.environment": settings.APP_ENV,
    })
    
    # Create tracer provider
    provider = TracerProvider(resource=resource)
    
    # Configure exporters based on environment
    if settings.is_development:
        # In development, use console exporter for debugging
        console_exporter = ConsoleSpanExporter()
        provider.add_span_processor(BatchSpanProcessor(console_exporter))
        logger.info("OpenTelemetry configured with console exporter (development)")
    
    # Add OTLP exporter if endpoint is configured
    if settings.OTEL_EXPORTER_OTLP_ENDPOINT:
        try:
            otlp_exporter = OTLPSpanExporter(
                endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
                insecure=settings.is_development,  # Use insecure in dev, secure in prod
            )
            provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
            logger.info(f"OpenTelemetry configured with OTLP exporter: {settings.OTEL_EXPORTER_OTLP_ENDPOINT}")
        except Exception as e:
            logger.error(f"Failed to configure OTLP exporter: {e}")
    
    # Set the global tracer provider
    trace.set_tracer_provider(provider)
    
    # Configure W3C trace context propagation
    set_global_textmap(TraceContextTextMapPropagator())
    
    # Get tracer instance
    tracer = trace.get_tracer(__name__, settings.VERSION)
    logger.info(f"OpenTelemetry initialized for service: {service_name}")


def get_tracer() -> trace.Tracer:
    """
    Get the global tracer instance.
    
    Returns:
        The configured tracer instance
    
    Raises:
        RuntimeError: If telemetry has not been initialized
    """
    if tracer is None:
        raise RuntimeError("Telemetry not initialized. Call init_telemetry() first.")
    return tracer


def instrument_app(app: Any) -> None:
    """
    Instrument FastAPI application with OpenTelemetry.
    
    Args:
        app: FastAPI application instance
    """
    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(app)
    logger.info("FastAPI application instrumented with OpenTelemetry")


def create_span(name: str, attributes: Optional[Dict[str, Any]] = None) -> trace.Span:
    """
    Create a new span with optional attributes.
    
    Args:
        name: Span name
        attributes: Optional dictionary of span attributes
    
    Returns:
        The created span
    """
    span = get_tracer().start_span(name)
    if attributes:
        span.set_attributes(attributes)
    return span


def set_span_error(span: trace.Span, error: Exception) -> None:
    """
    Set error status on a span.
    
    Args:
        span: The span to set error on
        error: The exception that occurred
    """
    span.set_status(Status(StatusCode.ERROR, str(error)))
    span.record_exception(error)


def shutdown_telemetry() -> None:
    """Shutdown telemetry providers and flush remaining spans."""
    provider = trace.get_tracer_provider()
    if hasattr(provider, "shutdown"):
        provider.shutdown()
        logger.info("OpenTelemetry shutdown complete")
