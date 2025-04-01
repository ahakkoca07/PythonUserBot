#!/usr/bin/env python3
# Main Python file for userbot
# Handles receiving and processing commands

import asyncio
import configparser
import datetime
import importlib
import logging
import os
import sys
import time
from typing import Optional, Tuple, Dict, Any

from telethon import TelegramClient, events
from telethon.tl.types import User, PeerUser

import auth
import modules

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", 
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Read configuration
config = configparser.ConfigParser()
config.read('config.ini')

# Telegram API credentials
API_ID = config['Telegram']['api_id']
API_HASH = config['Telegram']['api_hash']
SESSION_NAME = config['Telegram'].get('session_name', 'userbot')

# Start time for uptime calculation
START_TIME = datetime.datetime.now()

# Initialize client
client = TelegramClient(SESSION_NAME, API_ID, API_HASH)

# Function to extract command details
async def extract_command_details(event) -> Tuple[str, int, int, Optional[int], Optional[int]]:
    """Extract command details from the event."""
    text = event.raw_text[1:]  # Remove the dot
    command = text.split()[0]  # Get the first word after dot
    
    chat_id = event.chat_id
    message_id = event.id
    
    reply = await event.get_reply_message()
    reply_user_id = None
    reply_message_id = None
    
    if reply:
        reply_message_id = reply.id
        if reply.sender:
            if isinstance(reply.sender, User):
                reply_user_id = reply.sender.id
            elif isinstance(reply.sender, PeerUser):
                reply_user_id = reply.sender.user_id
    
    return command, chat_id, message_id, reply_user_id, reply_message_id

# Handler for commands (messages starting with '.')
@client.on(events.NewMessage(pattern=r'\.(\w+)'))
async def handle_command(event):
    """Handle commands starting with '.'"""
    # Extract the command and parameters
    command, chat_id, message_id, reply_user_id, reply_message_id = await extract_command_details(event)
    
    # Check if the user is authorized
    user_id = event.sender_id
    if not await auth.is_authorized(user_id, config):
        logger.warning(f"Unauthorized user {user_id} tried to use command: {command}")
        return
    
    # Process the command
    await modules.process_command(
        client, command, chat_id, user_id, message_id, reply_user_id, reply_message_id, config
    )

async def main():
    """Main function to start the userbot."""
    # Load modules
    await modules.load_modules(config)
    
    # Start the client
    await client.start()
    logger.info("Userbot started successfully!")
    
    # Keep the client running
    await client.run_until_disconnected()

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Userbot stopped by user")
        sys.exit(0)