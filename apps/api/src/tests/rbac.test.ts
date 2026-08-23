import { describe, it, expect, beforeEach, vi } from "vitest";
import { Request, Response, NextFunction } from "express";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";
import { UnauthorizedError, ForbiddenError } from "@armsphere/core";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("RBAC & Token Validation Middlewares Unit Tests", () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction = vi.fn() as any;

  beforeEach(() => {
    mockRequest = {
      headers: {},
      log: {
        warn: vi.fn(),
        info: vi.fn(),
        error: vi.fn(),
      } as any,
    };
    mockResponse = {};
    nextFunction = vi.fn() as any;
  });

  describe("authenticate() middleware", () => {
    it("should allow a valid bearer token request to proceed", () => {
      const accessToken = generateAccessToken("user-1", "admin@armsphere.com", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
      mockRequest.headers!.authorization = `Bearer ${accessToken}`;

      authenticate(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith();
      expect(mockRequest.user).toBeDefined();
      expect(mockRequest.user!.role).toBe(UserRole.SYSTEM_ADMIN);
    });

    it("should pass UnauthorizedError if Authorization header is missing", () => {
      authenticate(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(expect.any(UnauthorizedError));
    });

    it("should pass UnauthorizedError if token carries invalid signature", () => {
      mockRequest.headers!.authorization = "Bearer invalid_token_signature_value";

      authenticate(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(expect.any(UnauthorizedError));
    });
  });

  describe("requireRole() middleware", () => {
    it("should allow a matching authorized role context to pass", () => {
      mockRequest.user = {
        id: "user-1",
        email: "director@armsphere.com",
        role: UserRole.NATIONAL_DIRECTOR,
      };

      const middleware = requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN);
      middleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith();
    });

    it("should throw a ForbiddenError if user carries an unauthorized lower role context", () => {
      mockRequest.user = {
        id: "user-1",
        email: "referee@armsphere.com",
        role: UserRole.REFEREE,
      };

      const middleware = requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN);
      middleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(expect.any(ForbiddenError));
    });
  });
});
