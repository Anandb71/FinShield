import httpx
import asyncio
import os
import json

# Hardcoded from config.py for isolation
API_KEY = "espr_OkJGNjjZxsqiTXyfuO0NO2BJ5NFHQ7PQmCtQbpDOAeQ"
API_URL = "https://app.backboard.io/api"
HEADERS = {"X-API-Key": API_KEY}

async def test_backboard_v2():
    print(f"Testing Backboard API at {API_URL}...")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # 1. List Assistants (or Create One)
            print("\n1. Listing Assistants...")
            response = await client.get(f"{API_URL}/assistants", headers=HEADERS)
            
            assistant_id = None
            if response.status_code == 200:
                assistants = response.json()
                print(f"Found {len(assistants)} assistants.")
                for a in assistants:
                    if a.get("name") == "FinShield Auditor":
                        assistant_id = a.get("id")
                        print(f"Found existing FinShield Auditor: {assistant_id}")
                        break
            else:
                print(f"Error listing assistants: {response.text}")

            # Create if not found
            if not assistant_id:
                print("\nCreating new FinShield Auditor assistant...")
                payload = {
                    "name": "FinShield Auditor",
                    "system_prompt": "You are an expert financial auditor. Your job is to analyze documents, extract structured data, and detect risks.",
                    "llm_provider": "openai",
                    "model_name": "gpt-4o"
                }
                response = await client.post(f"{API_URL}/assistants", json=payload, headers=HEADERS)
                if response.status_code in [200, 201]:
                    assistant_id = response.json().get("assistant_id")
                    print(f"Created/Retrieved Assistant: {assistant_id}")
                else:
                    print(f"Failed to create assistant: {response.text}")
                    return

            # 2. Create Thread
            print(f"\n2. Creating Thread for Assistant {assistant_id}...")
            response = await client.post(f"{API_URL}/assistants/{assistant_id}/threads", json={}, headers=HEADERS)
            if response.status_code in [200, 201]:
                thread_id = response.json().get("thread_id")
                print(f"Created Thread: {thread_id}")
            else:
                print(f"Failed to create thread: {response.text}")
                return

            # 3. Send Message (Test connectivity)
            print(f"\n3. Sending Test Message to Thread {thread_id}...")
            payload = {
                "content": "Hello, are you ready to analyze documents?",
                "stream": False,
                "memory": "off"
            }
            # Note: API expects multipart/form-data for messages if files involved, but maybe json for text?
            # Docs said multipart body for message.
            # Let's try JSON first as it's cleaner, but fallback to form if needed.
            # Actually docs say "Body: multipart/form-data" in the example request.
            
            # Using form data
            files = {
                "content": (None, "Hello, are you ready to analyze documents?"),
                "stream": (None, "false"),
                "memory": (None, "off"),
                "send_to_llm": (None, "true")
            }
            
            response = await client.post(f"{API_URL}/threads/{thread_id}/messages", data=files, headers=HEADERS) # httpx handles multipart boundary if files dict used
            
            if response.status_code in [200, 201]:
                resp_json = response.json()
                print(f"Message Status: {resp_json.get('status')}")
                print(f"Response: {resp_json.get('content')}")
            else:
                try:
                    # Retry with JSON if 415 or 400
                     print(f"Multipart failed ({response.status_code}), trying JSON...")
                     response = await client.post(f"{API_URL}/threads/{thread_id}/messages", json=payload, headers=HEADERS)
                     print(f"JSON Response: {response.status_code} - {response.text}")
                except Exception:
                    pass

        except Exception as e:
            print(f"❌ Exception: {e}")

if __name__ == "__main__":
    asyncio.run(test_backboard_v2())
