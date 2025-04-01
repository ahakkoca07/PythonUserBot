@echo off
:: Installation script for PythonUserBot on Windows systems
:: Usage: install.bat [--update]

setlocal enabledelayedexpansion

:: Repository information
set "REPO_OWNER=ahakkoca07"
set "REPO_NAME=PythonUserBot"
set "REPO_BASE=https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/main"
set "FILELIST_URL=%REPO_BASE%/filelist_windows.txt"
set "BOT_DIR=%USERPROFILE%\PythonUserBot"
set "VENV_DIR=%BOT_DIR%\venv"
set "LOG_DIR=%BOT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\install.log"

:: Check if this is an update
set "UPDATE=false"
for %%a in (%*) do (
    if "%%a"=="--update" set "UPDATE=true"
)

:: Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Function to log messages
call :log "========================================" 
if "%UPDATE%"=="true" (
    call :log "Updating PythonUserBot..."
) else (
    call :log "Installing PythonUserBot..."
)
call :log "========================================" 

:: Check for dependencies
call :log "Checking dependencies..."

where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "Python not found! Please install Python 3.6+ from https://www.python.org/downloads/"
    exit /b 1
)

where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "curl not found! Please install curl or use Windows 10+ which has it built-in."
    exit /b 1
)

:: Create directory if it doesn't exist (first install)
if not exist "%BOT_DIR%" (
    call :log "Creating bot directory at %BOT_DIR%..."
    mkdir "%BOT_DIR%"
)

if not exist "%BOT_DIR%\modules" (
    mkdir "%BOT_DIR%\modules"
)

:: Download file list and files from repo
call :log "Downloading files from repository..."

:: Download filelist.txt
curl -s "%FILELIST_URL%" -o "%BOT_DIR%\filelist_windows.txt"
if %ERRORLEVEL% neq 0 (
    call :log "Failed to download file list. Check your internet connection or repository URL."
    exit /b 1
)

:: Read file list and download each file
for /f "tokens=*" %%f in ('type "%BOT_DIR%\filelist_windows.txt" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "file=%%f"
    set "dest_file=%BOT_DIR%\%%f"
    set "dest_dir=!dest_file:%%~nxf=!"
    
    if not exist "!dest_dir!" mkdir "!dest_dir!"
    
    call :log "Downloading %%f..."
    curl -s "%REPO_BASE%/%%f" -o "!dest_file!"
    if !ERRORLEVEL! neq 0 (
        call :log "Failed to download %%f"
    ) else (
        call :log "Downloaded %%f successfully"
    )
)

:: Create or update virtual environment
if not exist "%VENV_DIR%" (
    call :log "Creating virtual environment..."
    python -m venv "%VENV_DIR%"
) else if "%UPDATE%"=="true" (
    call :log "Updating virtual environment..."
)

:: Activate virtual environment and install requirements
call "%VENV_DIR%\Scripts\activate.bat"
call :log "Installing requirements..."
python -m pip install --upgrade pip
pip install --upgrade telethon configparser

:: Check if requirements.txt exists in repo and install from it
curl -s --head --fail "%REPO_BASE%/requirements.txt" >nul
if %ERRORLEVEL% equ 0 (
    curl -s "%REPO_BASE%/requirements.txt" -o "%BOT_DIR%\requirements.txt"
    pip install --upgrade -r "%BOT_DIR%\requirements.txt"
)

:: Create default config if it doesn't exist
if not exist "%BOT_DIR%\config.ini" (
    call :log "Creating default config.ini..."
    (
        echo [Telegram]
        echo # Your Telegram API credentials
        echo api_id = YOUR_API_ID
        echo api_hash = YOUR_API_HASH
        echo session_name = userbot
        echo.
        echo [Auth]
        echo # Comma-separated list of authorized user IDs
        echo authorized_users = YOUR_USER_ID
        echo.
        echo [Commands]
        echo # Define command mappings in format:
        echo # command = module.function
        echo # The module will be loaded from ./modules/ directory
        echo hello = hello.hello_world
        echo echo = echo.echo_text
        echo.
        echo [Settings]
        echo # General settings
        echo debug = false
        echo log_level = INFO
    ) > "%BOT_DIR%\config.ini"
    call :log "Created default config.ini. Please edit it with your details."
)

:: Create startup script
call :log "Creating startup script..."
(
    echo @echo off
    echo :: Startup script for PythonUserBot
    echo.
    echo cd "%BOT_DIR%"
    echo call "%VENV_DIR%\Scripts\activate.bat"
    echo python "%BOT_DIR%\main.py"
    echo.
    echo :: Keep the window open if there's an error
    echo pause
) > "%BOT_DIR%\start_bot.bat"

:: Create desktop shortcut
call :log "Creating desktop shortcut..."
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=%DESKTOP%\PythonUserBot.lnk"

powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT%'); $Shortcut.TargetPath = '%BOT_DIR%\start_bot.bat'; $Shortcut.Description = 'Start PythonUserBot'; $Shortcut.WorkingDirectory = '%BOT_DIR%'; $Shortcut.Save()"

call :log "========================================" 
if "%UPDATE%"=="true" (
    call :log "PythonUserBot updated successfully!"
) else (
    call :log "PythonUserBot installed successfully!"
    call :log "Please edit %BOT_DIR%\config.ini with your Telegram API credentials and user ID before starting."
    call :log "You can start the bot by running %BOT_DIR%\start_bot.bat or using the desktop shortcut."
)
call :log "========================================" 
call :log "Opening PythonUserBot folder..."

:: Open the PythonUserBot folder
start "" "%BOT_DIR%"

endlocal
exit /b 0

:log
:: Function to log messages
echo %~1
echo %date% %time% - %~1 >> "%LOG_FILE%"
goto :eof