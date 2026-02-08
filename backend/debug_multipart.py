import httpx
import asyncio
import os

API_KEY = "espr_OkJGNjjZxsqiTXyfuO0NO2BJ5NFHQ7PQmCtQbpDOAeQ"
API_URL = "https://app.backboard.io/api"
HEADERS = {"X-API-Key": API_KEY}

async def debug_multipart():
    print("Debugging Multipart Request...")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("Getting Assistant...")
        resp = await client.get(f"{API_URL}/assistants", headers=HEADERS)
        assistants = resp.json()
        print(f"Assistants Response: {assistants}")
        # Handle both 'id' and 'assistant_id'
        asst_id = next((a.get('id', a.get('assistant_id')) for a in assistants if a.get('name') == 'FinShield Auditor'), None)
        print(f"Found Assistant ID: {asst_id}")
        
        # 2. Create Thread
        print("Creating Thread...")
        resp = await client.post(f"{API_URL}/assistants/{asst_id}/threads", json={}, headers=HEADERS)
        thread_id = resp.json()['thread_id']
        print(f"Thread ID: {thread_id}")
        
        # 3. Send Message with File
        print("Sending Message...")
        headers_no_ct = HEADERS.copy()
        
        # Test Case 1: 'files' as field name
        files = {
            "files": ("test.pdf", b"%PDF-1.4...", "application/pdf")
        }
        data = {
            "content": "Analyze this.",
            "stream": "false",
            "send_to_llm": "true"
        }
        
        resp = await client.post(
            f"{API_URL}/threads/{thread_id}/messages", 
            data=data, 
            files=files, 
            headers=headers_no_ct
        )
        
        print(f"Response Status: {resp.status_code}")
        print(f"Response Body: {resp.text}")

if __name__ == "__main__":
    asyncio.run(debug_multipart())
