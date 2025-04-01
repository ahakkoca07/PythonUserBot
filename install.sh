#!/data/data/com.termux/files/usr/bin/bash
# Installation script for PythonUserBot on Android using Termux
# Usage: ./install_android.sh [--update]

set -e

# Repository information
REPO_OWNER="ahakkoca07"
REPO_NAME="PythonUserBot"
REPO_BASE="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main"
FILELIST_URL="$REPO_BASE/filelist.txt"
BOT_DIR="$HOME/PythonUserBot"
VENV_DIR="$BOT_DIR/venv"
CRON_FILE="$HOME/.termux/boot/start-pythonuserbot.sh"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if this is an update
UPDATE=false
for arg in "$@"; do
  if [[ "$arg" == "--update" ]]; then
    UPDATE=true
  fi
done

# Function to check for dependencies
check_dependencies() {
  echo -e "${YELLOW}Checking dependencies...${NC}"
  
  DEPS=("python" "pip" "git" "curl")
  MISSING_DEPS=()
  
  for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      MISSING_DEPS+=("$dep")
    fi
  done
  
  if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${YELLOW}Installing missing dependencies: ${MISSING_DEPS[*]}${NC}"
    pkg update
    pkg install -y "${MISSING_DEPS[@]}"
  fi
  
  # Additional Android-specific packages
  pkg install -y termux-services
}

# Function to create or update the virtual environment
setup_venv() {
  if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python -m venv "$VENV_DIR"
  elif [ "$UPDATE" = true ]; then
    echo -e "${YELLOW}Updating virtual environment...${NC}"
  fi
  
  source "$VENV_DIR/bin/activate"
  pip install --upgrade pip
  
  # Install or update requirements
  echo -e "${YELLOW}Installing requirements...${NC}"
  pip install --upgrade telethon configparser
  
  # Check if requirements.txt exists in repo and install from it
  if curl --output /dev/null --silent --head --fail "$REPO_BASE/requirements.txt"; then
    curl -s "$REPO_BASE/requirements.txt" -o "$BOT_DIR/requirements.txt"
    pip install --upgrade -r "$BOT_DIR/requirements.txt"
  fi
}

# Function to download file list and files from repo
download_files() {
  echo -e "${YELLOW}Downloading files from repository...${NC}"
  
  mkdir -p "$BOT_DIR/modules"
  
  # Download filelist.txt
  if ! curl -s "$FILELIST_URL" -o "$BOT_DIR/filelist.txt"; then
    echo -e "${RED}Failed to download file list. Check your internet connection or repository URL.${NC}"
    exit 1
  fi
  
  # Read file list and download each file
  while IFS= read -r file || [[ -n "$file" ]]; do
    # Skip empty lines and comments
    [[ -z "$file" || "$file" == \#* ]] && continue
    
    # Determine destination path
    dest_file="$BOT_DIR/$file"
    dest_dir=$(dirname "$dest_file")
    
    # Create directory if it doesn't exist
    mkdir -p "$dest_dir"
    
    # Download the file
    echo "Downloading $file..."
    if ! curl -s "$REPO_BASE/$file" -o "$dest_file"; then
      echo -e "${RED}Failed to download $file${NC}"
    else
      echo -e "${GREEN}Downloaded $file${NC}"
      # Make executable if it's a script
      if [[ "$file" == *.sh || "$file" == "main.py" ]]; then
        chmod +x "$dest_file"
      fi
    fi
  done < "$BOT_DIR/filelist.txt"
}

# Function to create default config if it doesn't exist
create_default_config() {
  CONFIG_FILE="$BOT_DIR/config.ini"
  
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Creating default config.ini...${NC}"
    cat > "$CONFIG_FILE" << EOF
[Telegram]
# Your Telegram API credentials
api_id = YOUR_API_ID
api_hash = YOUR_API_HASH
session_name = userbot

[Auth]
# Comma-separated list of authorized user IDs
authorized_users = YOUR_USER_ID

[Commands]
# Define command mappings in format:
# command = module.function
# The module will be loaded from ./modules/ directory
hello = hello.hello_world
echo = echo.echo_text

[Settings]
# General settings
debug = false
log_level = INFO
EOF
    echo -e "${GREEN}Created default config.ini. Please edit it with your details.${NC}"
    echo -e "${YELLOW}You need to update the config.ini file with your Telegram API credentials and user ID.${NC}"
  fi
}

# Function to setup autostart using Termux boot
setup_autostart() {
  echo -e "${YELLOW}Setting up autostart...${NC}"
  
  # Ensure the boot directory exists
  mkdir -p "$HOME/.termux/boot/"
  
  # Create boot script
  cat > "$CRON_FILE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# Autostart script for PythonUserBot

# Wait for network connectivity
sleep 20

# Change to bot directory
cd "$BOT_DIR"

# Start the bot in the background
source "$VENV_DIR/bin/activate" && python main.py >> "$BOT_DIR/bot.log" 2>&1 &
EOF
  
  chmod +x "$CRON_FILE"
  
  # Enable termux-boot if not already
  pkg install -y termux-boot
  
  # Start service
  if [ "$UPDATE" = true ]; then
    echo -e "${YELLOW}Restarting bot...${NC}"
    pkill -f "$BOT_DIR/main.py" || true
    sleep 2
    "$CRON_FILE" &
  else
    echo -e "${YELLOW}Starting bot...${NC}"
    "$CRON_FILE" &
  fi
}

# Main function
main() {
  echo -e "${GREEN}========================================${NC}"
  if [ "$UPDATE" = true ]; then
    echo -e "${GREEN}Updating PythonUserBot...${NC}"
  else
    echo -e "${GREEN}Installing PythonUserBot...${NC}"
  fi
  echo -e "${GREEN}========================================${NC}"
  
  check_dependencies
  
  # Create directory if it doesn't exist (first install)
  if [ ! -d "$BOT_DIR" ]; then
    echo -e "${YELLOW}Creating bot directory at $BOT_DIR...${NC}"
    mkdir -p "$BOT_DIR"
  fi
  
  download_files
  setup_venv
  create_default_config
  setup_autostart
  
  echo -e "${GREEN}========================================${NC}"
  if [ "$UPDATE" = true ]; then
    echo -e "${GREEN}PythonUserBot updated successfully!${NC}"
  else
    echo -e "${GREEN}PythonUserBot installed successfully!${NC}"
    echo -e "${YELLOW}Please edit $BOT_DIR/config.ini with your Telegram API credentials and user ID before starting.${NC}"
    echo -e "${YELLOW}Note: On Android, you may need to enable the 'Run at boot' permission for Termux in Android settings.${NC}"
  fi
  echo -e "${GREEN}========================================${NC}"
}

main