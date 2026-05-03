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
  try {
    await runMigrations();
    logger.info("DB migrations complete");
  } catch (err) {
    logger.warn({ err }, "DB migration failed – server will continue without database");
  }

  app.listen(port, (err) => {
    if (err) {
      logger.error({ err }, "Error listening on port");
      process.exit(1);
    }
    logger.info({ port }, "Server listening");

    // ── Keep-alive self-ping (prevents Render free tier from sleeping) ────────
    // Pings own healthz every 14 minutes. Free tier sleeps after 15 min idle.
    if (process.env.NODE_ENV === "production") {
      const selfUrl = process.env["RENDER_EXTERNAL_URL"]
        || `http://localhost:${port}`;
      const pingUrl = `${selfUrl}/api/healthz`;

      setInterval(async () => {
        try {
          const res = await fetch(pingUrl, { signal: AbortSignal.timeout(10000) });
          if (res.ok) logger.info("[keep-alive] ping ok");
          else logger.warn({ status: res.status }, "[keep-alive] ping non-2xx");
        } catch (e) {
          // Ignore — best effort
        }
      }, 14 * 60 * 1000); // 14 minutes

      logger.info({ pingUrl }, "[keep-alive] self-ping enabled");
    }
  });
}

start();
