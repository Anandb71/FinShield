from .utils import deep_sql_sink

class BaseHandler:
    def handle_data(self, data: dict):
        # Hop 4 (Inherited execution)
        user_id = data.get("id")
        return deep_sql_sink(user_id)

class SubHandler(BaseHandler):
    # Hop 3 (Resolves to BaseHandler)
    pass\n