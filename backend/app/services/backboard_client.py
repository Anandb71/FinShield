from __future__ import annotations

import json
import logging
import os
from io import BytesIO
import asyncio
from typing import Any, Dict, List, Optional

import httpx

from app.core.config import get_settings
from app.services.file_preprocess import preprocess_image_for_ocr


logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Cached learning patterns injected into every new prompt.
# Updated by BackboardLearningEnhancer.sync_learning_patterns().
# ---------------------------------------------------------------------------
_learned_patterns: str = ""


class BackboardClient:
    """Thin client around Backboard Assistants API."""

    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.backboard_api_key
        self.api_url = settings.backboard_api_url.rstrip("/")
        self.workspace_id = settings.backboard_workspace_id
        self.llm_provider = settings.backboard_llm_provider
        self.model_name = settings.backboard_model_name
        self.tesseract_cmd = settings.tesseract_cmd
        self.ocr_lang = settings.ocr_lang
        self.ocr_psm = settings.ocr_psm
        self.ocr_oem = settings.ocr_oem
        self.ocr_preserve_interword_spaces = settings.ocr_preserve_interword_spaces
        self.ocr_char_whitelist = settings.ocr_char_whitelist
        self.backboard_max_retries = settings.backboard_max_retries
        self.backboard_retry_delay = settings.backboard_retry_delay_seconds
        self.backboard_retry_max_delay = settings.backboard_retry_max_delay_seconds
        self._assistant_id: Optional[str] = None

    @property
    def headers(self) -> Dict[str, str]:
        headers = {"X-API-Key": self.api_key}
        if self.workspace_id:
            headers["X-Workspace-Id"] = self.workspace_id
        return headers

    async def _get_or_create_assistant(self, client: httpx.AsyncClient) -> str:
        if self._assistant_id:
            return self._assistant_id

        response = await client.get(f"{self.api_url}/assistants", headers=self.headers)
        response.raise_for_status()
        assistants = response.json()
        for assistant in assistants:
            if assistant.get("name") == "Finsight Auditor":
                self._assistant_id = assistant.get("assistant_id") or assistant.get("id")
                return self._assistant_id

        payload = {
            "name": "Finsight Auditor",
            "system_prompt": (
                "You are Finsight, an expert AI financial auditor. "
                "Analyze financial documents, extract structured data, and detect anomalies."
            ),
            "llm_provider": self.llm_provider,
            "model_name": self.model_name,
        }
        create_resp = await client.post(
            f"{self.api_url}/assistants",
            json=payload,
            headers={**self.headers, "Content-Type": "application/json"},
        )
        create_resp.raise_for_status()
        self._assistant_id = create_resp.json().get("assistant_id") or create_resp.json().get("id")
        return self._assistant_id

    async def _post_with_retry(
        self,
        client: httpx.AsyncClient,
        url: str,
        *,
        data: Optional[Dict[str, Any]] = None,
        json_payload: Optional[Dict[str, Any]] = None,
        files: Optional[Any] = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
    ) -> httpx.Response:
        retry_statuses = {408, 429, 500, 502, 503, 504}
        delay = self.backboard_retry_delay
        for attempt in range(self.backboard_max_retries + 1):
            try:
                response = await client.post(
                    url,
                    data=data,
                    json=json_payload,
                    files=files,
                    headers=headers,
                    timeout=timeout,
                )
                if response.status_code not in retry_statuses:
                    return response
                if attempt >= self.backboard_max_retries:
                    return response
            except httpx.TransportError:
                if attempt >= self.backboard_max_retries:
                    raise
            await asyncio.sleep(delay)
            delay = min(delay * 2, self.backboard_retry_max_delay)
        return await client.post(
            url,
            data=data,
            json=json_payload,
            files=files,
            headers=headers,
            timeout=timeout,
        )

    def _build_prompt(self, doc_hint: Optional[str] = None) -> str:
        hint_section = f"\nContext: {doc_hint}\n" if doc_hint else "\n"

        # Inject learned correction patterns so every new analysis benefits
        learning_section = ""
        if _learned_patterns:
            learning_section = (
                "\n--- LEARNED CORRECTION PATTERNS (from human reviewers) ---\n"
                f"{_learned_patterns}"
                "\n--- END LEARNED PATTERNS ---\n\n"
            )

        return (
            "You are Finsight, an expert financial document underwriter.\n"
            f"{learning_section}"
            "Analyze the attached document and return ONLY a single JSON object "
            "with this EXACT structure (no extra keys, no comments, no markdown):\n"
            f"{hint_section}\n"
            "{{\n"
            "  \"classification\": {{\n"
            "    \"type\": \"invoice\" | \"bank_statement\" | \"payslip\" | \"contract\" | "
            "\"check\" | \"utility_bill\" | \"form_16\" | \"unknown\",\n"
            "    \"confidence\": <number 0-1>,\n"
            "    \"language\": \"<BCP-47 language code, e.g. en, fr, hi>\",\n"
            "    \"image_quality_score\": <number 0-1>\n"
            "  }},\n"
            "  \"layout\": {{\n"
            "    \"tables\": <true|false>,\n"
            "    \"stamps\": <true|false>,\n"
            "    \"handwriting\": <true|false>,\n"
            "    \"signatures\": <true|false>,\n"
            "    \"headers\": <true|false>\n"
            "  }},\n"
            "  \"extracted_fields\": {{\n"
            "    \"vendor_name\": <string or null>,\n"
            "    \"invoice_number\": <string or null>,\n"
            "    \"total\": <number or null>,\n"
            "    \"subtotal\": <number or null>,\n"
            "    \"tax\": <number or null>,\n"
            "    \"invoice_date\": \"<ISO date or null>\",\n"
            "    \"due_date\": \"<ISO date or null>\",\n"
            "    \"bank_name\": <string or null>,\n"
            "    \"institution_name\": <string or null>,\n"
            "    \"account_holder_name\": <string or null>,\n"
            "    \"account_number\": <string or null>,\n"
            "    \"opening_balance\": <number or null>,\n"
            "    \"closing_balance\": <number or null>,\n"
            "    \"employee_name\": <string or null>,\n"
            "    \"employer_name\": <string or null>,\n"
            "    \"gross_salary\": <number or null>,\n"
            "    \"net_salary\": <number or null>,\n"
            "    \"deductions\": <number or null>,\n"
            "    \"cheque_number\": <string or null>,\n"
            "    \"payer_name\": <string or null>,\n"
            "    \"payee_name\": <string or null>,\n"
            "    \"cheque_amount\": <number or null>,\n"
            "    \"cheque_date\": \"<ISO date or null>\",\n"
            "    \"ifsc\": <string or null>,\n"
            "    \"micr\": <string or null>,\n"
            "    \"biller_name\": <string or null>,\n"
            "    \"bill_account_id\": <string or null>,\n"
            "    \"bill_period_start\": \"<ISO date or null>\",\n"
            "    \"bill_period_end\": \"<ISO date or null>\",\n"
            "    \"due_amount\": <number or null>,\n"
            "    \"pan\": <string or null>,\n"
            "    \"tan\": <string or null>,\n"
            "    \"financial_year\": <string or null>,\n"
            "    \"assessment_year\": <string or null>,\n"
            "    \"total_income\": <number or null>,\n"
            "    \"tax_deducted\": <number or null>,\n"
            "    \"transactions\": [\n"
            "      {{\n"
            "        \"date\": \"<ISO date>\",\n"
            "        \"amount\": <number>,\n"
            "        \"currency\": \"<currency code or null>\",\n"
            "        \"description\": \"<string>\"\n"
            "      }}\n"
            "    ],\n"
            "    \"line_items\": [\n"
            "      {{\n"
            "        \"description\": \"<string>\",\n"
            "        \"quantity\": <number or null>,\n"
            "        \"unit_price\": <number or null>,\n"
            "        \"amount\": <number>\n"
            "      }}\n"
            "    ]\n"
            "  }}\n"
            "}}\n\n"
            "Rules:\n"
            "- Respect the schema exactly; use null when a field is not applicable.\n"
            "- All numbers must be valid JSON numbers (no currency symbols).\n"
            "- Dates must be ISO 8601 (YYYY-MM-DD) when possible.\n"
            "- If you are uncertain, choose the best guess and lower the confidence.\n"
            "- Return ONLY the JSON object, with no explanation or markdown."
        )

    @staticmethod
    def _extract_text_from_response(result: Any) -> str:
        if isinstance(result, dict):
            for key in ("content", "message", "data", "output", "response"):
                value = result.get(key)
                if value:
                    return BackboardClient._extract_text_from_response(value)
            if "messages" in result and isinstance(result["messages"], list):
                return BackboardClient._extract_text_from_response(result["messages"])
            return json.dumps(result)
        if isinstance(result, list):
            parts = [BackboardClient._extract_text_from_response(item) for item in result]
            return "\n".join([part for part in parts if part])
        if isinstance(result, str):
            return result
        if isinstance(result, bytes):
            return result.decode("utf-8", errors="ignore")
        return str(result)

    def _try_ocr_from_image(self, file_bytes: bytes, mime_type: str) -> Optional[str]:
        if not mime_type.startswith("image/"):
            return None
        try:
            import pytesseract
        except Exception:
            return None

        tesseract_cmd = self.tesseract_cmd or os.getenv("TESSERACT_CMD")
        if tesseract_cmd:
            pytesseract.pytesseract.tesseract_cmd = tesseract_cmd

        config_parts = [f"--oem {self.ocr_oem}", f"--psm {self.ocr_psm}"]
        if self.ocr_preserve_interword_spaces:
            config_parts.append(f"-c preserve_interword_spaces={self.ocr_preserve_interword_spaces}")
        if self.ocr_char_whitelist:
            config_parts.append(f"-c tessedit_char_whitelist={self.ocr_char_whitelist}")
        config = " ".join(config_parts)

        try:
            with preprocess_image_for_ocr(file_bytes) as image:
                text = pytesseract.image_to_string(image, lang=self.ocr_lang, config=config)
        except Exception:
            return None

        cleaned = text.strip()
        return cleaned if cleaned else None

    @staticmethod
    def _response_mentions_missing_attachment(text: str) -> bool:
        if not text:
            return False
        lowered = text.lower()
        phrases = [
            "no document attached",
            "cannot access attached",
            "can't access attached",
            "unable to access attached",
            "cannot process attachments",
            "do not have the capability to process attachments",
            "unable to access attached documents",
        ]
        return any(phrase in lowered for phrase in phrases)

    @staticmethod
    def _extract_json(text: str) -> Dict[str, Any]:
        if "```json" in text:
            start = text.find("```json") + 7
            end = text.find("```", start)
            json_str = text[start:end].strip()
            return json.loads(json_str)
        if "```" in text:
            start = text.find("```") + 3
            end = text.find("```", start)
            json_str = text[start:end].strip()
            return json.loads(json_str)
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            if text:
                start = text.find("{")
                end = text.rfind("}")
                if start != -1 and end != -1 and end > start:
                    try:
                        return json.loads(text[start : end + 1])
                    except json.JSONDecodeError:
                        pass
            snippet = text[:500] if text else "<empty response>"
            raise ValueError(f"Backboard response was not JSON. Snippet: {snippet}")

    async def analyze_document(
        self,
        file_bytes: bytes,
        filename: str,
        mime_type: str = "application/pdf",
        fallback_bytes: Optional[bytes] = None,
        fallback_filename: Optional[str] = None,
        fallback_mime: Optional[str] = None,
        doc_hint: Optional[str] = None,
    ) -> Dict[str, Any]:
        if not self.api_key:
            raise RuntimeError("BACKBOARD_API_KEY is not configured.")

        async with httpx.AsyncClient(timeout=120.0) as client:
            assistant_id = await self._get_or_create_assistant(client)

            thread_resp = await self._post_with_retry(
                client,
                f"{self.api_url}/assistants/{assistant_id}/threads",
                json_payload={},
                headers={**self.headers, "Content-Type": "application/json"},
            )
            thread_resp.raise_for_status()
            thread_id = thread_resp.json().get("thread_id")
            data = {
                "content": self._build_prompt(doc_hint),
                "stream": "false",
                "send_to_llm": "true",
            }

            result = None
            attachment_error = None
            candidates = [(file_bytes, filename, mime_type)]
            if fallback_bytes and fallback_filename and fallback_mime:
                candidates.append((fallback_bytes, fallback_filename, fallback_mime))

            file_variants = [
                ("files", lambda name, data, mime: {"files": (name, data, mime)}),
                ("file", lambda name, data, mime: {"file": (name, data, mime)}),
                ("files[]", lambda name, data, mime: [("files[]", (name, data, mime))]),
            ]

            for file_bytes_candidate, name_candidate, mime_candidate in candidates:
                for _, build_files in file_variants:
                    files = build_files(name_candidate, file_bytes_candidate, mime_candidate)
                    msg_resp = await self._post_with_retry(
                        client,
                        f"{self.api_url}/threads/{thread_id}/messages",
                        data=data,
                        files=files,
                        headers=self.headers,
                        timeout=90.0,
                    )
                    try:
                        msg_resp.raise_for_status()
                    except httpx.HTTPStatusError as exc:
                        body = msg_resp.text[:1000]
                        raise RuntimeError(
                            f"Backboard API error {msg_resp.status_code}: {body}"
                        ) from exc

                    result = msg_resp.json()
                    attachments = result.get("attachments") if isinstance(result, dict) else None
                    if attachments and any(att.get("status") == "error" for att in attachments):
                        attachment_error = attachments
                        continue
                    break
                else:
                    continue
                break

            if result is None:
                raise RuntimeError("Backboard did not return a response.")

            ocr_unavailable = False
            ai_text = self._extract_text_from_response(result)
            attachment_issue = attachment_error or self._response_mentions_missing_attachment(ai_text)
            if attachment_issue:
                ocr_text = self._try_ocr_from_image(file_bytes, mime_type)
                if not ocr_text and fallback_bytes and fallback_mime:
                    ocr_text = self._try_ocr_from_image(fallback_bytes, fallback_mime)

                if ocr_text:
                    ocr_prompt = f"{self._build_prompt(doc_hint)}\n\nOCR_TEXT:\n{ocr_text[:12000]}"
                    ocr_resp = await self._post_with_retry(
                        client,
                        f"{self.api_url}/threads/{thread_id}/messages",
                        data={"content": ocr_prompt, "stream": "false", "send_to_llm": "true"},
                        headers=self.headers,
                        timeout=90.0,
                    )
                    ocr_resp.raise_for_status()
                    result = ocr_resp.json()
                    attachment_error = None
                    ai_text = self._extract_text_from_response(result)
                else:
                    ocr_unavailable = True

            parse_error = None
            try:
                parsed = self._extract_json(ai_text)
            except ValueError as exc:
                parsed = {
                    "classification": {
                        "type": "unknown",
                        "confidence": 0.0,
                        "language": None,
                        "image_quality_score": None,
                    },
                    "layout": {},
                    "extracted_fields": {},
                }
                parse_error = str(exc)

            if attachment_error and not parse_error:
                parse_error = f"Backboard attachment error: {attachment_error}"
                if ocr_unavailable:
                    parse_error += " | OCR fallback unavailable (set TESSERACT_CMD to your tesseract.exe path)."

            if "classification" not in parsed or "extracted_fields" not in parsed:
                raise RuntimeError("Backboard response missing required fields.")

            return {
                "document_id": thread_id,
                "raw_content": ai_text,
                "classification": parsed.get("classification"),
                "layout": parsed.get("layout", {}),
                "extracted_fields": parsed.get("extracted_fields"),
                "parse_error": parse_error,
            }

    async def analyze_text(self, text: str, doc_hint: Optional[str] = None) -> Dict[str, Any]:
        if not self.api_key:
            raise RuntimeError("BACKBOARD_API_KEY is not configured.")

        async with httpx.AsyncClient(timeout=120.0) as client:
            assistant_id = await self._get_or_create_assistant(client)

            thread_resp = await self._post_with_retry(
                client,
                f"{self.api_url}/assistants/{assistant_id}/threads",
                json_payload={},
                headers={**self.headers, "Content-Type": "application/json"},
            )
            thread_resp.raise_for_status()
            thread_id = thread_resp.json().get("thread_id")

            text_hint = "The document content is provided below as plain text."
            merged_hint = f"{doc_hint} {text_hint}" if doc_hint else text_hint
            prompt = f"{self._build_prompt(merged_hint)}\n\nDOCUMENT_TEXT:\n{text[:12000]}"
            msg_resp = await self._post_with_retry(
                client,
                f"{self.api_url}/threads/{thread_id}/messages",
                data={"content": prompt, "stream": "false", "send_to_llm": "true"},
                headers=self.headers,
                timeout=90.0,
            )
            msg_resp.raise_for_status()
            result = msg_resp.json()
            ai_text = self._extract_text_from_response(result)

            parse_error = None
            try:
                parsed = self._extract_json(ai_text)
            except ValueError as exc:
                parsed = {
                    "classification": {
                        "type": "unknown",
                        "confidence": 0.0,
                        "language": None,
                        "image_quality_score": None,
                    },
                    "layout": {},
                    "extracted_fields": {},
                }
                parse_error = str(exc)

            if "classification" not in parsed or "extracted_fields" not in parsed:
                raise RuntimeError("Backboard response missing required fields.")

            return {
                "document_id": thread_id,
                "raw_content": ai_text,
                "classification": parsed.get("classification"),
                "layout": parsed.get("layout", {}),
                "extracted_fields": parsed.get("extracted_fields"),
                "parse_error": parse_error,
            }

    async def submit_correction(self, thread_id: str, correction_summary: str) -> None:
        if not self.api_key:
            raise RuntimeError("BACKBOARD_API_KEY is not configured.")

        async with httpx.AsyncClient(timeout=60.0) as client:
            payload = {
                "content": correction_summary,
                "stream": "false",
                "send_to_llm": "true",
            }
            resp = await self._post_with_retry(
                client,
                f"{self.api_url}/threads/{thread_id}/messages",
                data=payload,
                headers=self.headers,
            )
            resp.raise_for_status()
