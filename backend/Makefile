# Makefile for Docker operations
.PHONY: help build build-prod up down logs shell test clean prune push

# Default target
help:
	@echo "Available commands:"
	@echo "  make build       - Build development Docker image"
	@echo "  make build-prod  - Build production Docker image"
	@echo "  make up          - Start development containers"
	@echo "  make down        - Stop and remove containers"
	@echo "  make logs        - View container logs"
	@echo "  make shell       - Open shell in backend container"
	@echo "  make test        - Run tests in Docker"
	@echo "  make clean       - Clean up containers and images"
	@echo "  make prune       - Remove unused Docker resources"
	@echo "  make push        - Push image to registry (requires login)"

# Build development image
build:
	docker-compose build --no-cache backend

# Build production image
build-prod:
	docker build -f Dockerfile.prod -t md-decision-maker-backend:prod .

# Build multi-architecture image for Azure Container Registry
build-multiarch:
	docker buildx create --use --name md-builder || true
	docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.prod -t md-decision-maker-backend:prod .

# Start development environment
up:
	docker-compose up -d
	@echo "Backend is running at http://localhost:8000"
	@echo "API docs available at http://localhost:8000/docs"

# Stop development environment
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f backend

# Open shell in backend container
shell:
	docker-compose exec backend /bin/bash

# Run tests in Docker
test:
	docker-compose run --rm backend pytest -v

# Run linting and type checking
lint:
	docker-compose run --rm backend bash -c "ruff check . && ruff format --check . && mypy app tests"

# Clean up containers and images
clean:
	docker-compose down -v --remove-orphans
	docker rmi md-decision-maker-backend:dev md-decision-maker-backend:prod || true

# Remove unused Docker resources
prune:
	docker system prune -af --volumes

# Push to Azure Container Registry (example)
push:
	@echo "Tagging image for ACR..."
	docker tag md-decision-maker-backend:prod ${ACR_NAME}.azurecr.io/md-decision-maker-backend:latest
	docker tag md-decision-maker-backend:prod ${ACR_NAME}.azurecr.io/md-decision-maker-backend:$(shell git rev-parse --short HEAD)
	@echo "Pushing to ACR..."
	docker push ${ACR_NAME}.azurecr.io/md-decision-maker-backend:latest
	docker push ${ACR_NAME}.azurecr.io/md-decision-maker-backend:$(shell git rev-parse --short HEAD)

# Build and push multi-architecture image to ACR
push-multiarch:
	@echo "Building and pushing multi-arch image to ACR..."
	docker buildx create --use --name md-builder || true
	docker buildx build --platform linux/amd64,linux/arm64 \
		-f Dockerfile.prod \
		-t ${ACR_NAME}.azurecr.io/md-decision-maker-backend:latest \
		-t ${ACR_NAME}.azurecr.io/md-decision-maker-backend:$(shell git rev-parse --short HEAD) \
		--push .

# Development workflow shortcuts
dev: build up logs

# Production test workflow
prod-test:
	docker-compose -f docker-compose.prod.yml up -d
	@echo "Production-like environment running at http://localhost:8000"

# Azure environment test workflow
azure-test:
	docker-compose -f docker-compose.azure.yml up -d
	@echo "Azure-like environment running at http://localhost:8000"
	@echo "Remember to set required Azure environment variables in .env"
