@echo off
:: Installation script for PythonUserBot on Windows systems
:: Usage: install.bat [--update]

setlocal enabledelayedexpansion

:: Repository information
set "REPO_OWNER=ahakkoca07"
set "REPO_NAME=PythonUserBot"
set "REPO_BASE=https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/main"
set "FILELIST_URL=%REPO_BASE%/filelist.txt"
set "BOT_DIR=%USERPROFILE%\PythonUserBot"
set "VENV_DIR=%BOT_DIR%\venv"
set "SERVICE_NAME=PythonUserBot"
set "NSSM_URL=https://nssm.cc/release/nssm-2.24.zip"
set "NSSM_DIR=%BOT_DIR%\nssm"
set "NSSM_EXE=%NSSM_DIR%\nssm-2.24\win64\nssm.exe"

:: Check if this is an update
set "UPDATE=false"
for %%a in (%*) do (
    if "%%a"=="--update" set "UPDATE=true"
)

echo ========================================
if "%UPDATE%"=="true" (
    echo Updating PythonUserBot...
) else (
    echo Installing PythonUserBot...
)
echo ========================================

:: Check for dependencies
echo Checking dependencies...

where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Python not found! Please install Python 3.6+ from https://www.python.org/downloads/
    exit /b 1
)

where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo curl not found! Please install curl or use Windows 10+ which has it built-in.
    exit /b 1
)

:: Create directory if it doesn't exist (first install)
if not exist "%BOT_DIR%" (
    echo Creating bot directory at %BOT_DIR%...
    mkdir "%BOT_DIR%"
)

if not exist "%BOT_DIR%\modules" (
    mkdir "%BOT_DIR%\modules"
)

:: Download file list and files from repo
echo Downloading files from repository...

:: Download filelist.txt
curl -s "%FILELIST_URL%" -o "%BOT_DIR%\filelist.txt"
if %ERRORLEVEL% neq 0 (
    echo Failed to download file list. Check your internet connection or repository URL.
    exit /b 1
)

:: Read file list and download each file
for /f "tokens=*" %%f in ('type "%BOT_DIR%\filelist.txt" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "file=%%f"
    set "dest_file=%BOT_DIR%\%%f"
    set "dest_dir=!dest_file:%%~nxf=!"
    
    if not exist "!dest_dir!" mkdir "!dest_dir!"
    
    echo Downloading %%f...
    curl -s "%REPO_BASE%/%%f" -o "!dest_file!"
    if !ERRORLEVEL! neq 0 (
        echo Failed to download %%f
    ) else (
        echo Downloaded %%f successfully
    )
)

:: Create or update virtual environment
if not exist "%VENV_DIR%" (
    echo Creating virtual environment...
    python -m venv "%VENV_DIR%"
) else if "%UPDATE%"=="true" (
    echo Updating virtual environment...
)

:: Activate virtual environment and install requirements
call "%VENV_DIR%\Scripts\activate.bat"
echo Installing requirements...
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
    echo Creating default config.ini...
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
    echo Created default config.ini. Please edit it with your details.
    echo You need to update the config.ini file with your Telegram API credentials and user ID.
)

:: Setup Windows service using NSSM
:: Download NSSM if not present
if not exist "%NSSM_EXE%" (
    echo Downloading NSSM service manager...
    if not exist "%NSSM_DIR%" mkdir "%NSSM_DIR%"
    curl -L "%NSSM_URL%" -o "%NSSM_DIR%\nssm.zip"
    
    :: Extract NSSM
    echo Extracting NSSM...
    powershell -Command "Expand-Archive -Path '%NSSM_DIR%\nssm.zip' -DestinationPath '%NSSM_DIR%' -Force"
)

:: Check if service exists
%NSSM_EXE% status "%SERVICE_NAME%" >nul 2>&1
set "SERVICE_EXISTS=%ERRORLEVEL%"

if "%SERVICE_EXISTS%"=="0" (
    if "%UPDATE%"=="true" (
        echo Stopping service for update...
        %NSSM_EXE% stop "%SERVICE_NAME%"
    )
) else (
    echo Installing as a Windows service...
    %NSSM_EXE% install "%SERVICE_NAME%" "%VENV_DIR%\Scripts\python.exe"
    %NSSM_EXE% set "%SERVICE_NAME%" AppParameters "%BOT_DIR%\main.py"
    %NSSM_EXE% set "%SERVICE_NAME%" AppDirectory "%BOT_DIR%"
    %NSSM_EXE% set "%SERVICE_NAME%" DisplayName "Python Telegram Userbot"
    %NSSM_EXE% set "%SERVICE_NAME%" Description "Python Userbot for Telegram"
    %NSSM_EXE% set "%SERVICE_NAME%" Start SERVICE_AUTO_START
    %NSSM_EXE% set "%SERVICE_NAME%" AppStdout "%BOT_DIR%\stdout.log"
    %NSSM_EXE% set "%SERVICE_NAME%" AppStderr "%BOT_DIR%\stderr.log"
)

:: Start service
echo Starting service...
%NSSM_EXE% start "%SERVICE_NAME%"

echo ========================================
if "%UPDATE%"=="true" (
    echo PythonUserBot updated successfully!
) else (
    echo PythonUserBot installed successfully!
    echo Please edit %BOT_DIR%\config.ini with your Telegram API credentials and user ID before starting.
)
echo ========================================

endlocal
