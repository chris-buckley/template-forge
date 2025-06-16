"""Router for document generation endpoints."""

from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, File, Form, UploadFile, status

from app.dependencies.auth import verify_password
from app.exceptions import ValidationError, ProcessingError, ResourceNotFoundError
from app.schemas.generate_schema import GenerateResponse
from app.services.document_processor import document_processor
from app.utils.file_validation import validate_upload_file, validate_file_size
from app.utils.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()


@router.post(
    "/generate",
    response_model=GenerateResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Generate document from uploaded files",
    description="Upload one or more files and request document generation",
    response_description="Generation request accepted and queued for processing",
)
async def generate_document(
    description: str = Form(
        ..., min_length=1, max_length=2000, description="Description of what to generate from the uploaded documents"
    ),
    output_format: str = Form(
        default="markdown",
        pattern="^(markdown|pdf|docx)$",
        description="Desired output format for the generated document",
    ),
    files: List[UploadFile] = File(..., description="One or more files to process (PDF, DOCX, CSV, XLSX)"),
    _: None = Depends(verify_password),
) -> GenerateResponse:
    """
    Generate a document from uploaded files.

    This endpoint accepts multiple files and a description of what to generate.
    It returns immediately with a request ID and SSE stream URL for progress tracking.

    Supported file types:
    - PDF (.pdf)
    - Word Documents (.docx)
    - CSV files (.csv)
    - Excel files (.xlsx)

    Maximum file size: 50MB per file
    """
    # Validate request
    if not files:
        raise ValidationError("At least one file must be uploaded", details={"field": "files"})

    if len(files) > 10:
        raise ValidationError(
            "Maximum 10 files can be uploaded at once",
            details={"field": "files", "file_count": len(files), "max_allowed": 10},
        )

    # Validate each file
    total_size = 0
    for file in files:
        # Validate file type and extension
        await validate_upload_file(file)

        # Check individual file size
        # We need to read the file to get size, but we'll do this in the processor
        # For now, trust the content-length if available

    logger.info(
        "Received generation request",
        extra={"file_count": len(files), "output_format": output_format, "description_length": len(description)},
    )

    try:
        # Create the generation request
        request_id, file_infos = await document_processor.create_request(
            files=files, description=description, output_format=output_format
        )

        # Check total size after processing
        total_size = sum(f.size for f in file_infos)
        max_total_size = 200 * 1024 * 1024  # 200MB total

        if total_size > max_total_size:
            raise ValidationError(
                f"Total file size {total_size / (1024 * 1024):.1f}MB exceeds maximum allowed {max_total_size / (1024 * 1024):.1f}MB",
                details={
                    "total_size_mb": round(total_size / (1024 * 1024), 1),
                    "max_size_mb": round(max_total_size / (1024 * 1024), 1),
                },
            )

        # Validate individual file sizes
        for file_info in file_infos:
            validate_file_size(file_info.size)

        # Construct response
        response = GenerateResponse(
            request_id=request_id,
            status="accepted",
            stream_url=f"/api/v1/generate/{request_id}/stream",
            files_received=file_infos,
            created_at=datetime.now(timezone.utc),
        )

        logger.info(
            "Generation request created successfully", extra={"request_id": str(request_id), "total_size": total_size}
        )

        return response

    except (ValidationError, ProcessingError, ResourceNotFoundError):
        # Re-raise our custom exceptions
        raise
    except Exception as e:
        logger.error("Error creating generation request", extra={"error": str(e)}, exc_info=True)
        raise ProcessingError(
            "Failed to process generation request", details={"error_type": type(e).__name__, "error_message": str(e)}
        )


@router.get(
    "/generate/{request_id}/status",
    summary="Get generation request status",
    description="Get the current status of a document generation request",
)
async def get_generation_status(request_id: str, _: None = Depends(verify_password)) -> dict:
    """Get the current status of a generation request."""
    request_status = await document_processor.get_request_status(request_id)

    if not request_status:
        raise ResourceNotFoundError("Generation request", request_id)

    return request_status.model_dump()
