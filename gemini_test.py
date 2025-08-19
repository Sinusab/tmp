from google import genai
from config import gemini_api_key

client = genai.Client(api_key=gemini_api_key)


async def ask_gemini(messages):
    """
    messages: لیست دیکشنری‌های {"role": "...", "content": "..."}
    """

    # فقط متن کاربر را استخراج می‌کنیم
    contents = [msg["content"] for msg in messages]

    response = client.models.generate_content(
        model="gemini-2.5-flash", contents=contents  # لیست رشته‌ها
    )

    return response.result[0].output_text
