# ---- build stage ----
FROM python:3.13-slim AS builder

# Install uv package manager
RUN pip install --no-cache-dir uv

WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies using uv
# Install directly to system Python
RUN uv pip install --system --no-cache -r pyproject.toml

# ---- runtime stage ----
FROM python:3.13-slim

# Add OCI labels
LABEL org.opencontainers.image.source="https://github.com/microsoft/md-decision-maker"
LABEL org.opencontainers.image.description="LLM Document Generation PoC Backend"
LABEL org.opencontainers.image.version="0.1.0"

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.13 /usr/local/lib/python3.13

WORKDIR /app

# Copy application code
COPY app ./app

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PYTHONPATH=/app \
    # Default configuration
    APP_ENV=production \
    LOG_LEVEL=INFO

# Expose port
EXPOSE 8000

# Health check - using the /health endpoint we created
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()"

# Run with proper signal handling using exec form
# The --host flag ensures the app listens on all interfaces
# Using exec form ensures proper SIGTERM handling for Azure App Service
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
