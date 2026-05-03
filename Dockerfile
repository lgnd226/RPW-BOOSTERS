# ─────────────────────────────────────────────────────────────────────────────
# RPW BOOSTER — Production Dockerfile
# Build: Docker (used by Render Blueprint via render.yaml)
# ─────────────────────────────────────────────────────────────────────────────

FROM node:22-bookworm

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-dev \
    libssl-dev libcurl4-openssl-dev \
    build-essential curl git \
    && rm -rf /var/lib/apt/lists/*

# ── Python dependencies (curl_cffi — Chrome TLS fingerprint for Facebook) ────
# Pre-built wheel for linux/amd64 — no compilation needed
RUN pip3 install --break-system-packages --no-cache-dir curl_cffi requests

# ── pnpm ─────────────────────────────────────────────────────────────────────
RUN npm install -g pnpm@9

WORKDIR /app

# ── Copy workspace manifests first (layer cache: only reinstalls on change) ──
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY tsconfig.base.json tsconfig.json ./

# ── CRITICAL: Patch minimumReleaseAge: 1440 → 0 ──────────────────────────────
# This setting blocks packages published less than 24 hours ago.
# Without this patch, catalog packages like vite@7.3.2, framer-motion@12.23.24
# will fail to install on Render's fresh environment.
RUN sed -i 's/minimumReleaseAge: [0-9]*/minimumReleaseAge: 0/' pnpm-workspace.yaml

# ── Copy all workspace package source ─────────────────────────────────────────
COPY lib/ lib/
COPY artifacts/api-server/ artifacts/api-server/
COPY artifacts/lara-web/ artifacts/lara-web/

# ── Install all workspace dependencies ────────────────────────────────────────
# --store-dir: fresh store avoids "Cache entry deserialization failed" on Render
# --no-frozen-lockfile: allows updating lockfile if any version resolution changed
RUN pnpm install --no-frozen-lockfile --store-dir /tmp/pnpm-store

# ── Build frontend (React + Vite → artifacts/lara-web/dist/public/) ──────────
RUN BASE_PATH=/ pnpm --filter @workspace/lara-web run build

# ── Build API server (esbuild bundle → artifacts/api-server/dist/) ───────────
RUN pnpm --filter @workspace/api-server run build

# ── Organize final runtime layout under /app ─────────────────────────────────
# app.ts (after bundling): staticDir = path.resolve(__dirname, "../public")
#   __dirname at runtime   = /app/dist
#   ../public              = /app/public  ← frontend goes here
#
# facebook.ts HELPER_PATH = path.resolve(__dirname, "../fb_helper.py")
#   ../fb_helper.py        = /app/fb_helper.py  ← python helper goes here
#
RUN cp -r artifacts/api-server/dist/. ./dist/ && \
    cp    artifacts/api-server/fb_helper.py ./fb_helper.py && \
    cp -r artifacts/lara-web/dist/public/ ./public/

# ── Environment ───────────────────────────────────────────────────────────────
ENV NODE_ENV=production
# Render auto-injects PORT; 10000 is Render's default for web services
ENV PORT=10000

EXPOSE 10000

# ── Start ─────────────────────────────────────────────────────────────────────
# __dirname = /app/dist  → ../public = /app/public ✓  ../fb_helper.py ✓
CMD ["node", "--enable-source-maps", "./dist/index.mjs"]
