#!/bin/bash
# VoiceTyper Server — Start script
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Activate venv
source ../venv/bin/activate

# Ensure Ollama is running
if ! pgrep -x ollama > /dev/null; then
    echo "Starting Ollama..."
    OLLAMA_FLASH_ATTENTION="1" OLLAMA_KV_CACHE_TYPE="q8_0" /opt/homebrew/opt/ollama/bin/ollama serve > /tmp/ollama.log 2>&1 &
    sleep 2
fi

# Start server
python3 server.py "$@"
