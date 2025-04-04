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

# Function to configure logging based on config settings
def setup_logging(config):
    """Set up logging configuration based on config settings."""
    # Get log level from config or default to INFO
    log_level_str = config['Settings'].get('log_level', 'INFO').upper()
    log_level = getattr(logging, log_level_str, logging.INFO)
    
    # Get log file path if specified
    log_file = config['Settings'].get('log_file', None)
    
    # Configure logging
    logging_config = {
        'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        'level': log_level,
    }
    
    # Add file handler if log file is specified
    if log_file:
        logging_config['filename'] = log_file
        logging_config['filemode'] = 'a'  # Append mode
    
    # Apply logging configuration
    logging.basicConfig(**logging_config)
    
    logger = logging.getLogger(__name__)
    
    # Log the configured settings
    logger.info(f"Logging initialized with level: {logging.getLevelName(log_level)}")
    if debug_mode:
        logger.debug("Debug mode enabled")
    
    return logger

# Read configuration
config = configparser.ConfigParser()
config.read('config.ini')

# Configure logging
logger = setup_logging(config)

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
    
    logger.debug(f"Command extracted: {command}, chat_id: {chat_id}, message_id: {message_id}")
    if reply:
        logger.debug(f"Reply info - message_id: {reply_message_id}, user_id: {reply_user_id}")
    
    return command, chat_id, message_id, reply_user_id, reply_message_id

# Handler for commands (messages starting with '.')
@client.on(events.NewMessage(pattern=r'\.(\w+)'))
async def handle_command(event):
    """Handle commands starting with '.'"""
    # Extract the command and parameters
    command, chat_id, message_id, reply_user_id, reply_message_id = await extract_command_details(event)
    
    # Check if the user is authorized
    user_id = event.sender_id
    is_authorized = await auth.is_authorized(user_id, config)
    
    if not is_authorized:
        logger.warning(f"Unauthorized user {user_id} tried to use command: {command}")
        return
    
    logger.info(f"Processing command '{command}' from user {user_id}")
    
    # Process the command
    try:
        await modules.process_command(
            client, command, chat_id, user_id, message_id, reply_user_id, reply_message_id, config
        )
        logger.debug(f"Command '{command}' processed successfully")
    except Exception as e:
        logger.error(f"Error processing command '{command}': {str(e)}", exc_info=True)

async def main():
    """Main function to start the userbot."""
    logger.info("Starting userbot...")
    
    # Log configuration details in debug mode
    if logger.level <= logging.DEBUG:
        # Don't log sensitive information like API hash
        safe_config = {section: {k: '***' if k in ['api_hash'] else v 
                               for k, v in config[section].items()} 
                      for section in config.sections()}
        logger.debug(f"Configuration: {safe_config}")
    
    # Load modules
    try:
        await modules.load_modules(config)
        logger.info("Modules loaded successfully")
    except Exception as e:
        logger.error(f"Error loading modules: {str(e)}", exc_info=True)
        sys.exit(1)
    
    # Start the client
    try:
        await client.start()
        logger.info("Userbot started successfully!")
    except Exception as e:
        logger.critical(f"Failed to start Telegram client: {str(e)}", exc_info=True)
        sys.exit(1)
    
    # Keep the client running
    try:
        await client.run_until_disconnected()
    except Exception as e:
        logger.critical(f"Unexpected error: {str(e)}", exc_info=True)
    finally:
        logger.info("Userbot disconnected")

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Userbot stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.critical(f"Fatal error: {str(e)}", exc_info=True)
        sys.exit(1)