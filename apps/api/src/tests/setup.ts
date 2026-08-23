import path from "path";
process.env.STRIPE_SECRET_KEY = "sk_test_mock_secret_key";
process.env.STRIPE_WEBHOOK_SECRET = "whsec_mock_webhook_secret";
process.env.CRON_SECRET = "test_cron_secret_key_1234567890_armsphere";

export let mockPaymentMethods: any[] = [];

import { vi, beforeEach } from "vitest";
console.log("=== GLOBAL: SETUP.TS EXECUTED ===");
import { UserRole } from "@armsphere/types";
import { 
  users, 
  userSessions, 
  auditLogs, 
  pendingActions,
  athleteProfiles,
  athleteClubs,
  athleteVerifications,
  athleteDocuments,
  athleteBiometrics,
  athleteMeasurements,
  athleteSocialLinks,
  athleteProfileHistory,
  matches,
  eloLedger,
  championshipTitles,
  beltLineage,
  championshipChallenges,
  prestigeMetrics,
  rankingSnapshots,
  events,
  eventRegistrations,
  officialWeighins,
  brackets,
  bracketSeeds,
  tournamentMatches,
  matchTables,
  disputes,
  disputeEvidence,
  disputeComments,
  sanctions,
  auditEvents,
  notifications,
  conversations,
  conversationParticipants,
  messages,
  announcements,
  userCommunicationPreferences,
  userDeviceTokens,
  userDevices,
  follows,
  teams,
  teamMembers,
  communityPosts,
  postLikes,
  postComments,
  blockedUsers,
  payments,
  processedStripeEvents,
  venuePartners,
  talentNominations,
  refereeCertifications,
  informalEvents,
  informalEventParticipants,
  ticketTypes,
  tickets,
  scheduledJobs,
  authTokens,
  syncTombstones
} from "@armsphere/db-schema";
import { createTestUserFixture } from "./factories.js";

// In-Memory Database Store for testing isolation
function findViewerAthleteId(obj: any, visited = new Set<any>()): string | null {
  if (!obj || typeof obj !== "object") return null;
  if (visited.has(obj)) return null;
  visited.add(obj);

  if (typeof obj.value === "string" && obj.value.length === 36) {
    return obj.value;
  }
  for (const key of Object.keys(obj)) {
    try {
      const found = findViewerAthleteId(obj[key], visited);
      if (found) return found;
    } catch (_) {}
  }
  return null;
}

export const testDbStore = {
  users: [] as any[],
  userSessions: [] as any[],
  auditLogs: [] as any[],
  pendingActions: [] as any[],
  athleteProfiles: [] as any[],
  athleteClubs: [] as any[],
  athleteVerifications: [] as any[],
  athleteDocuments: [] as any[],
  athleteBiometrics: [] as any[],
  athleteMeasurements: [] as any[],
  athleteSocialLinks: [] as any[],
  athleteProfileHistory: [] as any[],
  matches: [] as any[],
  eloLedger: [] as any[],
  championshipTitles: [] as any[],
  beltLineage: [] as any[],
  championshipChallenges: [] as any[],
  prestigeMetrics: [] as any[],
  rankingSnapshots: [] as any[],
  events: [] as any[],
  eventRegistrations: [] as any[],
  officialWeighins: [] as any[],
  brackets: [] as any[],
  bracketSeeds: [] as any[],
  tournamentMatches: [] as any[],
  matchTables: [] as any[],
  disputes: [] as any[],
  disputeEvidence: [] as any[],
  disputeComments: [] as any[],
  sanctions: [] as any[],
  auditEvents: [] as any[],
  notifications: [] as any[],
  conversations: [] as any[],
  conversationParticipants: [] as any[],
  messages: [] as any[],
  announcements: [] as any[],
  userCommunicationPreferences: [] as any[],
  userDeviceTokens: [] as any[],
  userDevices: [] as any[],
  follows: [] as any[],
  teams: [] as any[],
  teamMembers: [] as any[],
  communityPosts: [] as any[],
  postLikes: [] as any[],
  postComments: [] as any[],
  blockedUsers: [] as any[],
  payments: [] as any[],
  processedStripeEvents: [] as any[],
  venuePartners: [] as any[],
  talentNominations: [] as any[],
  refereeCertifications: [] as any[],
  informalEvents: [] as any[],
  informalEventParticipants: [] as any[],
  ticketTypes: [] as any[],
  tickets: [] as any[],
  scheduledJobs: [] as any[],
  authTokens: [] as any[],
  syncTombstones: [] as any[],
};

// Reset store before each test run
beforeEach(() => {
  mockPaymentMethods.length = 0;
  mockPaymentMethods.push(
    {
      id: "pm_mock_visa",
      customer: "cus_mock_123",
      type: "card",
      card: {
        brand: "visa",
        last4: "4242",
        exp_month: 12,
        exp_year: 2028,
      },
    },
    {
      id: "pm_mock_mastercard",
      customer: "cus_mock_123",
      type: "card",
      card: {
        brand: "mastercard",
        last4: "5555",
        exp_month: 10,
        exp_year: 2027,
      },
    }
  );

  testDbStore.users = [];
  testDbStore.userSessions = [];
  testDbStore.auditLogs = [];
  testDbStore.pendingActions = [];
  testDbStore.athleteProfiles = [];
  testDbStore.athleteClubs = [];
  testDbStore.athleteVerifications = [];
  testDbStore.athleteDocuments = [];
  testDbStore.athleteBiometrics = [];
  testDbStore.athleteMeasurements = [];
  testDbStore.athleteSocialLinks = [];
  testDbStore.athleteProfileHistory = [];
  testDbStore.matches = [];
  testDbStore.eloLedger = [];
  testDbStore.championshipTitles = [];
  testDbStore.beltLineage = [];
  testDbStore.championshipChallenges = [];
  testDbStore.prestigeMetrics = [];
  testDbStore.rankingSnapshots = [];
  testDbStore.events = [];
  testDbStore.eventRegistrations = [];
  testDbStore.officialWeighins = [];
  testDbStore.payments = [];
  testDbStore.processedStripeEvents = [];
  testDbStore.brackets = [];
  testDbStore.bracketSeeds = [];
  testDbStore.tournamentMatches = [];
  testDbStore.matchTables = [];
  testDbStore.disputes = [];
  testDbStore.disputeEvidence = [];
  testDbStore.disputeComments = [];
  testDbStore.sanctions = [];
  testDbStore.auditEvents = [];
  testDbStore.notifications = [];
  testDbStore.conversations = [];
  testDbStore.conversationParticipants = [];
  testDbStore.messages = [];
  testDbStore.announcements = [];
  testDbStore.userCommunicationPreferences = [];
  testDbStore.userDeviceTokens = [];
  testDbStore.userDevices = [];
  testDbStore.follows = [];
  testDbStore.teams = [];
  testDbStore.teamMembers = [];
  testDbStore.communityPosts = [];
  testDbStore.postLikes = [];
  testDbStore.postComments = [];
  testDbStore.blockedUsers = [];
  testDbStore.venuePartners = [];
  testDbStore.talentNominations = [];
  testDbStore.refereeCertifications = [];
  testDbStore.informalEvents = [];
  testDbStore.informalEventParticipants = [];
  testDbStore.ticketTypes = [];
  testDbStore.tickets = [];
  testDbStore.scheduledJobs = [];
  testDbStore.authTokens = [];
});

// Helper to evaluate mock query matching conditions
function getFieldVal(item: any, f: any) {
  if (!f) return undefined;
  const fieldName = typeof f === "string" ? f : (f.name || f.columnName || f.key);
  if (!fieldName || typeof fieldName !== "string") return undefined;
  const camelField = fieldName.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
  const val = item[fieldName] !== undefined ? item[fieldName] : item[camelField];
  if (val === undefined && (fieldName === "is_deleted" || camelField === "isDeleted")) {
    return false;
  }
  return val;
}

