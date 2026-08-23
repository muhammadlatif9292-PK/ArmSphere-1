import { logger } from "@armsphere/core";

export interface PasswordResetEmailPayload {
  to: string;
  resetToken: string;
  expiresAt: Date;
}

export interface EmailVerificationEmailPayload {
  to: string;
  verifyToken: string;
  expiresAt: Date;
}

interface CapturedEmails {
  passwordResets: PasswordResetEmailPayload[];
  emailVerifications: EmailVerificationEmailPayload[];
}

/**
 * Out-of-band credential delivery boundary.
 *
 * SECURITY INVARIANT: one-time credentials (password-reset tokens, email
 * verification tokens) may ONLY leave the system through this service. They
 * must never appear in API responses, audit logs, or application logs.
 *
 * The current implementation logs metadata only; wiring a real provider
 * (SES/SendGrid/Postmark) happens here without touching any caller.
 */
export class EmailDeliveryService {
  private static testCapture: CapturedEmails | null = null;

  /**
   * Test-only capture hook. Records payloads so integration tests can complete
   * credential flows without a real mailbox. Never used in production paths.
   */
  static enableTestCapture(): void {
    this.testCapture = { passwordResets: [], emailVerifications: [] };
  }

  static getCapturedEmailsForTesting(): CapturedEmails {
    return (
      this.testCapture ?? { passwordResets: [], emailVerifications: [] }
    );
  }

  static disableTestCapture(): void {
    this.testCapture = null;
  }

  static async sendPasswordResetEmail(payload: PasswordResetEmailPayload): Promise<void> {
    if (this.testCapture) {
      this.testCapture.passwordResets.push(payload);
    }
    logger.info(
      { to: payload.to, expiresAt: payload.expiresAt },
      "Password reset email dispatched via delivery provider"
    );
  }

  static async sendEmailVerificationEmail(payload: EmailVerificationEmailPayload): Promise<void> {
    if (this.testCapture) {
      this.testCapture.emailVerifications.push(payload);
    }
    logger.info(
      { to: payload.to, expiresAt: payload.expiresAt },
      "Email verification message dispatched via delivery provider"
    );
  }
}
