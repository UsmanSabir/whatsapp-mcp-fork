# WhatsApp MCP Docker Build Instructions

This Dockerfile builds and runs the WhatsApp MCP Server as a containerized application.

## Prerequisites

- Docker installed and running
- Docker Compose (optional, but recommended)
- The whatsapp-mcp repository cloned

## Quick Start with Docker Compose

The easiest way to build and run the application:

```bash
# Build and start the container
docker-compose up --build

# Run in detached mode (background)
docker-compose up -d --build

# Stop the container
docker-compose down

# View logs
docker-compose logs -f
```

## Manual Docker Commands

### Build the Docker Image

```bash
docker build -t whatsapp-mcp:latest .
```

### Run the Container

```bash
# Interactive mode (for QR code scanning)
docker run -it \
  -v whatsapp-store:/app/whatsapp-bridge/store \
  --name whatsapp-mcp-server \
  whatsapp-mcp:latest

# Background mode
docker run -d \
  -v whatsapp-store:/app/whatsapp-bridge/store \
  --name whatsapp-mcp-server \
  whatsapp-mcp:latest

# View logs
docker logs -f whatsapp-mcp-server
```

## What the Dockerfile Does

1. **Build Stage (Go)**: Compiles the Go WhatsApp bridge
   - Uses golang:1.21-alpine as the build base
   - Installs build dependencies (gcc, sqlite-dev, etc.)
   - Builds the `whatsapp-bridge` binary

2. **Final Stage (Python)**: Runs the MCP server
   - Uses python:3.11-slim as the runtime
   - Installs system dependencies (FFmpeg, SQLite, etc.)
   - Installs Go runtime (needed by the bridge)
   - Installs Python dependencies from `pyproject.toml`
   - Runs both the Go bridge and Python MCP server

## Important Notes

### QR Code Authentication

The first time you run the WhatsApp bridge, it will display a QR code for authentication. To handle this:

**Option 1: Interactive Mode**
```bash
docker run -it \
  -v whatsapp-store:/app/whatsapp-bridge/store \
  --name whatsapp-mcp-server \
  whatsapp-mcp:latest
```

**Option 2: Use docker-compose with stdin/tty enabled**
Uncomment the following in `docker-compose.yml`:
```yaml
stdin_open: true
tty: true
```

### Data Persistence

The container uses a Docker volume (`whatsapp-store`) to persist:
- WhatsApp session data
- SQLite database with message history
- Authentication credentials

This ensures your WhatsApp session is preserved even if the container is restarted.

### Rebuilding

If you make changes to the source code:

```bash
# With Docker Compose
docker-compose up --build

# Manual build
docker build --no-cache -t whatsapp-mcp:latest .
```

## Troubleshooting

### Port Already in Use
The container exposes port 8000. If it's in use, you can remap it:

```bash
docker run -d \
  -p 8001:8000 \
  -v whatsapp-store:/app/whatsapp-bridge/store \
  --name whatsapp-mcp-server \
  whatsapp-mcp:latest
```

### Container Won't Start
Check the logs:

```bash
docker logs whatsapp-mcp-server
```

### Permission Issues
Ensure proper permissions on the volume:

```bash
docker exec whatsapp-mcp-server ls -la /app/whatsapp-bridge/store/
```

### Need to Re-authenticate
Delete the database files and restart:

```bash
docker exec whatsapp-mcp-server rm -f /app/whatsapp-bridge/store/*.db
docker restart whatsapp-mcp-server
```

## Environment Variables

You can pass environment variables when running the container:

```bash
docker run -d \
  -e PYTHONUNBUFFERED=1 \
  -e CGO_ENABLED=1 \
  -v whatsapp-store:/app/whatsapp-bridge/store \
  --name whatsapp-mcp-server \
  whatsapp-mcp:latest
```

Or use a `.env` file with docker-compose:

```bash
docker-compose up -d --env-file .env
```

## Integration with Claude Desktop

Once the container is running, you can connect it to Claude Desktop by configuring your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "whatsapp": {
      "command": "docker",
      "args": [
        "exec",
        "whatsapp-mcp-server",
        "python",
        "/app/whatsapp-mcp-server/main.py"
      ]
    }
  }
}
```

Or if running locally with Python installed, follow the standard installation instructions in the README.

## See Also

- Original Repository: https://github.com/lharries/whatsapp-mcp
- Docker Documentation: https://docs.docker.com/
- Docker Compose Documentation: https://docs.docker.com/compose/
