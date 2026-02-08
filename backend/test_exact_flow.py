"""
Direct API test - mimics exactly what backboard_service.py does
to identify if there's a request format issue.
"""
import asyncio
import httpx
import json
import sys

# Same settings as config.py
API_KEY = "espr_OkJGNjjZxsqiTXyfuO0NO2BJ5NFHQ7PQmCtQbpDOAeQ"
API_URL = "https://app.backboard.io/api"

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

async def test_exact_flow():
    print("="*60)
    print("EXACT BACKBOARD SERVICE FLOW TEST")  
    print("="*60)
    
    # Mimics what BackboardDocumentService does
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        # 1. List assistants
        print("\n[1] List Assistants...")
        resp = await client.get(f"{API_URL}/assistants", headers=headers)
        print(f"    Status: {resp.status_code}")
        assistants = resp.json()
        asst_id = next((a.get("assistant_id") for a in assistants if a.get("name") == "FinShield Auditor"), None)
        print(f"    Found: {asst_id}")
        
        if not asst_id:
            print("    NO ASSISTANT! This would cause KeyError")
            return
        
        # 2. Create thread
        print("\n[2] Create Thread...")
        resp = await client.post(
            f"{API_URL}/assistants/{asst_id}/threads",
            json={},
            headers=headers
        )
        print(f"    Status: {resp.status_code}")
        print(f"    Response: {resp.text[:200]}")
        thread_id = resp.json().get("thread_id")
        print(f"    Thread ID: {thread_id}")
        
        # 3. Send message with file - EXACTLY like backboard_service.py
        print("\n[3] Send Message (mimicking backboard_service.py)...")
        
        prompt = "Analyze this document. Classify it (Invoice, Bank Statement, etc.) and extract key fields as JSON."
        
        files = {
            "files": ("test.pdf", PDF_CONTENT, "application/pdf")
        }
        
        data = {
            "content": prompt,
            "stream": "false",
            "memory": "off",
            "send_to_llm": "true",
            "llm_provider": "openai",
            "model_name": "gpt-4o"
        }
        
        # Remove Content-Type (like backboard_service.py does)
        headers_no_ct = {"X-API-Key": API_KEY}
        
        resp = await client.post(
            f"{API_URL}/threads/{thread_id}/messages",
            data=data,
            files=files,
            headers=headers_no_ct
        )
        
        print(f"    Status: {resp.status_code}")
        print(f"    Response Body: {resp.text[:1000]}")
        
        if resp.status_code == 200:
            result = resp.json()
            ai_content = result.get("content", "")
            print(f"\n    AI Content: {ai_content[:500]}")
        else:
            print(f"\n    ERROR RESPONSE:")
            print(resp.text)

if __name__ == "__main__":
    asyncio.run(test_exact_flow())
