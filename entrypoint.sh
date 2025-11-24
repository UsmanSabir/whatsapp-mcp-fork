#!/bin/bash
set -e

echo "Starting WhatsApp MCP Server..."

# Debug: List what's in the whatsapp-bridge directory
echo "Contents of /app/whatsapp-bridge/:"
ls -la /app/whatsapp-bridge/

# Start Go bridge in the background
echo "Starting WhatsApp bridge..."
cd /app/whatsapp-bridge

# Check if binary exists and is executable
if [ ! -f "whatsapp-bridge" ]; then
    echo "ERROR: whatsapp-bridge binary not found!"
    ls -la
    exit 1
fi

if [ ! -x "whatsapp-bridge" ]; then
    echo "Making whatsapp-bridge executable..."
    chmod +x whatsapp-bridge
fi

./whatsapp-bridge &
BRIDGE_PID=$!

# Wait for bridge to start
sleep 2

# Start Python MCP server
echo "Starting Python MCP server..."
cd /app/whatsapp-mcp-server
exec python main.py
