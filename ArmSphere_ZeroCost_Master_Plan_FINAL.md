ArmSphere — Zero-Cost Architecture & V1 Completion Master Plan (Updated)
Status: Living reference document. This update reflects a full, evidence-based pass over the zip uploaded most recently — every claim below was checked by actually running the build, the real test suite, and reading the actual source, not inferred.

Overall verdict up front, since you asked directly: genuinely good news on the whole. The backend is in the best state it's been in this entire project — clean build, full test suite passing, migration chain sound. There is exactly one serious, previously-unknown defect (below, Section 1), and it's narrow and well-understood, not a systemic problem. Everything else is either done, cosmetic, or a known/flagged open item.

---

## Part-by-Part Rating

### Backend API (`apps/api`) — 9/10
All 6 workspaces (`types`, `core`, `cryptography`, `db-schema`, `api`, `admin-web`) build with zero errors, verified by actually running `npm run build`. Full test suite: **24/24 test files, 307/307 tests pass**, verified by actually running `npm --prefix apps/api run test`, not inferred from a prior state. Migration chain verified sound via `npm run db:check`. All prior audit fixes (real idempotency-key column, real admin dashboard data, `assignRefereeRegion` actually persisting, `matches.updatedAt` tracking) are present and intact in this zip.
The one point off: a real, newly-found bug in double-elimination bracket generation — see Section 1. Nothing else pulled this rating down; it would otherwise be a 10.

### Database Schema & Migrations — 9/10
57+ tables, 15 clean sequential migrations (0000–0014), all previously-identified gaps (missing `updated_at` on matches, missing idempotency column, missing `regional_coverage`, the `sync_tombstones` table) are present and correct. `drizzle-kit check:pg` reports the chain fully sound. Docked one point only because the double-elimination bug (Section 1) is fundamentally a schema-vs-code mismatch (a `uuid` column being fed non-UUID strings) — the schema itself is fine, but it's the site where the bug actually breaks.

### Admin Web (`apps/admin-web`) — 7/10
Builds clean (Vite production build succeeds). 9 pages present: Dashboard, Athletes, Championships, Analytics, Governance, Nominations, Venues, Moderation Queue, Login. Solid coverage of the Federation/Admin role. Not docked for anything broken — docked for what's *not yet there*: no dedicated Referee management page (referee data is admin-API-accessible but not yet its own screen), and the actual Netlify deployment click-through is still outstanding (code-ready, not yet live) per earlier work in this project.

### Mobile App (`apps/mobile`) — 7/10
Structurally complete this time — `pubspec.yaml`, `main.dart`, and all 15 feature areas (athlete, auth, championship, community, governance, informal_event, messaging, nomination, notifications, referee, search, session, settings, team, tournament, venue) are present, 39 screen files. That's a real, broad app, not a skeleton. Flutter Analyze currently fails on exactly 2 missing-import bugs (`dioClientProvider` in `referee_provider.dart`, `liveMatchesProvider` in `referee_screens.dart`) — both trivial, both already diagnosed with exact fixes in the prior message. The remaining 124 analyzer issues are info/warnings (deprecated `withOpacity`, unused imports, `const` suggestions) that don't fail CI and are cosmetic debt, not defects. Docked for the 2 real errors plus the fact I still can't verify this myself (no Flutter toolchain available to me) — it needs a real `flutter analyze` run after the 2-line fix to confirm clean.

### Infrastructure & Deployment — 8/10
Netlify config (`netlify.toml`, `netlify/functions/api.ts`, `netlify/functions/scheduled-runner.ts`) present and consistent with the live, verified production deployment described earlier in this project (armsphere2.netlify.app). Zero-cost constraint honored throughout — no card-requiring services introduced anywhere I checked. Not a 10 because admin-web's actual deploy hasn't happened yet, and CostGuard remains correctly deferred (by design, not a gap).

### Test & CI Discipline — 9/10
This is the project's strongest area. 307 real tests, testing actual HTTP paths end-to-end (not just unit-isolated logic), including edge cases like idempotency replay, cross-user data isolation, and bracket-reset scenarios. The one blind spot, which is structural rather than sloppy: the in-memory test mock doesn't enforce Postgres column types, so it couldn't catch Section 1's bug — a real database would have rejected it immediately. That's a known, common limitation of mock-based testing, not a discipline failure, but worth naming.

---

## 1. NEW — Real, Verified Bug: Double-Elimination Bracket Generation Will Crash Against the Real Database

**Not fixed. Found this pass, evidence below — not guessing.**

