import { authPaths } from "./auth.js";
import { athletePaths } from "./athletes.js";
import { matchPaths } from "./matches.js";
import { rankingPaths } from "./rankings.js";
import { tournamentPaths } from "./tournaments.js";
import { syncPaths } from "./sync.js";
import { adminPaths } from "./admin.js";
import { communityPaths } from "./community.js";
import { securitySchemes, rfc7807ErrorSchema } from "./common.js";

export const openapiDefinition = {
  openapi: "3.1.0",
  info: {
    title: "ArmSphere Professional Armwrestling API",
    version: "1.0.0",
    description: `Production API reference for ArmSphere, the elite armwrestling league platform. 
    Powering match submissions, live double-elimination bracket routing, certified weigh-ins, real-time ELO rankings, offline-first sync engines, PostgreSQL scheduled jobs, and robust MFA security profiles.`,
    contact: {
      name: "ArmSphere Developer Support",
      email: "muhammadlatif9292@gmail.com",
      url: "https://armsphere.com/support",
    },
    license: {
      name: "Proprietary",
      url: "https://armsphere.com/license",
    },
  },
  servers: [
    {
      url: "http://localhost:3000",
      description: "Local development server",
    },
    {
      url: "https://api.armsphere.com",
      description: "Production gateway",
    },
  ],
  tags: [
    { name: "Authentication", description: "Standard, MFA, and OAuth login flows." },
    { name: "Multi-Factor Authentication", description: "TOTP activation, validation, and backup key verification." },
    { name: "Social Auth", description: "Google and Apple deep integrated sign-in." },
    { name: "Athletes", description: "Athlete biometrics, clubs, and registrations." },
    { name: "Matches", description: "Ingesting match outcomes and resolving disputes." },
    { name: "ELO Rankings", description: "Live leaderboard displays and snapshot operations." },
    { name: "Tournaments & Brackets", description: "Double-elimination bracket generators and table setups." },
    { name: "Weigh-In System", description: "Certified scales checking." },
    { name: "Offline Sync Engine", description: "Client offline mutation queues." },
    { name: "Administration", description: "System and credential management." },
    { name: "Security Operations", description: "Token verification and CAPTCHA." },
    { name: "Observability & Diagnostics", description: "System health monitoring." },
    { name: "Community & Media", description: "Secure presigned uploads, user feeds, and post likes/comments." },
  ],
  paths: {
    ...authPaths,
    ...athletePaths,
    ...matchPaths,
    ...rankingPaths,
    ...tournamentPaths,
    ...syncPaths,
    ...adminPaths,
    ...communityPaths,
  },
  components: {
    securitySchemes,
    schemas: {
      ProblemDetails: rfc7807ErrorSchema,
    },
  },
};

export default openapiDefinition;
