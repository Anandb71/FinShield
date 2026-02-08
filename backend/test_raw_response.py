"""
Test BackboardDocumentService - SHOW FULL RAW RESPONSE
"""
import asyncio
import sys
sys.path.insert(0, ".")

from app.services.backboard_service import BackboardDocumentService
from app.core.config import get_settings

# Simple PDF
PDF_CONTENT = b"""%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Kids [3 0 R] /Count 1 /Type /Pages >> endobj
3 0 obj << /Type /Page /MediaBox [0 0 612 792] /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj
4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj
5 0 obj << /Length 100 >> stream
BT /F1 12 Tf 72 720 Td (INVOICE #12345) Tj 0 -20 Td (Vendor: Acme Corp) Tj 0 -20 Td (Total: $5000.00) Tj ET
endstream endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000270 00000 n 
0000000347 00000 n 
trailer << /Size 6 /Root 1 0 R >>
startxref
497
%%EOF"""

async def test():
    print("="*60)
    print("FULL RAW RESPONSE CHECK")
    print("="*60)
    
    settings = get_settings()
    service = BackboardDocumentService(
        api_key=settings.backboard_api_key,
        api_url=settings.backboard_api_url,
        workspace_id=settings.backboard_workspace_id
    )
    
    result = await service.analyze_document(PDF_CONTENT, "test.pdf")
    
    # Print FULL raw_response
    print("\n" + "="*60)
    print("FULL RAW RESPONSE:")
    print("="*60)
    raw = result.get("raw_response", "")
    print(raw)
    
    print("\n" + "="*60)
    print("JSON Block Detection Test:")
    print("="*60)
    print(f"'```json' in response: {'```json' in raw}")
    print(f"'```' in response: {'```' in raw}")
    
    if "```" in raw:
        start = raw.find("```")
        end = raw.find("```", start + 3)
        print(f"First code block: {raw[start:end+3]}")

if __name__ == "__main__":
    asyncio.run(test())
