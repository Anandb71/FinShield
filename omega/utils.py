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
    return func(arg)\n