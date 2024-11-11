# Use Python 3.11 slim-bullseye as it's more secure and regularly updated
FROM python:3.11-slim-bullseye AS builder

# Set working directory
WORKDIR /app

# Update system packages and install security updates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment and activate it
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install open-webui with additional security flags
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir open-webui

# Start with a fresh slim image for the final stage
FROM python:3.11-slim-bullseye

WORKDIR /app

# Copy only the necessary files from builder
COPY --from=builder /app/venv /app/venv

# Update system packages and remove unnecessary files
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-privileged user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

# Set environment variables
ENV PATH="/app/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ENABLE_PERMISSIONS=TRUE \
    DEBUG_PERMISSIONS=TRUE \
    USER_APP=10014 \
    GROUP_APP=10014

# Set proper permissions
RUN chown -R choreo:choreo /app

# Switch to non-root user
USER 10014

# Expose the default port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Command to run the application
CMD ["open-webui", "serve"]
