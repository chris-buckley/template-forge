# MD Decision Maker Backend

FastAPI backend service for the LLM Document Generation PoC. This service provides REST APIs and Server-Sent Events (SSE) for real-time document processing with Azure AI integration.

## Features

- 🚀 **FastAPI** framework with async/await support
- 🔒 **Password-based authentication** for API access
- 📄 **Multi-format file upload** support (PDF, DOCX, CSV, XLSX)
- 📡 **Server-Sent Events** for real-time progress streaming
- 🔍 **OpenTelemetry** instrumentation for observability
- 🐳 **Docker** support for development and production
- ☁️ **Azure-ready** with App Service and Container Registry compatibility

## Tech Stack

- **Python 3.13** - Runtime
- **FastAPI 0.115** - Web framework
- **Pydantic 2.11** - Data validation
- **SSE-Starlette 2.3** - Server-Sent Events
- **UV** - Fast Python package manager
- **Docker** - Containerization
- **OpenTelemetry** - Observability

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration management
│   ├── dependencies/        # Dependency injection
│   │   ├── auth.py          # Authentication
│   │   └── telemetry.py     # OpenTelemetry setup
│   ├── routes/              # API endpoints
│   │   ├── health_router.py # Health checks
│   │   ├── generate_router.py # Document generation
│   │   └── stream_router.py # SSE streaming
│   ├── services/            # Business logic
│   │   └── document_processor.py
│   ├── schemas/             # Pydantic models
│   ├── middleware.py        # Custom middleware
│   ├── exceptions.py        # Custom exceptions
│   └── utils/               # Utilities
│       ├── file_validation.py
│       └── logging.py
├── tests/                   # Test suite
├── Dockerfile              # Development image
├── Dockerfile.prod         # Production image
├── docker-compose.yml      # Development environment
├── pyproject.toml          # Dependencies
└── Makefile               # Convenience commands
```

## Prerequisites

- **Option 1 (Recommended):** Docker Desktop or Docker Engine (v24.0+)
- **Option 2:** Python 3.13+ with UV package manager

## Quick Start

### Using Docker (Recommended)

1. **Clone and navigate to backend:**
   ```bash
   cd backend/
   ```

2. **Copy environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the development environment:**
   ```bash
   docker-compose up -d
   # Or using make: make up
   ```

4. **Access the application:**
   - API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Health endpoint: http://localhost:8000/health

### Local Development (without Docker)

1. **Install UV package manager:**
   ```bash
   pip install uv
   ```

2. **Install dependencies:**
   ```bash
   uv pip sync
   ```

3. **Run the application:**
   ```bash
   uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## API Documentation

### Authentication

All endpoints (except `/health`) require Bearer token authentication:

```bash
curl -H "Authorization: Bearer your-password-here" http://localhost:8000/api/v1/generate
```

### Endpoints

#### Health Check
```
GET /health
```
Returns service status and version. No authentication required.

#### Generate Document
```
POST /api/v1/generate
```
Upload files and generate documents. Accepts multipart/form-data with:
- `files`: Multiple files (PDF, DOCX, CSV, XLSX)
- `description`: Processing instructions
- `output_format`: Desired output format (optional)

Returns:
```json
{
  "request_id": "uuid",
  "status": "processing",
  "stream_url": "/api/v1/generate/{request_id}/stream",
  "created_at": "2025-06-17T00:00:00Z"
}
```

#### Stream Progress
```
GET /api/v1/generate/{request_id}/stream
```
Server-Sent Events endpoint for real-time progress updates.

Event format:
```
event: progress
data: {"step": 1, "total": 5, "message": "Processing file 1 of 3"}

event: complete
data: {"request_id": "uuid", "timestamp": "2025-06-17T00:00:00Z"}
```

## Development

### Docker Development Workflow

```bash
# Show all available commands
make help

# Build and start with logs
make dev

# Run tests
make test

# Run linting and type checking
make lint

# Open shell in container
make shell

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

### Hot Reload

The development setup includes hot reload functionality:
- Application code in `./app` is mounted as a volume
- Uvicorn runs with `--reload` flag
- Changes to Python files automatically restart the server

### Running Tests

```bash
# Run all tests
uv run pytest -v

# Run with coverage
uv run pytest --cov=app --cov-report=html

