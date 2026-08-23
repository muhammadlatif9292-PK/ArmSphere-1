import crypto from "crypto";
import { v4 as uuidv4 } from "uuid";
import { desc, eq } from "drizzle-orm";
import { db } from "../config/db.js";
import { auditEvents } from "@armsphere/db-schema";
import { logger } from "@armsphere/core";

export class AuditLedgerService {
  private genesisHash = "0".repeat(64);

  private sha256(content: string): string {
    return crypto.createHash("sha256").update(content).digest("hex");
  }

  /**
   * Logs a security audit event and appends it to the cryptographically linked hash chain.
   */
  async logEvent(input: {
    actorId?: string | null;
    entityType: string;
    entityId: string;
    action: string;
    payload?: any;
  }) {
    try {
      // 1. Fetch the absolute latest audit event to get the parent hash
      const [lastEvent] = await db
        .select()
        .from(auditEvents)
        .orderBy(desc(auditEvents.createdAt))
        .limit(1);

      const parentHash = lastEvent ? lastEvent.eventHash : this.genesisHash;
      const eventId = uuidv4();
      const createdAt = new Date();

      const actorStr = input.actorId || "SYSTEM";
      const payloadStr = input.payload ? JSON.stringify(input.payload) : "{}";

      // 2. Compute cryptographically secure hash chain value
      const dataToHash = [
        parentHash,
        eventId,
        actorStr,
        input.entityType,
        input.entityId,
        input.action,
        payloadStr,
        createdAt.toISOString()
      ].join("|");

      const eventHash = this.sha256(dataToHash);

      // 3. Write event to the immutable ledger
      await db.insert(auditEvents).values({
        eventId,
        parentHash,
        eventHash,
        actorId: input.actorId || null,
        entityType: input.entityType,
        entityId: input.entityId,
        action: input.action,
        payload: input.payload || {},
        createdAt,
      });

      logger.info(
        { eventId, action: input.action, eventHash },
        `Secure audit log appended: ${input.action}`
      );
    } catch (error) {
      logger.error({ error, input }, "Failed to append cryptographic audit log");
    }
  }

  /**
   * Verifies the entire audit log chain integrity.
   * Returns validity status and a report of any corrupted block indices.
   */
  async verifyChainIntegrity(): Promise<{ valid: boolean; corruptedEventIds: string[] }> {
    const allEvents = await db
      .select()
      .from(auditEvents)
      .orderBy(desc(auditEvents.createdAt)); // ordered from newest to oldest

    const corruptedEventIds: string[] = [];
    let expectedNextParentHash = "";

    // Iterate backwards (or forwards). Let's go oldest to newest (by reversing the array).
    const chain = [...allEvents].reverse();

    for (let i = 0; i < chain.length; i++) {
      const current = chain[i];
      const actualParentHash = i === 0 ? this.genesisHash : chain[i - 1].eventHash;

      if (current.parentHash !== actualParentHash) {
        corruptedEventIds.push(current.eventId);
        continue;
      }

      const actorStr = current.actorId || "SYSTEM";
      const payloadStr = current.payload ? JSON.stringify(current.payload) : "{}";
      const createdAtStr = new Date(current.createdAt).toISOString();

      const dataToHash = [
        current.parentHash,
        current.eventId,
        actorStr,
        current.entityType,
        current.entityId,
        current.action,
        payloadStr,
        createdAtStr
      ].join("|");

      const recalculatedHash = this.sha256(dataToHash);
      if (recalculatedHash !== current.eventHash) {
        corruptedEventIds.push(current.eventId);
      }
    }

    return {
      valid: corruptedEventIds.length === 0,
      corruptedEventIds,
    };
  }
}

export const auditLedgerService = new AuditLedgerService();
