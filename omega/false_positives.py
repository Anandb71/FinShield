def log_security_rules():
    # These are string literals, NOT executable sinks.
    # The AST should NOT flag these if the generator bug is fixed.
    rule1 = "Never use os.system(user_input)"
    rule2 = 'Avoid pickle.loads(data) in production'
    rule3 = """
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    """
    print("Logged rules.")\n