# Run specific test file
uv run pytest tests/test_health.py -v
```

### Code Quality

```bash
# Run linting
uv run ruff check .

# Format code
uv run ruff format .

# Type checking
uv run mypy .
```

## Environment Variables

Required environment variables (see `.env.example`):

| Variable | Description | Example |
|----------|-------------|---------|
| `ACCESS_PASSWORD` | API authentication password | `secure-password-123` |
| `APP_ENV` | Environment (development/production) | `development` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `AZURE_FOUNDRY_ENDPOINT` | Azure AI endpoint | `https://resource.openai.azure.com/` |
| `AZURE_FOUNDRY_API_KEY` | Azure AI API key | `your-api-key` |
| `ALLOWED_ORIGINS_STR` | CORS allowed origins | `http://localhost:3000` |

## Production Deployment

### Docker Production Build

```bash
# Build production image
docker build -f Dockerfile.prod -t md-decision-maker-backend:prod .

# Test production configuration locally
docker-compose -f docker-compose.prod.yml up
```

### Key Production Features

1. **Multi-stage build** for smaller image size (~150MB)
2. **Security scanning** with Trivy
3. **Non-root user** execution (UID 1000)
4. **Health checks** configured
5. **Resource limits** matching Azure App Service
6. **Read-only filesystem** with tmpfs mounts

### Azure Deployment

The application is optimized for Azure deployment:

1. **Azure App Service Compatibility**
   - Proper port configuration via `WEBSITES_PORT`
   - Health check endpoint for App Service probes
   - SIGTERM handling with 30s grace period
   - Single worker process (App Service handles scaling)

2. **Azure Container Registry**
   ```bash
   # Login to ACR
   az acr login --name myacr
   
   # Build and push multi-architecture image
   ACR_NAME=myacr make push-multiarch
   ```

3. **Application Insights Integration**
   - OpenTelemetry pre-configured
   - W3C Trace Context propagation
   - Structured logging with correlation IDs

4. **Deployment Steps**
   ```bash
   # Create Web App
   az webapp create \
     --name app-md-decision-maker \
     --resource-group rg-md-decision-maker \
     --plan asp-md-decision-maker \
     --deployment-container-image-name myacr.azurecr.io/md-decision-maker:latest
   
   # Configure App Settings
   az webapp config appsettings set \
     --name app-md-decision-maker \
     --resource-group rg-md-decision-maker \
     --settings @appsettings.json
   ```

## Troubleshooting

### Container Issues

1. **Container won't start:**
   - Check logs: `docker-compose logs backend`
   - Verify port 8000 is available: `netstat -an | grep 8000`
   - Ensure `.env` file exists with required variables

2. **Permission errors:**
   - Container runs as non-root user (UID 1000)
   - Ensure file permissions allow reading

3. **Build failures:**
   - Clear Docker cache: `docker system prune -af`
   - Rebuild without cache: `docker-compose build --no-cache`

### Application Issues

1. **Authentication failures:**
   - Verify `ACCESS_PASSWORD` is set in `.env`
   - Use correct header format: `Authorization: Bearer <password>`

2. **File upload errors:**
   - Check file size limits (50MB per file, 200MB total)
   - Verify file extensions (.pdf, .docx, .csv, .xlsx)
   - Maximum 10 files per request

3. **SSE connection drops:**
   - Check proxy/reverse proxy timeout settings
   - Verify heartbeat mechanism (15s intervals)

## API Examples

### Upload Files and Generate
```bash
curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer your-password" \
  -F "files=@document.pdf" \
  -F "files=@data.csv" \
  -F "description=Generate a summary report"
```

### Stream Progress Updates
```javascript
const eventSource = new EventSource(
  'http://localhost:8000/api/v1/generate/abc-123/stream',
  { headers: { 'Authorization': 'Bearer your-password' } }
);

eventSource.addEventListener('progress', (event) => {
  const data = JSON.parse(event.data);
  console.log(`Progress: ${data.step}/${data.total} - ${data.message}`);
});

eventSource.addEventListener('complete', (event) => {
  console.log('Processing complete!');
  eventSource.close();
});
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

[Your License Here]

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [OpenTelemetry Python](https://opentelemetry.io/docs/instrumentation/python/)
