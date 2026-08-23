export enum UserRole {
  ATHLETE = "ATHLETE",
  REFEREE = "REFEREE",
  PROVINCIAL_DIRECTOR = "PROVINCIAL_DIRECTOR",
  NATIONAL_DIRECTOR = "NATIONAL_DIRECTOR",
  SYSTEM_ADMIN = "SYSTEM_ADMIN",
  TOURNAMENT_OPERATOR = "TOURNAMENT_OPERATOR",
  COMPLIANCE_OFFICER = "COMPLIANCE_OFFICER",
  SUPPORT_AGENT = "SUPPORT_AGENT"
}

export interface User {
  id: string;
  email: string;
  username: string;
  role: UserRole;
  fullName: string;
}

export const ADMIN_ROLES: UserRole[] = [
  UserRole.SYSTEM_ADMIN,
  UserRole.NATIONAL_DIRECTOR,
  UserRole.PROVINCIAL_DIRECTOR,
  UserRole.TOURNAMENT_OPERATOR,
  UserRole.COMPLIANCE_OFFICER,
  UserRole.SUPPORT_AGENT
];

export interface MatchVolume {
  date: string;
  count: number;
}

export interface AnalyticsOverview {
  totalMatches: number;
  totalDisputes: number;
  disputeRatePercentage: number;
  activeAthleteCount: number;
  matchVolumeOverTime: MatchVolume[];
}

export interface DashboardStats {
  kpis: {
    totalAthletes: number;
    totalReferees: number;
    totalEvents: number;
    totalMatches: number;
    totalDisputes: number;
    activeChampionships: number;
  };
  athleteGrowth: Array<{ month: string; count: number }>;
  matchStats: {
    total: number;
    completed: number;
    pending: number;
    disputed: number;
  };
  verificationBacklog: number;
  disputeStats: {
    total: number;
    open: number;
    resolved: number;
    escalated: number;
    appealed: number;
  };
  eloHealth: {
    average: number;
    min: number;
    max: number;
  };
  systemStatus: {
    database: string;
    redis: string;
    websockets: string;
    workers: string;
    latencyMs: number;
  };
}

export interface EloDistributionItem {
  range: string;
  leftArmCount: number;
  rightArmCount: number;
}

export interface AthleteProfile {
  id: string;
  userId: string;
  displayName: string;
  province: string;
  city: string;
  handedness: string;
  dominantArm: string;
  gender: string;
  weightClass: string;
}

export interface ChampionshipTitle {
  id: string;
  name: string;
  arm: "LEFT" | "RIGHT";
  division: string;
  weightClass: string;
  activeChampionId: string | null;
  activeChampion?: AthleteProfile | null;
  createdAt: string;
  updatedAt: string;
}

export interface ChampionshipChallenge {
  id: string;
  titleId: string;
  challengerId: string;
  status: "PENDING" | "ACCEPTED" | "DECLINED" | "COMPLETED" | "EXPIRED";
  title?: ChampionshipTitle;
  challenger?: AthleteProfile;
  createdAt: string;
  updatedAt: string;
}

export interface Dispute {
  id: string;
  matchId: string | null;
  creatorId: string;
  title: string;
  description: string;
  status: string; // OPEN, UNDER_REVIEW, AWAITING_EVIDENCE, RESOLVED, REJECTED, ESCALATED, CLOSED
  resolutionDetails: string | null;
  assignedReviewerId: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface DisputeEvidence {
  id: string;
  disputeId: string;
  submitterId: string;
  fileUrl: string;
  fileType: "VIDEO" | "IMAGE" | "DOCUMENT";
  sha256Hash: string;
  virusScanned: boolean;
  virusScanResult: "PENDING" | "CLEAN" | "INFECTED";
  createdAt: string;
}

export interface AthleteAdminView {
  id: string;
  userId: string;
  displayName: string;
  province: string;
  city: string;
  handedness: string;
  dominantArm: string;
  weightClass: string;
  leftArmElo: number;
  rightArmElo: number;
  isActive: boolean;
  verificationStatus: "UNVERIFIED" | "PENDING" | "VERIFIED" | "REJECTED" | "SUSPENDED" | "BLACKLISTED";
  rejectionReason: string | null;
}

export interface ReviewProfilePayload {
  status: "VERIFIED" | "REJECTED";
  reason?: string;
}

export interface SuspendAthletePayload {
  reason: string;
  durationDays?: number;
}

export interface BlacklistAthletePayload {
  reason: string;
}

export interface ManualCorrectionPayload {
  displayName?: string;
  weightClass?: string;
  leftArmElo?: number;
  rightArmElo?: number;
  province?: string;
  city?: string;
}

export interface CreateTitlePayload {
  name: string;
  arm: "LEFT" | "RIGHT";
  division: "JUNIOR" | "SENIOR" | "FEMALE";
  weightClass: string;
}

export interface PendingCommunityPost {
  id: string;
  athleteId: string;
  externalUrl: string;
  platform: string;
  category: string;
  caption: string | null;
  matchId: string | null;
  moderationStatus: string;
  createdAt: string;
  updatedAt: string;
  athlete: {
    id: string;
    displayName: string;
    profilePhoto: string | null;
  };
}

export interface Venue {
  id: string;
  name: string;
  city: string;
  province: string;
  address: string;
  contactInfo: string | null;
  description: string | null;
  logoUrl: string | null;
  ownerUserId: string | null;
  isVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Nomination {
  id: string;
  nominatedByUserId: string;
  nomineeName: string;
  nomineeContact: string | null;
  city: string;
  province: string;
  notes: string | null;
  status: "PENDING" | "CONTACTED" | "REGISTERED" | "DECLINED";
  createdAt: string;
}

export interface RefereeCertification {
  id: string;
  userId: string;
  certificationLevel: string;
  issuedAt: string;
  expiresAt: string | null;
  status: "ACTIVE" | "EXPIRED" | "REVOKED";
  issuingBody: string;
  createdAt: string;
}

export interface IssueCertificationPayload {
  certificationLevel: string;
  issuedAt: string;
  expiresAt?: string;
  issuingBody: string;
}





