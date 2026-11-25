import { UserRole } from "@armsphere/types";

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role: UserRole;
        province?: string | null;
        orgId?: string;
        orgName?: string;
      };
      log?: any;
    }
  }
}
