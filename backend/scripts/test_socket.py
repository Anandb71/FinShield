
import asyncio
import websockets
import json
import random
import time

async def test_audio_stream():
    client_id = f"test_client_{random.randint(1000, 9999)}"
    uri = f"ws://localhost:8000/ws/stream/{client_id}"
    
    print(f"🔌 Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            # Wait for connection message
            response = await websocket.recv()
            print(f"✅ Server: {response}")
            
            print("🎙️ Starting simulated audio stream...")
            
            # Simulate streaming 10 chunks of audio
            for i in range(1, 11):
                # Simulate Int16 PCM audio chunk (random bytes)
                # 16000Hz * 0.1s * 2 bytes = 3200 bytes
                chunk = random.randbytes(3200)
                
                await websocket.send(chunk)
                print(f"📤 Sent chunk #{i} ({len(chunk)} bytes)")
                
                # Wait for analysis response
                response = await websocket.recv()
                data = json.loads(response)
                
                print(f"📥 Analysis: Risk={data.get('risk_score'):.2f} | Level={data.get('threat_level')} | Flags={data.get('flags')}")
                
                # Simulate real-time delay
                await asyncio.sleep(0.1)
                
            print("⏹️ Stream finished.")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_audio_stream())
