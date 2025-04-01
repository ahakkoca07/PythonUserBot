#!/usr/bin/env python3
# Authentication module for userbot
# Checks if a user is authorized based on config.ini or temporary list

import logging
from typing import Set, Dict, Any

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", 
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Temporary list of authorized users (can be modified during runtime)
# Dict of user_id: expiry_timestamp (0 for permanent)
temp_authorized_users: Dict[int, int] = {}

async def is_authorized(user_id: int, config: Any) -> bool:
    """
    Check if a user is authorized.
    
    Args:
        user_id: The Telegram user ID
        config: ConfigParser object containing configuration
    
    Returns:
        bool: True if user is authorized, False otherwise
    """
    # Check temporary list first
    if user_id in temp_authorized_users:
        expiry = temp_authorized_users[user_id]
        # 0 means permanent authorization
        if expiry == 0 or expiry > int(time.time()):
            return True
        else:
            # Remove expired authorization
            del temp_authorized_users[user_id]
    
    # Check config.ini
    try:
        authorized_ids = config['Auth']['authorized_users'].split(',')
        authorized_ids = [int(uid.strip()) for uid in authorized_ids if uid.strip()]
        
        if user_id in authorized_ids:
            return True
    except (KeyError, ValueError) as e:
        logger.warning(f"Error reading authorized users from config: {e}")
    
    return False

async def add_temp_auth(user_id: int, duration: int = 0) -> bool:
    """
    Add a user to the temporary authorized users list.
    
    Args:
        user_id: The Telegram user ID
        duration: Duration in seconds (0 for permanent)
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        import time
        expiry = 0 if duration == 0 else int(time.time()) + duration
        temp_authorized_users[user_id] = expiry
        logger.info(f"Added temporary authorization for user {user_id}")
        return True
    except Exception as e:
        logger.error(f"Failed to add temporary authorization: {e}")
        return False

async def remove_temp_auth(user_id: int) -> bool:
    """
    Remove a user from the temporary authorized users list.
    
    Args:
        user_id: The Telegram user ID
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        if user_id in temp_authorized_users:
            del temp_authorized_users[user_id]
            logger.info(f"Removed temporary authorization for user {user_id}")
            return True
        return False
    except Exception as e:
        logger.error(f"Failed to remove temporary authorization: {e}")
        return False

async def get_authorized_users(config: Any) -> Set[int]:
    """
    Get a set of all authorized users (both from config and temporary).
    
    Args:
        config: ConfigParser object containing configuration
    
    Returns:
        Set[int]: Set of authorized user IDs
    """
    authorized = set()
    
    # Add users from config
    try:
        authorized_ids = config['Auth']['authorized_users'].split(',')
        for uid in authorized_ids:
            if uid.strip():
                authorized.add(int(uid.strip()))
    except (KeyError, ValueError) as e:
        logger.warning(f"Error reading authorized users from config: {e}")
    
    # Add temporary users
    import time
    current_time = int(time.time())
    for user_id, expiry in list(temp_authorized_users.items()):
        if expiry == 0 or expiry > current_time:
            authorized.add(user_id)
    
    return authorized