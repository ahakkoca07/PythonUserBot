#!/bin/bash
# Installation script for PythonUserBot on Linux systems
# Usage: ./install.sh [--update]

set -e

# Repository information
REPO_OWNER="ahakkoca07"
REPO_NAME="PythonUserBot"
REPO_BASE="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main"
FILELIST_URL="$REPO_BASE/filelist_linux.txt"
BOT_DIR="$HOME/PythonUserBot"
VENV_DIR="$BOT_DIR/venv"
SYSTEMD_SERVICE_NAME="pythonuserbot.service"
SYSTEMD_SERVICE_PATH="/etc/systemd/system/$SYSTEMD_SERVICE_NAME"

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
  
  DEPS=("python3" "python3-venv" "python3-pip" "git" "curl")
  MISSING_DEPS=()
  
  for dep in "${DEPS[@]}"; do
    if ! command -v ${dep%%[-]*} &> /dev/null && ! dpkg -s "$dep" &> /dev/null; then
      MISSING_DEPS+=("$dep")
    fi
  done
  
  if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${YELLOW}Installing missing dependencies: ${MISSING_DEPS[*]}${NC}"
    if command -v apt-get &> /dev/null; then
      sudo apt-get update
      sudo apt-get install -y "${MISSING_DEPS[@]}"
    elif command -v dnf &> /dev/null; then
      sudo dnf install -y "${MISSING_DEPS[@]}"
    elif command -v pacman &> /dev/null; then
      sudo pacman -Sy --noconfirm "${MISSING_DEPS[@]}"
    else
      echo -e "${RED}Could not install dependencies. Please install manually: ${MISSING_DEPS[*]}${NC}"
      exit 1
    fi
  fi
}

# Function to create or update the virtual environment
setup_venv() {
  if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
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
  
  mkdir -p "$BOT_DIR/mymodules"
  
  # Download filelist.txt
  if ! curl -s "$FILELIST_URL" -o "$BOT_DIR/filelist_linux.txt"; then
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
  done < "$BOT_DIR/filelist_linux.txt"
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
# The module will be loaded from ./mymodules/ directory
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

# Function to create and install systemd service
setup_systemd() {
  if [ ! -f "$SYSTEMD_SERVICE_PATH" ] || [ "$UPDATE" = true ]; then
    echo -e "${YELLOW}Setting up systemd service...${NC}"
    
    # First try to download from repository
    if curl --output /dev/null --silent --head --fail "$REPO_BASE/$SYSTEMD_SERVICE_NAME"; then
      sudo curl -s "$REPO_BASE/$SYSTEMD_SERVICE_NAME" -o "$SYSTEMD_SERVICE_PATH"
    else
      # If not available, create a default one
      cat << EOF | sudo tee "$SYSTEMD_SERVICE_PATH" > /dev/null
[Unit]
Description=Python Telegram Userbot
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$BOT_DIR
ExecStart=$VENV_DIR/bin/python $BOT_DIR/main.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    sudo systemctl daemon-reload
    sudo systemctl enable "$SYSTEMD_SERVICE_NAME"
    
    if [ "$UPDATE" = true ]; then
      echo -e "${YELLOW}Restarting service...${NC}"
      sudo systemctl restart "$SYSTEMD_SERVICE_NAME"
    else
      echo -e "${YELLOW}Starting service...${NC}"
      sudo systemctl start "$SYSTEMD_SERVICE_NAME"
    fi
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
  setup_systemd
  
  echo -e "${GREEN}========================================${NC}"
  if [ "$UPDATE" = true ]; then
    echo -e "${GREEN}PythonUserBot updated successfully!${NC}"
  else
    echo -e "${GREEN}PythonUserBot installed successfully!${NC}"
    echo -e "${YELLOW}Please edit $BOT_DIR/config.ini with your Telegram API credentials and user ID before starting.${NC}"
  fi
  echo -e "${GREEN}========================================${NC}"
}

main
