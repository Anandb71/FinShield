from ..utils.helpers import execute_db_query

def get_user_profile(user_id: str):
    # 2 hops
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    return execute_db_query(query)\n