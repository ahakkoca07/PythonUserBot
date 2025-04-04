#!/bin/bash
# Userbot running script for PythonUserBot on Linux systems
# Usage: ./run.sh
cd ./src/
source ./venv/bin/activate
python3 main.py > userbot.log 2>&1