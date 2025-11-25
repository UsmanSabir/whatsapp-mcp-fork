# Multi-stage build for WhatsApp MCP Server
# Build the Go binary using Debian-based Go image (glibc)
FROM golang:1.25.4 AS go-builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    sqlite3 \
    libsqlite3-dev

WORKDIR /build

# Copy go bridge source
COPY whatsapp-bridge /build/

# Build Go app (CGO enabled, glibc-linked)
RUN go mod download && \
    CGO_ENABLED=1 go build -o ./whatsapp-bridge main.go


# Final stage
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    ffmpeg \
    sqlite3 \
    libsqlite3-dev \
    curl \
    git \
    build-essential \
    gcc \
    libc6 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy entire project
COPY . /app/

# Copy built Go binary
COPY --from=go-builder /build/whatsapp-bridge /app/whatsapp-bridge/whatsapp-bridge

# Install Python deps
WORKDIR /app/whatsapp-mcp-server
RUN pip install --no-cache-dir \
    httpx>=0.28.1 \
    "mcp[cli]>=1.6.0" \
    requests>=2.32.3

WORKDIR /app
RUN mkdir -p /app/whatsapp-bridge/store

EXPOSE 8000
EXPOSE 8080

ENV PYTHONUNBUFFERED=1
ENV CGO_ENABLED=1

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
