FROM python:3.11-slim

# Install Node.js (>=18), nginx, supervisor, and build tools
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       ca-certificates curl gnupg \
       nginx \
       supervisor \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# Copy uv from the official image
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

WORKDIR /app

# ── Install Node dependencies (cached layer) ──────────────────────────────────
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN npm ci && npm ci --prefix frontend

# ── Install Python dependencies (cached layer) ────────────────────────────────
COPY backend/pyproject.toml backend/uv.lock ./backend/
RUN cd backend && uv sync --frozen --no-dev

# ── Copy source code ─────────────────────────────────────────────────────────
COPY . .

# ── Build the Vue SPA (output → frontend/dist) ────────────────────────────────
# VITE_API_BASE_URL is intentionally empty so the browser uses relative /api/…
# paths, which nginx then proxies to the backend.
RUN VITE_API_BASE_URL="" npm run build

# ── Configure nginx ───────────────────────────────────────────────────────────
COPY nginx.conf /etc/nginx/sites-available/mirofish
RUN rm -f /etc/nginx/sites-enabled/default \
  && ln -s /etc/nginx/sites-available/mirofish /etc/nginx/sites-enabled/mirofish

# ── Configure supervisor ──────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/mirofish.conf

# Only port 80 is needed externally; cloudflared routes to this port.
EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