function checkMatch(item: any, expr: any): boolean {
  if (!expr) return true;
  if (expr.type === "and" && Array.isArray(expr.conditions)) {
    return expr.conditions.every((cond: any) => checkMatch(item, cond));
  }
  if (expr.type === "or" && Array.isArray(expr.conditions)) {
    return expr.conditions.some((cond: any) => checkMatch(item, cond));
  }
  if (expr.type === "sql") {
    if (Array.isArray(expr.values)) {
      // Check for OR-based multi-column equality used by ownership lookups:
      // sql`${t.deviceId} = ${v} OR ${t.id}::text = ${v}`
      if (expr.values.length === 4) {
        const joinedStr = Array.isArray(expr.strings) ? expr.strings.join("") : String(expr.strings);
        if (joinedStr.includes(" OR ") && (joinedStr.match(/=/g) || []).length >= 2) {
          const [f1, v1, f2, v2] = expr.values;
          const eqOn = (fieldObj: any, val: any): boolean => {
            if (!fieldObj || typeof fieldObj !== "object" || !fieldObj.name) return false;
            const itemVal = getFieldVal(item, fieldObj.name);
            if (itemVal === undefined || itemVal === null) return false;
            return String(itemVal) === String(val);
          };
          return eqOn(f1, v1) || eqOn(f2, v2);
        }
      }
      // Check for ID pagination cursor: sql`${athleteProfiles.id} > ${cursorAthleteId}`
      if (expr.values.length === 2) {
        const joinedStr = Array.isArray(expr.strings) ? expr.strings.join("") : String(expr.strings);
        if (joinedStr.includes("!=")) {
          const fieldObj = expr.values[0];
          const val = expr.values[1];
          if (fieldObj && typeof fieldObj === "object" && fieldObj.name) {
            const itemVal = getFieldVal(item, fieldObj.name);
            return String(itemVal) !== String(val);
          }
        }
        const val = expr.values[1];
        if (typeof val === "string" && val.startsWith("00000000-0000-")) {
          if (joinedStr.includes(">")) {
            return item.id > val;
          }
        }
      }
      // Check for scheduling comparison: sql`${announcements.scheduledFor} <= ${now}`
      if (expr.values.length === 2) {
        const joinedStr = Array.isArray(expr.strings) ? expr.strings.join("") : String(expr.strings);
        if (joinedStr.includes("<=")) {
          const fieldObj = expr.values[0];
          const val = expr.values[1];
          if (fieldObj && (fieldObj.name === "scheduled_for" || fieldObj.name === "scheduledFor")) {
            const itemVal = getFieldVal(item, "scheduled_for");
            if (itemVal === undefined || itemVal === null) return false;
            const itemValParsed = typeof itemVal === "string" || itemVal instanceof Date ? new Date(itemVal) : itemVal;
            const compareVal = typeof val === "string" || val instanceof Date ? new Date(val) : val;
            return itemValParsed <= compareVal;
          }
        }
      }
      // Check for ticket expiration comparison: sql`${tickets.createdAt} < ${fifteenMinutesAgo}`
      if (expr.values.length === 2) {
        const joinedStr = Array.isArray(expr.strings) ? expr.strings.join("") : String(expr.strings);
        if (joinedStr.includes("<")) {
          const fieldObj = expr.values[0];
          const val = expr.values[1];
          if (fieldObj && (fieldObj.name === "created_at" || fieldObj.name === "createdAt")) {
            const itemVal = getFieldVal(item, "created_at");
            if (itemVal === undefined || itemVal === null) return false;
            const itemValParsed = typeof itemVal === "string" || itemVal instanceof Date ? new Date(itemVal) : itemVal;
            const compareVal = typeof val === "string" || val instanceof Date ? new Date(val) : val;
            return itemValParsed < compareVal;
          }
          if (fieldObj && (fieldObj.name === "last_active_at" || fieldObj.name === "lastActiveAt")) {
            const itemVal = getFieldVal(item, "last_active_at");
            if (itemVal === undefined || itemVal === null) return false;
            const itemValParsed = typeof itemVal === "string" || itemVal instanceof Date ? new Date(itemVal) : itemVal;
            const compareVal = typeof val === "string" || val instanceof Date ? new Date(val) : val;
            return itemValParsed < compareVal;
          }
        }
      }
      const searchVal = expr.values.find((v: any) => typeof v === "string" && v.includes("%"));
      if (searchVal) {
        const cleanPattern = searchVal.replace(/%/g, "").toLowerCase();
        return item.displayName && item.displayName.toLowerCase().includes(cleanPattern);
      }
    }
    return true;
  }
  if (expr.operator === "not") {
    return !checkMatch(item, expr.condition);
  }
  if (expr.operator === "notInArray") {
    const f = expr.field;
    const itemVal = getFieldVal(item, f);
    const arr = Array.isArray(expr.value) ? expr.value : [];
    return !arr.includes(itemVal);
  }
  if (expr.operator === "inArray") {
    const f = expr.field;
    const itemVal = getFieldVal(item, f);
    const arr = Array.isArray(expr.value) ? expr.value : [];
    return arr.includes(itemVal);
  }
  if (expr.operator === "ne") {
    const f = expr.field;
    const itemVal = getFieldVal(item, f);
    return itemVal !== expr.value;
  }
  if (expr.operator === "isNull") {
    const f = expr.field;
    if (f === "vacatedAt" || f === "vacated_at") {
      return item.vacatedAt === null || item.vacatedAt === undefined;
    }
    if (f === "active_champion_id" || f === "activeChampionId") {
      return item.activeChampionId === null || item.activeChampionId === undefined;
    }
    const val = getFieldVal(item, f);
    return val === null || val === undefined;
  }
  if (expr.operator === "isNotNull") {
    const f = expr.field;
    if (f === "vacatedAt" || f === "vacated_at") {
      return item.vacatedAt !== null && item.vacatedAt !== undefined;
    }
    if (f === "active_champion_id" || f === "activeChampionId") {
      return item.activeChampionId !== null && item.activeChampionId !== undefined;
    }
    const val = getFieldVal(item, f);
    return val !== null && val !== undefined;
  }
  if (expr.operator === "lt") {
    const f = expr.field;
    let itemVal = f === "leftArmElo" || f === "left_arm_elo" ? item.leftArmElo : f === "rightArmElo" || f === "right_arm_elo" ? item.rightArmElo : getFieldVal(item, f);
    if ((f === "endsAt" || f === "ends_at") && (itemVal === undefined || itemVal === null)) {
      itemVal = item.expiresAt || item.expires_at || item.endsAt || item.ends_at;
    }
    const valCompare = typeof expr.value === "string" || expr.value instanceof Date ? new Date(expr.value) : expr.value;
    const itemValParsed = typeof itemVal === "string" || itemVal instanceof Date ? new Date(itemVal) : itemVal;
    return itemValParsed < valCompare;
  }
  if (expr.operator === "gt") {
    const f = expr.field;
    const itemVal = f === "createdAt" || f === "created_at" ? new Date(item.createdAt || item.created_at) : getFieldVal(item, f);
    const compareVal = typeof expr.value === "string" || expr.value instanceof Date ? new Date(expr.value) : expr.value;
    return itemVal > compareVal;
  }
  if (expr.operator === "gte") {
    const f = expr.field;
    const itemVal = f === "createdAt" || f === "created_at" ? new Date(item.createdAt || item.created_at) : (f === "leftArmElo" || f === "left_arm_elo" ? item.leftArmElo : f === "rightArmElo" || f === "right_arm_elo" ? item.rightArmElo : getFieldVal(item, f));
    const compareVal = typeof expr.value === "string" || expr.value instanceof Date ? new Date(expr.value) : expr.value;
    return itemVal >= compareVal;
  }
  if (expr.operator === "lte") {
    const f = expr.field;
    const itemVal = getFieldVal(item, f);
    if (itemVal === undefined || itemVal === null) return false;
    const itemValParsed = typeof itemVal === "string" || itemVal instanceof Date ? new Date(itemVal) : itemVal;
    const compareVal = typeof expr.value === "string" || expr.value instanceof Date ? new Date(expr.value) : expr.value;
    return itemValParsed <= compareVal;
  }
  if (expr.operator === "like" && expr.field === "display_name") {
    const cleanPattern = (expr.value || "").replace(/%/g, "").toLowerCase();
    return item.displayName && item.displayName.toLowerCase().includes(cleanPattern);
  }
  if (expr.field) {
    const val = expr.value;
    if (expr.field === "email") return item.email === val;
    if (expr.field === "username") return item.username === val;
    if (expr.field === "id") return item.id === val;
    if (expr.field === "user_id" || expr.field === "userId") return (item.userId || item.user_id) === val;
    if (expr.field === "athlete_id" || expr.field === "athleteId") return (item.athleteId || item.athlete_id) === val;
    if (expr.field === "title_id" || expr.field === "titleId") return (item.titleId || item.title_id) === val;
    if (expr.field === "challenger_id" || expr.field === "challengerId") return (item.challengerId || item.challenger_id) === val;
    if (expr.field === "arm") return item.arm === val;
    if (expr.field === "division") return item.division === val;
    if (expr.field === "weight_class" || expr.field === "weightClass") return (item.weightClass || item.weight_class) === val;
    if (expr.field === "snapshot_type" || expr.field === "snapshotType") return (item.snapshotType || item.snapshot_type) === val;
    if (expr.field === "status") return item.status === val;
    if (expr.field === "tokenFamily") return item.tokenFamily === val;
    if (expr.field === "idempotency_key") return item.idempotencyKey === val;
    if (expr.field === "isDeleted") return item.isDeleted === val;
    if (expr.field === "province") return item.province === val;
    if (expr.field === "country") return item.country === val;
    if (expr.field === "club_id" || expr.field === "clubId") return (item.clubId || item.club_id) === val;

    const resolvedVal = getFieldVal(item, expr.field);
    return resolvedVal === val;
  }
  return true;
}

