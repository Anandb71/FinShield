import asyncio
import os
import sys

# Add app to path
sys.path.append(os.getcwd())

from app.services.universal_pipeline import get_pipeline

async def test_pipeline():
    print("--- Testing Universal Pipeline (Real AI) ---")
    pipeline = get_pipeline()
    
    # Create dummy PDF bytes (header only)
    dummy_pdf = b"%PDF-1.4\n%..." 
    
    print(f"Pipeline Backboard Configured: {pipeline.backboard.api_key[:5]}...")
    
    try:
        # We expect this to fail at Backboard level due to invalid PDF, 
        # BUT it will prove we are hitting the AI service if we get a Backboard error
        # vs a successful "Mock" response.
        print("Sending dummy document...")
        result = await pipeline.process_document(dummy_pdf, "test_invoice.pdf")
        
        print("\n--- Result ---")
        print(f"Type: {result.get('classification', {}).get('type')}")
        print(f"Extracted: {result.get('extracted_fields')}")
        print(f"Status: {result.get('status')}")
        
    except Exception as e:
        print(f"\n--- Exception ---")
        print(e)

if __name__ == "__main__":
    asyncio.run(test_pipeline())
