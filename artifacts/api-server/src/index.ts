import app from "./app";
import { logger } from "./lib/logger";
import { runMigrations } from "@workspace/db";

const rawPort = process.env["PORT"];

if (!rawPort) {
  throw new Error("PORT environment variable is required but was not provided.");
}

const port = Number(rawPort);
if (Number.isNaN(port) || port <= 0) {
  throw new Error(`Invalid PORT value: "${rawPort}"`);
}

async function start() {
  // Run DB migrations (no-op if DATABASE_URL not set)
  try {
    await runMigrations();
    logger.info("DB migrations complete");
  } catch (err) {
    logger.warn({ err }, "DB migration failed – continuing without database");
  }

  app.listen(port, () => {
    logger.info({ port }, "RPW BOOSTER API server listening");

    // ── Permanent keep-alive: prevent Render free tier from sleeping ──────────
    // Pings own public URL every 13 minutes.
    // Render sleeps after 15 min idle — this keeps it permanently awake.
    // External GitHub Actions workflow also pings every 5 min as backup.
    if (process.env.NODE_ENV === "production") {
      const externalUrl = (process.env["RENDER_EXTERNAL_URL"] || "").replace(/\/$/, "");
      const pingUrl = externalUrl
        ? `${externalUrl}/api/healthz`
        : null;

      if (pingUrl) {
        logger.info({ pingUrl }, "Keep-alive enabled — pinging every 13 min");

        setInterval(async () => {
          try {
            const res = await fetch(pingUrl, {
              signal: AbortSignal.timeout(15000),
              headers: { "User-Agent": "RPW-BOOSTER-keepalive/1.0" },
            });
            logger.info({ status: res.status }, "[keep-alive] ping");
          } catch {
            // Ignore — best effort
          }
        }, 13 * 60 * 1000);
      } else {
        logger.warn("RENDER_EXTERNAL_URL not set — keep-alive disabled (GitHub Actions handles it)");
      }
    }
  });
}

start();
