#!/usr/bin/env python3
# Modules handler for userbot
# Loads and manages modules and processes commands

import asyncio
import configparser
import datetime
import importlib
import inspect
import logging
import os
import sys
import time
from typing import Dict, Any, Callable, List, Optional

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", 
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Dictionary to store loaded module functions
loaded_modules: Dict[str, Callable] = {}

# Import main for START_TIME
import main

async def load_modules(config: Any) -> None:
    """
    Load all modules defined in config.ini.
    
    Args:
        config: ConfigParser object containing configuration
    """
    global loaded_modules
    loaded_modules = {}
    
    # Built-in commands
    loaded_modules["reload"] = reload_config
    loaded_modules["start"] = bot_alive
    loaded_modules["help"] = show_help
    
    if not config.has_section('Commands'):
        logger.warning("No 'Commands' section found in config")
        return
    
    # Load custom modules from ./modules/ directory
    for command, function_path in config['Commands'].items():
        try:
            # Parse the function path (module.function format)
            module_name, function_name = function_path.rsplit('.', 1)
            
            # Make sure the module name has modules. prefix for proper importing
            if not module_name.startswith('modules.'):
                module_name = f'modules.{module_name}'
            
            # Import the module
            module = importlib.import_module(module_name)
            
            # Get the function
            func = getattr(module, function_name)
            
            # Register the command
            loaded_modules[command] = func
            logger.info(f"Loaded command: .{command} -> {function_path}")
            
        except (ValueError, ImportError, AttributeError) as e:
            logger.error(f"Failed to load command {command}: {e}")

async def process_command(
    client: Any, 
    command: str, 
    chat_id: int,
    user_id: int,
    message_id: int,
    reply_user_id: Optional[int],
    reply_message_id: Optional[int],
    config: Any
) -> None:
    """
    Process a command by running the appropriate function.
    
    Args:
        client: TelegramClient instance
        command: The command (without the dot)
        chat_id: The chat ID where the command was used
        user_id: The user ID who sent the command
        message_id: The message ID of the command
        reply_user_id: The user ID of the replied message (if any)
        reply_message_id: The message ID of the replied message (if any)
        config: ConfigParser object containing configuration
    """
    if command in loaded_modules:
        func = loaded_modules[command]
        try:
            # Check function signature to send appropriate arguments
            sig = inspect.signature(func)
            params = sig.parameters
            
            kwargs = {
                'client': client,
                'chat_id': chat_id,
                'user_id': user_id,
                'message_id': message_id,
                'reply_user_id': reply_user_id,
                'reply_message_id': reply_message_id,
                'config': config
            }
            
            # Filter kwargs to only include parameters the function accepts
            filtered_kwargs = {k: v for k, v in kwargs.items() if k in params}
            
            # Run the function
            await func(**filtered_kwargs)
            logger.info(f"Executed command: {command}")
            
        except Exception as e:
            logger.error(f"Error executing command {command}: {e}")
            # Optionally notify the user about the error
            await client.edit_message(chat_id, message_id, f"Error executing command: {e}")
    else:
        logger.warning(f"Unknown command: {command}")
        await client.edit_message(chat_id, message_id, f"Unknown command: {command}")

# Built-in commands

async def reload_config(
    client: Any, 
    chat_id: int,
    message_id: int,
    config: Any
) -> None:
    """
    Reload the config file.
    
    Args:
        client: TelegramClient instance
        chat_id: The chat ID where the command was used
        message_id: The message ID of the command
        config: ConfigParser object containing configuration
    """
    try:
        # Reload config file
        config.read('config.ini')
        
        # Reload modules
        await load_modules(config)
        
        # Edit the message
        await client.edit_message(
            chat_id, 
            message_id, 
            "✅ Configuration and modules reloaded successfully!"
        )
        logger.info("Configuration and modules reloaded")
    except Exception as e:
        await client.edit_message(
            chat_id, 
            message_id, 
            f"❌ Error reloading configuration: {e}"
        )
        logger.error(f"Error reloading configuration: {e}")

async def bot_alive(
    client: Any, 
    chat_id: int,
    message_id: int
) -> None:
    """
    Show that the userbot is alive and display uptime.
    
    Args:
        client: TelegramClient instance
        chat_id: The chat ID where the command was used
        message_id: The message ID of the command
    """
    uptime = datetime.datetime.now() - main.START_TIME
    days, remainder = divmod(uptime.total_seconds(), 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)
    
    uptime_str = f"{int(days)}d {int(hours)}h {int(minutes)}m {int(seconds)}s"
    
    message = f"🤖 **Userbot is alive!**\n\n" \
              f"⏱️ **Uptime:** {uptime_str}\n" \
              f"🔌 **Active modules:** {len(loaded_modules)}"
    
    await client.edit_message(chat_id, message_id, message)

async def show_help(
    client: Any, 
    chat_id: int,
    message_id: int
) -> None:
    """
    Show available commands.
    
    Args:
        client: TelegramClient instance
        chat_id: The chat ID where the command was used
        message_id: The message ID of the command
    """
    commands = sorted(loaded_modules.keys())
    
    built_in = ["reload", "start", "help"]
    custom = [cmd for cmd in commands if cmd not in built_in]
    
    message = "📚 **Available Commands:**\n\n"
    
    # Built-in commands
    message += "**Built-in Commands:**\n"
    message += "`.reload` - Reload the configuration and modules\n"
    message += "`.start` - Show userbot status and uptime\n"
    message += "`.help` - Show this help message\n\n"
    
    # Custom commands
    if custom:
        message += "**Custom Commands:**\n"
        for cmd in custom:
            message += f"`.{cmd}`\n"
    else:
        message += "No custom commands available."
    
    await client.edit_message(chat_id, message_id, message)