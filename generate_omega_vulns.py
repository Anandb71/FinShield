import os

base_dir = "omega"
os.makedirs(base_dir, exist_ok=True)
open(os.path.join(base_dir, "__init__.py"), 'w').close()

files = {
    "router.py": """
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
    return execute_lambda_task(payload)
""",
    "services.py": """
from .base_models import SubHandler
from .utils import apply_function

def process_request(data: dict):
    # Hop 2 (OOP Test)
    handler = SubHandler()
    return handler.handle_data(data)

def execute_lambda_task(payload: str):
    # Hop 2 (Lambda / Higher Order Function Test)
    import os as system_lib
    # Passing a lambda that contains a sink
    action = lambda x: system_lib.system(x)
    return apply_function(action, payload)
""",
    "base_models.py": """
from .utils import deep_sql_sink

class BaseHandler:
    def handle_data(self, data: dict):
        # Hop 4 (Inherited execution)
        user_id = data.get("id")
        return deep_sql_sink(user_id)

class SubHandler(BaseHandler):
    # Hop 3 (Resolves to BaseHandler)
    pass
""",
    "utils.py": """
import sqlite3

def deep_sql_sink(user_id: str):
    # Hop 5 (The Sink)
    conn = sqlite3.connect("omega.db")
    cursor = conn.cursor()
    # SQLi
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    return cursor.fetchall()

def apply_function(func, arg):
    # Hop 3 (Executes the passed lambda)
    return func(arg)
""",
    "false_positives.py": """
def log_security_rules():
    # These are string literals, NOT executable sinks.
    # The AST should NOT flag these if the generator bug is fixed.
    rule1 = "Never use os.system(user_input)"
    rule2 = 'Avoid pickle.loads(data) in production'
    rule3 = \"\"\"
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    \"\"\"
    print("Logged rules.")
"""
}

for filepath, content in files.items():
    with open(os.path.join(base_dir, filepath), "w") as f:
        f.write(content.strip() + "\\n")
