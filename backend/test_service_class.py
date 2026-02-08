"""
Test BackboardDocumentService class directly
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
    print("BACKBOARD SERVICE CLASS TEST")
    print("="*60)
    
    settings = get_settings()
    print(f"\nSettings:")
    print(f"  API URL: {settings.backboard_api_url}")
    print(f"  API Key: {settings.backboard_api_key[:20]}...")
    
    service = BackboardDocumentService(
        api_key=settings.backboard_api_key,
        api_url=settings.backboard_api_url,
        workspace_id=settings.backboard_workspace_id
    )
    
    print("\nCalling analyze_document()...")
    result = await service.analyze_document(PDF_CONTENT, "test.pdf")
    
    print(f"\nResult:")
    import json
    print(json.dumps(result, indent=2, default=str))
    
    print(f"\nKey Fields:")
    print(f"  status: {result.get('status')}")
    print(f"  classification: {result.get('classification')}")
    print(f"  extracted_fields: {result.get('extracted_fields')}")

if __name__ == "__main__":
    asyncio.run(test())
