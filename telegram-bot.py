from telegram import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    ReplyKeyboardMarkup,
    KeyboardButton,
)
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    filters,
    CallbackQueryHandler,
    ConversationHandler,
)
from config import telegram_api_key
from gemini_test import ask_gemini  # فایل gemini_test که درست شد
import asyncio

GEMINI_CHAT = 1

# ذخیره session کاربران
user_sessions = {}

# دکمه Persistent Menu
persistent_keyboard = ReplyKeyboardMarkup(
    [[KeyboardButton("شروع چت جدید")]],
    resize_keyboard=True,
    one_time_keyboard=False,
)


# /start
async def start(update, context):
    chat_id = update.effective_chat.id
    user_sessions[chat_id] = {"active": True, "history": []}

    keyboard = [
        [InlineKeyboardButton("شروع گفتگو با Gemini", callback_data="start_gemini")],
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await context.bot.send_message(
        chat_id=chat_id,
        text="سلام! من ربات Gemini(Sinus) 🤖 هستم.\nبرای شروع یکی از گزینه‌ها را انتخاب کنید:",
        reply_markup=reply_markup,
    )
    await context.bot.send_message(
        chat_id=chat_id,
        text="همیشه می‌توانید از منوی پایین صفحه 'شروع چت جدید' را بزنید.",
        reply_markup=persistent_keyboard,
    )


# هندلر دکمه Inline
async def button_handler(update, context):
    query = update.callback_query
    await query.answer()
    chat_id = query.message.chat.id

    if query.data == "start_gemini":
        user_sessions[chat_id] = {"active": True, "history": []}
        await context.bot.send_message(
            chat_id=chat_id,
            text="حالا متن خود را ارسال کنید تا به Gemini فرستاده شود.",
            reply_markup=persistent_keyboard,
        )
        return GEMINI_CHAT


# هندلر پیام‌ها
async def handle_messages(update, context):
    chat_id = update.effective_chat.id
    text = update.message.text

    # اگر کاربر روی Persistent Menu زد
    if text == "شروع چت جدید":
        user_sessions[chat_id] = {"active": True, "history": []}
        await update.message.reply_text(
            "چت جدید آغاز شد! حالا می‌توانید پیام خود را ارسال کنید.",
            reply_markup=persistent_keyboard,
        )
        return GEMINI_CHAT

    # بررسی وضعیت session
    if not user_sessions.get(chat_id, {}).get("active"):
        await update.message.reply_text(
            "لطفاً ابتدا 'شروع چت جدید' را بزنید.", reply_markup=persistent_keyboard
        )
        return GEMINI_CHAT

    # اضافه کردن پیام کاربر به تاریخچه
    user_sessions[chat_id]["history"].append({"role": "user", "content": text})

    # ارسال به Gemini و دریافت پاسخ
    response_text = await ask_gemini(user_sessions[chat_id]["history"])

    # اضافه کردن پاسخ Gemini به تاریخچه
    user_sessions[chat_id]["history"].append(
        {"role": "assistant", "content": response_text}
    )

    await update.message.reply_text(response_text, reply_markup=persistent_keyboard)

    return GEMINI_CHAT


# ConversationHandler
conv_handler = ConversationHandler(
    entry_points=[CallbackQueryHandler(button_handler, pattern="start_gemini")],
    states={
        GEMINI_CHAT: [MessageHandler(filters.TEXT & ~filters.COMMAND, handle_messages)]
    },
    fallbacks=[],
)

# اجرای ربات
app = Application.builder().token(telegram_api_key).build()
app.add_handler(CommandHandler("start", start))
app.add_handler(conv_handler)

app.run_polling()
