from fastapi import APIRouter
from .services import process_request, execute_lambda_task

router = APIRouter()

@router.post("/api/omega/process")
async def process(data: dict):
    # Hop 1
    return process_request(data)

@router.post("/api/omega/task")
async def task(payload: str):
    # Hop 1
    return execute_lambda_task(payload)\n