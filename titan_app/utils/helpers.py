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
    return None\n