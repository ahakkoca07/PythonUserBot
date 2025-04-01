#!/usr/bin/env python3
# Echo module for userbot
# Echoes back the text after the command

import logging
from typing import Any

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", 
    level=logging.INFO
)
logger = logging.getLogger(__name__)

async def echo_text(
    client: Any, 
    chat_id: int,
    message_id: int,
    user_id: int
) -> None:
    """
    Echo back the text after the command.
    
    Args:
        client: TelegramClient instance
        chat_id: The chat ID where the command was used
        message_id: The message ID of the command
        user_id: The user ID who sent the command
    """
    # Get the original message
    message = await client.get_messages(chat_id, ids=message_id)
    
    # Extract the text after the .echo command
    # Split by whitespace, take everything after the first word (.echo)
    command_text = message.text
    parts = command_text.split(maxsplit=1)
    
    if len(parts) > 1:
        text_to_echo = parts[1]  # Everything after .echo
        await client.edit_message(chat_id, message_id, text_to_echo)
    else:
        await client.edit_message(chat_id, message_id, "⚠️ No text to echo! Usage: .echo your text here")
    
    logger.info(f"Echo command executed by user {user_id}")
