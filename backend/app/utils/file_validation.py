"""File validation utilities for upload endpoints."""

import mimetypes
from pathlib import Path
from typing import Optional, Tuple, Set

from fastapi import UploadFile

from app.exceptions import FileValidationError


# Allowed file extensions and their expected MIME types
ALLOWED_EXTENSIONS: dict[str, Set[str]] = {
    ".pdf": {"application/pdf"},
    ".docx": {"application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"},
    ".csv": {"text/csv", "application/csv"},
    ".xlsx": {"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.ms-excel"},
}

# Maximum file size in bytes (50MB)
MAX_FILE_SIZE = 50 * 1024 * 1024

# Magic bytes for file type detection
FILE_SIGNATURES = {
    b"%PDF": ".pdf",
    b"PK\x03\x04": None,  # ZIP-based formats (docx, xlsx) - need further checking
}


def get_file_extension(filename: str) -> str:
    """Extract file extension from filename."""
    return Path(filename).suffix.lower()


def validate_file_extension(filename: str) -> Tuple[bool, Optional[str]]:
    """
    Validate if file extension is allowed.

    Returns:
        Tuple of (is_valid, error_message)
    """
    extension = get_file_extension(filename)

    if not extension:
        return False, "File must have an extension"

    if extension not in ALLOWED_EXTENSIONS:
        allowed = ", ".join(ALLOWED_EXTENSIONS.keys())
        return False, f"File type '{extension}' not allowed. Allowed types: {allowed}"

    return True, None


def validate_content_type(filename: str, content_type: str) -> Tuple[bool, Optional[str]]:
    """
    Validate if content type matches expected MIME types for the file extension.

    Returns:
        Tuple of (is_valid, error_message)
    """
    extension = get_file_extension(filename)

    if extension not in ALLOWED_EXTENSIONS:
        return False, f"Invalid file extension: {extension}"

    expected_types = ALLOWED_EXTENSIONS[extension]

    # Some browsers may send generic types, so also check with mimetypes
    guessed_type, _ = mimetypes.guess_type(filename)

    if content_type in expected_types or (guessed_type and guessed_type in expected_types):
        return True, None

    return False, f"Content type '{content_type}' does not match expected types for {extension}"


async def detect_file_type(file: UploadFile) -> Optional[str]:
    """
    Detect file type by reading magic bytes.

    Returns:
        Detected file extension or None if unknown
    """
    # Read first 8 bytes for signature detection
    chunk = await file.read(8)
    await file.seek(0)  # Reset file position

    if not chunk:
        return None

    # Check against known signatures
    for signature, ext in FILE_SIGNATURES.items():
        if chunk.startswith(signature):
            if ext:
                return ext
            # For ZIP-based formats, need to check further
            if signature == b"PK\x03\x04":
                # This could be docx or xlsx
                filename_lower = file.filename.lower() if file.filename else ""
                if filename_lower.endswith(".docx"):
                    return ".docx"
                elif filename_lower.endswith(".xlsx"):
                    return ".xlsx"

    return None


async def validate_upload_file(file: UploadFile) -> None:
    """
    Comprehensive validation of uploaded file.

    Raises:
        FileValidationError: If validation fails
    """
    # Check if file is provided
    if not file or not file.filename:
        raise FileValidationError("No file provided", details={"field": "file"})

    # Validate extension
    is_valid, error_msg = validate_file_extension(file.filename)
    if not is_valid:
        raise FileValidationError(
            error_msg or "Invalid file extension", details={"filename": file.filename, "field": "file"}
        )

    # Validate content type
    is_valid, error_msg = validate_content_type(file.filename, file.content_type or "")
    if not is_valid:
        # Try to be lenient if content type is missing but extension is valid
        if not file.content_type:
            # Use mimetypes to guess
            guessed_type, _ = mimetypes.guess_type(file.filename)
            if guessed_type:
                file.content_type = guessed_type
            else:
                raise FileValidationError(
                    "Unable to determine file content type", details={"filename": file.filename, "field": "file"}
                )
        else:
            raise FileValidationError(
                error_msg or "Invalid content type",
                details={"filename": file.filename, "content_type": file.content_type, "field": "file"},
            )

    # Check file size (this requires reading the file)
    # We'll check this during actual file processing

    # Detect actual file type from content
    detected_type = await detect_file_type(file)
    expected_type = get_file_extension(file.filename)

    if detected_type and detected_type != expected_type:
        raise FileValidationError(
            f"File content does not match extension. Expected {expected_type}, detected {detected_type}",
            details={
                "filename": file.filename,
                "expected_type": expected_type,
                "detected_type": detected_type,
                "field": "file",
            },
        )


def validate_file_size(size: int) -> None:
    """
    Validate file size is within limits.

    Raises:
        FileValidationError: If file is too large
    """
    if size > MAX_FILE_SIZE:
        size_mb = size / (1024 * 1024)
        max_mb = MAX_FILE_SIZE / (1024 * 1024)
        raise FileValidationError(
            f"File size {size_mb:.1f}MB exceeds maximum allowed size of {max_mb:.1f}MB",
            details={
                "size_mb": round(size_mb, 1),
                "max_size_mb": round(max_mb, 1),
                "size_bytes": size,
                "max_size_bytes": MAX_FILE_SIZE,
            },
        )
