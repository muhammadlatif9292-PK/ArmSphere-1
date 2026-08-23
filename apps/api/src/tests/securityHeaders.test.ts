import { describe, it, expect } from "vitest";
import request from "supertest";
import { app } from "../app.js";

const APP_CSP_DIRECTIVES = {
  "default-src": ["'self'"],
  "script-src": ["'self'"],
  "style-src": ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
  "font-src": ["'self'", "https://fonts.gstatic.com", "data:"],
  "img-src": ["'self'", "data:", "https:"],
  "connect-src": ["'self'", "https://api.armsphere.com"],
  "frame-src": ["https://www.youtube.com", "https://www.tiktok.com", "https://www.facebook.com"],
  "frame-ancestors": ["'none'"],
  "object-src": ["'none'"],
  "base-uri": ["'self'"]
};

function parseCsp(header: string): Record<string, string[]> {
  const directives: Record<string, string[]> = {};
  for (const part of header.split(";")) {
    const tokens = part.trim().split(/\s+/);
    if (tokens[0]) {
      directives[tokens[0]] = tokens.slice(1);
    }
  }
  return directives;
}

describe("Content Security Policy & Security Headers", () => {
  it("applies the strict application CSP to API responses", async () => {
    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    const cspHeader = response.headers["content-security-policy"];
    expect(cspHeader).toBeDefined();

    const parsed = parseCsp(cspHeader);
    for (const [directive, expected] of Object.entries(APP_CSP_DIRECTIVES)) {
      expect(parsed[directive]).toEqual(expected);
    }
  });

  it("never permits wildcard sources, eval, blob:, or arbitrary framing on API responses", async () => {
    const response = await request(app).get("/health");
    const csp = response.headers["content-security-policy"];

    expect(csp).not.toContain("*");
    expect(csp).not.toContain("'unsafe-eval'");
    expect(csp).not.toContain("blob:");
    expect(csp).not.toContain("ws:");
    // Wildcard frame-ancestors would allow clickjacking
    expect(csp).toMatch(/frame-ancestors 'none'/);
  });

  it("ships complementary hardening headers on every response", async () => {
    const response = await request(app).get("/health");

    expect(response.headers["x-content-type-options"]).toBe("nosniff");
    expect(response.headers["strict-transport-security"]).toContain("max-age=");
    expect(response.headers["referrer-policy"]).toBe("strict-origin-when-cross-origin");
    expect(response.headers["permissions-policy"]).toContain("camera=()");
  });

  it("serves Swagger UI docs with a scoped inline-script allowance while keeping framing locked down", async () => {
    const response = await request(app)
      .get("/api/v1/docs")
      .redirects(1);

    const cspHeader = response.headers["content-security-policy"];
    expect(cspHeader).toBeDefined();
    const parsed = parseCsp(cspHeader);

    // Scoped relaxation: inline bootstrap allowed ONLY here
    expect(parsed["script-src"]).toContain("'unsafe-inline'");
    expect(parsed["script-src"]).not.toContain("*");
    expect(parsed["style-src"]).toContain("'unsafe-inline'");

    // Hardening must survive the relaxation
    expect(parsed["default-src"]).toEqual(["'self'"]);
    expect(parsed["frame-ancestors"]).toEqual(["'none'"]);
    expect(parsed["object-src"]).toEqual(["'none'"]);
  });
});
