# ─────────────────────────────────────────────────────────────────────────────
# RPW BOOSTER — Dockerfile (used by Render Blueprint: env: docker)
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:22-slim AS builder

RUN apt-get update && apt-get install -y python3 python3-pip curl git && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9

WORKDIR /app

# Copy workspace manifests first for layer caching
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# Override minimumReleaseAge so CI never blocks on new packages
RUN pnpm config set minimumReleaseAge 0

# Copy all source needed for the build
COPY lib/ lib/
COPY artifacts/api-server/ artifacts/api-server/
COPY artifacts/lara-web/ artifacts/lara-web/
COPY tsconfig*.json ./

# Install all workspace deps
RUN pnpm install --no-frozen-lockfile

# Build frontend (BASE_PATH=/ so assets resolve from root)
RUN BASE_PATH=/ pnpm --filter @workspace/lara-web run build

# Build API server (esbuild bundles everything into dist/)
RUN pnpm --filter @workspace/api-server run build

# ── Stage 2: Lean runtime ─────────────────────────────────────────────────────
FROM node:22-slim AS runtime

RUN apt-get update && apt-get install -y python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Install Python FB dependencies in a virtual env
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"
RUN pip install --no-cache-dir curl_cffi requests

WORKDIR /app

# Copy the esbuild bundle (self-contained — no node_modules needed)
COPY --from=builder /app/artifacts/api-server/dist/ ./dist/

# Copy pino transport workers that esbuild-plugin-pino emits alongside the bundle
COPY --from=builder /app/node_modules/pino-pretty/ ./node_modules/pino-pretty/
COPY --from=builder /app/node_modules/pino/ ./node_modules/pino/
COPY --from=builder /app/node_modules/thread-stream/ ./node_modules/thread-stream/

# Python FB helper
COPY --from=builder /app/artifacts/api-server/fb_helper.py ./fb_helper.py

# Frontend static files (served by Express in production)
# app.ts resolves staticDir = __dirname/../public = /app/public ✓
COPY --from=builder /app/artifacts/lara-web/dist/public/ ./public/

ENV NODE_ENV=production
# Render passes PORT automatically; default 10000 matches Render's web service default
ENV PORT=10000

EXPOSE 10000

CMD ["node", "--enable-source-maps", "./dist/index.mjs"]
