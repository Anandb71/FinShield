from .user_manager import get_user_profile
from ..utils.helpers import unsafe_deserialize

def process_payment(payload: dict):
    # 1 hop
    user_id = payload.get("id", "")
    metadata = payload.get("metadata", "")
    
    # Branch A: SQLi path
    profile = get_user_profile(user_id)
    
    # Branch B: RCE path
    parsed_meta = unsafe_deserialize(metadata)
    
    return {"status": "processed", "user": profile}\n