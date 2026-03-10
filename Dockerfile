FROM python:3.12-slim

WORKDIR /app

# Ensure latest pip
RUN pip install --upgrade pip

# Install dependencies including keyrings.alt for file-based keyring fallback in headless Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir keyrings.alt

# Copy the rest of the application
COPY . .

# Install the application package
RUN pip install -e .

# Configure keyring to use a plaintext file backend in a specific directory
ENV PYTHON_KEYRING_BACKEND=keyrings.alt.file.PlaintextKeyring
ENV XDG_DATA_HOME=/app/data

# Ensure the data directory exists
RUN mkdir -p /app/data

# Default entrypoint to the MCP server
ENTRYPOINT ["monarch-mcp-server"]
