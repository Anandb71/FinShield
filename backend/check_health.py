import requests
import sys

def check_endpoint(url):
    print(f"Checking {url}...")
    try:
        response = requests.get(url, timeout=5)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:100]}...")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

urls = [
    "http://127.0.0.1:8000/",
    "http://127.0.0.1:8000/api/v1/health",
    "http://localhost:8000/",
    "http://localhost:8000/api/v1/health"
]

success = False
for url in urls:
    if check_endpoint(url):
        success = True

sys.exit(0 if success else 1)
