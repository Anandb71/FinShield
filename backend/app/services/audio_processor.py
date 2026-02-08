
import random
from typing import Dict, Any, List
# from app.services.audio_processor import AudioProcessorBase  # Assuming interface exists

class MockAudioProcessor:
    def __init__(self):
        self._chunk_count = 0
        self._transcript_segments = [
            "Hello, am I speaking with Mr. Anand?",
            "This is calling from the Card Protection Department regarding your Visa ending in 4521.",
            "We have detected a suspicious transaction of Rs. 50,000 on your account.",
            "If this was not you, we need to verify your identity immediately to block it.",
            "Please confirm your date of birth for verification based on our records from 1990.",
            "Do not hang up, or your account will be debit frozen within 15 minutes.",
            "To reverse the charge, I need you to download the QuickSupport app now.",
            "Rest assured, this is a secure line monitored by the RBI fraud prevention unit.",
            "Just tell me the OTP you received to cancel the transaction of Rs. 50,000.",
            "Why are you hesitating? Do you want to lose your money, sir?",
        ]
        
        # Scenarios
        self.scenarios = {
            "SAFE": {
                "risk_base": 0.05,
                "intent": "GRIEVANCE",
                "stress": 0.12,
                "transcript": [
                    "Hello, this is verified support.", 
                    "How can I help you with your query today?",
                    "I see you have a dispute about a charge.",
                    "Let me check that for you right now.",
                    "Okay, I can see the transaction of Rs. 500.",
                    "I will raise a ticket for this refund.",
                    "It should reflect in 3-5 business days.",
                    "Is there anything else I can help you with?",
                    "Thank you for banking with us.",
                    "Have a wonderful day."
                ]
            },
            "SCAM": {
                "risk_base": 0.95,
                "intent": "THREAT / FRAUD",
                "stress": 0.85,
                "transcript": self._transcript_segments
            },
            "SUSPICIOUS": {
                "risk_base": 0.45,
                "intent": "COLLECTION",
                "stress": 0.55,
                "transcript": [
                   "Hello, calling about your pending dues.",
                   "You have missed the payment of Rs. 12,000.",
                   "When can we expect this payment to be cleared?",
                   "If you delay, there will be a penalty charge.",
                   "We might have to send an agent to your address.",
                   "Please make the payment by tomorrow 5 PM.",
                   "This will affect your CIBIL score negatively.",
                   "We are offering a settlement if you pay now.",
                   "Do not ignore these calls, sir.",
                   "Pay immediately to avoid legal action."
                ]
            }
        }
        
        self.current_scenario = "SCAM" # Default for now, can be changed via "Wizard" injection potentially

    async def process_chunk(self, audio_bytes: bytes) -> Dict[str, Any]:
        self._chunk_count += 1
        
        # Determine scenario based on external injection (not implemented here yet, just random or fixed)
        # For demo, let's rotate or stick to one. 
        # Actually, let's pick a segment based on chunk count.
        
        scenario_data = self.scenarios.get(self.current_scenario, self.scenarios["SCAM"])
        transcript_list = scenario_data["transcript"]
        
        # Loop through transcript
        idx = (self._chunk_count - 1) % len(transcript_list)
        transcript_text = transcript_list[idx]
        
        # Mock Logic
        risk_score = scenario_data["risk_base"] + random.uniform(-0.05, 0.05)
        risk_score = max(0.0, min(1.0, risk_score))
        
        return {
            "risk_score": round(risk_score, 3),
            "threat_level": "critical" if risk_score > 0.8 else ("high" if risk_score > 0.6 else "safe"),
            "flags": ["Urgency Detected", "Financial Threat"] if risk_score > 0.6 else [],
            "transcript_snippet": transcript_text, # SENDING TRANSCRIPT NOW
            "intent": scenario_data["intent"],
            "stress_score": scenario_data["stress"],
            "chunk_size": len(audio_bytes),
        }

    def set_scenario(self, scenario_name: str):
        if scenario_name in self.scenarios:
            self.current_scenario = scenario_name
            self._chunk_count = 0 # Reset transcript loop
