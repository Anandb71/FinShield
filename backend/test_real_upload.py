import asyncio
import os
from app.services.backboard_service import BackboardDocumentService
from app.core.config import get_settings

# Simple test to run through the service layer
async def test_real_upload():
    print("Testing Real Document Upload via Service Layer...")
    settings = get_settings()
    service = BackboardDocumentService(
        api_key=settings.backboard_api_key,
        api_url=settings.backboard_api_url
    )
    
    # Create a dummy PDF file in memory (Tiny, same as debug_multipart)
    # pdf_content = b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Kids [3 0 R] /Count 1 /Type /Pages >>\nendobj\n3 0 obj\n<< /Type /Page /MediaBox [0 0 612 792] /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n5 0 obj\n<< /Length 44 >>\nstream\nBT /F1 12 Tf 72 712 Td (This is a generic invoice for testing.) Tj ET\nendstream\nendobj\nxref\n0 6\n0000000000 65535 f\n0000000010 00000 n\n0000000060 00000 n\n0000000157 00000 n\n0000000302 00000 n\n0000000389 00000 n\ntrailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n483\n%%EOF"
    pdf_content = b"%PDF-1.4 dummy content"
    
    filename = "test.pdf"
    
    try:
        print(f"Analyzing {filename}...")
        result = await service.analyze_document(pdf_content, filename)
        
        print("\n--- Analysis Result ---")
        print(f"Status: {result.get('status')}")
        print(f"Doc ID: {result.get('document_id')}")
        print(f"Classification: {result.get('classification')}")
        print(f"Extracted Fields: {result.get('extracted_fields')}")
        # print(f"Raw: {result.get('raw_response')}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        if hasattr(e, 'response') and e.response:
             print(f"Updated Response: {e.response.text}")

if __name__ == "__main__":
    asyncio.run(test_real_upload())
