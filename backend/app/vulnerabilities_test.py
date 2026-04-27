import os
import sqlite3
import subprocess
import pickle
import hashlib

# LOW: Hardcoded Secret (sometimes medium/high depending on context, but let's say it's an API key)
# A generic api key to trigger scanner
API_KEY = "12345-ABCDE-67890-FGHIJ"
SUPER_SECRET_PASSWORD = "Password123!"

def process_user_data(user_input):
    # CRITICAL: Command Injection
    # Using shell=True with user input directly
    os.system(f"ping -c 1 {user_input}")
    
    subprocess.call("ping -c 1 " + user_input, shell=True)

def get_user(db_path, username):
    # CRITICAL: SQL Injection
    # Direct string formatting into a SQL query
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE username = '{username}'"
    cursor.execute(query)
    return cursor.fetchall()

def load_data(file_data):
    # HIGH: Insecure Deserialization
    # Using pickle.loads on unverified data
    return pickle.loads(file_data)

def read_file(filename):
    # HIGH: Path Traversal
    # Opening a file path directly from user input
    base_path = "/var/www/html/downloads/"
    with open(base_path + filename, 'r') as f:
        return f.read()

def generate_hash(password):
    # MEDIUM: Weak Cryptography
    # Using MD5 for hashing passwords
    m = hashlib.md5()
    m.update(password.encode('utf-8'))
    return m.hexdigest()

def render_page(user_name):
    # MEDIUM / HIGH: Cross-Site Scripting (XSS)
    # Direct reflection of user input in HTML context without sanitization
    html_template = "<html><body><h1>Welcome, %s!</h1></body></html>" % user_name
    return html_template

# LOW: Missing secure flag / HttpOnly flag example
def set_insecure_cookie(response, session_id):
    # Just an example function simulating setting a cookie insecurely
    response.set_cookie('session_id', session_id, secure=False, httponly=False)

def catch_all_exception():
    # LOW: Broad Exception Catching
    try:
        do_something_risky()
    except Exception as e:
        pass # Ignored exception
