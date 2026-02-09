from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
import mimetypes
from pathlib import Path

from PIL import Image
import cv2
import numpy as np


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff"}


@dataclass
class NormalizedInput:
    normalized_bytes: bytes
    normalized_name: str
    normalized_mime: str
    original_bytes: bytes
    original_name: str
    original_mime: str
    converted: bool


def _estimate_skew_angle(gray: np.ndarray) -> float:
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    coords = np.column_stack(np.where(thresh < 255))
    if coords.shape[0] < 50:
        return 0.0
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    return angle


def _deskew(gray: np.ndarray) -> np.ndarray:
    angle = _estimate_skew_angle(gray)
    if abs(angle) < 0.3:
        return gray
    (h, w) = gray.shape[:2]
    center = (w // 2, h // 2)
    matrix = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(gray, matrix, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    return rotated


def _enhance_for_ocr(img: np.ndarray) -> np.ndarray:
    denoised = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
    gray = cv2.cvtColor(denoised, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)
    gray = _deskew(gray)
    thresh = cv2.adaptiveThreshold(
        gray,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        8,
    )
    bordered = cv2.copyMakeBorder(
        thresh,
        8,
        8,
        8,
        8,
        cv2.BORDER_CONSTANT,
        value=255,
    )
    return cv2.cvtColor(bordered, cv2.COLOR_GRAY2BGR)


def preprocess_image_for_ocr(content: bytes) -> Image.Image:
    data = np.frombuffer(content, np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_COLOR)
    if img is None:
        return Image.open(BytesIO(content))
    enhanced = _enhance_for_ocr(img)
    return Image.fromarray(cv2.cvtColor(enhanced, cv2.COLOR_BGR2RGB))


def normalize_input(filename: str, content: bytes) -> NormalizedInput:
    """Convert supported images to single-page PDF for Backboard ingestion."""
    ext = Path(filename).suffix.lower()
    original_mime = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    if ext not in IMAGE_EXTENSIONS:
        return NormalizedInput(
            normalized_bytes=content,
            normalized_name=filename,
            normalized_mime=original_mime,
            original_bytes=content,
            original_name=filename,
            original_mime=original_mime,
            converted=False,
        )

    with preprocess_image_for_ocr(content) as pil_img:
        rgb = pil_img.convert("RGB")
        buffer = BytesIO()
        rgb.save(buffer, format="PNG")
        png_bytes = buffer.getvalue()

    png_name = f"{Path(filename).stem}.png"
    return NormalizedInput(
        normalized_bytes=png_bytes,
        normalized_name=png_name,
        normalized_mime="image/png",
        original_bytes=content,
        original_name=filename,
        original_mime=original_mime,
        converted=True,
    )
