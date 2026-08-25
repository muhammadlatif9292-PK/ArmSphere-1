import { eq, and, desc, asc, not, isNull, sql, inArray } from "drizzle-orm";
import { alias } from "drizzle-orm/pg-core";
import { db } from "../config/db.js";
import crypto from "crypto";
import { 
  events,
  eventRegistrations,
  officialWeighins,
  brackets,
  bracketSeeds,
  tournamentMatches,
  matchTables,
  athleteProfiles,
  athleteClubs,
  users,
  auditLogs,
  payments
} from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, ForbiddenError, logger } from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import { getStripe } from "./stripe.js";
import { RefereeCertificationService } from "./refereeCertification.js";
import { auditLedgerService } from "./auditLedger.js";
import { StorageService } from "./storage.js";
import { env } from "../config/env.js";

export class TournamentService {
  // ==========================================
  // 1. Event Management
  // ==========================================

  static async listEvents(filters?: { status?: string; timeframe?: "upcoming" | "past" }) {
    logger.info({ filters }, "Listing tournament events");
    let query = db.select().from(events);
    const conditions = [];

    if (filters?.status) {
      conditions.push(eq(events.status, filters.status));
    }

    if (filters?.timeframe) {
      const now = new Date();
      if (filters.timeframe === "upcoming") {
        conditions.push(sql`${events.startDate} >= ${now}`);
      } else if (filters.timeframe === "past") {
        conditions.push(sql`${events.endDate} < ${now}`);
      }
    }

    if (conditions.length > 0) {
      query = query.where(and(...conditions)) as any;
    }

    const eventsList = await query.orderBy(desc(events.startDate));
    for (const event of eventsList) {
      if (event.paymentQrImageUrl && !event.paymentQrImageUrl.startsWith("http")) {
        try {
          event.paymentQrImageUrl = await StorageService.generatePresignedDownloadUrl(
            env.B2_BUCKET_COMPLIANCE_DOCS,
            event.paymentQrImageUrl
          );
        } catch (err) {
          logger.error({ err, fileKey: event.paymentQrImageUrl }, "Failed to generate presigned download URL for QR code in listEvents");
        }
      }
    }
    return eventsList;
  }