// High-fidelity mock representation of Drizzle ORM query runner
const mockDrizzle = {
  query: {
    championshipTitles: {
      findMany: async (options?: any) => {
        let results = [...testDbStore.championshipTitles];
        if (options?.where) {
          results = results.filter((item) => checkMatch(item, options.where));
        }
        if (options?.with?.activeChampion) {
          results = results.map((title) => {
            const activeChampion = testDbStore.athleteProfiles.find(
              (p) => p.id === title.activeChampionId
            );
            return {
              ...title,
              activeChampion: activeChampion || null,
            };
          });
        }
        return results;
      }
    },
    championshipChallenges: {
      findMany: async (options?: any) => {
        let results = [...testDbStore.championshipChallenges];
        if (options?.where) {
          results = results.filter((item) => checkMatch(item, options.where));
        }
        results = results.map((challenge) => {
          const title = options?.with?.title
            ? testDbStore.championshipTitles.find((t) => t.id === challenge.titleId)
            : undefined;
          const challenger = options?.with?.challenger
            ? testDbStore.athleteProfiles.find((p) => p.id === challenge.challengerId)
            : undefined;
          return {
            ...challenge,
            title: title || null,
            challenger: challenger || null,
          };
        });
        
        results.sort((a, b) => {
          const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          return dateB - dateA;
        });

        return results;
      }
    }
  },
  select: (fieldsObj?: any) => ({
    from: (table: any) => {
      let results: any[] = [];
      if (table === users) {
        results = testDbStore.users;
      } else if (table === userSessions) {
        results = testDbStore.userSessions;
      } else if (table === pendingActions) {
        results = testDbStore.pendingActions;
      } else if (table === athleteProfiles) {
        results = testDbStore.athleteProfiles;
      } else if (table === athleteClubs) {
        results = testDbStore.athleteClubs;
      } else if (table === athleteVerifications) {
        results = testDbStore.athleteVerifications;
      } else if (table === athleteBiometrics) {
        results = testDbStore.athleteBiometrics;
      } else if (table === athleteMeasurements) {
        results = testDbStore.athleteMeasurements;
      } else if (table === athleteSocialLinks) {
        results = testDbStore.athleteSocialLinks;
      } else if (table === matches) {
        results = testDbStore.matches.map((m) => {
          const challenger = testDbStore.athleteProfiles.find((ap) => ap.id === m.challengerId);
          const opponent = testDbStore.athleteProfiles.find((ap) => ap.id === m.opponentId);
          return {
            ...m,
            challengerName: challenger ? challenger.displayName : undefined,
            opponentName: opponent ? opponent.displayName : undefined,
          };
        });
      } else if (table === eloLedger) {
        results = testDbStore.eloLedger;
      } else if (table === championshipTitles) {
        results = testDbStore.championshipTitles;
      } else if (table === beltLineage) {
        results = testDbStore.beltLineage;
      } else if (table === championshipChallenges) {
        results = testDbStore.championshipChallenges;
      } else if (table === prestigeMetrics) {
        results = testDbStore.prestigeMetrics;
      } else if (table === rankingSnapshots) {
        results = testDbStore.rankingSnapshots;
      } else if (table === events) {
        results = testDbStore.events;
      } else if (table === eventRegistrations) {
        results = testDbStore.eventRegistrations;
      } else if (table === payments) {
        results = testDbStore.payments;
      } else if (table === processedStripeEvents) {
        results = testDbStore.processedStripeEvents;
      } else if (table === officialWeighins) {
        results = testDbStore.officialWeighins;
      } else if (table === brackets) {
        results = testDbStore.brackets;
      } else if (table === bracketSeeds) {
        results = testDbStore.bracketSeeds;
      } else if (table === tournamentMatches) {
        results = testDbStore.tournamentMatches.map((tm) => {
          const bracket = testDbStore.brackets.find((b) => b.id === tm.bracketId);
          return {
            ...tm,
            arm: bracket ? bracket.arm : undefined,
          };
        });
      } else if (table === matchTables) {
        results = testDbStore.matchTables;
      } else if (table === disputes) {
        results = testDbStore.disputes;
      } else if (table === disputeEvidence) {
        results = testDbStore.disputeEvidence;
      } else if (table === disputeComments) {
        results = testDbStore.disputeComments;
      } else if (table === sanctions) {
        results = testDbStore.sanctions;
      } else if (table === auditEvents) {
        results = testDbStore.auditEvents;
      } else if (table === notifications) {
        results = testDbStore.notifications;
      } else if (table === conversations) {
        results = testDbStore.conversations;
      } else if (table === conversationParticipants) {
        results = testDbStore.conversationParticipants;
      } else if (table === messages) {
        results = testDbStore.messages;
      } else if (table === announcements) {
        results = testDbStore.announcements;
      } else if (table === userCommunicationPreferences) {
        results = testDbStore.userCommunicationPreferences;
      } else if (table === userDeviceTokens) {
        results = testDbStore.userDeviceTokens;
      } else if (table === userDevices) {
        results = testDbStore.userDevices;
      } else if (table === follows) {
        results = testDbStore.follows;
      } else if (table === blockedUsers) {
        results = testDbStore.blockedUsers.map((bu) => {
          const athlete = testDbStore.athleteProfiles.find((ap) => ap.id === bu.blockedId);
          return {
            id: athlete ? athlete.id : bu.blockedId,
            userId: athlete ? athlete.userId : undefined,
            displayName: athlete ? athlete.displayName : undefined,
            province: athlete ? athlete.province : undefined,
            city: athlete ? athlete.city : undefined,
            profilePhoto: athlete ? (athlete.profilePhoto || null) : null,
            gender: athlete ? athlete.gender : undefined,
            weightClass: athlete ? athlete.weightClass : undefined,
            blockedAt: bu.createdAt,
            blockerId: bu.blockerId,
            blockedId: bu.blockedId,
          };
        });
      } else if (table === teams) {
        results = testDbStore.teams;
      } else if (table === teamMembers) {
        results = testDbStore.teamMembers;
      } else if (table === communityPosts) {
        results = testDbStore.communityPosts.map((post) => {
          const athlete = testDbStore.athleteProfiles.find((ap) => ap.id === post.athleteId);
          return {
            ...post,
            likedByViewer: false,
            athlete: athlete ? {
              id: athlete.id,
              displayName: athlete.displayName,
              profilePhoto: athlete.profilePhoto || null,
            } : null,
          };
        });
      } else if (table === postLikes) {
        results = testDbStore.postLikes;
      } else if (table === postComments) {
        results = testDbStore.postComments.map((comment) => {
          const athlete = testDbStore.athleteProfiles.find((ap) => ap.id === comment.athleteId);
          return {
            ...comment,
            athlete: athlete ? {
              id: athlete.id,
              displayName: athlete.displayName,
              profilePhoto: athlete.profilePhoto || null,
            } : null,
          };
        });
      } else if (table === venuePartners) {
        results = testDbStore.venuePartners;
      } else if (table === talentNominations) {
        results = testDbStore.talentNominations;
      } else if (table === refereeCertifications) {
        results = testDbStore.refereeCertifications;
      } else if (table === informalEvents) {
        results = testDbStore.informalEvents;
      } else if (table === informalEventParticipants) {
        results = testDbStore.informalEventParticipants.map((iep) => {
          const userObj = testDbStore.users.find((u) => u.id === iep.userId);
          const profileObj = testDbStore.athleteProfiles.find((p) => p.userId === iep.userId);
          return {
            id: iep.id,
            informalEventId: iep.informalEventId,
            userId: iep.userId,
            fullName: userObj ? userObj.fullName : undefined,
            username: userObj ? userObj.username : undefined,
            profilePhoto: profileObj ? profileObj.profilePhoto : null,
          };
        });
      } else if (table === ticketTypes) {
        results = testDbStore.ticketTypes;
      } else if (table === tickets) {
        results = testDbStore.tickets;
      } else if (table === scheduledJobs) {
        results = testDbStore.scheduledJobs;
      } else if (table === authTokens) {
        results = testDbStore.authTokens;
      } else if (table === syncTombstones) {
        results = testDbStore.syncTombstones;
      }

      const chain = {
        leftJoin: (joinedTable: any, joinOn: any) => {
          if (joinedTable === postLikes) {
            const viewerId = findViewerAthleteId(joinOn);
            if (viewerId) {
              results = results.map(item => {
                const isLiked = testDbStore.postLikes.some(
                  like => like.postId === item.id && like.athleteId === viewerId
                );
                return {
                  ...item,
                  likedByViewer: isLiked,
                };
              });
            } else {
              results = results.map(item => ({
                ...item,
                likedByViewer: false,
              }));
            }
          }
          return chain;
        },
        innerJoin: (joinedTable: any, joinOn: any) => {
          return chain;
        },
        where: (expression: any) => {
          results = results.filter((item) => checkMatch(item, expression));
          return chain;
        },
        limit: (n: number) => {
          results = results.slice(0, n);
          return chain;
        },
        // Mock-only no-op: this single-threaded, single-process in-memory
        // store has no concept of row locks or concurrent transactions, so
        // there is nothing here for `.for("update")` to actually do. This
        // exists purely so real application code that calls `.for("update")`
        // (a genuine SELECT ... FOR UPDATE against real Postgres) doesn't
        // crash against this mock. It does NOT prove real concurrent-request
        // locking behavior — that can only be verified against a real
        // Postgres instance, which this test environment does not have.
        // Do not treat a passing test that exercises this path as evidence
        // that row locking works under real concurrency.
        for: (_strength: string, _config?: any) => {
          return chain;
        },
        offset: (n: number) => {
          results = results.slice(n);
          return chain;
        },
        orderBy: (...args: any[]) => {
          if (args.length > 0) {
            const firstArg = args[0];
            if (firstArg && typeof firstArg === "object" && firstArg.field) {
              const field = firstArg.field;
              const camelField = field.replace(/_([a-z])/g, (g: any) => g[1].toUpperCase());
              const isDesc = firstArg.direction === "desc";
              results = [...results].sort((a, b) => {
                const valA = a[camelField] ?? a[field] ?? 0;
                const valB = b[camelField] ?? b[field] ?? 0;
                if (valA === valB) {
                  return a.id > b.id ? 1 : -1;
                }
                return isDesc ? valB - valA : valA - valB;
              });
            }
          }
          return chain;
        },
        then: (resolve: any) => Promise.resolve(results).then(resolve),
      };

      return chain;
    }
  }),

  insert: (table: any) => ({
    values: (valueObj: any) => {
      const isArray = Array.isArray(valueObj);
      const items = isArray ? valueObj : [valueObj];

      const records = items.map((item) => ({
        id: item.id || "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
          const r = (Math.random() * 16) | 0;
          const v = c === "x" ? r : (r & 0x3) | 0x8;
          return v.toString(16);
        }),
        createdAt: new Date(),
        updatedAt: new Date(),
        ...item,
      }));

      // Guardrail: every table's `id` column in this schema is a genuine
      // Postgres `uuid` type EXCEPT `processedStripeEvents`, which uses
      // `varchar` by design to store Stripe's own event ID string (e.g.
      // "evt_xxx") directly as the primary key — that's correct, not a bug.
      // A real database rejects any non-UUID string in an actual uuid
      // column with "invalid input syntax for type uuid" — this plain-array
      // mock has no concept of column types and would otherwise happily
      // accept anything, silently hiding bugs like hand-crafted IDs (e.g.
      // `wb-${bracketId}-1-1`) that pass every test here but crash the
      // instant they hit a real database. Fail loudly instead, the same way
      // Postgres would, so this class of bug can't hide behind a green
      // test suite again.
      if (table !== processedStripeEvents) {
        const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        for (const record of records) {
          if (record.id !== undefined && record.id !== null && !UUID_RE.test(String(record.id))) {
            throw new Error(
              `Mock DB guardrail: attempted to insert non-UUID id "${record.id}" into a uuid-typed column. ` +
              `A real Postgres database would reject this with "invalid input syntax for type uuid". ` +
              `Generate IDs with crypto.randomUUID() (or let the column default handle it) instead of a hand-built string.`
            );
          }
        }
      }

      // Guardrail: enforce the actual composite-unique database constraints
      // this schema declares, so a test claiming "duplicate X is rejected"
      // is proving something real rather than trusting an in-memory array
      // that has no concept of constraints at all. This does NOT simulate
      // concurrency/locking (a single-threaded mock structurally can't) —
      // only the synchronous uniqueness invariant itself, which is a
      // real, meaningful thing to verify even without a live database.
      const UNIQUE_CONSTRAINTS: { table: any; store: () => any[]; columns: string[] }[] = [
        { table: eloLedger, store: () => testDbStore.eloLedger, columns: ["matchId", "athleteId"] },
        { table: teamMembers, store: () => testDbStore.teamMembers, columns: ["teamId", "athleteId"] },
      ];
      const constraint = UNIQUE_CONSTRAINTS.find((c) => c.table === table);
      if (constraint) {
        for (const record of records) {
          const existing = constraint.store();
          const clash = existing.find((row) =>
            constraint.columns.every((col) => row[col] === record[col])
          );
          if (clash) {
            throw new Error(
              `Mock DB guardrail: duplicate insert violates unique constraint on (${constraint.columns.join(", ")}). ` +
              `A real Postgres database would reject this the same way.`
            );
          }
        }
      }

      records.forEach((record) => {
        if (table === users) {
          testDbStore.users.push(record);
        } else if (table === userSessions) {
          testDbStore.userSessions.push(record);
        } else if (table === auditLogs) {
          testDbStore.auditLogs.push(record);
        } else if (table === pendingActions) {
          testDbStore.pendingActions.push(record);
        } else if (table === athleteProfiles) {
          testDbStore.athleteProfiles.push({
            profileVisibility: "PUBLIC",
            isSearchable: true,
            ...record
          });
        } else if (table === athleteClubs) {
          testDbStore.athleteClubs.push(record);
        } else if (table === athleteVerifications) {
          testDbStore.athleteVerifications.push(record);
        } else if (table === athleteDocuments) {
          testDbStore.athleteDocuments.push(record);
        } else if (table === athleteBiometrics) {
          testDbStore.athleteBiometrics.push(record);
        } else if (table === athleteMeasurements) {
          testDbStore.athleteMeasurements.push(record);
        } else if (table === athleteSocialLinks) {
          testDbStore.athleteSocialLinks.push(record);
        } else if (table === athleteProfileHistory) {
          testDbStore.athleteProfileHistory.push(record);
        } else if (table === matches) {
          testDbStore.matches.push(record);
        } else if (table === eloLedger) {
          testDbStore.eloLedger.push(record);
        } else if (table === championshipTitles) {
          testDbStore.championshipTitles.push(record);
        } else if (table === beltLineage) {
          testDbStore.beltLineage.push(record);
        } else if (table === championshipChallenges) {
          testDbStore.championshipChallenges.push(record);
        } else if (table === prestigeMetrics) {
          testDbStore.prestigeMetrics.push(record);
        } else if (table === rankingSnapshots) {
          testDbStore.rankingSnapshots.push(record);
        } else if (table === events) {
          testDbStore.events.push(record);
        } else if (table === eventRegistrations) {
          testDbStore.eventRegistrations.push(record);
        } else if (table === payments) {
          testDbStore.payments.push(record);
        } else if (table === processedStripeEvents) {
          testDbStore.processedStripeEvents.push(record);
        } else if (table === officialWeighins) {
          testDbStore.officialWeighins.push(record);
        } else if (table === brackets) {
          testDbStore.brackets.push(record);
        } else if (table === bracketSeeds) {
          testDbStore.bracketSeeds.push(record);
        } else if (table === tournamentMatches) {
          testDbStore.tournamentMatches.push(record);
        } else if (table === matchTables) {
          testDbStore.matchTables.push(record);
        } else if (table === disputes) {
          testDbStore.disputes.push(record);
        } else if (table === disputeEvidence) {
          testDbStore.disputeEvidence.push(record);
        } else if (table === disputeComments) {
          testDbStore.disputeComments.push(record);
        } else if (table === sanctions) {
          testDbStore.sanctions.push(record);
        } else if (table === auditEvents) {
          testDbStore.auditEvents.push(record);
        } else if (table === notifications) {
          testDbStore.notifications.push(record);
        } else if (table === conversations) {
          testDbStore.conversations.push(record);
        } else if (table === conversationParticipants) {
          testDbStore.conversationParticipants.push(record);
        } else if (table === messages) {
          testDbStore.messages.push(record);
        } else if (table === announcements) {
          testDbStore.announcements.push(record);
        } else if (table === userCommunicationPreferences) {
          testDbStore.userCommunicationPreferences.push(record);
        } else if (table === userDeviceTokens) {
          testDbStore.userDeviceTokens.push(record);
        } else if (table === userDevices) {
          testDbStore.userDevices.push(record);
        } else if (table === follows) {
          testDbStore.follows.push(record);
        } else if (table === blockedUsers) {
          testDbStore.blockedUsers.push(record);
        } else if (table === teams) {
          testDbStore.teams.push(record);
        } else if (table === teamMembers) {
          testDbStore.teamMembers.push(record);
        } else if (table === communityPosts) {
          testDbStore.communityPosts.push(record);
        } else if (table === postLikes) {
          testDbStore.postLikes.push(record);
        } else if (table === postComments) {
          testDbStore.postComments.push(record);
        } else if (table === venuePartners) {
          testDbStore.venuePartners.push(record);
        } else if (table === talentNominations) {
          testDbStore.talentNominations.push(record);
        } else if (table === refereeCertifications) {
          testDbStore.refereeCertifications.push(record);
        } else if (table === informalEvents) {
          testDbStore.informalEvents.push(record);
        } else if (table === informalEventParticipants) {
          testDbStore.informalEventParticipants.push(record);
        } else if (table === ticketTypes) {
          testDbStore.ticketTypes.push(record);
        } else if (table === tickets) {
          testDbStore.tickets.push(record);
        } else if (table === scheduledJobs) {
          testDbStore.scheduledJobs.push(record);
        } else if (table === authTokens) {
          testDbStore.authTokens.push(record);
        } else if (table === syncTombstones) {
          testDbStore.syncTombstones.push(record);
        }
      });

      return {
        returning: () => Promise.resolve(records),
        then: (resolve: any) => Promise.resolve(records).then(resolve),
      };
    },
  }),

  update: (table: any) => ({
    set: (updateValues: any) => ({
      where: (expression: any) => {
        let matched: any[] = [];
        if (table === userSessions) {
          testDbStore.userSessions = testDbStore.userSessions.map((s) => {
            if (checkMatch(s, expression)) {
              const updated = { ...s, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return s;
          });
        } else if (table === pendingActions) {
          testDbStore.pendingActions = testDbStore.pendingActions.map((p) => {
            if (checkMatch(p, expression)) {
              const updated = { ...p, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return p;
          });
        } else if (table === users) {
          testDbStore.users = testDbStore.users.map((u) => {
            if (checkMatch(u, expression)) {
              const updated = { ...u, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return u;
          });
        } else if (table === athleteProfiles) {
          testDbStore.athleteProfiles = testDbStore.athleteProfiles.map((ap) => {
            if (checkMatch(ap, expression)) {
              const updated = { ...ap, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ap;
          });
        } else if (table === athleteVerifications) {
          testDbStore.athleteVerifications = testDbStore.athleteVerifications.map((av) => {
            if (checkMatch(av, expression)) {
              const updated = { ...av, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return av;
          });
        } else if (table === athleteBiometrics) {
          testDbStore.athleteBiometrics = testDbStore.athleteBiometrics.map((ab) => {
            if (checkMatch(ab, expression)) {
              const updated = { ...ab, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ab;
          });
        } else if (table === athleteMeasurements) {
          testDbStore.athleteMeasurements = testDbStore.athleteMeasurements.map((am) => {
            if (checkMatch(am, expression)) {
              const updated = { ...am, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return am;
          });
        } else if (table === matches) {
          testDbStore.matches = testDbStore.matches.map((m) => {
            if (checkMatch(m, expression)) {
              const updated = { ...m, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return m;
          });
        } else if (table === championshipTitles) {
          testDbStore.championshipTitles = testDbStore.championshipTitles.map((t) => {
            if (checkMatch(t, expression)) {
              const updated = { ...t, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return t;
          });
        } else if (table === beltLineage) {
          testDbStore.beltLineage = testDbStore.beltLineage.map((l) => {
            if (checkMatch(l, expression)) {
              const updated = { ...l, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return l;
          });
        } else if (table === championshipChallenges) {
          testDbStore.championshipChallenges = testDbStore.championshipChallenges.map((c) => {
            if (checkMatch(c, expression)) {
              const updated = { ...c, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return c;
          });
        } else if (table === prestigeMetrics) {
          testDbStore.prestigeMetrics = testDbStore.prestigeMetrics.map((p) => {
            if (checkMatch(p, expression)) {
              const updated = { ...p, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return p;
          });
        } else if (table === rankingSnapshots) {
          testDbStore.rankingSnapshots = testDbStore.rankingSnapshots.map((r) => {
            if (checkMatch(r, expression)) {
              const updated = { ...r, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return r;
          });
        } else if (table === events) {
          testDbStore.events = testDbStore.events.map((e) => {
            if (checkMatch(e, expression)) {
              const updated = { ...e, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return e;
          });
        } else if (table === eventRegistrations) {
          testDbStore.eventRegistrations = testDbStore.eventRegistrations.map((er) => {
            if (checkMatch(er, expression)) {
              const updated = { ...er, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return er;
          });
        } else if (table === payments) {
          testDbStore.payments = testDbStore.payments.map((p) => {
            if (checkMatch(p, expression)) {
              const updated = { ...p, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return p;
          });
        } else if (table === processedStripeEvents) {
          testDbStore.processedStripeEvents = testDbStore.processedStripeEvents.map((e) => {
            if (checkMatch(e, expression)) {
              const updated = { ...e, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return e;
          });
        } else if (table === officialWeighins) {
          testDbStore.officialWeighins = testDbStore.officialWeighins.map((w) => {
            if (checkMatch(w, expression)) {
              const updated = { ...w, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return w;
          });
        } else if (table === brackets) {
          testDbStore.brackets = testDbStore.brackets.map((b) => {
            if (checkMatch(b, expression)) {
              const updated = { ...b, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return b;
          });
        } else if (table === bracketSeeds) {
          testDbStore.bracketSeeds = testDbStore.bracketSeeds.map((bs) => {
            if (checkMatch(bs, expression)) {
              const updated = { ...bs, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return bs;
          });
        } else if (table === tournamentMatches) {
          testDbStore.tournamentMatches = testDbStore.tournamentMatches.map((tm) => {
            if (checkMatch(tm, expression)) {
              const updated = { ...tm, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return tm;
          });
        } else if (table === matchTables) {
          testDbStore.matchTables = testDbStore.matchTables.map((mt) => {
            if (checkMatch(mt, expression)) {
              const updated = { ...mt, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return mt;
          });
        } else if (table === disputes) {
          testDbStore.disputes = testDbStore.disputes.map((d) => {
            if (checkMatch(d, expression)) {
              const updated = { ...d, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return d;
          });
        } else if (table === disputeEvidence) {
          testDbStore.disputeEvidence = testDbStore.disputeEvidence.map((de) => {
            if (checkMatch(de, expression)) {
              const updated = { ...de, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return de;
          });
        } else if (table === disputeComments) {
          testDbStore.disputeComments = testDbStore.disputeComments.map((dc) => {
            if (checkMatch(dc, expression)) {
              const updated = { ...dc, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return dc;
          });
        } else if (table === sanctions) {
          testDbStore.sanctions = testDbStore.sanctions.map((s) => {
            if (checkMatch(s, expression)) {
              const updated = { ...s, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return s;
          });
        } else if (table === auditEvents) {
          testDbStore.auditEvents = testDbStore.auditEvents.map((ae) => {
            if (checkMatch(ae, expression)) {
              const updated = { ...ae, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ae;
          });
        } else if (table === notifications) {
          testDbStore.notifications = testDbStore.notifications.map((n) => {
            if (checkMatch(n, expression)) {
              const updated = { ...n, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return n;
          });
        } else if (table === conversations) {
          testDbStore.conversations = testDbStore.conversations.map((c) => {
            if (checkMatch(c, expression)) {
              const updated = { ...c, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return c;
          });
        } else if (table === conversationParticipants) {
          testDbStore.conversationParticipants = testDbStore.conversationParticipants.map((cp) => {
            if (checkMatch(cp, expression)) {
              const updated = { ...cp, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return cp;
          });
        } else if (table === messages) {
          testDbStore.messages = testDbStore.messages.map((m) => {
            if (checkMatch(m, expression)) {
              const updated = { ...m, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return m;
          });
        } else if (table === announcements) {
          testDbStore.announcements = testDbStore.announcements.map((a) => {
            if (checkMatch(a, expression)) {
              const updated = { ...a, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return a;
          });
        } else if (table === userCommunicationPreferences) {
          testDbStore.userCommunicationPreferences = testDbStore.userCommunicationPreferences.map((ucp) => {
            if (checkMatch(ucp, expression)) {
              const updated = { ...ucp, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ucp;
          });
        } else if (table === userDeviceTokens) {
          testDbStore.userDeviceTokens = testDbStore.userDeviceTokens.map((udt) => {
            if (checkMatch(udt, expression)) {
              const updated = { ...udt, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return udt;
          });
        } else if (table === userDevices) {
          testDbStore.userDevices = testDbStore.userDevices.map((ud) => {
            if (checkMatch(ud, expression)) {
              const updated = { ...ud, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ud;
          });
        } else if (table === communityPosts) {
          testDbStore.communityPosts = testDbStore.communityPosts.map((cp) => {
            if (checkMatch(cp, expression)) {
              const updated = { ...cp, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return cp;
          });
        } else if (table === venuePartners) {
          testDbStore.venuePartners = testDbStore.venuePartners.map((vp) => {
            if (checkMatch(vp, expression)) {
              const updated = { ...vp, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return vp;
          });
        } else if (table === talentNominations) {
          testDbStore.talentNominations = testDbStore.talentNominations.map((tn) => {
            if (checkMatch(tn, expression)) {
              const updated = { ...tn, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return tn;
          });
        } else if (table === refereeCertifications) {
          testDbStore.refereeCertifications = testDbStore.refereeCertifications.map((rc) => {
            if (checkMatch(rc, expression)) {
              const updated = { ...rc, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return rc;
          });
        } else if (table === informalEvents) {
          testDbStore.informalEvents = testDbStore.informalEvents.map((ie) => {
            if (checkMatch(ie, expression)) {
              const updated = { ...ie, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return ie;
          });
        } else if (table === informalEventParticipants) {
          testDbStore.informalEventParticipants = testDbStore.informalEventParticipants.map((iep) => {
            if (checkMatch(iep, expression)) {
              const updated = { ...iep, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return iep;
          });
        } else if (table === ticketTypes) {
          testDbStore.ticketTypes = testDbStore.ticketTypes.map((tt) => {
            if (checkMatch(tt, expression)) {
              let updatedQtySold = updateValues.quantitySold;
              let isSqlIncrement = false;
              if (updatedQtySold && typeof updatedQtySold === "object" && (updatedQtySold as any).type === "sql") {
                const joinedStr = Array.isArray(updatedQtySold.strings) ? updatedQtySold.strings.join("") : String(updatedQtySold.strings);
                if (joinedStr.includes("-")) {
                  updatedQtySold = Math.max(0, (tt.quantitySold || 0) - 1);
                } else {
                  updatedQtySold = (tt.quantitySold || 0) + 1;
                  isSqlIncrement = true;
                }
              }
              // If it's an atomic increment, we must enforce that quantitySold < quantityAvailable
              if (isSqlIncrement && tt.quantitySold >= tt.quantityAvailable) {
                // Do not update, did not meet conditional where clause!
                return tt;
              }
              const finalUpdate = { ...updateValues };
              if (updatedQtySold !== undefined) {
                finalUpdate.quantitySold = updatedQtySold;
              }
              const updated = { ...tt, ...finalUpdate };
              matched.push(updated);
              return updated;
            }
            return tt;
          });
        } else if (table === tickets) {
          testDbStore.tickets = testDbStore.tickets.map((t) => {
            if (checkMatch(t, expression)) {
              const updated = { ...t, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return t;
          });
        } else if (table === scheduledJobs) {
          testDbStore.scheduledJobs = testDbStore.scheduledJobs.map((sj) => {
            if (checkMatch(sj, expression)) {
              const updated = { ...sj, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return sj;
          });
        } else if (table === authTokens) {
          testDbStore.authTokens = testDbStore.authTokens.map((at) => {
            if (checkMatch(at, expression)) {
              const updated = { ...at, ...updateValues };
              matched.push(updated);
              return updated;
            }
            return at;
          });
        }
        
        const returnObj = {
          returning: () => Promise.resolve(matched),
          rowCount: matched.length,
          then: (resolve: any) => Promise.resolve({ rowCount: matched.length, rows: matched }).then(resolve),
        };
        return returnObj;
      },
    }),
  }),

  delete: (table: any) => ({
    where: (expression: any) => {
      let deleted: any[] = [];
      const filterFn = (store: any[]) => {
        return store.filter((item) => {
          if (checkMatch(item, expression)) {
            deleted.push(item);
            return false;
          }
          return true;
        });
      };

      if (table === eloLedger) {
        testDbStore.eloLedger = filterFn(testDbStore.eloLedger);
      } else if (table === matches) {
        testDbStore.matches = filterFn(testDbStore.matches);
      } else if (table === championshipTitles) {
        testDbStore.championshipTitles = filterFn(testDbStore.championshipTitles);
      } else if (table === beltLineage) {
        testDbStore.beltLineage = filterFn(testDbStore.beltLineage);
      } else if (table === championshipChallenges) {
        testDbStore.championshipChallenges = filterFn(testDbStore.championshipChallenges);
      } else if (table === prestigeMetrics) {
        testDbStore.prestigeMetrics = filterFn(testDbStore.prestigeMetrics);
      } else if (table === rankingSnapshots) {
        testDbStore.rankingSnapshots = filterFn(testDbStore.rankingSnapshots);
      } else if (table === events) {
        testDbStore.events = filterFn(testDbStore.events);
      } else if (table === eventRegistrations) {
        testDbStore.eventRegistrations = filterFn(testDbStore.eventRegistrations);
      } else if (table === payments) {
        testDbStore.payments = filterFn(testDbStore.payments);
      } else if (table === processedStripeEvents) {
        testDbStore.processedStripeEvents = filterFn(testDbStore.processedStripeEvents);
      } else if (table === officialWeighins) {
        testDbStore.officialWeighins = filterFn(testDbStore.officialWeighins);
      } else if (table === brackets) {
        testDbStore.brackets = filterFn(testDbStore.brackets);
      } else if (table === bracketSeeds) {
        testDbStore.bracketSeeds = filterFn(testDbStore.bracketSeeds);
      } else if (table === tournamentMatches) {
        testDbStore.tournamentMatches = filterFn(testDbStore.tournamentMatches);
      } else if (table === matchTables) {
        testDbStore.matchTables = filterFn(testDbStore.matchTables);
      } else if (table === disputes) {
        testDbStore.disputes = filterFn(testDbStore.disputes);
      } else if (table === disputeEvidence) {
        testDbStore.disputeEvidence = filterFn(testDbStore.disputeEvidence);
      } else if (table === disputeComments) {
        testDbStore.disputeComments = filterFn(testDbStore.disputeComments);
      } else if (table === sanctions) {
        testDbStore.sanctions = filterFn(testDbStore.sanctions);
      } else if (table === auditEvents) {
        testDbStore.auditEvents = filterFn(testDbStore.auditEvents);
      } else if (table === notifications) {
        testDbStore.notifications = filterFn(testDbStore.notifications);
      } else if (table === conversations) {
        testDbStore.conversations = filterFn(testDbStore.conversations);
      } else if (table === conversationParticipants) {
        testDbStore.conversationParticipants = filterFn(testDbStore.conversationParticipants);
      } else if (table === messages) {
        testDbStore.messages = filterFn(testDbStore.messages);
      } else if (table === announcements) {
        testDbStore.announcements = filterFn(testDbStore.announcements);
      } else if (table === userCommunicationPreferences) {
        testDbStore.userCommunicationPreferences = filterFn(testDbStore.userCommunicationPreferences);
      } else if (table === userDeviceTokens) {
        testDbStore.userDeviceTokens = filterFn(testDbStore.userDeviceTokens);
      } else if (table === userDevices) {
        testDbStore.userDevices = filterFn(testDbStore.userDevices);
      } else if (table === follows) {
        testDbStore.follows = filterFn(testDbStore.follows);
      } else if (table === blockedUsers) {
        testDbStore.blockedUsers = filterFn(testDbStore.blockedUsers);
      } else if (table === teams) {
        testDbStore.teams = filterFn(testDbStore.teams);
      } else if (table === teamMembers) {
        testDbStore.teamMembers = filterFn(testDbStore.teamMembers);
      } else if (table === communityPosts) {
        testDbStore.communityPosts = filterFn(testDbStore.communityPosts);
      } else if (table === postLikes) {
        testDbStore.postLikes = filterFn(testDbStore.postLikes);
      } else if (table === postComments) {
        testDbStore.postComments = filterFn(testDbStore.postComments);
      } else if (table === informalEvents) {
        testDbStore.informalEvents = filterFn(testDbStore.informalEvents);
      } else if (table === informalEventParticipants) {
        testDbStore.informalEventParticipants = filterFn(testDbStore.informalEventParticipants);
      } else if (table === tickets) {
        testDbStore.tickets = filterFn(testDbStore.tickets);
      } else if (table === scheduledJobs) {
        testDbStore.scheduledJobs = filterFn(testDbStore.scheduledJobs);
      } else if (table === authTokens) {
        testDbStore.authTokens = filterFn(testDbStore.authTokens);
      } else if (table === ticketTypes) {
        testDbStore.ticketTypes = filterFn(testDbStore.ticketTypes);
      }

      return {
        returning: () => Promise.resolve(deleted),
        rowCount: deleted.length,
        then: (resolve: any) => Promise.resolve({ rowCount: deleted.length, rows: deleted }).then(resolve),
      };
    },
  }),

  // Support transaction block simulation
  transaction: async (callback: any) => {
    // Save snapshot of state for transaction rollback simulation
    const snapshot = {
      users: [...testDbStore.users],
      userSessions: [...testDbStore.userSessions],
      auditLogs: [...testDbStore.auditLogs],
      pendingActions: [...testDbStore.pendingActions],
      // matches / athleteProfiles / eloLedger were missing here — meaning a
      // transaction that throws partway through verifyMatch() (which writes
      // to exactly these three tables) would only partially roll back: the
      // tables above would correctly revert, but a match could be left
      // stuck VERIFIED with stale/partial ELO applied. That's the opposite
      // of what pessimistic locking + transactional atomicity exists to
      // guarantee, and it was untestable until this was fixed.
      matches: [...testDbStore.matches],
      athleteProfiles: [...testDbStore.athleteProfiles],
      eloLedger: [...testDbStore.eloLedger],
      championshipTitles: [...testDbStore.championshipTitles],
      beltLineage: [...testDbStore.beltLineage],
      championshipChallenges: [...testDbStore.championshipChallenges],
      prestigeMetrics: [...testDbStore.prestigeMetrics],
      rankingSnapshots: [...testDbStore.rankingSnapshots],
      disputes: [...testDbStore.disputes],
      disputeEvidence: [...testDbStore.disputeEvidence],
      disputeComments: [...testDbStore.disputeComments],
      sanctions: [...testDbStore.sanctions],
      auditEvents: [...testDbStore.auditEvents],
      notifications: [...testDbStore.notifications],
      conversations: [...testDbStore.conversations],
      conversationParticipants: [...testDbStore.conversationParticipants],
      messages: [...testDbStore.messages],
      announcements: [...testDbStore.announcements],
      userCommunicationPreferences: [...testDbStore.userCommunicationPreferences],
      userDeviceTokens: [...testDbStore.userDeviceTokens],
      events: [...testDbStore.events],
      eventRegistrations: [...testDbStore.eventRegistrations],
      payments: [...testDbStore.payments],
      processedStripeEvents: [...testDbStore.processedStripeEvents],
      tickets: [...testDbStore.tickets],
      ticketTypes: [...testDbStore.ticketTypes],
    };

    try {
      return await callback(mockDrizzle);
    } catch (error) {
      // Rollback transaction to snapshot state on error
      testDbStore.users = snapshot.users;
      testDbStore.userSessions = snapshot.userSessions;
      testDbStore.auditLogs = snapshot.auditLogs;
      testDbStore.pendingActions = snapshot.pendingActions;
      testDbStore.matches = snapshot.matches;
      testDbStore.athleteProfiles = snapshot.athleteProfiles;
      testDbStore.eloLedger = snapshot.eloLedger;
      testDbStore.championshipTitles = snapshot.championshipTitles;
      testDbStore.beltLineage = snapshot.beltLineage;
      testDbStore.championshipChallenges = snapshot.championshipChallenges;
      testDbStore.prestigeMetrics = snapshot.prestigeMetrics;
      testDbStore.rankingSnapshots = snapshot.rankingSnapshots;
      testDbStore.disputes = snapshot.disputes;
      testDbStore.disputeEvidence = snapshot.disputeEvidence;
      testDbStore.disputeComments = snapshot.disputeComments;
      testDbStore.sanctions = snapshot.sanctions;
      testDbStore.auditEvents = snapshot.auditEvents;
      testDbStore.notifications = snapshot.notifications;
      testDbStore.conversations = snapshot.conversations;
      testDbStore.conversationParticipants = snapshot.conversationParticipants;
      testDbStore.messages = snapshot.messages;
      testDbStore.announcements = snapshot.announcements;
      testDbStore.userCommunicationPreferences = snapshot.userCommunicationPreferences;
      testDbStore.userDeviceTokens = snapshot.userDeviceTokens;
      testDbStore.events = snapshot.events;
      testDbStore.eventRegistrations = snapshot.eventRegistrations;
      testDbStore.payments = snapshot.payments;
      testDbStore.processedStripeEvents = snapshot.processedStripeEvents;
      testDbStore.tickets = snapshot.tickets;
      testDbStore.ticketTypes = snapshot.ticketTypes;
      throw error;
    }
  },

  // Support direct raw SQL execution for health & readiness probes and scheduled jobs
  execute: (sqlExpr?: any) => {
    const str = Array.isArray(sqlExpr?.strings)
      ? sqlExpr.strings.join(" ")
      : String(sqlExpr?.strings || sqlExpr || "");

    if (str.includes("scheduled_jobs")) {
      const vals = sqlExpr?.values || [];
      if (str.includes("status = 'pending'") || str.includes('status = "pending"')) {
        const nowVal = vals[0] ? new Date(vals[0]) : new Date();
        const matching = testDbStore.scheduledJobs
          .filter((j) => j.status === "pending" && new Date(j.scheduledFor) <= nowVal)
          .slice(0, 50);
        return Promise.resolve({ rows: matching.map((j) => ({ id: j.id })) });
      }
      if (str.includes("status = 'running'") || str.includes('status = "running"')) {
        const threshold = vals[0] ? new Date(vals[0]) : new Date();
        const matching = testDbStore.scheduledJobs.filter(
          (j) => j.status === "running" && new Date(j.updatedAt) <= threshold
        );
        return Promise.resolve({ rows: matching.map((j) => ({ id: j.id })) });
      }
    }
    return Promise.resolve({ rows: [] });
  },
};

// Intercept pg Pool globally during test execution
vi.mock("pg", () => {
  const mockPool = {
    connect: vi.fn(),
    query: vi.fn(),
    end: vi.fn().mockResolvedValue(undefined),
    on: vi.fn(),
  };
  return {
    default: {
      Pool: vi.fn().mockImplementation(() => mockPool),
    },
    Pool: vi.fn().mockImplementation(() => mockPool),
  };
});

// Intercept pg Pool and Drizzle ORM globally during test execution
vi.mock("../config/db.ts", () => {
  return {
    pool: {
      end: () => Promise.resolve(),
    },
    get db() {
      return mockDrizzle;
    },
    get default() {
      return mockDrizzle;
    },
  };
});

vi.mock("../config/db.js", () => {
  return {
    pool: {
      end: () => Promise.resolve(),
    },
    get db() {
      return mockDrizzle;
    },
    get default() {
      return mockDrizzle;
    },
  };
});

vi.mock("../config/db", () => {
  return {
    pool: {
      end: () => Promise.resolve(),
    },
    get db() {
      return mockDrizzle;
    },
    get default() {
      return mockDrizzle;
    },
  };
});

// Intercept eq and and helper functions from drizzle-orm
vi.mock("drizzle-orm", () => {
  return {
    eq: (fieldObj: any, val: any) => {
      return { operator: "eq", field: fieldObj?.name, value: val };
    },
    ne: (fieldObj: any, val: any) => {
      return { operator: "ne", field: fieldObj?.name, value: val };
    },
    notInArray: (fieldObj: any, vals: any[]) => {
      return { operator: "notInArray", field: fieldObj?.name, value: vals };
    },
    inArray: (fieldObj: any, vals: any[]) => {
      return { operator: "inArray", field: fieldObj?.name, value: vals };
    },
    like: (fieldObj: any, val: any) => {
      return { operator: "like", field: fieldObj?.name, value: val };
    },
    and: (...conditions: any[]) => {
      return { type: "and", conditions };
    },
    or: (...conditions: any[]) => {
      return { type: "or", conditions };
    },
    desc: (fieldObj: any) => {
      return { direction: "desc", field: fieldObj?.name };
    },
    asc: (fieldObj: any) => {
      return { direction: "asc", field: fieldObj?.name };
    },
    isNull: (fieldObj: any) => {
      return { operator: "isNull", field: fieldObj?.name };
    },
    isNotNull: (fieldObj: any) => {
      return { operator: "isNotNull", field: fieldObj?.name };
    },
    not: (condition: any) => {
      return { operator: "not", condition };
    },
    sql: (strings: TemplateStringsArray | string, ...values: any[]) => {
      return { type: "sql", strings, values };
    },
    lt: (fieldObj: any, val: any) => {
      return { operator: "lt", field: fieldObj?.name, value: val };
    },
    gt: (fieldObj: any, val: any) => {
      return { operator: "gt", field: fieldObj?.name, value: val };
    },
    gte: (fieldObj: any, val: any) => {
      return { operator: "gte", field: fieldObj?.name, value: val };
    },
    lte: (fieldObj: any, val: any) => {
      return { operator: "lte", field: fieldObj?.name, value: val };
    },
    relations: (table: any, cb: any) => {
      return {};
    },
    SQL: class SQL {},
  };
});

// Mock stripe completely for unit testing and payment simulation
export const mockStripeConstructEvent = vi.fn().mockImplementation((rawBody, sig, secret) => {
  if (sig !== "mock-signature-here") {
    throw new Error("Webhook signature verification failed: Invalid signature");
  }

  let parsedBody: any = {};
  try {
    parsedBody = JSON.parse(rawBody.toString());
  } catch (e) {}

  return {
    id: parsedBody.eventId || "evt_test",
    type: parsedBody.type || "payment_intent.succeeded",
    data: {
      object: {
        id: parsedBody.id || "pi_test",
        amount: parsedBody.amount || 5000,
        currency: parsedBody.currency || "cad",
        metadata: parsedBody.metadata || {},
      },
    },
  };
});

vi.mock("stripe", () => {
  return {
    default: class MockStripe {
      paymentIntents = {
        create: vi.fn().mockImplementation(async (data: any) => {
          return {
            id: "pi_mock_" + Math.random().toString(36).substring(7),
            amount: data.amount,
            currency: data.currency,
            client_secret: "pi_mock_secret_" + Math.random().toString(36).substring(7),
            metadata: data.metadata || {},
          };
        }),
      };
      customers = {
        create: vi.fn().mockImplementation(async (data: any) => {
          return {
            id: "cus_mock_" + Math.random().toString(36).substring(7),
            email: data.email,
            name: data.name,
          };
        }),
      };
      setupIntents = {
        create: vi.fn().mockImplementation(async (data: any) => {
          return {
            id: "seti_mock_" + Math.random().toString(36).substring(7),
            client_secret: "seti_mock_secret_" + Math.random().toString(36).substring(7),
            customer: data.customer,
          };
        }),
      };
      paymentMethods = {
        list: vi.fn().mockImplementation(async (data: any) => {
          return {
            data: mockPaymentMethods.filter(pm => pm.customer === data.customer)
          };
        }),
        detach: vi.fn().mockImplementation(async (id: string) => {
          const idx = mockPaymentMethods.findIndex(pm => pm.id === id);
          if (idx !== -1) {
            mockPaymentMethods.splice(idx, 1);
          }
          return { id };
        }),
      };
      webhooks = {
        constructEvent: (rawBody: Buffer, sig: string, secret: string) => {
          return mockStripeConstructEvent(rawBody, sig, secret);
        },
      };
      refunds = {
        create: vi.fn().mockImplementation(async (data: any) => {
          return {
            id: "re_mock_" + Math.random().toString(36).substring(7),
            payment_intent: data.payment_intent,
            status: "succeeded",
          };
        }),
      };
    },
  };
});

