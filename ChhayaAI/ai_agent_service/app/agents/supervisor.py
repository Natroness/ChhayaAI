from app.agents.llm_client import classify_map_or_data
from app.agents.map_agent import handle_map_task
from app.agents.data_agent import handle_data_task
from app.database.redis_client import get_chat_history


def process_user_request(user_id, session_id, query, lat, lon, trigger_type):
    """
    The CEO Logic: Decides who works on the request.
    """

    # 1. GET CONTEXT: What were we talking about?
    history = get_chat_history(session_id)

    # 2. HARD LOGIC: Check for the Emergency Button
    if trigger_type == "EMERGENCY_BUTTON":
        return handle_map_task(query, lat, lon, emergency=True)

    # 3. SOFT LOGIC: Classify MAP vs DATA (dedicated prompt + keyword fallback on API failure)
    intent = classify_map_or_data(query)

    # 4. DELEGATION: The Switchboard
    if intent == "MAP":
        # User needs the Spanner Graph
        response = handle_map_task(query, lat, lon)
    else:
        # User just wants to talk or needs general info
        response = handle_data_task(query, history)

    return response
