from fastapi import APIRouter
from ..services.payment import process_payment
from ..services.system_tasks import fetch_logs, run_legacy_job
from ..services.auth import login_user

router = APIRouter()

@router.post("/api/v1/checkout")
async def checkout(user_payload: dict):
    # Entry Point 1
    return process_payment(user_payload)

@router.get("/api/v1/system/logs")
async def get_logs(query_string: str):
    # Entry Point 2
    return fetch_logs(query_string)

@router.post("/api/v1/legacy/execute")
async def execute_legacy(payload: str):
    # Entry Point 3
    return run_legacy_job(payload)

@router.post("/api/v1/auth/login")
async def login(username: str):
    # Entry Point 4
    return login_user(username)\n