  static async getEvent(id: string) {
    logger.info({ id }, "Getting tournament event by ID");
    const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
    if (!event) {
      throw new NotFoundError("Tournament event not found.");
    }
    if (event.paymentQrImageUrl && !event.paymentQrImageUrl.startsWith("http")) {
      try {
        event.paymentQrImageUrl = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_COMPLIANCE_DOCS,
          event.paymentQrImageUrl
        );
      } catch (err) {
        logger.error({ err, fileKey: event.paymentQrImageUrl }, "Failed to generate presigned download URL for QR code in getEvent");
      }
    }
    return event;
  }

  static async createEvent(data: {
    name: string;
    startDate: Date;
    endDate: Date;
    registrationStart: Date;
    registrationEnd: Date;
    province: string;
    city: string;
    venue: string;
    capacity: number;
    organizerId?: string;
    paymentMethod?: string;
    paymentQrImageUrl?: string;
  }) {
    logger.info({ name: data.name }, "Creating new tournament event");

    // Boundary validations
    if (data.registrationStart >= data.registrationEnd) {
      throw new BadRequestError("Registration start date must be before registration end date.");
    }
    if (data.registrationEnd >= data.startDate) {
      throw new BadRequestError("Registration window must close before the event starts.");
    }
    if (data.startDate > data.endDate) {
      throw new BadRequestError("Event start date must be before or equal to the end date.");
    }

    const [newEvent] = await db
      .insert(events)
      .values({
        name: data.name,
        startDate: data.startDate,
        endDate: data.endDate,
        registrationStart: data.registrationStart,
        registrationEnd: data.registrationEnd,
        province: data.province,
        city: data.city,
        venue: data.venue,
        capacity: data.capacity,
        status: "DRAFT",
        organizerId: data.organizerId || null,
        paymentMethod: data.paymentMethod || "STRIPE",
        paymentQrImageUrl: data.paymentQrImageUrl || null
      })
      .returning();

    return newEvent;
  }

  static async editEvent(id: string, data: Partial<{
    name: string;
    startDate: Date;
    endDate: Date;
    registrationStart: Date;
    registrationEnd: Date;
    province: string;
    city: string;
    venue: string;
    capacity: number;
    organizerId: string;
    paymentMethod: string;
    paymentQrImageUrl: string | null;
  }>) {
    logger.info({ id }, "Editing tournament event");

    const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
    if (!event) {
      throw new NotFoundError("Tournament event not found.");
    }

    if (event.status === "CANCELLED") {
      throw new BadRequestError("Cannot edit a cancelled event.");
    }

    // Date bounds checks if updated
    const finalRegStart = data.registrationStart || event.registrationStart;
    const finalRegEnd = data.registrationEnd || event.registrationEnd;
    const finalStart = data.startDate || event.startDate;
    const finalEnd = data.endDate || event.endDate;

    if (finalRegStart >= finalRegEnd) {
      throw new BadRequestError("Registration start date must be before registration end date.");
    }
    if (finalRegEnd >= finalStart) {
      throw new BadRequestError("Registration window must close before the event starts.");
    }
    if (finalStart > finalEnd) {
      throw new BadRequestError("Event start date must be before or equal to the end date.");
    }

    const [updatedEvent] = await db
      .update(events)
      .set({
        ...data,
        updatedAt: new Date()
      })
      .where(eq(events.id, id))
      .returning();

    return updatedEvent;
  }

  static async cancelEvent(id: string) {
    logger.info({ id }, "Cancelling tournament event");

    const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
    if (!event) {
      throw new NotFoundError("Tournament event not found.");
    }

    const [cancelledEvent] = await db
      .update(events)
      .set({ status: "CANCELLED", updatedAt: new Date() })
      .where(eq(events.id, id))
      .returning();

    return cancelledEvent;
  }

  static async publishEvent(id: string) {
    logger.info({ id }, "Publishing tournament event");

    const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
    if (!event) {
      throw new NotFoundError("Tournament event not found.");
    }

    const [publishedEvent] = await db
      .update(events)
      .set({ status: "PUBLISHED", updatedAt: new Date() })
      .where(eq(events.id, id))
      .returning();

    return publishedEvent;
  }

  // ==========================================
  // 2. Athlete Registration
  // ==========================================

  static async registerAthlete(eventId: string, athleteId: string, data: {
    division: string;
    weightClass: string;
    arm: string;
    notes?: string;
  }) {
    logger.info({ eventId, athleteId }, "Registering athlete to event");

    return await db.transaction(async (tx) => {
      const [event] = await tx.select().from(events).where(eq(events.id, eventId)).limit(1);
      if (!event) {
        throw new NotFoundError("Tournament event not found.");
      }

      // Registration window check
      const now = new Date();
      if (now < event.registrationStart || now > event.registrationEnd) {
        throw new BadRequestError("Registration window is currently closed for this event.");
      }

      // Eligibility profile check
      const [athlete] = await tx.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId)).limit(1);
      if (!athlete || athlete.isDeleted) {
        throw new BadRequestError("Athlete must have an active profile to register.");
      }

      // Gender profile check alignment
      if (data.division.toUpperCase() === "FEMALE" && athlete.gender?.toUpperCase() === "MALE") {
        throw new BadRequestError("Athlete is not eligible for Female division based on profile gender.");
      }

      // Duplicate registration check: partial unique check on (eventId, athleteId) excluding REJECTED
      const [existingReg] = await tx
        .select()
        .from(eventRegistrations)
        .where(
          and(
            eq(eventRegistrations.eventId, eventId),
            eq(eventRegistrations.athleteId, athleteId),
            not(eq(eventRegistrations.status, "REJECTED"))
          )
        )
        .limit(1);
      if (existingReg) {
        throw new BadRequestError("Athlete is already registered in this event.");
      }

      // Capacity limit check for Waitlist promotion
      const currentActiveRegs = await tx
        .select()
        .from(eventRegistrations)
        .where(
          and(
            eq(eventRegistrations.eventId, eventId),
            not(eq(eventRegistrations.status, "REJECTED"))
          )
        );

      const isPaidEvent = event.registrationFeeCents !== null && event.registrationFeeCents !== undefined && event.registrationFeeCents > 0;
      const isAtCapacity = currentActiveRegs.length >= event.capacity;
      const status = isAtCapacity
        ? "WAITLISTED"
        : (isPaidEvent ? "PENDING_PAYMENT" : "PENDING");

      const [newReg] = await tx
        .insert(eventRegistrations)
        .values({
          eventId,
          athleteId,
          division: data.division,
          weightClass: data.weightClass,
          arm: data.arm,
          notes: data.notes,
          status
        })
        .returning();

      let clientSecret: string | null = null;

      if (status === "PENDING_PAYMENT" && event.paymentMethod !== "MANUAL_QR") {
        const stripe = getStripe();
        const paymentIntent = await stripe.paymentIntents.create({
          amount: event.registrationFeeCents!,
          currency: "cad",
          metadata: {
            eventId,
            athleteId,
            registrationId: newReg.id
          }
        });

        await tx
          .insert(payments)
          .values({
            eventRegistrationId: newReg.id,
            amountCents: event.registrationFeeCents!,
            currency: "CAD",
            stripePaymentIntentId: paymentIntent.id,
            status: "PENDING"
          });

        clientSecret = paymentIntent.client_secret;
      }

      if (clientSecret) {
        return {
          ...newReg,
          clientSecret
        };
      }
      return newReg;
    });
  }

  static async approveRegistration(registrationId: string, approvedBy: string) {
    logger.info({ registrationId }, "Approving athlete event registration");

    const [reg] = await db.select().from(eventRegistrations).where(eq(eventRegistrations.id, registrationId)).limit(1);
    if (!reg) {
      throw new NotFoundError("Registration record not found.");
    }

    const [approvedReg] = await db
      .update(eventRegistrations)
      .set({ status: "APPROVED", approvedBy, updatedAt: new Date() })
      .where(eq(eventRegistrations.id, registrationId))
      .returning();

    return approvedReg;
  }

  // ==========================================
  // 3. Weigh-In System
  // ==========================================

  static async recordWeighIn(registrationId: string, weight: number, certifiedBy: string) {
    await RefereeCertificationService.assertActiveCertification(certifiedBy);
    logger.info({ registrationId, weight }, "Recording official athlete weigh-in attempt");

    const [reg] = await db.select().from(eventRegistrations).where(eq(eventRegistrations.id, registrationId)).limit(1);
    if (!reg) {
      throw new NotFoundError("Athlete registration not found.");
    }

    // Lock safety checks
    const priorWeighins = await db
      .select()
      .from(officialWeighins)
      .where(eq(officialWeighins.registrationId, registrationId));

    const isLocked = priorWeighins.some((w) => w.isLocked);
    if (isLocked) {
      throw new BadRequestError("Weigh-in record has been certified and locked. No further updates permitted.");
    }

    const attemptNumber = priorWeighins.length + 1;

    // Weight Class limit parser (e.g. "70KG" -> 70, "OPEN" -> Infinity)
    let weightLimit = Infinity;
    const cleanWeightClass = reg.weightClass.toUpperCase();
    if (cleanWeightClass !== "OPEN") {
      const match = cleanWeightClass.match(/\d+/);
      if (match) {
        weightLimit = parseFloat(match[0]);
      }
    }

    const status = weight <= weightLimit ? "PASSED" : "FAILED";

    const [newWeighIn] = await db
      .insert(officialWeighins)
      .values({
        registrationId,
        attemptNumber,
        weight,
        status,
        certifiedBy,
        isLocked: false
      })
      .returning();

    // Auto audit log entry
    await db.insert(auditLogs).values({
      userId: certifiedBy,
      action: "WEIGH_IN_RECORDED",
      details: { registrationId, weight, attemptNumber, status }
    });

    return newWeighIn;
  }

  static async reassignRegistration(registrationId: string, newDivision: string, newWeightClass: string, actorId?: string) {
    if (actorId) {
      await RefereeCertificationService.assertActiveCertification(actorId);
    }
    logger.info({ registrationId, newDivision, newWeightClass }, "Reassigning registration division/weight class");

    const [reg] = await db.select().from(eventRegistrations).where(eq(eventRegistrations.id, registrationId)).limit(1);
    if (!reg) {
      throw new NotFoundError("Registration not found.");
    }

    // Verify weigh-in isn't locked
    const priorWeighins = await db
      .select()
      .from(officialWeighins)
      .where(eq(officialWeighins.registrationId, registrationId));
    if (priorWeighins.some((w) => w.isLocked)) {
      throw new BadRequestError("Weigh-in is certified and locked. Cannot reassign division.");
    }

    const [updatedReg] = await db
      .update(eventRegistrations)
      .set({
        division: newDivision,
        weightClass: newWeightClass,
        updatedAt: new Date()
      })
      .where(eq(eventRegistrations.id, registrationId))
      .returning();

    // Log reassignment on last weigh-in attempt if exists
    if (priorWeighins.length > 0) {
      const sorted = [...priorWeighins].sort((a, b) => (b.attemptNumber || 0) - (a.attemptNumber || 0));
      await db
        .update(officialWeighins)
        .set({
          reassignedDivision: newDivision,
          reassignedWeightClass: newWeightClass,
          updatedAt: new Date()
        })
        .where(eq(officialWeighins.id, sorted[0].id));
    }

    return updatedReg;
  }

  static async certifyWeighIn(registrationId: string, actorId?: string) {
    if (actorId) {
      await RefereeCertificationService.assertActiveCertification(actorId);
    }
    logger.info({ registrationId }, "Certifying and locking weigh-ins");

    const [reg] = await db.select().from(eventRegistrations).where(eq(eventRegistrations.id, registrationId)).limit(1);
    if (!reg) {
      throw new NotFoundError("Registration not found.");
    }

    await db
      .update(officialWeighins)
      .set({ isLocked: true, updatedAt: new Date() })
      .where(eq(officialWeighins.registrationId, registrationId));

    return { success: true };
  }

  // ==========================================
  // 4. Seeding Engine
  // ==========================================

  static async createBracket(eventId: string, name: string, format: string, division: string, weightClass: string, arm: string) {
    const [newBracket] = await db
      .insert(brackets)
      .values({
        eventId,
        name,
        format,
        division,
        weightClass,
        arm,
        status: "DRAFT",
        seedingLocked: false
      })
      .returning();

    return newBracket;
  }

  static async generateSeeds(bracketId: string) {
    logger.info({ bracketId }, "Running ELO-based seeding generation");

    const [bracket] = await db.select().from(brackets).where(eq(brackets.id, bracketId)).limit(1);
    if (!bracket) {
      throw new NotFoundError("Bracket not found.");
    }

    // Retrieve approved, weighed-in passed athletes registered for this category
    const registrants = await db
      .select({
        id: eventRegistrations.id,
        athleteId: eventRegistrations.athleteId,
        leftArmElo: athleteProfiles.leftArmElo,
        rightArmElo: athleteProfiles.rightArmElo
      })
      .from(eventRegistrations)
      .innerJoin(athleteProfiles, eq(athleteProfiles.id, eventRegistrations.athleteId))
      .where(
        and(
          eq(eventRegistrations.eventId, bracket.eventId as string),
          eq(eventRegistrations.division, bracket.division as string),
          eq(eventRegistrations.weightClass, bracket.weightClass as string),
          eq(eventRegistrations.arm, bracket.arm as string),
          eq(eventRegistrations.status, "APPROVED")
        )
      );

    // Filter to those with a passed official weigh-in
    const qualifiedRegistrants = [];
    for (const r of registrants) {
      const weighins = await db
        .select()
        .from(officialWeighins)
        .where(
          and(
            eq(officialWeighins.registrationId, r.id),
            eq(officialWeighins.status, "PASSED")
          )
        );
      if (weighins.length > 0) {
        qualifiedRegistrants.push(r);
      }
    }

    // ELO-based sorting
    const isLeft = bracket.arm.toUpperCase() === "LEFT";
    const sorted = [...qualifiedRegistrants].sort((a, b) => {
      const eloA = isLeft ? (a.leftArmElo ?? 1000) : (a.rightArmElo ?? 1000);
      const eloB = isLeft ? (b.leftArmElo ?? 1000) : (b.rightArmElo ?? 1000);
      return eloB - eloA;
    });

    // Wipe any existing draft seeds
    await db.delete(bracketSeeds).where(eq(bracketSeeds.bracketId, bracketId));

    // Save seeding positions
    const seedsToInsert = sorted.map((r, idx) => ({
      bracketId,
      athleteId: r.athleteId,
      seedPosition: idx + 1,
      isManualOverride: false
    }));

    if (seedsToInsert.length > 0) {
      await db.insert(bracketSeeds).values(seedsToInsert);
    }

    await db
      .update(brackets)
      .set({ status: "SEEDED", updatedAt: new Date() })
      .where(eq(brackets.id, bracketId));

    return seedsToInsert;
  }

  static async overrideSeed(bracketId: string, athleteId: string, newPosition: number) {
    logger.info({ bracketId, athleteId, newPosition }, "Applying manual seed override");

    const [bracket] = await db.select().from(brackets).where(eq(brackets.id, bracketId)).limit(1);
    if (!bracket) {
      throw new NotFoundError("Bracket not found.");
    }
    if (bracket.seedingLocked) {
      throw new BadRequestError("Seeding is locked and cannot be overridden.");
    }

    const seeds = await db.select().from(bracketSeeds).where(eq(bracketSeeds.bracketId, bracketId));
    const targetSeedIndex = seeds.findIndex((s) => s.athleteId === athleteId);
    if (targetSeedIndex === -1) {
      throw new NotFoundError("Athlete seed record not found for this bracket.");
    }

    const currentPosition = seeds[targetSeedIndex].seedPosition || 0;

    // Shift other seeds to accommodate manual insertion
    for (const seed of seeds) {
      if (seed.athleteId === athleteId) continue;
      
      const seedPos = seed.seedPosition || 0;
      let updatedPos = seedPos;
      if (newPosition < currentPosition) {
        if (seedPos >= newPosition && seedPos < currentPosition) {
          updatedPos = seedPos + 1;
        }
      } else if (newPosition > currentPosition) {
        if (seedPos <= newPosition && seedPos > currentPosition) {
          updatedPos = seedPos - 1;
        }
      }

      if (updatedPos !== seedPos) {
        await db
          .update(bracketSeeds)
          .set({ seedPosition: updatedPos, updatedAt: new Date() })
          .where(eq(bracketSeeds.id, seed.id));
      }
    }

    await db
      .update(bracketSeeds)
      .set({ seedPosition: newPosition, isManualOverride: true, updatedAt: new Date() })
      .where(eq(bracketSeeds.id, seeds[targetSeedIndex].id));

    return { success: true };
  }

  static async lockSeeds(bracketId: string) {
    logger.info({ bracketId }, "Locking seeding configuration");

    const [bracket] = await db.select().from(brackets).where(eq(brackets.id, bracketId)).limit(1);
    if (!bracket) {
      throw new NotFoundError("Bracket not found.");
    }

    await db
      .update(brackets)
      .set({ seedingLocked: true, updatedAt: new Date() })
      .where(eq(brackets.id, bracketId));

    return { success: true };
  }

  // ==========================================
  // 5. Bracket Generation & Safe Safeguards
  // ==========================================

  static async generateBracketMatches(bracketId: string) {
    logger.info({ bracketId }, "Generating tournament matches");

    const [bracket] = await db.select().from(brackets).where(eq(brackets.id, bracketId)).limit(1);
    if (!bracket) {
      throw new NotFoundError("Bracket not found.");
    }

    if (!bracket.seedingLocked) {
      throw new BadRequestError("Seeding must be locked before generating tournament brackets.");
    }

    if (bracket.status === "ACTIVE" || bracket.status === "COMPLETED") {
      throw new BadRequestError("Bracket is already active/completed. Regeneration is prohibited for structural safety.");
    }

    const seeds = await db
      .select()
      .from(bracketSeeds)
      .where(eq(bracketSeeds.bracketId, bracketId))
      .orderBy(asc(bracketSeeds.seedPosition));

    if (seeds.length === 0) {
      throw new BadRequestError("Cannot generate a bracket with zero seeded athletes.");
    }

    // Wipe any older draft matches
    await db.delete(tournamentMatches).where(eq(tournamentMatches.bracketId, bracketId));

    if (bracket.format === "SINGLE_ELIMINATION") {
      // Find nearest power of 2
      const powerOf2 = Math.pow(2, Math.ceil(Math.log2(seeds.length)));
      
      // Seed positions padded with nulls for byes
      const paddedSeeds: (string | null)[] = Array.from({ length: powerOf2 }, () => null);
      seeds.forEach((s) => {
        if (s.seedPosition) {
          paddedSeeds[s.seedPosition - 1] = s.athleteId;
        }
      });

      // Standard tournament seeding pairings (1 vs N, 2 vs N-1)
      const pairings: (string | null)[][] = [];
      for (let i = 0; i < powerOf2 / 2; i++) {
        pairings.push([paddedSeeds[i], paddedSeeds[powerOf2 - 1 - i]]);
      }

      // Generate round 1 matches
      const matchesToInsert = [];
      const matchIndexStart = 1;

      // Construct rounds
      // We will generate the matches recursively/iteratively linking nextMatchId
      let currentRoundPairs = pairings;
      let roundNum = 1;
      let previousRoundMatches: any[] = [];

      while (currentRoundPairs.length >= 1) {
        const roundMatches: any[] = [];
        
        for (let idx = 0; idx < currentRoundPairs.length; idx++) {
          const pair = currentRoundPairs[idx];
          const isRound1 = roundNum === 1;

          const matchId = crypto.randomUUID();
          const athleteAId = isRound1 ? pair[0] : null;
          const athleteBId = isRound1 ? pair[1] : null;

          // Compute status: if BYE, automatically complete
          let status = "PENDING";
          let winnerId = null;
          if (isRound1) {
            if (athleteAId && !athleteBId) {
              status = "BYE";
              winnerId = athleteAId;
            } else if (!athleteAId && athleteBId) {
              status = "BYE";
              winnerId = athleteBId;
            } else if (athleteAId && athleteBId) {
              status = "READY";
            }
          }

          const matchObj = {
            id: matchId,
            bracketId,
            round: roundNum,
            matchIndex: idx + 1,
            bracketType: "PRIMARY",
            athleteAId,
            athleteBId,
            winnerId,
            status,
            createdAt: new Date(),
            updatedAt: new Date()
          };

          matchesToInsert.push(matchObj);
          roundMatches.push(matchObj);
        }

        // Connect previous round to this round
        if (previousRoundMatches.length > 0) {
          for (let i = 0; i < previousRoundMatches.length; i++) {
            const prev = previousRoundMatches[i];
            const targetIndex = Math.floor(i / 2);
            const targetMatch = roundMatches[targetIndex];
            
            prev.nextMatchId = targetMatch.id;
            prev.nextMatchPlayerPosition = (i % 2 === 0) ? "A" : "B";
          }
        }

        previousRoundMatches = roundMatches;
        roundNum++;
        
        if (currentRoundPairs.length === 1) {
          break;
        }
        currentRoundPairs = Array.from({ length: currentRoundPairs.length / 2 }, () => [null, null]);
      }

      // Bulk write
      for (const m of matchesToInsert) {
        await db.insert(tournamentMatches).values(m);
      }

    } else if (bracket.format === "DOUBLE_ELIMINATION") {
      const powerOf2 = Math.pow(2, Math.ceil(Math.log2(seeds.length)));
      const K = Math.ceil(Math.log2(powerOf2)); // K rounds in winners bracket

      // Seed positions padded with nulls for byes
      const paddedSeeds: (string | null)[] = Array.from({ length: powerOf2 }, () => null);
      seeds.forEach((s) => {
        if (s.seedPosition) {
          paddedSeeds[s.seedPosition - 1] = s.athleteId;
        }
      });

      // Standard tournament seeding pairings (1 vs N, 2 vs N-1)
      const pairings: (string | null)[][] = [];
      for (let i = 0; i < powerOf2 / 2; i++) {
        pairings.push([paddedSeeds[i], paddedSeeds[powerOf2 - 1 - i]]);
      }

      const matchesToInsert: any[] = [];

      // Grand Final match IDs are needed before the routing loops below run,
      // since WB/LB matches route into them.
      const gf1Id = crypto.randomUUID();
      const gf2Id = crypto.randomUUID();

      // 1. Generate Winners Bracket (PRIMARY) matches
      const wbMatchesByRound: { [round: number]: any[] } = {};
      for (let r = 1; r <= K; r++) {
        wbMatchesByRound[r] = [];
        const matchCount = powerOf2 / Math.pow(2, r);
        for (let idx = 0; idx < matchCount; idx++) {
          const matchId = crypto.randomUUID();
          let athleteAId = null;
          let athleteBId = null;
          let status = "PENDING";
          let winnerId = null;

          if (r === 1) {
            const pair = pairings[idx];
            athleteAId = pair[0];
            athleteBId = pair[1];
            if (athleteAId && !athleteBId) {
              status = "BYE";
              winnerId = athleteAId;
            } else if (!athleteAId && athleteBId) {
              status = "BYE";
              winnerId = athleteBId;
            } else if (athleteAId && athleteBId) {
              status = "READY";
            }
          }

          const matchObj = {
            id: matchId,
            bracketId,
            round: r,
            matchIndex: idx + 1,
            bracketType: "PRIMARY",
            athleteAId,
            athleteBId,
            winnerId,
            status,
            createdAt: new Date(),
            updatedAt: new Date(),
            nextMatchId: null as string | null,
            nextMatchPlayerPosition: null as string | null,
            losersNextMatchId: null as string | null,
          };
          matchesToInsert.push(matchObj);
          wbMatchesByRound[r].push(matchObj);
        }
      }

      // Connect Winners Bracket nextMatchId and nextMatchPlayerPosition
      // (array index === matchIndex - 1 throughout, since matches are pushed
      // in idx order above — so wbMatchesByRound[r][targetIdx] is exactly
      // the real object for "round r, match targetIdx+1", no ID string
      // reconstruction needed.)
      for (let r = 1; r < K; r++) {
        const roundMatches = wbMatchesByRound[r];
        for (let i = 0; i < roundMatches.length; i++) {
          const match = roundMatches[i];
          const targetIdx = Math.floor(i / 2);
          match.nextMatchId = wbMatchesByRound[r + 1][targetIdx].id;
          match.nextMatchPlayerPosition = (i % 2 === 0) ? "A" : "B";
        }
      }

      // Connect Winners Bracket Final to Grand Final Round 1 Slot A
      if (wbMatchesByRound[K] && wbMatchesByRound[K][0]) {
        wbMatchesByRound[K][0].nextMatchId = gf1Id;
        wbMatchesByRound[K][0].nextMatchPlayerPosition = "A";
      }

      // 2. Generate Losers Bracket (LOSERS) matches
      // LB Round count is 2*K - 2
      const lbMatchesByRound: { [round: number]: any[] } = {};
      const lbRoundCount = 2 * K - 2;
      for (let j = 1; j <= lbRoundCount; j++) {
        lbMatchesByRound[j] = [];
        const matchCount = powerOf2 / Math.pow(2, Math.floor((j + 3) / 2));
        for (let idx = 0; idx < matchCount; idx++) {
          const matchId = crypto.randomUUID();
          const matchObj = {
            id: matchId,
            bracketId,
            round: j,
            matchIndex: idx + 1,
            bracketType: "LOSERS",
            athleteAId: null as string | null,
            athleteBId: null as string | null,
            winnerId: null as string | null,
            status: "PENDING",
            createdAt: new Date(),
            updatedAt: new Date(),
            nextMatchId: null as string | null,
            nextMatchPlayerPosition: null as string | null,
            losersNextMatchId: null as string | null,
          };
          matchesToInsert.push(matchObj);
          lbMatchesByRound[j].push(matchObj);
        }
      }

      // Connect Winners Bracket losers to Losers Bracket matches:
      // - Losers of WB Round 1 go to LB Round 1: Match W1-i loser goes to LB Round 1, Match Math.floor((i-1)/2) + 1
      if (wbMatchesByRound[1]) {
        for (let i = 0; i < wbMatchesByRound[1].length; i++) {
          const m = wbMatchesByRound[1][i];
          const targetIdx = Math.floor(i / 2);
          m.losersNextMatchId = lbMatchesByRound[1][targetIdx].id;
        }
      }
      // - Losers of WB Round r (for r >= 2) go to LB Round 2r - 2: Match Wr-m loser goes to LB Round 2r - 2, Match m
      for (let r = 2; r <= K; r++) {
        if (wbMatchesByRound[r]) {
          for (let m = 0; m < wbMatchesByRound[r].length; m++) {
            const match = wbMatchesByRound[r][m];
            match.losersNextMatchId = lbMatchesByRound[2 * r - 2][m].id;
          }
        }
      }

      // Connect Losers Bracket matches nextMatchId:
      for (let j = 1; j <= lbRoundCount; j++) {
        const roundMatches = lbMatchesByRound[j];
        if (j < lbRoundCount) {
          if (j % 2 === 1) {
            // odd LB rounds: winner goes to next LB round (j+1) same match index, position A
            for (let i = 0; i < roundMatches.length; i++) {
              roundMatches[i].nextMatchId = lbMatchesByRound[j + 1][i].id;
              roundMatches[i].nextMatchPlayerPosition = "A";
            }
          } else {
            // even LB rounds: winner goes to next LB round (j+1) match index Math.floor(i/2) + 1, position depends on index
            for (let i = 0; i < roundMatches.length; i++) {
              const targetIdx = Math.floor(i / 2);
              roundMatches[i].nextMatchId = lbMatchesByRound[j + 1][targetIdx].id;
              roundMatches[i].nextMatchPlayerPosition = (i % 2 === 0) ? "A" : "B";
            }
          }
        } else {
          // Losers Final winner goes to Grand Final Round 1 Slot B
          if (roundMatches[0]) {
            roundMatches[0].nextMatchId = gf1Id;
            roundMatches[0].nextMatchPlayerPosition = "B";
          }
        }
      }

      // 3. Generate Grand Final (GRAND_FINAL) matches
      // GF Round 1
      const gf1 = {
        id: gf1Id,
        bracketId,
        round: 1,
        matchIndex: 1,
        bracketType: "GRAND_FINAL",
        athleteAId: null as string | null,
        athleteBId: null as string | null,
        winnerId: null as string | null,
        status: "PENDING",
        createdAt: new Date(),
        updatedAt: new Date(),
        nextMatchId: gf2Id,
        nextMatchPlayerPosition: null as string | null,
        losersNextMatchId: null as string | null,
      };
      // GF Round 2
      const gf2 = {
        id: gf2Id,
        bracketId,
        round: 2,
        matchIndex: 1,
        bracketType: "GRAND_FINAL",
        athleteAId: null as string | null,
        athleteBId: null as string | null,
        winnerId: null as string | null,
        status: "PENDING",
        createdAt: new Date(),
        updatedAt: new Date(),
        nextMatchId: null as string | null,
        nextMatchPlayerPosition: null as string | null,
        losersNextMatchId: null as string | null,
      };
      matchesToInsert.push(gf1, gf2);

      // Write all matches to DB
      for (const m of matchesToInsert) {
        await db.insert(tournamentMatches).values(m);
      }

      // Perform initial reconciliation to propagate any BYEs
      await TournamentService.reconcileBracketMatches(bracketId);

    } else if (bracket.format === "ROUND_ROBIN" || bracket.format === "SUPERMATCH") {
      // Supermatch best of 6 rounds
      const roundsCount = bracket.format === "SUPERMATCH" ? 6 : Math.max(1, seeds.length - 1);
      const athA = seeds[0]?.athleteId || null;
      const athB = seeds[1]?.athleteId || null;

      for (let r = 1; r <= roundsCount; r++) {
        await db.insert(tournamentMatches).values({
          bracketId,
          round: r,
          matchIndex: 1,
          bracketType: "PRIMARY",
          athleteAId: athA,
          athleteBId: athB,
          status: (athA && athB) ? "READY" : "PENDING"
        });
      }
    }

    await db
      .update(brackets)
      .set({ status: "ACTIVE", updatedAt: new Date() })
      .where(eq(brackets.id, bracketId));

    return { success: true };
  }

  // ==========================================
  // 6. Match Queue & Table Management
  // ==========================================

  static async createTable(name: string) {
    const [table] = await db.insert(matchTables).values({ name, status: "IDLE" }).returning();
    return table;
  }

  static async listTables() {
    logger.info("Listing match tables");
    return db.select().from(matchTables).orderBy(asc(matchTables.name));
  }

  static async assignReferee(matchId: string, refereeId: string) {
    logger.info({ matchId, refereeId }, "Assigning referee to tournament match");

    const [refereeUser] = await db.select().from(users).where(eq(users.id, refereeId)).limit(1);
    if (!refereeUser) {
      throw new NotFoundError("Referee user not found.");
    }

    const assignableRoles: string[] = [UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN];
    if (!assignableRoles.includes(refereeUser.role)) {
      throw new BadRequestError("Referee must hold a referee or director role.");
    }

    const [match] = await db.select().from(tournamentMatches).where(eq(tournamentMatches.id, matchId)).limit(1);
    if (!match) {
      throw new NotFoundError("Match not found.");
    }

    const [updated] = await db
      .update(tournamentMatches)
      .set({ refereeId, updatedAt: new Date() })
      .where(eq(tournamentMatches.id, matchId))
      .returning();

    return updated;
  }

  static async callMatchToTable(matchId: string, tableId: string, actorId?: string) {
    if (actorId) {
      await RefereeCertificationService.assertActiveCertification(actorId);
    }
    logger.info({ matchId, tableId }, "Calling tournament match to table");

    const [match] = await db.select().from(tournamentMatches).where(eq(tournamentMatches.id, matchId)).limit(1);
    if (!match) {
      throw new NotFoundError("Match not found.");
    }

    const [table] = await db.select().from(matchTables).where(eq(matchTables.id, tableId)).limit(1);
    if (!table) {
      throw new NotFoundError("Match table not found.");
    }

    // Call match updates
    const [updatedMatch] = await db
      .update(tournamentMatches)
      .set({ status: "CALLED", tableId, updatedAt: new Date() })
      .where(eq(tournamentMatches.id, matchId))
      .returning();

    await db
      .update(matchTables)
      .set({ status: "ACTIVE", currentMatchId: matchId, updatedAt: new Date() })
      .where(eq(matchTables.id, tableId));

    return updatedMatch;
  }

  static async reconcileBracketMatches(bracketId: string) {
    logger.info({ bracketId }, "Reconciling bracket matches and propagating progression");

    let changed = true;
    let iteration = 0;
    const maxIterations = 50;

    while (changed && iteration < maxIterations) {
      changed = false;
      iteration++;

      const matches = await (db as any).select().from(tournamentMatches).where(eq(tournamentMatches.bracketId as any, bracketId as any));
      const matchMap = new Map<string, any>();
      for (const m of matches) {
        matchMap.set(m.id, m);
      }

      const sourceMap = new Map<string, { A: { match: any; type: string } | null; B: { match: any; type: string } | null }>();
      for (const m of matches) {
        sourceMap.set(m.id, { A: null, B: null });
      }

      for (const m of matches) {
        if (m.nextMatchId) {
          const nextSources = sourceMap.get(m.nextMatchId);
          if (nextSources) {
            if (m.nextMatchPlayerPosition === "A") nextSources.A = { match: m, type: "winner" };
            if (m.nextMatchPlayerPosition === "B") nextSources.B = { match: m, type: "winner" };
          }
        }
        if (m.losersNextMatchId) {
          const nextSources = sourceMap.get(m.losersNextMatchId);
          if (nextSources) {
            const losersMatch = matchMap.get(m.losersNextMatchId);
            if (losersMatch) {
              const isLbR1 = losersMatch.round === 1;
              const position = isLbR1 ? (((m.matchIndex - 1) % 2 === 0) ? "A" : "B") : "B";
              if (position === "A") nextSources.A = { match: m, type: "loser" };
              if (position === "B") nextSources.B = { match: m, type: "loser" };
            }
          }
        }
      }

      for (const m of matches) {
        if (m.bracketType === "GRAND_FINAL" && m.round === 1) {
          if (m.status === "COMPLETED") {
            const nextM = matchMap.get(m.nextMatchId);
            if (nextM) {
              if (m.winnerId === m.athleteBId) {
                if (nextM.athleteAId !== m.athleteAId || nextM.athleteBId !== m.athleteBId || (nextM.status !== "READY" && nextM.status !== "COMPLETED")) {
                  const statusToSet = nextM.status === "COMPLETED" ? "COMPLETED" : "READY";
                  await (db as any).update(tournamentMatches)
                    .set({ athleteAId: m.athleteAId, athleteBId: m.athleteBId, status: statusToSet, updatedAt: new Date() })
                    .where(eq(tournamentMatches.id as any, m.nextMatchId as any));
                  nextM.athleteAId = m.athleteAId;
                  nextM.athleteBId = m.athleteBId;
                  if (nextM.status !== "COMPLETED") {
                    nextM.status = "READY";
                  }
                  changed = true;
                }
              } else if (m.winnerId === m.athleteAId) {
                if (nextM.status !== "BYE") {
                  await (db as any).update(tournamentMatches)
                    .set({ status: "BYE", winnerId: null, updatedAt: new Date() })
                    .where(eq(tournamentMatches.id as any, m.nextMatchId as any));
                  nextM.status = "BYE";
                  nextM.winnerId = null;
                  changed = true;
                }
              }
            }
          }
        }

        if ((m.status === "COMPLETED" || m.status === "BYE") && m.winnerId) {
          if (m.nextMatchId) {
            const nextM = matchMap.get(m.nextMatchId);
            if (nextM) {
              const pos = m.nextMatchPlayerPosition;
              if (pos === "A" && nextM.athleteAId !== m.winnerId) {
                await (db as any).update(tournamentMatches).set({ athleteAId: m.winnerId, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.nextMatchId as any));
                nextM.athleteAId = m.winnerId;
                changed = true;
              } else if (pos === "B" && nextM.athleteBId !== m.winnerId) {
                await (db as any).update(tournamentMatches).set({ athleteBId: m.winnerId, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.nextMatchId as any));
                nextM.athleteBId = m.winnerId;
                changed = true;
              }
            }
          }

          if (m.status === "COMPLETED" && m.losersNextMatchId) {
            const loserId = m.winnerId === m.athleteAId ? m.athleteBId : m.athleteAId;
            if (loserId) {
              const losersM = matchMap.get(m.losersNextMatchId);
              if (losersM) {
                const isLbR1 = losersM.round === 1;
                const position = isLbR1 ? (((m.matchIndex - 1) % 2 === 0) ? "A" : "B") : "B";
                if (position === "A" && losersM.athleteAId !== loserId) {
                  await (db as any).update(tournamentMatches).set({ athleteAId: loserId, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, losersM.id as any));
                  losersM.athleteAId = loserId;
                  changed = true;
                } else if (position === "B" && losersM.athleteBId !== loserId) {
                  await (db as any).update(tournamentMatches).set({ athleteBId: loserId, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, losersM.id as any));
                  losersM.athleteBId = loserId;
                  changed = true;
                }
              }
            }
          }
        }

        const sources = sourceMap.get(m.id);
        const sourceA = sources?.A;
        const sourceB = sources?.B;

        const helperCanFill = (athleteId: string | null, srcInfo: { match: any; type: string } | null) => {
          if (athleteId) return true;
          if (!srcInfo) return false;
          const src = srcInfo.match;
          if (srcInfo.type === "winner") {
            if (src.status !== "COMPLETED" && src.status !== "BYE") {
              return true;
            }
            return !!src.winnerId;
          } else {
            if (src.status !== "COMPLETED" && src.status !== "BYE") {
              return true;
            }
            if (src.status === "BYE") {
              return false;
            }
            const loserId = src.winnerId === src.athleteAId ? src.athleteBId : src.athleteAId;
            return !!loserId;
          }
        };

        const canFillA = helperCanFill(m.athleteAId, sourceA || null);
        const canFillB = helperCanFill(m.athleteBId, sourceB || null);

        if (m.status === "BYE") {
          let expectedWinnerId: string | null = null;
          if (!canFillA && canFillB && m.athleteBId) {
            expectedWinnerId = m.athleteBId;
          } else if (canFillA && !canFillB && m.athleteAId) {
            expectedWinnerId = m.athleteAId;
          }
          if (expectedWinnerId && m.winnerId !== expectedWinnerId) {
            await (db as any).update(tournamentMatches).set({ winnerId: expectedWinnerId, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
            m.winnerId = expectedWinnerId;
            changed = true;
          }
        }

        if (m.status === "PENDING" || m.status === "READY") {
          if (m.athleteAId && m.athleteBId) {
            if (m.status !== "READY") {
              await (db as any).update(tournamentMatches).set({ status: "READY", updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
              m.status = "READY";
              changed = true;
            }
          } else {
            if (!canFillA && !canFillB) {
              if (m.status !== "BYE" || m.winnerId !== null) {
                await (db as any).update(tournamentMatches).set({ status: "BYE", winnerId: null, updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
                m.status = "BYE";
                m.winnerId = null;
                changed = true;
              }
            } else if (!canFillA && canFillB) {
              if (m.status !== "BYE") {
                await (db as any).update(tournamentMatches).set({ status: "BYE", updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
                m.status = "BYE";
                changed = true;
              }
            } else if (canFillA && !canFillB) {
              if (m.status !== "BYE") {
                await (db as any).update(tournamentMatches).set({ status: "BYE", updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
                m.status = "BYE";
                changed = true;
              }
            } else {
              if (m.status !== "PENDING") {
                await (db as any).update(tournamentMatches).set({ status: "PENDING", updatedAt: new Date() }).where(eq(tournamentMatches.id as any, m.id as any));
                m.status = "PENDING";
                changed = true;
              }
            }
          }
        }
      }
    }
  }

  static async submitMatchResult(matchId: string, winnerId: string, scoreLine: string, actorId?: string) {
    if (actorId) {
      await RefereeCertificationService.assertActiveCertification(actorId);
    }
    logger.info({ matchId, winnerId, scoreLine }, "Submitting official match result");

    const [match] = await (db as any).select().from(tournamentMatches).where(eq(tournamentMatches.id as any, matchId as any)).limit(1);
    if (!match) {
      throw new NotFoundError("Tournament match not found.");
    }

    if (actorId) {
      const [actorUser] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
      const isSupervisor =
        actorUser &&
        [UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN].includes(
          actorUser.role as UserRole
        );
      if (!isSupervisor && match.refereeId !== actorId) {
        throw new ForbiddenError("Only the assigned referee or a tournament director can submit this match result.");
      }
    }

    if (match.status === "COMPLETED" || match.status === "BYE") {
      return match;
    }

    if (winnerId !== match.athleteAId && winnerId !== match.athleteBId) {
      throw new BadRequestError("Winner must be one of the match participants.");
    }

    const tableId = (match as any).tableId;

    // Save winner result
    const [completedMatch] = await (db as any)
      .update(tournamentMatches)
      .set({
        winnerId,
        scoreLine,
        status: "COMPLETED",
        updatedAt: new Date()
      })
      .where(eq(tournamentMatches.id as any, matchId as any))
      .returning();

    // Release table
    if (tableId) {
      await (db as any)
        .update(matchTables)
        .set({ status: "IDLE", currentMatchId: null, updatedAt: new Date() })
        .where(eq(matchTables.id as any, tableId as any));
    }

    // Run recursive, comprehensive progression & reconciliation engine
    await TournamentService.reconcileBracketMatches((match as any).bracketId);

    // Check bracket completion status
    const uncompleted = await (db as any)
      .select()
      .from(tournamentMatches)
      .where(
        and(
          eq(tournamentMatches.bracketId as any, (match as any).bracketId as any),
          not(eq(tournamentMatches.status as any, "COMPLETED" as any)),
          not(eq(tournamentMatches.status as any, "BYE" as any))
        )
      );

    if (uncompleted.length === 0) {
      await (db as any)
        .update(brackets)
        .set({ status: "COMPLETED", updatedAt: new Date() })
        .where(eq(brackets.id as any, (match as any).bracketId as any));
    }

    return completedMatch;
  }

  // ==========================================
  // 7. Metrics & Analytics Reporting
  // ==========================================

  static async getEventStats(eventId: string) {
    const [event] = await (db as any).select().from(events).where(eq(events.id as any, eventId as any)).limit(1);
    if (!event) {
      throw new NotFoundError("Event not found.");
    }

    const regs = await (db as any).select().from(eventRegistrations).where(eq(eventRegistrations.eventId as any, eventId as any));
    
    const approved = regs.filter((r: any) => r.status === "APPROVED").length;
    const waitlisted = regs.filter((r: any) => r.status === "WAITLISTED").length;
    const pending = regs.filter((r: any) => r.status === "PENDING").length;

    // Weigh in stats
    let passedWeighinCount = 0;
    for (const r of regs) {
      const weighins = await (db as any)
        .select()
        .from(officialWeighins)
        .where(
          and(
            eq(officialWeighins.registrationId as any, (r as any).id as any),
            eq(officialWeighins.status as any, "PASSED" as any)
          )
        );
      if (weighins.length > 0) {
        passedWeighinCount++;
      }
    }

    return {
      eventId,
      eventName: (event as any).name,
      totalRegistrations: regs.length,
      approved,
      waitlisted,
      pending,
      passedWeighins: passedWeighinCount,
      capacity: (event as any).capacity
    };
  }

  static async getParticipationMetrics() {
    const regs = await (db as any).select().from(eventRegistrations);
    
    const divisions: Record<string, number> = {};
    const weightClasses: Record<string, number> = {};
    const arms: Record<string, number> = {};

    regs.forEach((r: any) => {
      divisions[r.division] = (divisions[r.division] || 0) + 1;
      weightClasses[r.weightClass] = (weightClasses[r.weightClass] || 0) + 1;
      arms[r.arm] = (arms[r.arm] || 0) + 1;
    });

    return {
      registrationsByDivision: divisions,
      registrationsByWeightClass: weightClasses,
      registrationsByArm: arms
    };
  }

  static async getMedalTable(eventId: string) {
    // Collect bracket winners
    const eventBrackets = await (db as any).select().from(brackets).where(eq(brackets.eventId as any, eventId as any));
    
    const results = [];
    for (const b of eventBrackets) {
      // Find grand final match (the one with no nextMatchId)
      const primaryMatches = await (db as any)
        .select()
        .from(tournamentMatches)
        .where(
          and(
            eq(tournamentMatches.bracketId as any, b.id as any),
            eq(tournamentMatches.bracketType as any, "PRIMARY" as any)
          )
        );

      const finals = primaryMatches.filter((m: any) => !m.nextMatchId);
      if (finals.length > 0 && finals[0].winnerId) {
        const [winner] = await (db as any).select().from(athleteProfiles).where(eq(athleteProfiles.id as any, finals[0].winnerId as any)).limit(1);
        results.push({
          bracketId: b.id,
          bracketName: b.name,
          goldMedalist: winner ? winner.displayName : "Unknown",
          division: b.division,
          weightClass: b.weightClass
        });
      }
    }

    return results;
  }

  static async getClubStandings(eventId: string) {
    // Aggregate club performance by combining registrations and matches won
    const regs = await (db as any)
      .select({
        clubName: athleteClubs.name,
        athleteId: athleteProfiles.id
      })
      .from(eventRegistrations)
      .innerJoin(athleteProfiles, eq(athleteProfiles.id as any, eventRegistrations.athleteId as any))
      .leftJoin(athleteClubs, eq(athleteClubs.id as any, athleteProfiles.clubId as any))
      .where(eq(eventRegistrations.eventId as any, eventId as any));

    const standings: Record<string, { registrations: number; wins: number; points: number }> = {};

    regs.forEach((r: any) => {
      const club = (r.clubName || "Independent") as string;
      if (!standings[club]) {
        standings[club] = { registrations: 0, wins: 0, points: 0 };
      }
      standings[club].registrations += 1;
      standings[club].points += 1; // 1 point per registration
    });

    return Object.entries(standings)
      .map(([club, stats]) => ({
        clubName: club,
        ...stats
      }))
      .sort((a, b) => b.points - a.points);
  }

  static async getBracket(id: string) {
    logger.info({ id }, "Getting bracket structure and matches");
    const [bracket] = await db.select().from(brackets).where(eq(brackets.id, id)).limit(1);
    if (!bracket) {
      throw new NotFoundError("Bracket not found.");
    }

    const matchesList = await db.select().from(tournamentMatches).where(eq(tournamentMatches.bracketId, id));

    const athleteIds = Array.from(
      new Set(
        matchesList
          .flatMap((m) => [m.athleteAId, m.athleteBId])
          .filter((id): id is string => id !== null)
      )
    );
    const athletesList = athleteIds.length > 0
      ? await db.select().from(athleteProfiles).where(inArray(athleteProfiles.id, athleteIds))
      : [];

    const athleteMap = new Map<string, typeof athleteProfiles.$inferSelect>();
    athletesList.forEach((a) => {
      athleteMap.set(a.id, a);
    });

    return {
      id: bracket.id,
      name: bracket.name,
      format: bracket.format,
      division: bracket.division,
      weightClass: bracket.weightClass,
      arm: bracket.arm,
      status: bracket.status,
      seedingLocked: bracket.seedingLocked,
      eventId: bracket.eventId,
      matches: matchesList.map((m) => {
        const athleteA = m.athleteAId ? athleteMap.get(m.athleteAId) : null;
        const athleteB = m.athleteBId ? athleteMap.get(m.athleteBId) : null;
        return {
          id: m.id,
          round: m.round,
          matchIndex: m.matchIndex,
          bracketType: m.bracketType,
          athleteAId: m.athleteAId,
          athleteBId: m.athleteBId,
          athleteAName: athleteA ? athleteA.displayName : null,
          athleteBName: athleteB ? athleteB.displayName : null,
          athleteAElo: athleteA ? (bracket.arm === "LEFT" ? athleteA.leftArmElo : athleteA.rightArmElo) : null,
          athleteBElo: athleteB ? (bracket.arm === "LEFT" ? athleteB.leftArmElo : athleteB.rightArmElo) : null,
          winnerId: m.winnerId,
          scoreLine: m.scoreLine,
          status: m.status,
          tableId: m.tableId,
          refereeId: m.refereeId,
          nextMatchId: m.nextMatchId,
          nextMatchPlayerPosition: m.nextMatchPlayerPosition,
        };
      })
    };
  }

  static async listBrackets() {
    logger.info("Listing all tournament brackets");
    return (db as any).select().from(brackets);
  }

  static async getEventRegistrations(eventId: string) {
    logger.info({ eventId }, "Getting all registrations for tournament event");
    return db
      .select({
        id: eventRegistrations.id,
        eventId: eventRegistrations.eventId,
        athleteId: eventRegistrations.athleteId,
        athleteName: athleteProfiles.displayName,
        division: eventRegistrations.division,
        weightClass: eventRegistrations.weightClass,
        arm: eventRegistrations.arm,
        status: eventRegistrations.status,
        paymentConfirmedByOrganizer: eventRegistrations.paymentConfirmedByOrganizer,
        paymentConfirmedAt: eventRegistrations.paymentConfirmedAt,
        createdAt: eventRegistrations.createdAt,
        updatedAt: eventRegistrations.updatedAt
      })
      .from(eventRegistrations)
      .innerJoin(athleteProfiles, eq(athleteProfiles.id, eventRegistrations.athleteId))
      .where(eq(eventRegistrations.eventId, eventId));
  }

  /// Every bracket match across one event, with athlete display names and the
  /// bracket category — powers the operator match-day board and referee
  /// assignment views without N+1 bracket fetches.
  static async getEventMatches(eventId: string) {
    logger.info({ eventId }, "Getting all bracket matches for tournament event");
    const athleteA = alias(athleteProfiles, "athlete_a");
    const athleteB = alias(athleteProfiles, "athlete_b");
    return db
      .select({
        id: tournamentMatches.id,
        bracketId: tournamentMatches.bracketId,
        bracketName: brackets.name,
        division: brackets.division,
        weightClass: brackets.weightClass,
        arm: brackets.arm,
        round: tournamentMatches.round,
        matchIndex: tournamentMatches.matchIndex,
        bracketType: tournamentMatches.bracketType,
        athleteAId: tournamentMatches.athleteAId,
        athleteBId: tournamentMatches.athleteBId,
        athleteAName: athleteA.displayName,
        athleteBName: athleteB.displayName,
        winnerId: tournamentMatches.winnerId,
        scoreLine: tournamentMatches.scoreLine,
        status: tournamentMatches.status,
        tableId: tournamentMatches.tableId,
        refereeId: tournamentMatches.refereeId
      })
      .from(tournamentMatches)
      .innerJoin(brackets, eq(brackets.id, tournamentMatches.bracketId))
      .leftJoin(athleteA, eq(athleteA.id, tournamentMatches.athleteAId))
      .leftJoin(athleteB, eq(athleteB.id, tournamentMatches.athleteBId))
      .where(eq(brackets.eventId, eventId))
      .orderBy(asc(tournamentMatches.round), asc(tournamentMatches.matchIndex));
  }

  static async confirmManualPayment(registrationId: string, actorId: string, actorRole: string) {
    logger.info({ registrationId, actorId, actorRole }, "Confirming manual payment for registration");
    const [registration] = await db
      .select()
      .from(eventRegistrations)
      .where(eq(eventRegistrations.id, registrationId))
      .limit(1);

    if (!registration) {
      throw new NotFoundError("Registration not found.");
    }

    const [event] = await db
      .select()
      .from(events)
      .where(eq(events.id, registration.eventId))
      .limit(1);

    if (!event) {
      throw new NotFoundError("Tournament event not found.");
    }

    const isOrganizer = event.organizerId && actorId === event.organizerId;
    const isAdmin = actorRole === "SYSTEM_ADMIN" || actorRole === "NATIONAL_DIRECTOR";

    if (!isOrganizer && !isAdmin) {
      throw new ForbiddenError("Only the event's organizer or an admin can confirm manual payments.");
    }

    if (!event.registrationFeeCents || event.registrationFeeCents <= 0) {
      throw new BadRequestError("This event does not require payment.");
    }

    if (event.paymentMethod !== "MANUAL_QR") {
      throw new BadRequestError("This event uses Stripe checkout, not manual QR payment.");
    }

    if (registration.status !== "PENDING_PAYMENT") {
      throw new BadRequestError("This registration is not awaiting payment.");
    }

    // Update status to PENDING
    const [updatedReg] = await db
      .update(eventRegistrations)
      .set({
        status: "PENDING",
        paymentConfirmedByOrganizer: true,
        paymentConfirmedAt: new Date(),
        updatedAt: new Date()
      })
      .where(eq(eventRegistrations.id, registrationId))
      .returning();

    // Log to immutable audit ledger
    await auditLedgerService.logEvent({
      actorId,
      entityType: "event_registrations",
      entityId: registrationId,
      action: "MANUAL_PAYMENT_CONFIRMATION",
      payload: {
        confirmedBy: actorId,
        confirmedAt: new Date().toISOString(),
        eventId: event.id,
        athleteId: registration.athleteId,
        amountCents: event.registrationFeeCents
      }
    });

    return updatedReg;
  }
}
