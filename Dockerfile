# ==============================================================================
# Multi-stage production-ready Dockerfile for Google Threat Intelligence MCP Server
# ==============================================================================

# --- Stage 1: Build stage ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system build dependencies if needed, and upgrade pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --upgrade pip

# Copy package configuration files
COPY pyproject.toml README.md ./
COPY gti_mcp_server/ ./gti_mcp_server/

# Build a wheel package for clean installation in the runner stage
RUN pip install --no-cache-dir build \
    && python -m build --wheel --outdir /app/dist

# --- Stage 2: Runner stage ---
FROM python:3.11-slim AS runner

# Set production environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    TRANSPORT=sse

WORKDIR /app

# Create a non-privileged system user for security best practices (least privilege)
RUN groupadd -g 10001 mcpuser && \
    useradd -u 10001 -g mcpuser -m -s /sbin/nologin mcpuser

# Upgrade pip and install the built wheel from the builder stage
COPY --from=builder /app/dist/*.whl ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir *.whl \
    && rm -f *.whl

# Switch to the non-root user
USER mcpuser

# Inform Docker that the container listens on the specified port
EXPOSE 8000

# Run the MCP server. Calling python -m gti_mcp_server.server is highly robust
# and bypasses any non-root path resolution issues.
ENTRYPOINT ["python", "-m", "gti_mcp_server.server"]
