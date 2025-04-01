# Modular Python Userbot

A modular Telegram userbot with dynamic command loading and user authentication.

## Directory Structure

```
.
├── main.py              # Main file for command handling
├── auth.py              # Authentication module
├── modules.py           # Module manager with built-in commands
├── config.ini           # Configuration file
└── mymodules/             # Custom module directory
    ├── hello.py         # Example hello module
    └── echo.py          # Example echo module
```

## Features

- **Command Processing**: Handles commands that start with `.`
- **Authentication**: Checks if users are authorized via config.ini or temporary list
- **Modular Structure**: Dynamically loads modules from the `./modules/` directory
- **Built-in Commands**:
  - `.start` - Shows userbot status and uptime
  - `.reload` - Reloads the config file and modules
  - `.help` - Lists all available commands

## Setup

1. Install required packages:
   ```bash
   pip install telethon
   ```

2. Configure your `config.ini` file:
   - Add your Telegram API credentials
   - Add authorized user IDs
   - Define command mappings

3. Create custom modules in the `./mymodules/` directory

4. Run the userbot:
   ```bash
   python main.py
   ```

## Creating Custom Modules

1. Create a new Python file in the `./mymodules/` directory
2. Define your async function with parameters:
   ```python
   async def your_function(client, chat_id, user_id, message_id, reply_user_id=None, reply_message_id=None):
       # Your code here
   ```
3. Add the command mapping to `config.ini`:
   ```ini
   [Commands]
   command_name = module_name.your_function
   ```

## Usage

Once running, the userbot will process commands that start with `.` in any chat. Only authorized users can use the commands.

Example usage:
- `.start` - Check if the bot is alive and see uptime
- `.reload` - Reload configuration and modules
- `.help` - Show all available commands
- `.hello` - Run the example hello function
- `.echo text` - Echo back the text after the command

## Todo
- [ ] Instead of directly pulling the files, pull the latest release.
- [ ] Add complete version checking for updating.
- [ ] Create run_bot files.
