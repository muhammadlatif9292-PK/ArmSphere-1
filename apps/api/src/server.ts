import { app } from "./app.js";
import { env } from "./config/env.js";
import { pool } from "./config/db.js";
import { logger } from "@armsphere/core";
import { startScheduledJobsRunner, stopScheduledJobsRunner } from "./services/scheduledJobs.js";

async function bootstrap() {
  logger.info("Initializing ArmSphere backend service bootstrapping sequence...");

  try {
    // 2. Initialize PostgreSQL-backed Scheduled Jobs Runner (Only when NOT running in serverless mode)
    if (env.NODE_ENV !== "test" && !env.IS_SERVERLESS) {
      startScheduledJobsRunner();
    }

    // 3. Start Listening securely on the configured runtime port
    const PORT = env.PORT;
    const server = app.listen(PORT, "0.0.0.0", () => {
      logger.info(
        { port: PORT, environment: env.NODE_ENV },
        `🚀 ArmSphere API Engine listening securely on http://0.0.0.0:${PORT}`
      );
    });

    server.on("error", (err: any) => {
      logger.error({ error: err }, "HTTP Server listener error encountered.");
      process.exit(1);
    });

    // Graceful Shutdown Protocol
    const gracefulShutdown = (signal: string) => {
      logger.info({ signal }, "Received shutdown signal. Commencing clean termination procedures...");
      
      const terminate = async () => {
        logger.info("HTTP Server successfully terminated.");
        try {
          if (env.NODE_ENV !== "test" && !env.IS_SERVERLESS) {
            stopScheduledJobsRunner();
          }
          await pool.end();
          logger.info("PostgreSQL connection pool drained successfully.");
          process.exit(0);
        } catch (error) {
          logger.error({ error }, "Error encountered while draining PostgreSQL connection pool.");
          process.exit(1);
        }
      };

      server.close(terminate);

      // Forcefully terminate after a safety timeout (e.g., 10 seconds)
      setTimeout(() => {
        logger.error("Shutdown safety timeout breached. Forcefully terminating process.");
        process.exit(1);
      }, 10000).unref();
    };

    process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
    process.on("SIGINT", () => gracefulShutdown("SIGINT"));

  } catch (error) {
    logger.error({ error }, "Bootstrapping sequence failed. Process aborted.");
    process.exit(1);
  }
}

bootstrap();
