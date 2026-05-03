import express, { type Express } from "express";
import cors from "cors";
import pinoHttp from "pino-http";
import path from "path";
import { existsSync } from "fs";
import { fileURLToPath } from "url";
import router from "./routes/index.js";
import { logger } from "./lib/logger.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app: Express = express();

app.use(
  pinoHttp({
    logger,
    serializers: {
      req(req) { return { id: req.id, method: req.method, url: req.url?.split("?")[0] }; },
      res(res) { return { statusCode: res.statusCode }; },
    },
  }),
);
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api", router);

// Serve built frontend in production
// Resolves staticDir by trying multiple candidate paths so it works in
// Docker (/app/public), Render Node (/app/artifacts/api-server/public),
// and local dev.
if (process.env.NODE_ENV === "production") {
  const candidates = [
    path.resolve(__dirname, "../public"),                               // Docker: /app/public
    path.resolve(__dirname, "../../lara-web/dist/public"),              // Render node: monorepo
    path.resolve(process.cwd(), "artifacts/lara-web/dist/public"),     // Render node: from root
    path.resolve(process.cwd(), "public"),                              // Render node: from root
  ];

  const staticDir = candidates.find(existsSync) ?? candidates[0];
  logger.info({ staticDir }, "Serving static files from");

  app.use(express.static(staticDir));
  app.get("*", (_req, res) => {
    const indexPath = path.join(staticDir, "index.html");
    if (existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      res.status(503).json({ error: "Frontend not built. Run: pnpm --filter @workspace/lara-web run build" });
    }
  });
}

export default app;
