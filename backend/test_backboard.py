import asyncio
import httpx
import os
import sys

# Hardcoded from config.py for isolation
API_KEY = "espr_OkJGNjjZxsqiTXyfuO0NO2BJ5NFHQ7PQmCtQbpDOAeQ"
API_URL = "https://api.backboard.io/v1"

async def test_backboard():
    print(f"Testing Backboard API at {API_URL}...")
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # Try a simple GET request to check auth
            # Usually /users/me or similar, or just a health endpoint
            # backboard_service uses POST /documents/analyze
            # Let's try to list documents or get workspace info if possible
            # Or just hit the root/health if it exists
            
            # Since I don't know the exact "whoami" endpoint, I'll try a dummy analysis or query
            # But that requires a file/query.
            
            # Let's try query with dummy data to see if we get 401 or 400 (which implies auth worked)
            payload = {
                "query": "hello",
                "workspace_id": ""
            }
            response = await client.post(f"{API_URL}/query", json=payload, headers=headers)
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:200]}")
            
            if response.status_code in [200, 400]:
                print("✅ Connection/Auth likely OK (or at least reachable)")
                return True
            elif response.status_code in [401, 403]:
                print("❌ Authentication Failed")
                return False
            else:
                print("❌ Other Error")
                return False
                
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_backboard())
