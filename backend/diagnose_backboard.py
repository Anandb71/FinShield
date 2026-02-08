"""
Diagnostic script: What does Backboard ACTUALLY return for a PDF?
"""
import asyncio
import httpx

API_KEY = "espr_OkJGNjjZxsqiTXyfuO0NO2BJ5NFHQ7PQmCtQbpDOAeQ"
API_URL = "https://app.backboard.io/api"
HEADERS = {"X-API-Key": API_KEY}

# Create a REAL minimal PDF with text content
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

async def diagnose():
    print("="*60)
    print("BACKBOARD API DIAGNOSTIC")
    print("="*60)
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        # 1. Get Assistant
        print("\n[1] Getting Assistant...")
        resp = await client.get(f"{API_URL}/assistants", headers=HEADERS)
        assistants = resp.json()
        asst_id = next((a.get("assistant_id") for a in assistants if a.get("name") == "FinShield Auditor"), None)
        print(f"    Assistant ID: {asst_id}")
        
        if not asst_id:
            print("    ❌ No assistant found. Creating one...")
            # Create assistant...
            return
        
        # 2. Create Thread
        print("\n[2] Creating Thread...")
        resp = await client.post(
            f"{API_URL}/assistants/{asst_id}/threads", 
            json={}, 
            headers=HEADERS
        )
        thread_id = resp.json().get("thread_id")
        print(f"    Thread ID: {thread_id}")
        
        # 3. Send Message with PDF
        print("\n[3] Sending PDF with analysis request...")
        prompt = """Analyze this document. Return your analysis as JSON with this EXACT structure:
{
    "classification": {
        "type": "invoice" or "bank_statement" or "payslip" or "unknown",
        "confidence": 0.95
    },
    "extracted_fields": {
        "invoice_number": "...",
        "vendor_name": "...",
        "total_amount": "..."
    }
}"""
        
        files = {"files": ("invoice_test.pdf", PDF_CONTENT, "application/pdf")}
        data = {
            "content": prompt,
            "stream": "false",
            "send_to_llm": "true"
        }
        
        resp = await client.post(
            f"{API_URL}/threads/{thread_id}/messages",
            data=data,
            files=files,
            headers=HEADERS
        )
        
        print(f"    Response Status: {resp.status_code}")
        result = resp.json()
        
        print("\n" + "="*60)
        print("RAW API RESPONSE:")
        print("="*60)
        import json
        print(json.dumps(result, indent=2))
        
        # 4. Check the AI content
        print("\n" + "="*60)
        print("AI RESPONSE CONTENT:")
        print("="*60)
        ai_content = result.get("content", "")
        print(ai_content)
        
        # 5. Check attachment status
        print("\n" + "="*60)
        print("ATTACHMENT STATUS:")
        print("="*60)
        attachments = result.get("attachments", [])
        for att in attachments:
            print(f"    File: {att.get('filename')}")
            print(f"    Status: {att.get('status')}")
            print(f"    Summary: {att.get('summary')}")

if __name__ == "__main__":
    asyncio.run(diagnose())
