# syntax=docker/dockerfile:1.7
FROM python:3.12-slim-bookworm AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Minimal base runtime deps (add more if your libs need them at runtime)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates bash \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Builder: install Poetry + deps
# -----------------------------
FROM base AS builder
WORKDIR /app

# Optionally include system build tools if you have native deps
# (comment out if not needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Install Poetry (the ONLY time we use pip)
ENV POETRY_VERSION=1.8.3 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1
RUN python -m pip install "poetry==${POETRY_VERSION}"

# --- Cache layer 1: only files that affect dependency resolution
# (Adjust these to your project. poetry.lock is the key to caching!)
COPY pyproject.toml poetry.lock* ./

# Install ONLY dependencies into the project venv (.venv), no project code yet.
#   - For main deps only: add "--only main"
#   - Include dev deps by setting build arg later and removing the flag
ARG INCLUDE_DEV=false
RUN if [ "${INCLUDE_DEV}" = "true" ]; then \
      poetry install --no-ansi --no-root; \
    else \
      poetry install --no-ansi --no-root --only main; \
    fi

# --- Cache layer 2: now bring in the source
COPY . .

# Install the project itself into the same venv (still via Poetry)
RUN if [ "${INCLUDE_DEV}" = "true" ]; then \
      poetry install --no-ansi; \
    else \
      poetry install --no-ansi --only main; \
    fi

# -----------------------------
# Runtime: copy venv + app only
# -----------------------------
FROM base AS runtime
WORKDIR /app

# Non-root user
RUN useradd -ms /bin/bash appuser

# Copy the installed venv and your code from builder
COPY --from=builder /app /app

# Make Poetry’s in-project venv the default Python
ENV PATH="/app/.venv/bin:${PATH}"

USER appuser

ENTRYPOINT ["rss_to_opensearch"]
CMD ["--help"]
