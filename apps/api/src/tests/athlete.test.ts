import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Athlete Profiles, Verification & Storage API Suite", () => {
  let athleteUser: any;
  let athleteToken: string;
  let adminUser: any;
  let adminToken: string;
  let refereeUser: any;
  let refereeToken: string;

  // Use valid UUIDs to satisfy Zod .uuid() rules
  const athleteUserId = "11111111-1111-1111-1111-111111111111";
  const adminUserId = "55555555-5555-5555-5555-555555555555";
  const refereeUserId = "99999999-9999-9999-9999-999999999999";
  const clubId = "88888888-8888-8888-8888-888888888888";

  beforeEach(async () => {
    // Clean and pre-populate the mock store before each test for absolute state isolation
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

    // Seed users
    athleteUser = {
      id: athleteUserId,
      email: "athlete@armsphere.com",
      username: "athlete123",
      role: UserRole.ATHLETE,
      fullName: "John Athlete Doe",
      isActive: true,
    };
    testDbStore.users.push(athleteUser);
    athleteToken = `Bearer ${generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    adminUser = {
      id: adminUserId,
      email: "admin@armsphere.com",
      username: "admin555",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "Super Administrator",
      isActive: true,
    };
    testDbStore.users.push(adminUser);
    adminToken = `Bearer ${generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    refereeUser = {
      id: refereeUserId,
      email: "referee@armsphere.com",
      username: "referee999",
      role: UserRole.REFEREE,
      fullName: "Referee Joe",
      isActive: true,
    };
    testDbStore.users.push(refereeUser);
    refereeToken = `Bearer ${generateAccessToken(
      refereeUser.id,
      refereeUser.email,
      refereeUser.role,
      env.JWT_ACCESS_SECRET
    )}`;
  });

  describe("POST /athletes - Profile Creation", () => {
    it("should allow an authenticated user to create their own athlete profile", async () => {
      const payload = {
        displayName: "Johnny Doe",
        biography: "The champion in the making.",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "2000-01-01T00:00:00.000Z",
        gender: "MALE",
        weightClass: "80kg",
        height: 185,
        weight: 80,
        reach: 190,
      };

      const res = await request(app)
        .post("/athletes")
        .set("Authorization", athleteToken)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.userId).toBe(athleteUser.id);
      expect(res.body.data.displayName).toBe("Johnny Doe");
    });

    it("should return a 400 Bad Request on invalid payload structure", async () => {
      const payload = {
        displayName: "", // Invalid
        province: "Punjab",
      };

      const res = await request(app)
        .post("/athletes")
        .set("Authorization", athleteToken)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("should refuse duplicate profile creation for the same user", async () => {
      // Pre-seed an existing profile
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });

      const payload = {
        displayName: "Johnny Doe II",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "2000-01-01T00:00:00.000Z",
        gender: "MALE",
        weightClass: "80kg",
      };

      const res = await request(app)
        .post("/athletes")
        .set("Authorization", athleteToken)
        .send(payload);

      expect(res.status).toBe(409); // Conflict
    });
  });

  describe("GET /athletes/me - Self Profile Retrieval", () => {
    it("should retrieve the complete aggregated profile details of the logged in user", async () => {
      // Pre-seed profile
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });

      const res = await request(app)
        .get("/athletes/me")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.userId).toBe(athleteUser.id);
      expect(res.body.data.verificationStatus).toBe("UNVERIFIED");
      expect(res.body.data.biometrics).toBeNull();
    });

    it("should convert a stored private-bucket avatar fileKey into a presigned download URL, never exposing the raw key", async () => {
      const rawFileKey = "avatars/a1e0bc7e-42cf-444b-9e29-2bcfa5a4d911.jpg";
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
        profilePhoto: rawFileKey,
      });

      const res = await request(app)
        .get("/athletes/me")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.data.profilePhoto).toBe(
        `http://localhost:9000/mock-download-url/${env.B2_BUCKET_ATHLETE_AVATARS}/${rawFileKey}`
      );
      // The raw private-bucket key itself must never leak to the client
      expect(res.body.data.profilePhoto).not.toBe(rawFileKey);
    });
  });

  describe("GET /athletes/:id - Individual Profile Retrieval", () => {
    it("should retrieve the athlete profile by its associated User ID", async () => {
      // Pre-seed profile
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });

      const res = await request(app)
        .get(`/athletes/${athleteUser.id}`)
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.displayName).toBe("Johnny Doe");
    });

    it("should return a 404 NotFound if profile does not exist", async () => {
      const res = await request(app)
        .get("/athletes/22222222-2222-2222-2222-222222222222") // non-existent UUID
        .set("Authorization", athleteToken);

      expect(res.status).toBe(404);
    });

    it("should also convert profilePhoto to a presigned download URL when viewing another user's profile", async () => {
      const rawFileKey = "avatars/other-user-photo.png";
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
        profilePhoto: rawFileKey,
      });

      const res = await request(app)
        .get(`/athletes/${athleteUser.id}`)
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.data.profilePhoto).toBe(
        `http://localhost:9000/mock-download-url/${env.B2_BUCKET_ATHLETE_AVATARS}/${rawFileKey}`
      );
    });
  });

  describe("PATCH /athletes/:id - Profile Editing", () => {
    beforeEach(() => {
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });
    });

    it("should allow the profile owner to update their own profile", async () => {
      const res = await request(app)
        .patch(`/athletes/${athleteUser.id}`)
        .set("Authorization", athleteToken)
        .send({
          displayName: "Johnny Doe Updated",
          weightClass: "85kg",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.displayName).toBe("Johnny Doe Updated");
    });

    it("should allow an Administrator to update an athlete's profile", async () => {
      const res = await request(app)
        .patch(`/athletes/${athleteUser.id}`)
        .set("Authorization", adminToken)
        .send({
          displayName: "Johnny Doe AdminOverrode",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.displayName).toBe("Johnny Doe AdminOverrode");
    });

    it("should refuse profile updates from unauthorized third parties", async () => {
      const res = await request(app)
        .patch(`/athletes/${athleteUser.id}`)
        .set("Authorization", refereeToken)
        .send({
          displayName: "Referee Hacked Me",
        });

      expect(res.status).toBe(403);
    });
  });

  describe("GET /athletes/search - Search & Filters", () => {
    it("should filter and retrieve active athletes dynamically", async () => {
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });

      const res = await request(app)
        .get("/athletes/search?displayName=Johnny")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.data.length).toBeGreaterThan(0);
    });
  });

  describe("POST /athletes/upload - Secure Direct File Uploads", () => {
    it("should strip EXIF and upload base64 images securely", async () => {
      const base64Jpeg = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00]).toString("base64");

      const res = await request(app)
        .post("/athletes/upload")
        .set("Authorization", athleteToken)
        .send({
          fileType: "AVATAR",
          fileName: "photo.jpg",
          mimeType: "image/jpeg",
          base64Data: base64Jpeg,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.fileKey).toContain("avatars/");
      expect(res.body.data.sha256Hash).toHaveLength(64);
    });

    it("should reject direct uploads exceeding size thresholds", async () => {
      const largeBuffer = Buffer.alloc(3 * 1024 * 1024);
      const res = await request(app)
        .post("/athletes/upload")
        .set("Authorization", athleteToken)
        .send({
          fileType: "AVATAR",
          fileName: "giant.jpg",
          mimeType: "image/jpeg",
          base64Data: largeBuffer.toString("base64"),
        });

      expect(res.status).toBe(400);
    });

    it("should reject restricted MIME types", async () => {
      const base64Txt = Buffer.from("arbitrary-text").toString("base64");
      const res = await request(app)
        .post("/athletes/upload")
        .set("Authorization", athleteToken)
        .send({
          fileType: "AVATAR",
          fileName: "malicious.sh",
          mimeType: "text/plain",
          base64Data: base64Txt,
        });

      expect(res.status).toBe(400);
    });
  });

  describe("POST /athletes/presigned - Presigned URL Orchestration", () => {
    it("should generate a presigned POST policy for client-direct uploads", async () => {
      const res = await request(app)
        .post("/athletes/presigned")
        .set("Authorization", athleteToken)
        .send({
          fileType: "DOCUMENT",
          fileName: "national_id.pdf",
          mimeType: "application/pdf",
          size: 5 * 1024 * 1024,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.postURL).toBeDefined();
      expect(res.body.data.formData).toBeDefined();
      expect(res.body.data.fileKey).toContain("documents/");
    });

    it("should enforce server-side size limit on the generated post policy, ensuring storage rejects files exceeding rules.maxSize", async () => {
      const res = await request(app)
        .post("/athletes/presigned")
        .set("Authorization", athleteToken)
        .send({
          fileType: "DOCUMENT",
          fileName: "large_id.pdf",
          mimeType: "application/pdf",
          size: 5 * 1024 * 1024, // Declared size within limit
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      const { formData } = res.body.data;
      expect(formData.conditions).toBeDefined();

      const conditions = JSON.parse(formData.conditions);
      const contentLengthCondition = conditions.find(
        (c: any) => Array.isArray(c) && c[0] === "content-length-range"
      );

      expect(contentLengthCondition).toBeDefined();
      const [, minSize, maxSize] = contentLengthCondition;
      expect(maxSize).toBe(10 * 1024 * 1024); // Server-side maxSize for DOCUMENT (10MB)

      // Simulate the storage provider rejecting an upload larger than the policy's maxSize
      const attemptUploadSize = 15 * 1024 * 1024; // 15MB file
      const storageRejects = attemptUploadSize > maxSize;
      expect(storageRejects).toBe(true);
    });
  });

  describe("Verification Engine (Submit & Review)", () => {
    beforeEach(() => {
      testDbStore.athleteProfiles.push({
        id: "profile-1",
        userId: athleteUserId,
        displayName: "Johnny Doe",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
      });
    });

    it("should allow an athlete to submit a document, transitioning status to PENDING", async () => {
      const res = await request(app)
        .post("/athletes/verification/document")
        .set("Authorization", athleteToken)
        .send({
          documentType: "CNIC",
          fileKey: "documents/fake-cnic-key.pdf",
          bucketName: "compliance-docs",
          sha256Hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe("PENDING");

      const profileRes = await request(app)
        .get("/athletes/me")
        .set("Authorization", athleteToken);
      expect(profileRes.body.data.verificationStatus).toBe("PENDING");
    });

    it("should allow a federation administrator to approve verification status", async () => {
      const res = await request(app)
        .post("/athletes/verification/review")
        .set("Authorization", adminToken)
        .send({
          athleteId: athleteUser.id,
          status: "VERIFIED",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe("VERIFIED");

      const profileRes = await request(app)
        .get("/athletes/me")
        .set("Authorization", athleteToken);
      expect(profileRes.body.data.verificationStatus).toBe("VERIFIED");
    });

    it("should prevent non-admin/non-reviewers from reviewing documents", async () => {
      const res = await request(app)
        .post("/athletes/verification/review")
        .set("Authorization", athleteToken)
        .send({
          athleteId: athleteUser.id,
          status: "VERIFIED",
        });

      expect(res.status).toBe(403);
    });

    it("should result in a PENDING verification status and two athleteDocuments rows with correct fileKeys upon onboarding submission of both CNIC and SELFIE", async () => {
      // 1. Submit CNIC document
      const resCnic = await request(app)
        .post("/athletes/verification/document")
        .set("Authorization", athleteToken)
        .send({
          documentType: "CNIC",
          fileKey: "documents/cnic.jpg",
          bucketName: "compliance-docs",
          sha256Hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        });

      expect(resCnic.status).toBe(200);
      expect(resCnic.body.success).toBe(true);

      // 2. Submit SELFIE document
      const resSelfie = await request(app)
        .post("/athletes/verification/document")
        .set("Authorization", athleteToken)
        .send({
          documentType: "SELFIE",
          fileKey: "documents/selfie.jpg",
          bucketName: "compliance-docs",
          sha256Hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        });

      expect(resSelfie.status).toBe(200);
      expect(resSelfie.body.success).toBe(true);

      // 3. Confirm status transitions to PENDING
      expect(resSelfie.body.data.status).toBe("PENDING");

      // Verify profile retrieval shows PENDING
      const profileRes = await request(app)
        .get("/athletes/me")
        .set("Authorization", athleteToken);
      expect(profileRes.body.data.verificationStatus).toBe("PENDING");

      // 4. Confirm in the DB store that exactly two document records exist
      const docs = testDbStore.athleteDocuments.filter(d => d.athleteId === athleteUserId);
      expect(docs.length).toBe(2);

      const cnicDoc = docs.find(d => d.documentType === "CNIC");
      const selfieDoc = docs.find(d => d.documentType === "SELFIE");

      expect(cnicDoc).toBeDefined();
      expect(cnicDoc?.fileKey).toBe("documents/cnic.jpg");

      expect(selfieDoc).toBeDefined();
      expect(selfieDoc?.fileKey).toBe("documents/selfie.jpg");
    });
  });

  describe("POST /athletes/biometrics - Biometric foundation", () => {
    it("should update and return user biometric specifications", async () => {
      const res = await request(app)
        .post("/athletes/biometrics")
        .set("Authorization", athleteToken)
        .send({
          handLength: 20.5,
          handWidth: 9.2,
          palmLength: 11.1,
          armSpan: 188,
          forearmCircumference: 31,
          bicepCircumference: 38.5,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.handLength).toBe(20.5);
      expect(res.body.data.armSpan).toBe(188);
    });
  });

  describe("Club Affiliations", () => {
    it("should allow administrators to register new clubs", async () => {
      const res = await request(app)
        .post("/athletes/clubs")
        .set("Authorization", adminToken)
        .send({
          name: "Lahore Armwrestling Club",
          city: "Lahore",
          province: "Punjab",
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe("Lahore Armwrestling Club");
    });

    it("should list registered clubs for athletes", async () => {
      // Seed a club record
      testDbStore.athleteClubs.push({
        id: clubId,
        name: "Lahore Armwrestling Club",
        city: "Lahore",
        province: "Punjab",
      });

      const res = await request(app)
        .get("/athletes/clubs")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.data.length).toBeGreaterThan(0);
    });
  });

  describe("Athlete Visibility & Searchability Preferences", () => {
    const anotherAthleteUserId = "22222222-2222-2222-2222-222222222222";
    const thirdAthleteUserId = "33333333-3333-3333-3333-333333333333";
    let anotherAthleteToken: string;
    let thirdAthleteToken: string;

    beforeEach(() => {
      // Seed another athlete user in same club
      const anotherUser = {
        id: anotherAthleteUserId,
        email: "another@armsphere.com",
        username: "another_athlete",
        role: UserRole.ATHLETE,
        fullName: "Jane Same Club Doe",
        isActive: true,
      };
      testDbStore.users.push(anotherUser);
      anotherAthleteToken = `Bearer ${generateAccessToken(
        anotherUser.id,
        anotherUser.email,
        anotherUser.role,
        env.JWT_ACCESS_SECRET
      )}`;

      // Seed third athlete user in different club / no club
      const thirdUser = {
        id: thirdAthleteUserId,
        email: "third@armsphere.com",
        username: "third_athlete",
        role: UserRole.ATHLETE,
        fullName: "Jim Diff Club Doe",
        isActive: true,
      };
      testDbStore.users.push(thirdUser);
      thirdAthleteToken = `Bearer ${generateAccessToken(
        thirdUser.id,
        thirdUser.email,
        thirdUser.role,
        env.JWT_ACCESS_SECRET
      )}`;
    });

    it("should allow updating profileVisibility and isSearchable preferences", async () => {
      // Seed a profile
      testDbStore.athleteProfiles.push({
        id: "profile-owner",
        userId: athleteUserId,
        displayName: "John Owner",
        province: "Punjab",
        city: "Lahore",
        clubId: clubId,
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        profileVisibility: "PUBLIC",
        isSearchable: true,
        isDeleted: false,
      });

      const res = await request(app)
        .patch("/athletes/me/visibility")
        .set("Authorization", athleteToken)
        .send({
          profileVisibility: "GYM_ONLY",
          isSearchable: false,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profileVisibility).toBe("GYM_ONLY");
      expect(res.body.data.isSearchable).toBe(false);

      // Verify it's updated in store
      const updated = testDbStore.athleteProfiles.find(ap => ap.userId === athleteUserId);
      expect(updated?.profileVisibility).toBe("GYM_ONLY");
      expect(updated?.isSearchable).toBe(false);
    });

    it("should allow same-club viewer and owner to view GYM_ONLY profile, and block other viewers", async () => {
      // 1. Seed owner profile (GYM_ONLY, clubId)
      testDbStore.athleteProfiles.push({
        id: "profile-owner",
        userId: athleteUserId,
        displayName: "John Owner",
        province: "Punjab",
        city: "Lahore",
        clubId: clubId,
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        profileVisibility: "GYM_ONLY",
        isSearchable: true,
        isDeleted: false,
      });

      // 2. Seed same-club viewer profile
      testDbStore.athleteProfiles.push({
        id: "profile-same-club",
        userId: anotherAthleteUserId,
        displayName: "Jane Same Club",
        province: "Punjab",
        city: "Lahore",
        clubId: clubId,
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "FEMALE",
        weightClass: "60kg",
        profileVisibility: "PUBLIC",
        isSearchable: true,
        isDeleted: false,
      });

      // 3. Seed different-club viewer profile (clubId-diff or undefined)
      testDbStore.athleteProfiles.push({
        id: "profile-diff-club",
        userId: thirdAthleteUserId,
        displayName: "Jim Diff Club",
        province: "Punjab",
        city: "Lahore",
        clubId: "99999999-9999-9999-9999-999999999999",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        profileVisibility: "PUBLIC",
        isSearchable: true,
        isDeleted: false,
      });

      // Owner can view own profile
      const resOwner = await request(app)
        .get(`/athletes/${athleteUserId}`)
        .set("Authorization", athleteToken);
      expect(resOwner.status).toBe(200);

      // Same-club viewer can view
      const resSameClub = await request(app)
        .get(`/athletes/${athleteUserId}`)
        .set("Authorization", anotherAthleteToken);
      expect(resSameClub.status).toBe(200);

      // Different-club viewer is forbidden
      const resDiffClub = await request(app)
        .get(`/athletes/${athleteUserId}`)
        .set("Authorization", thirdAthleteToken);
      expect(resDiffClub.status).toBe(403);
    });

    it("should hide non-searchable profile from search results for others, but still appear for owner and remain directly viewable", async () => {
      // 1. Seed non-searchable profile
      testDbStore.athleteProfiles.push({
        id: "profile-owner",
        userId: athleteUserId,
        displayName: "HiddenJohn",
        province: "Punjab",
        city: "Lahore",
        clubId: clubId,
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        profileVisibility: "PUBLIC",
        isSearchable: false,
        isDeleted: false,
      });

      // 2. Seed viewer profile
      testDbStore.athleteProfiles.push({
        id: "profile-viewer",
        userId: anotherAthleteUserId,
        displayName: "Jane Viewer",
        province: "Punjab",
        city: "Lahore",
        clubId: clubId,
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("2000-01-01"),
        gender: "FEMALE",
        weightClass: "60kg",
        profileVisibility: "PUBLIC",
        isSearchable: true,
        isDeleted: false,
      });

      // Direct view is still fully accessible to viewer
      const resDirect = await request(app)
        .get(`/athletes/${athleteUserId}`)
        .set("Authorization", anotherAthleteToken);
      expect(resDirect.status).toBe(200);

      // Search from another viewer: HiddenJohn should NOT appear
      const resSearchOther = await request(app)
        .get("/athletes/search?displayName=HiddenJohn")
        .set("Authorization", anotherAthleteToken);
      expect(resSearchOther.status).toBe(200);
      expect(resSearchOther.body.data.some((a: any) => a.displayName === "HiddenJohn")).toBe(false);

      // Search from owner: HiddenJohn SHOULD appear
      const resSearchOwner = await request(app)
        .get("/athletes/search?displayName=HiddenJohn")
        .set("Authorization", athleteToken);
      expect(resSearchOwner.status).toBe(200);
      expect(resSearchOwner.body.data.some((a: any) => a.displayName === "HiddenJohn")).toBe(true);
    });
  });
});
