# RPW BOOSTER

## Overview

Facebook multi-tool suite with web dashboard, mobile app (Expo), and Express API backend.
pnpm workspace monorepo using TypeScript.

## Stack

- **Monorepo tool**: pnpm workspaces
- **Node.js version**: 22
- **Package manager**: pnpm
- **TypeScript version**: 5.9
- **API framework**: Express 5
- **Database**: PostgreSQL + Drizzle ORM (`fb_accounts` table)
- **Validation**: Zod (`zod/v4`), `drizzle-zod`
- **API codegen**: Orval (from OpenAPI spec)
- **Build**: esbuild (CJS bundle)
- **Frontend**: React + Vite + Tailwind CSS (lara-web)
- **Mobile**: Expo (rpw-mobile)

## Artifacts

| Artifact | Path | Description |
|---|---|---|
| `lara-web` | `/` | React/Vite web dashboard for FB tools |
| `api-server` | `/api` | Express backend + Python `fb_helper.py` for FB ops |
| `rpw-mobile` | `/rpw-mobile/` | Expo React Native mobile app |

## Key Commands

- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- `pnpm --filter @workspace/api-server run dev` — run API server locally
- `pnpm --filter @workspace/lara-web run dev` — run web frontend locally

## Deployment

### Render (render.yaml)
- Builds both lara-web and api-server
- Provisions a free PostgreSQL database automatically
- Installs Python deps (curl_cffi, requests) for fb_helper.py
- API runs at `/api`, frontend at `/`

### Railway (railway.toml + Dockerfile)
- Multi-stage Docker build (node:22-slim base)
- Stage 1 builds lara-web and api-server
- Stage 2 creates Python venv, installs curl_cffi
- `DATABASE_URL` and `SESSION_SECRET` must be set in Railway dashboard

### Vercel (vercel.json)
- Deploys lara-web frontend as static site
- Rewrites `/api/*` → `https://rpw-booster-api.onrender.com/api/*`
- Set `VITE_API_URL` override if using a different backend URL

### APK (GitHub Actions: .github/workflows/android-apk.yml)
- Triggers on push to `main` or manual dispatch
- Uses Node.js 22 + Java 17 + Android SDK
- Runs `expo prebuild` then Gradle `assembleDebug`
- Uploads APK as GitHub artifact + creates a GitHub Release
- Set `EXPO_PUBLIC_API_URL` repo variable to override the default Render URL

## Architecture Notes

- `fb_helper.py` is a Python script (uses `curl_cffi` for Chrome TLS impersonation) called via child_process from the Node.js API server
- `HELPER_PATH` resolves relative to the compiled `dist/` directory — in production, `fb_helper.py` must be one level above `dist/`
- The API server serves the built lara-web frontend as static files from `../public` (relative to dist/) in production

See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details.
