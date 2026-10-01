# ==============================================================================
# Laya Studio - Production Multi-Stage Container
# ==============================================================================
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast deterministic builds
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Copy dependencies definitions
COPY pyproject.toml uv.lock ./

# Install python dependencies into virtualenv
RUN uv sync --frozen --no-dev

# Copy application source code
COPY app.py ./
COPY static ./static

# Expose HTTP port
EXPOSE 8000

# Run server in production mode
CMD ["uv", "run", "app.py", "--no-browser", "--host", "0.0.0.0", "--port", "8000"]
