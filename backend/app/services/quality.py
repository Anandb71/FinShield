from __future__ import annotations

from typing import Dict, Any
from io import BytesIO

import cv2
import numpy as np


def _to_gray(image_bytes: bytes) -> np.ndarray | None:
    data = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_COLOR)
    if img is None:
        return None
    return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)


def score_image_quality(image_bytes: bytes) -> Dict[str, Any]:
    gray = _to_gray(image_bytes)
    if gray is None:
        return {
            "score": None,
            "blur": None,
            "brightness": None,
            "contrast": None,
            "warnings": ["Image decoding failed."],
        }

    blur_metric = cv2.Laplacian(gray, cv2.CV_64F).var()
    brightness = float(np.mean(gray))
    contrast = float(np.std(gray))

    blur_score = min(1.0, blur_metric / 150.0)  # heuristic
    brightness_score = 1.0 - min(1.0, abs(brightness - 127.0) / 127.0)
    contrast_score = min(1.0, contrast / 64.0)

    score = float((blur_score * 0.4) + (brightness_score * 0.3) + (contrast_score * 0.3))

    warnings: list[str] = []
    if blur_metric < 50:
        warnings.append("High blur detected.")
    if brightness < 60:
        warnings.append("Low brightness detected.")
    if contrast < 30:
        warnings.append("Low contrast detected.")

    return {
        "score": round(score, 3),
        "blur": round(float(blur_metric), 2),
        "brightness": round(brightness, 2),
        "contrast": round(contrast, 2),
        "warnings": warnings,
    }
