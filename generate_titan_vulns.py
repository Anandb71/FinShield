import os

base_dir = "titan_app"
folders = ["core", "services", "utils", "legacy"]

for folder in folders:
    os.makedirs(os.path.join(base_dir, folder), exist_ok=True)
    if folder != "legacy":
        open(os.path.join(base_dir, folder, "__init__.py"), 'w').close()

files = {
    "core/router.py": """
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
    return login_user(username)
""",
    "services/payment.py": """
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
    
    return {"status": "processed", "user": profile}
""",
    "services/user_manager.py": """
from ..utils.helpers import execute_db_query

def get_user_profile(user_id: str):
    # 2 hops
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    return execute_db_query(query)
""",
    "services/system_tasks.py": """
from ..utils.helpers import run_cmd
import subprocess

def fetch_logs(query: str):
    # 1 hop to helper
    cmd = "cat /var/log/sys.log | grep " + query
    return run_cmd(cmd)

def run_legacy_job(payload: str):
    # 1 hop directly to subprocess but targeting a vulnerable JS file
    # Cross-language execution trace
    proc = subprocess.run(["node", "titan_app/legacy/old_api.js", payload], capture_output=True)
    return proc.stdout.decode()
""",
    "services/auth.py": """
from ..utils.helpers import execute_db_query

def login_user(username: str):
    # 1 hop
    query = f"SELECT * FROM credentials WHERE username = '{username}'"
    return execute_db_query(query)
""",
    "utils/helpers.py": """
import sqlite3
import os
import pickle
import base64

def execute_db_query(query: str):
    # SINK: Database Access (SQLi)
    # 3 hops from checkout, 2 hops from login
    conn = sqlite3.connect("titan.db")
    cursor = conn.cursor()
    cursor.execute(query)
    return cursor.fetchall()

def run_cmd(cmd: str):
    # SINK: Arbitrary Code Execution
    # 2 hops from get_logs
    os.system(cmd)
    return "Executed"

def unsafe_deserialize(data: str):
    # SINK: Insecure Deserialization
    # 2 hops from checkout
    if data:
        return pickle.loads(base64.b64decode(data))
    return None
""",
    "legacy/old_api.js": """
// Vulnerable Legacy JS
const args = process.argv.slice(2);
const payload = args[0];

if (payload) {
    // SINK: Arbitrary Code Execution in JS
    console.log(eval(payload));
}
"""
}

for filepath, content in files.items():
    with open(os.path.join(base_dir, filepath), "w") as f:
        f.write(content.strip() + "\\n")
