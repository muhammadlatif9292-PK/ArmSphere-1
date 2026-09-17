import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken, hashPassword } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

/**
 * Task 23 — Full Product Flow E2E Audit
 * Validates the complete Master-Spec user journeys sequentially:
 * 1. Auth & Registration (register -> credentials -> login -> token refresh)
 * 2. Onboarding (profile creation -> biometrics -> verification submission -> review)
 * 3. Home & Role Routing (athlete -> referee -> provincial director)
 * 4. Discovery Surface (athlete search -> rankings -> venues -> events)
 * 5. Event Lifecycle & Tournament Registration (create event -> publish -> register -> confirm)
 * 6. Competition & Match Flow (weigh-in -> brackets -> match scoring -> verify -> ELO adjustment)
 * 7. Profile & Activity (public profile detail -> match history)
 * 8. Community & Social (post creation -> like -> comment -> follow)
 * 9. Governance & Dispute Resolution (dispute filing -> evidence -> provincial jurisdiction enforcement -> resolution)
 */
describe("Task 23: Full Product Flow End-to-End Audit", () => {
  // Common UUIDs for deterministic tracking across journeys
  const UUID_ATHLETE_1 = "11111111-1111-1111-1111-aaaaaaaaaaaa";
  const UUID_ATHLETE_2 = "22222222-2222-2222-2222-bbbbbbbbbbbb";
  const UUID_PROFILE_1 = "11111111-0000-0000-0000-aaaaaaaaaaaa";
  const UUID_PROFILE_2 = "22222222-0000-0000-0000-bbbbbbbbbbbb";
  const UUID_REFEREE = "33333333-3333-3333-3333-cccccccccccc";
  const UUID_DIRECTOR_ONTARIO = "44444444-4444-4444-4444-dddddddddddd";
  const UUID_DIRECTOR_QUEBEC = "55555555-5555-5555-5555-eeeeeeeeeeee";
  const UUID_ADMIN = "66666666-6666-6666-6666-ffffffffffff";

  let tokenAthlete1: string;
  let tokenAthlete2: string;
  let tokenReferee: string;
  let tokenDirectorOntario: string;
  let tokenDirectorQuebec: string;
  let tokenAdmin: string;

  beforeEach(async () => {
    // Reset testDbStore for pristine isolation
    testDbStore.users = [];
    testDbStore.userSessions = [];
    testDbStore.athleteProfiles = [];
    testDbStore.athleteBiometrics = [];
    testDbStore.athleteVerifications = [];
    testDbStore.refereeCertifications = [];
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.officialWeighins = [];
    testDbStore.brackets = [];
    testDbStore.matches = [];
    testDbStore.eloLedger = [];
    testDbStore.communityPosts = [];
    testDbStore.postLikes = [];
    testDbStore.postComments = [];
    testDbStore.follows = [];
    testDbStore.disputes = [];
    testDbStore.disputeEvidence = [];
    testDbStore.venuePartners = [];

    // Seed Referee & Directors & Admin
    testDbStore.users.push(
      {
        id: UUID_REFEREE,
        email: "referee.certified@armsphere.com",
        username: "referee_pro",
        role: UserRole.REFEREE,
        fullName: "Certified Referee",
        isActive: true,
      },
      {
        id: UUID_DIRECTOR_ONTARIO,
        email: "director.ontario@armsphere.com",
        username: "dir_ontario",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Ontario Director",
        province: "Ontario",
        regionalCoverage: "Ontario",
        isActive: true,
      },
      {
        id: UUID_DIRECTOR_QUEBEC,
        email: "director.quebec@armsphere.com",
        username: "dir_quebec",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Quebec Director",
        province: "Quebec",
        regionalCoverage: "Quebec",
        isActive: true,
      },
      {
        id: UUID_ADMIN,
        email: "admin@armsphere.com",
        username: "super_admin",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      }
    );

    // Seed Active Referee Certification
    testDbStore.refereeCertifications.push({
      id: "cert-ref-001",
      userId: UUID_REFEREE,
      certificationLevel: "PRO_LEVEL_1",
      issuedAt: new Date(),
      expiresAt: new Date(Date.now() + 86400000 * 365),
      status: "ACTIVE",
      issuingBody: "WAF_OFFICIAL",
    });

    // Seed Venue Partner for discovery
    testDbStore.venuePartners.push({
      id: "venue-001",
      name: "Toronto Arm Wrestling Club",
      city: "Toronto",
      province: "Ontario",
      address: "100 King St W, Toronto, ON",
      isVerified: true,
    });

    // Pre-generate auth tokens for privileged personas
    tokenReferee = `Bearer ${generateAccessToken(UUID_REFEREE, "referee.certified@armsphere.com", UserRole.REFEREE, env.JWT_ACCESS_SECRET)}`;
    tokenDirectorOntario = `Bearer ${generateAccessToken(UUID_DIRECTOR_ONTARIO, "director.ontario@armsphere.com", UserRole.PROVINCIAL_DIRECTOR, env.JWT_ACCESS_SECRET)}`;
    tokenDirectorQuebec = `Bearer ${generateAccessToken(UUID_DIRECTOR_QUEBEC, "director.quebec@armsphere.com", UserRole.PROVINCIAL_DIRECTOR, env.JWT_ACCESS_SECRET)}`;
    tokenAdmin = `Bearer ${generateAccessToken(UUID_ADMIN, "admin@armsphere.com", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET)}`;
  });

  it("executes the full end-to-end Master Spec user journey seamlessly", async () => {
    // =========================================================================
    // 1. AUTH & REGISTRATION JOURNEY
    // =========================================================================
    // Register Athlete 1
    const regRes1 = await request(app)
      .post("/auth/register")
      .send({
        email: "challenger@armsphere.com",
        username: "challenger_pro",
        password: "SecurePassword123!",
        fullName: "Challenger Pro",
      });
    expect(regRes1.status).toBe(201);
    expect(regRes1.body.success).toBe(true);
    expect(regRes1.body.data.email).toBe("challenger@armsphere.com");
    const athlete1Id = regRes1.body.data.id;

    // Register Athlete 2
    const regRes2 = await request(app)
      .post("/auth/register")
      .send({
        email: "opponent@armsphere.com",
        username: "opponent_pro",
        password: "SecurePassword123!",
        fullName: "Opponent Pro",
      });
    expect(regRes2.status).toBe(201);
    expect(regRes2.body.success).toBe(true);
    const athlete2Id = regRes2.body.data.id;

    // Login Athlete 1
    const loginRes1 = await request(app)
      .post("/auth/login")
      .send({
        email: "challenger@armsphere.com",
        password: "SecurePassword123!",
      });
    expect(loginRes1.status).toBe(200);
    expect(loginRes1.body.success).toBe(true);
    expect(loginRes1.body.data.accessToken).toBeDefined();
    expect(loginRes1.body.data.refreshToken).toBeDefined();
    tokenAthlete1 = `Bearer ${loginRes1.body.data.accessToken}`;
    const refreshToken1 = loginRes1.body.data.refreshToken;

    // Login Athlete 2
    const loginRes2 = await request(app)
      .post("/auth/login")
      .send({
        email: "opponent@armsphere.com",
        password: "SecurePassword123!",
      });
    expect(loginRes2.status).toBe(200);
    tokenAthlete2 = `Bearer ${loginRes2.body.data.accessToken}`;

    // Test Token Refresh for Athlete 1
    const refreshRes = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken: refreshToken1 });
    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body.success).toBe(true);
    expect(refreshRes.body.data.accessToken).toBeDefined();
    // Update tokenAthlete1 with refreshed access token
    tokenAthlete1 = `Bearer ${refreshRes.body.data.accessToken}`;

    // =========================================================================
    // 2. ONBOARDING JOURNEY
    // =========================================================================
    // Athlete 1 creates profile
    const profileRes1 = await request(app)
      .post("/athletes")
      .set("Authorization", tokenAthlete1)
      .send({
        displayName: "Challenger Pro",
        province: "Ontario",
        city: "Toronto",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "1995-05-15T00:00:00.000Z",
        gender: "MALE",
        weightClass: "80kg",
        height: 182,
        weight: 80,
      });
    expect(profileRes1.status).toBe(201);
    expect(profileRes1.body.success).toBe(true);
    const profile1Id = profileRes1.body.data.id;

    // Athlete 2 creates profile
    const profileRes2 = await request(app)
      .post("/athletes")
      .set("Authorization", tokenAthlete2)
      .send({
        displayName: "Opponent Pro",
        province: "Ontario",
        city: "Toronto",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "1996-08-20T00:00:00.000Z",
        gender: "MALE",
        weightClass: "80kg",
        height: 185,
        weight: 80,
      });
    expect(profileRes2.status).toBe(201);
    const profile2Id = profileRes2.body.data.id;

    // Athlete 1 submits biometrics
    const bioRes = await request(app)
      .post("/athletes/biometrics")
      .set("Authorization", tokenAthlete1)
      .send({
        armSpan: 188,
        forearmCircumference: 36,
        bicepCircumference: 42,
        handLength: 20,
        handWidth: 9.5,
      });
    expect(bioRes.status).toBe(200);
    expect(bioRes.body.success).toBe(true);

    // Athlete 1 submits verification document
    const verDocRes = await request(app)
      .post("/athletes/verification/document")
      .set("Authorization", tokenAthlete1)
      .send({
        documentType: "PASSPORT",
        fileKey: "verifications/challenger-id.pdf",
        bucketName: env.B2_BUCKET_COMPLIANCE_DOCS,
        sha256Hash: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      });
    expect(verDocRes.status).toBe(200);
    expect(verDocRes.body.success).toBe(true);

    // Provincial Director reviews & approves verification
    const reviewRes = await request(app)
      .post("/athletes/verification/review")
      .set("Authorization", tokenDirectorOntario)
      .send({
        athleteId: athlete1Id,
        status: "VERIFIED",
      });
    expect(reviewRes.status).toBe(200);
    expect(reviewRes.body.success).toBe(true);

    // =========================================================================
    // 3. HOME & ROLE RESOLUTION JOURNEY
    // =========================================================================
    // Athlete checks /athletes/me
    const meRes = await request(app)
      .get("/athletes/me")
      .set("Authorization", tokenAthlete1);
    expect(meRes.status).toBe(200);
    expect(meRes.body.data.displayName).toBe("Challenger Pro");
    expect(meRes.body.data.verificationStatus).toBe("VERIFIED");

    // Referee checks certifications
    const refCertRes = await request(app)
      .get(`/referees/${UUID_REFEREE}/certifications`)
      .set("Authorization", tokenReferee);
    expect(refCertRes.status).toBe(200);
    expect(refCertRes.body.data).toHaveLength(1);
    expect(refCertRes.body.data[0].status).toBe("ACTIVE");

    // Director checks provincial governance queue
    const govQueueRes = await request(app)
      .get("/governance/disputes")
      .set("Authorization", tokenDirectorOntario);
    expect(govQueueRes.status).toBe(200);

    // =========================================================================
    // 4. DISCOVERY SURFACE JOURNEY
    // =========================================================================
    // Search athlete directory
    const searchRes = await request(app)
      .get("/athletes/search?q=Challenger")
      .set("Authorization", tokenAthlete1);
    expect(searchRes.status).toBe(200);
    expect(searchRes.body.data.some((a: any) => a.displayName.includes("Challenger"))).toBe(true);

    // Query leaderboard rankings
    const leaderboardRes = await request(app)
      .get("/rankings/leaderboard?arm=RIGHT")
      .set("Authorization", tokenAthlete1);
    expect(leaderboardRes.status).toBe(200);
    expect(leaderboardRes.body.success).toBe(true);

    // Query venue partners directory
    const venuesRes = await request(app).get("/venues");
    expect(venuesRes.status).toBe(200);
    expect(venuesRes.body.data.length).toBeGreaterThanOrEqual(1);

    // =========================================================================
    // 5. TOURNAMENT EVENT LIFECYCLE & REGISTRATION JOURNEY
    // =========================================================================
    const now = new Date();
    const startDate = new Date(now.getTime() + 86400000 * 7); // 7 days ahead
    const endDate = new Date(now.getTime() + 86400000 * 8);
    const regStart = new Date(now.getTime() - 86400000 * 2);
    const regEnd = new Date(now.getTime() + 86400000 * 5);

    // Director creates tournament in Ontario
    const createEventRes = await request(app)
      .post("/tournaments/events")
      .set("Authorization", tokenDirectorOntario)
      .send({
        name: "Ontario Arm Wrestling Championship 2026",
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        registrationStart: regStart.toISOString(),
        registrationEnd: regEnd.toISOString(),
        province: "Ontario",
        city: "Toronto",
        venue: "Toronto Exhibition Center",
        capacity: 100,
        registrationFeeCents: 5000,
        paymentMethod: "MANUAL_QR",
      });
    expect(createEventRes.status).toBe(201);
    const eventId = createEventRes.body.id;

    // Director publishes tournament
    const publishEventRes = await request(app)
      .post(`/tournaments/events/${eventId}/publish`)
      .set("Authorization", tokenDirectorOntario);
    expect(publishEventRes.status).toBe(200);
    expect(publishEventRes.body.status).toBe("PUBLISHED");

    // Discovery check: event appears in listEvents
    const eventsListRes = await request(app)
      .get("/tournaments/events?timeframe=upcoming")
      .set("Authorization", tokenAthlete1);
    expect(eventsListRes.status).toBe(200);
    expect(eventsListRes.body.some((e: any) => e.id === eventId)).toBe(true);

    // Athlete 1 registers for tournament
    const reg1Res = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", tokenAthlete1)
      .send({
        eventId,
        athleteId: profile1Id,
        division: "SENIOR",
        weightClass: "80kg",
        arm: "RIGHT",
        notes: "Challenger Pro right arm entry",
      });
    expect(reg1Res.status).toBe(201);
    const reg1Id = reg1Res.body.id;

    // Athlete 2 registers for tournament
    const reg2Res = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", tokenAthlete2)
      .send({
        eventId,
        athleteId: profile2Id,
        division: "SENIOR",
        weightClass: "80kg",
        arm: "RIGHT",
        notes: "Opponent Pro right arm entry",
      });
    expect(reg2Res.status).toBe(201);
    const reg2Id = reg2Res.body.id;

    // Organizer / Director confirms registration payments
    const pay1Res = await request(app)
      .post(`/tournaments/registrations/${reg1Id}/confirm-manual-payment`)
      .set("Authorization", tokenDirectorOntario);
    expect(pay1Res.status).toBe(200);

    const pay2Res = await request(app)
      .post(`/tournaments/registrations/${reg2Id}/confirm-manual-payment`)
      .set("Authorization", tokenDirectorOntario);
    expect(pay2Res.status).toBe(200);

    // Organizer / Director approves registrations
    const approveReg1Res = await request(app)
      .post(`/tournaments/registrations/${reg1Id}/approve`)
      .set("Authorization", tokenDirectorOntario);
    expect(approveReg1Res.status).toBe(200);

    const approveReg2Res = await request(app)
      .post(`/tournaments/registrations/${reg2Id}/approve`)
      .set("Authorization", tokenDirectorOntario);
    expect(approveReg2Res.status).toBe(200);

    // =========================================================================
    // 6. COMPETITION, WEIGH-IN & MATCH FLOW JOURNEY
    // =========================================================================
    // Referee records official weigh-in for Athlete 1
    const weighIn1Res = await request(app)
      .post("/tournaments/weighins")
      .set("Authorization", tokenReferee)
      .send({
        registrationId: reg1Id,
        weight: 79.5,
      });
    expect(weighIn1Res.status).toBe(201);

    // Referee records official weigh-in for Athlete 2
    const weighIn2Res = await request(app)
      .post("/tournaments/weighins")
      .set("Authorization", tokenReferee)
      .send({
        registrationId: reg2Id,
        weight: 80.0,
      });
    expect(weighIn2Res.status).toBe(201);

    // Director creates bracket for SENIOR 80kg RIGHT
    const bracketRes = await request(app)
      .post("/tournaments/brackets")
      .set("Authorization", tokenDirectorOntario)
      .send({
        eventId,
        name: "Senior 80kg Right Arm Bracket",
        division: "SENIOR",
        weightClass: "80kg",
        arm: "RIGHT",
        format: "DOUBLE_ELIMINATION",
      });
    expect(bracketRes.status).toBe(201);

    // Referee submits peer-to-peer competitive match
    const submitMatchRes = await request(app)
      .post("/matches")
      .set("Authorization", tokenReferee)
      .send({
        challengerId: profile1Id,
        opponentId: profile2Id,
        arm: "RIGHT",
        winnerId: profile1Id,
        scoreLine: "3-1",
        evidenceUrl: "https://youtube.com/watch?v=mockMatchVideo",
      });
    expect(submitMatchRes.status).toBe(202);
    expect(submitMatchRes.body.status).toBe("PENDING_VERIFICATION");
    const matchId = submitMatchRes.body.matchId;

    // Referee verifies match -> triggers ELO rating update & ledger
    const verifyMatchRes = await request(app)
      .post(`/matches/${matchId}/verify`)
      .set("Authorization", tokenReferee);
    expect(verifyMatchRes.status).toBe(200);
    expect(verifyMatchRes.body.data.match.status).toBe("VERIFIED");

    // =========================================================================
    // 7. PROFILE & MATCH HISTORY JOURNEY
    // =========================================================================
    // Fetch profile of Challenger
    const getProfileRes = await request(app)
      .get(`/athletes/${profile1Id}`)
      .set("Authorization", tokenAthlete1);
    expect(getProfileRes.status).toBe(200);
    expect(getProfileRes.body.data.displayName).toBe("Challenger Pro");

    // Fetch verified matches for Challenger
    const athleteMatchesRes = await request(app)
      .get(`/athletes/${profile1Id}/matches`)
      .set("Authorization", tokenAthlete1);
    expect(athleteMatchesRes.status).toBe(200);
    expect(athleteMatchesRes.body.data.length).toBeGreaterThanOrEqual(1);
    expect(athleteMatchesRes.body.data[0].id).toBe(matchId);

    // =========================================================================
    // 8. COMMUNITY & SOCIAL JOURNEY
    // =========================================================================
    // Athlete 1 creates a community post
    const linkPostRes = await request(app)
      .post("/community/links")
      .set("Authorization", tokenAthlete1)
      .send({
        externalUrl: "https://youtube.com/watch?v=greatPullingTechnique",
        caption: "Top-Roll Mechanics Masterclass",
        category: "TUTORIALS",
      });
    expect(linkPostRes.status).toBe(201);
    const postId = linkPostRes.body.data.id;

    // Athlete 2 likes the post
    const likeRes = await request(app)
      .post(`/community/posts/${postId}/like`)
      .set("Authorization", tokenAthlete2);
    expect(likeRes.status).toBe(201);

    // Athlete 2 comments on the post
    const commentRes = await request(app)
      .post(`/community/posts/${postId}/comments`)
      .set("Authorization", tokenAthlete2)
      .send({
        body: "Outstanding pronation technique breakdown!",
      });
    expect(commentRes.status).toBe(201);

    // Athlete 2 follows Athlete 1
    const followRes = await request(app)
      .post("/social/follow")
      .set("Authorization", tokenAthlete2)
      .send({
        followingId: profile1Id,
      });
    expect(followRes.status).toBe(201);

    // =========================================================================
    // 9. GOVERNANCE, DISPUTES & JURISDICTION JOURNEY
    // =========================================================================
    // Athlete 2 files a dispute on the match
    const disputeRes = await request(app)
      .post("/governance/disputes")
      .set("Authorization", tokenAthlete2)
      .send({
        matchId,
        title: "Disputed Elbow Foul in Round 3",
        description: "Competitor elbow clearly left the rear pad prior to the pin signal.",
      });
    expect(disputeRes.status).toBe(201);
    const disputeId = disputeRes.body.dispute.id;
    // Set dispute jurisdiction to Ontario to test cross-province boundary enforcement
    const disputeRow = testDbStore.disputes.find((d: any) => d.id === disputeId);
    if (disputeRow) {
      disputeRow.province = "Ontario";
    }

    // Athlete 2 submits video evidence
    const evidenceRes = await request(app)
      .post(`/governance/disputes/${disputeId}/evidence`)
      .set("Authorization", tokenAthlete2)
      .send({
        fileType: "VIDEO",
        fileUrl: "https://storage.armsphere.com/evidence/round3_elbow.mp4",
      });
    expect(evidenceRes.status).toBe(201);

    // Cross-province director (Quebec) tries to resolve Ontario dispute -> 403 Forbidden!
    const crossProvRes = await request(app)
      .post(`/governance/disputes/${disputeId}/resolve`)
      .set("Authorization", tokenDirectorQuebec)
      .send({
        resolutionDetails: "Unauthorized cross-province resolution attempt",
        decision: "REJECTED",
      });
    expect(crossProvRes.status).toBe(403);

    // In-jurisdiction Provincial Director (Ontario) resolves dispute
    const resolveRes = await request(app)
      .post(`/governance/disputes/${disputeId}/resolve`)
      .set("Authorization", tokenDirectorOntario)
      .send({
        resolutionDetails: "Referee decision stands after slow-motion video review; elbow remained in contact with pad.",
        decision: "RESOLVED",
      });
    expect(resolveRes.status).toBe(200);
    expect(resolveRes.body.success).toBe(true);
    expect(resolveRes.body.dispute.status).toBe("RESOLVED");
  });
});
