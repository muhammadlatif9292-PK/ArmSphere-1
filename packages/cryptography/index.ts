import crypto from "crypto";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "armsphere-super-secret-key-12345";

export async function hashPassword(password: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const salt = crypto.randomBytes(16).toString("hex");
    crypto.scrypt(password, salt, 64, (err, derivedKey) => {
      if (err) reject(err);
      resolve(`${salt}:${derivedKey.toString("hex")}`);
    });
  });
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return new Promise((resolve, reject) => {
    const [salt, key] = hash.split(":");
    crypto.scrypt(password, salt, 64, (err, derivedKey) => {
      if (err) reject(err);
      resolve(derivedKey.toString("hex") === key);
    });
  });
}

export function generateAccessToken(
  userIdOrPayload: any,
  email?: string,
  role?: string,
  secret?: string
): string {
  const payload = typeof userIdOrPayload === "object"
    ? { type: "access" as const, ...userIdOrPayload }
    : { sub: userIdOrPayload, email, role, type: "access" as const };
  const signingSecret = secret || JWT_SECRET;
  return jwt.sign(payload, signingSecret, { expiresIn: "15m" });
}

export function generateRefreshToken(
  userIdOrPayload: any,
  email?: string,
  role?: string,
  tokenFamily?: string,
  secret?: string
): string {
  const payload = typeof userIdOrPayload === "object"
    ? { type: "refresh" as const, ...userIdOrPayload }
    : { sub: userIdOrPayload, email, role, family: tokenFamily, type: "refresh" as const };
  const signingSecret = secret || JWT_SECRET;
  return jwt.sign(payload, signingSecret, { expiresIn: "7d" });
}

export function verifyToken(token: string, secret?: string): any {
  return jwt.verify(token, secret || JWT_SECRET);
}
