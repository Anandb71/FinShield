"""
Live test: Hit the running backend at port 8000
"""
import httpx
import asyncio

# Minimal PDF with invoice data
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
    print("LIVE BACKEND TEST")
    print("="*60)
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        # Upload to the running backend
        print("\n[1] Uploading PDF to localhost:8000...")
        
        files = {"file": ("test_invoice.pdf", PDF_CONTENT, "application/pdf")}
        
        try:
            resp = await client.post(
                "http://127.0.0.1:8000/api/documents/analyze",
                files=files
            )
            
            print(f"Status: {resp.status_code}")
            print(f"\n{'='*60}")
            print("RESPONSE JSON:")
            print("="*60)
            
            import json
            result = resp.json()
            print(json.dumps(result, indent=2))
            
            # Key checks
            print(f"\n{'='*60}")
            print("KEY DATA POINTS:")
            print("="*60)
            print(f"  status: {result.get('status')}")
            print(f"  document_id: {result.get('document_id')}")
            print(f"  classification.type: {result.get('classification', {}).get('type')}")
            print(f"  classification.confidence: {result.get('classification', {}).get('confidence')}")
            print(f"  extracted_fields: {result.get('extracted_fields')}")
            print(f"  validation.valid: {result.get('validation', {}).get('valid')}")
            
        except Exception as e:
            print(f"ERROR: {e}")

if __name__ == "__main__":
    asyncio.run(test())
