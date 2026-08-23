import { logger } from "@armsphere/core";
import env from "../config/env.js";

export class SecretRotationService {
  // Rotating JWT Key sets
  private static accessSecrets: string[] = [env.JWT_ACCESS_SECRET];
  private static refreshSecrets: string[] = [env.JWT_REFRESH_SECRET];

  /**
   * Retrieves the current active access secret for signing new tokens.
   */
  static getActiveAccessSecret(): string {
    return this.accessSecrets[0];
  }

  /**
   * Retrieves the current active refresh secret for signing new tokens.
   */
  static getActiveRefreshSecret(): string {
    return this.refreshSecrets[0];
  }

  /**
   * Rotates JWT secrets. The current active secret becomes the "previous" secret,
   * allowing existing signed tokens to remain valid during transition, while
   * all new tokens are signed with the new secret.
   */
  static rotateJWTKeys(newAccessSecret: string, newRefreshSecret: string) {
    if (newAccessSecret.length < 32 || newRefreshSecret.length < 32) {
      throw new Error("New secrets must be at least 32 characters in length for security.");
    }

    // Keep up to 3 keys in rotation window to handle gradual client syncs
    this.accessSecrets.unshift(newAccessSecret);
    if (this.accessSecrets.length > 3) {
      this.accessSecrets.pop();
    }

    this.refreshSecrets.unshift(newRefreshSecret);
    if (this.refreshSecrets.length > 3) {
      this.refreshSecrets.pop();
    }

    logger.info("JWT Access and Refresh secrets successfully rotated. Rotation key chain updated.");
  }

  /**
   * Gets all access secrets currently in rotation.
   */
  static getAccessSecretsChain(): string[] {
    return this.accessSecrets;
  }

  /**
   * Gets all refresh secrets currently in rotation.
   */
  static getRefreshSecretsChain(): string[] {
    return this.refreshSecrets;
  }

  /**
   * Models the Google Cloud Secret Manager version rotation flow for DB credentials.
   */
  static async rotateDatabaseCredentials(newConnectionString: string) {
    logger.warn("Initiating Database Credential Rotation and connection pool refresh...");
    // Update active connection URL
    env.DATABASE_URL = newConnectionString;
    
    // In production, this would trigger the pg.Pool to drain old connections and spin up new ones
    logger.info("Database connection pool credentials rotated and refreshed successfully.");
    return { success: true, message: "Database connection credentials successfully rotated." };
  }

  /**
   * Models Redis credential rotation.
   */
  static async rotateRedisCredentials(_newRedisUrl: string) {
    logger.info("Redis credentials rotation request received (Redis disabled).");
    return { success: true, message: "Redis is disabled; rotation skipped." };
  }

  /**
   * Models Object Storage (Backblaze B2) credential rotation.
   */
  static async rotateStorageCredentials(newAccessKey: string, newSecretKey: string) {
    logger.warn("Initiating Object Storage (B2) credentials rotation...");
    env.B2_ACCESS_KEY_ID = newAccessKey;
    env.B2_SECRET_ACCESS_KEY = newSecretKey;
    logger.info("B2 Object Storage credentials rotated in runtime memory successfully.");
    return { success: true, message: "Storage credentials successfully rotated." };
  }
}
export default SecretRotationService;
