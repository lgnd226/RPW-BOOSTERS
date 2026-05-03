# RPW BOOSTER

Facebook Multi-Tool Suite — React, Share, Comment, Token, Profile Guard.

## Deploy to Render (Fully Automatic — One Click)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/lgnd226/RPW-BOOSTERS)

Or manually:
1. Go to [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint**
2. Connect `lgnd226/RPW-BOOSTERS`
3. Render auto-provisions: **PostgreSQL database** + **Node web service** + **env vars** — no manual input needed
4. Wait ~3-5 min for first build to complete
5. Your API will be live at: `https://rpw-booster-api.onrender.com`

> **Note:** Free tier services sleep after 15 min of inactivity. A keep-alive self-ping is built in to prevent this.

## APK Build

APK builds automatically via GitHub Actions on every push to `main`.
Download the latest APK from the [Releases](https://github.com/lgnd226/RPW-BOOSTERS/releases) page.

## Architecture

- **API Server**: Express + Python (`fb_helper.py`) — handles all Facebook operations
- **Web Panel**: React + Vite (served by Express in production)  
- **Mobile App**: Expo React Native (builds to APK via GitHub Actions)
- **Database**: PostgreSQL (optional — app works without it, DB enables bulk/all-account operations)

## API URL

```
https://rpw-booster-api.onrender.com
```
