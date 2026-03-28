import os
from groq import Groq

SYSTEM_PROMPT = """
You are a Geo-Spatial AI Assistant.
Your goal is to help users navigate safely and answer local questions.

RULES:
1. If the user asks for a route, output ONLY the start and end points in JSON format.
2. If the user asks a general question, be concise (under 3 sentences).
3. Do not make up facts about locations you don't know.
4. Always respond in a professional, helpful tone.
"""

# 1. Initialize the client (Keys come from environment variables)
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

def get_ai_response(user_input: str):
    """
    Calls the Llama-3-8b model with robust error handling.
    """
    try:
        # 2. The API Call
        completion = client.chat.completions.create(
            model="llama3-8b-8192",  # The efficient choice
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_input}
            ],
            temperature=0.5, # Lower temperature = more factual/less creative
            max_tokens=500
        )
        
        # 3. Extract the text
        return completion.choices[0].message.content

    except Exception as e:
        # 4. Fallback Logic: If the API fails, return a safe message
        print(f"ERROR calling Groq: {e}")
        return "I'm having trouble thinking right now. Please check your connection."