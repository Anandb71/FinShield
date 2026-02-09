from __future__ import annotations

from typing import Dict

import cv2
import numpy as np


def detect_layout_flags(image_bytes: bytes) -> Dict[str, bool | None]:
    data = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return {
            "tables": None,
            "stamps": None,
            "handwriting": None,
            "signatures": None,
            "headers": None,
        }

    _, bw = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    # Detect table-like lines
    horizontal = bw.copy()
    vertical = bw.copy()
    cols = horizontal.shape[1]
    rows = vertical.shape[0]

    horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (cols // 20, 1))
    vertical_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, rows // 20))

    horizontal = cv2.erode(horizontal, horizontal_kernel)
    horizontal = cv2.dilate(horizontal, horizontal_kernel)

    vertical = cv2.erode(vertical, vertical_kernel)
    vertical = cv2.dilate(vertical, vertical_kernel)

    table_mask = cv2.add(horizontal, vertical)
    table_pixels = cv2.countNonZero(table_mask)
    tables = table_pixels > 0.01 * bw.size

    # Header heuristic: darker top band
    top_band = bw[: max(1, rows // 8), :]
    headers = cv2.countNonZero(top_band) > 0.05 * top_band.size

    return {
        "tables": tables,
        "stamps": None,
        "handwriting": None,
        "signatures": None,
        "headers": headers,
    }