`apps/api/src/services/tournament.ts`'s `DOUBLE_ELIMINATION` branch generates match IDs as deterministic strings: `` `wb-${bracketId}-${r}-${idx+1}` ``, `` `lb-${bracketId}-${j}-${idx+1}` ``, `` `gf-${bracketId}-1-1` ``.

These get inserted into `tournamentMatches.id`, which is declared in the schema as:
```ts
id: uuid("id").primaryKey().defaultRandom(),
```
— a genuine Postgres `uuid`-typed column. A real Postgres/Neon database will reject a non-UUID string like `"wb-de-bracket-prog-1-1"` with `invalid input syntax for type uuid`, the moment anyone actually generates a double-elimination bracket in production.

**Why the test suite doesn't catch it:** the test suite's database mock is a plain in-memory JavaScript array — it has no concept of Postgres column types, so it happily stores any string as an "id." All double-elimination tests pass (verified — I ran them), but that passing result doesn't mean what it looks like it means for this specific defect. This is exactly the kind of gap that only shows up against a real database, which is why "all tests green" isn't the same claim as "this works in production."

**What confirms this is real, not theoretical:** the corresponding validation schema (`submitResultSchema` in `controllers/tournament.ts`) was recently changed from `matchId: z.string().uuid()` to `matchId: z.string()` — i.e., the UUID requirement was relaxed at the API boundary specifically so these non-UUID generated IDs would be *accepted by the request validator*. That fixes the symptom of one earlier bug (matches couldn't be submitted at all) while leaving the deeper one (the database will reject the insert in the first place) untouched.

**The fix, for whoever applies it (AI Studio or otherwise):** generate real UUIDs for every match ID in the double-elimination branch (`wb-`/`lb-`/`gf-` prefixed matches), e.g. via `crypto.randomUUID()`, and route all the `nextMatchId`/`losersNextMatchId` cross-references through the actual generated UUIDs instead of the predictable string pattern. This is a well-contained fix — the bracket-generation *logic* (round structure, minor/major LB alternation, WB-to-LB routing, Grand Final wiring) all appears structurally sound; only the ID scheme itself needs to change. After that, the `matchId: z.string()` validation relaxation can stay as-is (harmless) or be tightened back to `.uuid()` once IDs are real UUIDs again (recommended, for the same input-validation-integrity reasons the rest of the API uses it elsewhere).

**Severity:** this only manifests when a real double-elimination bracket is generated against a real database — single-elimination and round-robin formats are unaffected (they don't share this code path issue), and nothing currently in production traffic would hit this until the feature is actually used. Not an emergency, but a real, confirmed landmine sitting in a shipped code path.

---

## 2. Carried-Forward Open Items (Unchanged Since Last Review)

- **Admin-web deployment**: code-ready, not yet clicked-through live. Requires Netlify dashboard access this analysis environment doesn't have.
- **`/sync/queue` mechanism**: the older, currently-dead (unreachable by the real mobile client) offline-sync path — still an open architectural call: wire it up for defense-in-depth, or remove it in favor of the generic-replay approach the app actually uses.
- **CostGuard**: correctly still deferred — no real usage pressure yet (last known Neon usage was a small fraction of any real limit).
- **Referee performance `accuracyRate`/`disputeRate`**: honestly `null` (not fabricated) pending real dispute-to-referee attribution logic, which doesn't exist yet.
- **Mobile local-first caching**: built on Hive (not Drift/SQLite as originally planned) due to lack of Flutter toolchain access for verification — still needs a real `flutter analyze` pass to confirm.

## 3. What Changed Since the Last Review (Good News Recap)

- Full monorepo build: 0 errors (was previously blocked entirely by a schema/package mismatch).
- Full backend test suite: 307/307 passing (was blocked entirely).
- Migration chain: verified sound.
- All previously-flagged audit fixes (idempotency, admin dashboard fake data, region persistence) confirmed present and correct in this exact zip.
- Mobile app structurally whole again (was previously missing `pubspec.yaml`/`main.dart`/entire feature directories in an earlier upload) — now down to 2 trivial missing-import errors.

---

**Bottom line for how you're feeling about this**: you're right to feel good about it. The foundational, hardest-to-get-right layer — the backend, its data model, and its test coverage — is genuinely solid and verified, not just claimed. What's left is a short, well-defined list: one real backend bug with a clear fix, two one-line mobile import fixes, and the already-known deployment/architecture decisions that were always going to need a deliberate choice rather than an automatic one.

---

# ZERO-COST BINDING IMPLEMENTATION CONTRACT

## 1. Core rule

ArmSphere's initial production infrastructure target is **$0/month**. The AI builder must not silently introduce paid infrastructure, paid APIs, paid databases, paid storage, paid email, paid monitoring, or credit-card-required services.

A paid dependency may only be introduced after:
1. proving the free architecture cannot meet a real measured requirement;
2. documenting the exact limitation;
3. proposing free alternatives;
4. receiving explicit owner approval.

## 2. Target architecture

```text
Flutter mobile
   |
   +--> Supabase Auth (identity, sessions, JWT, password reset, MFA)
   |
   v
ArmSphere API (business rules + authorization)
   |
   +--> PostgreSQL (ArmSphere domain data)
   |
   +--> Backblaze B2 (large files/media)
   |
   +--> payment provider only when an actual payment is made

Netlify = admin/public web + serverless API entrypoint
GitHub = source + CI
Brevo Free OR Resend Free = transactional auth email
```

Do not turn ArmSphere into a generic Supabase application. The ArmSphere API remains authoritative for roles, ownership, ELO, tournaments, matches, referees, governance, disputes, payments, and other business rules.

## 3. Supabase Auth

Use Supabase Auth for:
- signup/login;
- password authentication;
- email verification;
- password reset;
- OAuth only when explicitly needed;
- session restoration;
- access/refresh token lifecycle;
- TOTP MFA where appropriate.

The stable Supabase Auth user UUID becomes the identity reference for the ArmSphere user.

The client may never grant itself a privileged role.

Selecting "Referee", "Organizer", "Governance", etc. during onboarding means **intent/application**, not automatic permission.

Example:

```text
Register
  -> authenticated Supabase session
  -> ArmSphere API validates JWT
  -> create/link ArmSphere user
  -> choose journey
  -> normal athlete onboarding OR privileged-role application
  -> server-side verification
  -> privileged permission only after approval
```

The existing registration defect where onboarding can receive `401` because no authenticated session is established must be eliminated.

## 4. Supabase free-tier constraints

Design around the currently documented Free limits:
- 50,000 monthly active users;
- 500 MB database quota per project;
- 1 GB file storage;
- 5 GB egress;
- 500,000 Edge Function invocations;
- 2 million Realtime messages;
- 200 peak Realtime connections.

The 500 MB database quota is a hard design consideration. Use indexes, pagination, bounded queries, aggregation, retention, and object storage for large files.

Do not claim these limits are unlimited capacity.

## 5. Production email

Do not depend on Supabase's built-in email sender for public production. It is currently limited to 2 emails/hour and is best-effort.

Configure one free transactional provider:
- **Brevo Free:** 300 emails/day; or
- **Resend Free:** 3,000 emails/month and 100/day.

Use it for:
- verification;
- password reset;
- important security/account email.

Do not add both unless explicitly requested.

## 6. Backblaze B2

Use B2 for large objects:
- profile images;
- event images;
- certificates/documents;
- thumbnails;
- media;
- exports.

Never place B2 secrets in Flutter.

Prefer private buckets and API-authorized access for protected material.

Design around the free allowance:
- first 10 GB storage free;
- 1 GB/day free download bandwidth;
- 2,500 Class B transactions/day free;
- 2,500 Class C transactions/day free.

Compress and resize uploads, generate thumbnails, paginate media feeds, and avoid turning ArmSphere into an unlimited video-hosting service.

## 7. Netlify

Keep Netlify as the zero-cost deployment layer for the admin/public web and serverless API entrypoint already present in the repository.

Do not put secrets in frontend source.

Use production environment variables for:
- database credentials;
- B2 credentials;
- Supabase service credentials;
- SMTP credentials;
- payment secrets.

Do not leave production in development mode.

## 8. GitHub

GitHub remains the source of truth.

CI should verify:
- TypeScript build;
- backend tests;
- Flutter analyze;
- Flutter tests;
- migration/schema checks;
- production build;
- secret scanning.

Never commit `.env.production`, database passwords, B2 keys, Supabase service-role keys, SMTP passwords, payment secrets, or signing secrets.

## 9. Zero-cost engineering rules

Always:
- paginate;
- use database indexes;
- cache expensive aggregates;
- store large media in B2;
- compress images;
- lazy-load media;
- use push notifications selectively;
- use PostgreSQL search instead of paid search infrastructure initially;
- aggregate analytics instead of collecting unnecessary raw events;
- clean temporary/expired data.

Never:
- load entire feeds;
- load every match/tournament row unnecessarily;
- store videos/images in PostgreSQL;
- create always-on realtime subscriptions for every screen;
- introduce a paid SaaS service because it is convenient.

## 10. Payments

Payment processing is allowed because it can be transaction-based rather than a monthly infrastructure subscription. However, payment processors may charge transaction fees when money is actually processed.

Do not claim payment processing itself is universally free.

## 11. Current repository fixes before release

The uploaded audit identified:
- a confirmed double-elimination UUID mismatch: generated `wb-*`, `lb-*`, `gf-*` IDs conflict with a PostgreSQL UUID column;
- two known Flutter missing-import analyzer errors;
- admin-web deployment/click-through and other listed open items.

Fix these and verify against a real PostgreSQL database where applicable. Do not rely solely on in-memory mocks.

## 12. Real consumer flow

The first app experience must be:

```text
Launch
 -> Splash
 -> Welcome
 -> Sign in / Create account
 -> Registration
 -> Verification
 -> Authenticated session
 -> Journey/intent selection
 -> Personalized onboarding
 -> Profile
 -> Home
```

It must not open on the developer/admin authentication interface.

The visible navigation must change according to authentication state, onboarding completion, verified permissions, and relevant product context.

## 13. Release order

Use this dependency order:

### Phase 0
Read-only forensic audit.

### Phase 1
Supabase authentication/session foundation.

### Phase 2
First-open consumer experience and onboarding.

### Phase 3
Core athlete experience.

### Phase 4
Referee workflow.

### Phase 5
Organizer/event workflow.

### Phase 6
Governance/admin/support workflows.

### Phase 7
B2/media, notifications, email, and usage controls.

### Phase 8
UX polish: remove placeholders, developer UI, fake data, dead routes/buttons; complete loading/empty/error/retry states.

### Phase 9
Real-device, real-database, security, migration, production, and store verification.

## 14. Definition of zero cost

The target is:

> **$0 recurring infrastructure cost while actual usage remains inside the published free allowances of the selected providers.**

This does not mean unlimited users, unlimited storage, unlimited bandwidth, or unlimited email forever.

Before paying for anything:
1. measure actual usage;
2. optimize;
3. reduce storage/egress/query volume;
4. evaluate another free service;
5. only then request explicit approval for paid scaling.

## 15. Binding instruction to the AI builder

The AI must:
1. inspect the actual repository before changing architecture;
2. preserve working ArmSphere domain logic;
3. use Supabase Auth for identity if the authentication migration is approved;
4. keep authorization in ArmSphere's server-side domain layer;
5. keep B2 secrets server-side;
6. keep production secrets out of Git;
7. use only the specified free-tier architecture;
8. stop and report if a free-tier limitation blocks a required feature;
9. never silently substitute a paid provider;
10. never call a screen "complete" merely because the UI exists;
11. verify every important journey end-to-end;
12. optimize before scaling.

## 16. Immediate task

Before implementation, perform a read-only authentication migration audit covering:

```text
apps/api/src/services/auth.ts
apps/api/src/controllers/auth.ts
apps/api/src/routes/auth.ts
apps/api/src/middlewares/auth.ts
apps/api/src/config/env.ts
apps/mobile/lib/features/auth/
apps/mobile/lib/core/api/
apps/mobile/lib/core/providers/session_provider.dart
database schema/migrations
Netlify environment configuration
B2 configuration
```

Answer:
- current identity source;
- current password/session mechanism;
- access/refresh-token lifecycle;
- Flutter session persistence;
- API identity extraction;
- user/profile foreign-key relationships;
- current role model;
- migration impact;
- Supabase JWT validation design;
- email provider configuration;
- secret-management design;
- exact files that would change.

Do not implement the migration until this audit is complete and its dependency risks are understood.

## 17. Store costs are separate

$0 infrastructure does not mean $0 app-store program fees. Apple/Google developer-account or distribution fees are separate from hosting, database, authentication, storage, API, and email costs.

## 18. Final stack

| Layer | Initial choice | Target recurring infrastructure cost |
|---|---|---:|
| Source | GitHub | $0 |
| CI | GitHub Actions within included quota | $0 |
| Mobile | Flutter | $0 |
| Auth | Supabase Auth Free | $0 |
| Database | PostgreSQL/Supabase Free within quota | $0 |
| API/Web | Netlify Free + ArmSphere API | $0 |
| Media | Backblaze B2 within free allowance | $0 |
| Email | Brevo Free OR Resend Free | $0 |
| Push | Firebase Cloud Messaging where applicable | $0 target |
| Search | PostgreSQL | $0 |
| Analytics | First-party/free tooling | $0 |
| Realtime | Supabase Realtime within quota | $0 |
| Payments | Payment processor only when used | no monthly infrastructure target; transaction fees may apply |

**Binding contract:** no paid infrastructure may be introduced without explicit owner approval.
