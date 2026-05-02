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
    return apply_function(action, payload)\n