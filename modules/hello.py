#!/usr/bin/env python3
# Example module for userbot
# Simple hello world function

import logging
from typing import Any, Optional

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", 
    level=logging.INFO
)
logger = logging.getLogger(__name__)

async def hello_world(
    client: Any, 
    chat_id: int,
    message_id: int,
    user_id: int,
    reply_user_id: Optional[int] = None
) -> None:
    """
    Simple hello world command.
    
    Args:
        client: TelegramClient instance
        chat_id: The chat ID where the command was used
        message_id: The message ID of the command
        user_id: The user ID who sent the command
        reply_user_id: The user ID of the replied message (if any)
    """
    if reply_user_id:
        message = f"👋 Hello! This message is for user {reply_user_id}, sent by {user_id}"
    else:
        message = f"👋 Hello, World! Command executed by user {user_id}"
    
    await client.edit_message(chat_id, message_id, message)
    logger.info(f"Hello command executed by user {user_id}")