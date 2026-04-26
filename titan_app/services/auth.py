from ..utils.helpers import execute_db_query

def login_user(username: str):
    # 1 hop
    query = f"SELECT * FROM credentials WHERE username = '{username}'"
    return execute_db_query(query)\n