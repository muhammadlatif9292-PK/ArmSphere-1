# ARMSPHERE — MASTER PRODUCT AUDIT, DESIGN ARCHAEOLOGY & USER-JOURNEY INVESTIGATION

**Date:** 2026-10-26 (Reconciled with Post-Implementation Safety Audit & Test Addendum)  
**Audit Type:** Read-Only Forensic Product Audit, Design Archaeology, Runtime Video vs. Source Reconciliation & Post-Implementation Verification Report  
**Repository Baseline:** Snapshot Commit `8a472fa` (`fix(mobile): resolve CI static analysis issues and formatting`, per `/_git_log.txt` & `/_head.txt`), plus Post-Implementation Audit of the 27-File Remediation Pass  
**Runtime Video Evidence:** `/public/assets/aistudio/Screen_Recording_20261026_062348_1__17455fe3.mp4` (`228.59s`, `720x1600`, `29.75 fps`, Android Physical Device Capture)

---

## 1. Executive Summary & Audit Methodology

ArmSphere is a multi-role competitive arm-wrestling platform built for the Pakistan Arm Wrestling Federation ecosystem, comprising:
1. **Flutter Mobile Client (`apps/mobile`)** — Athlete, Referee, Tournament Operator, and Governance/Official mobile workflows using `flutter_riverpod` and `go_router`.
2. **React/Vite Admin Web Console (`apps/admin-web`)** — Federation administration, championship operations, arbitration/governance, referee certification, moderation, venues, nominations, audit trail, and support triage.
3. **Node.js/Express + Drizzle ORM Backend (`apps/api`, `packages/db-schema`)** — 25 API route modules backed by a 40+ table PostgreSQL schema (`packages/db-schema/index.ts`).
4. **Cloudflare Edge Gateway (`apps/cloudflare-gateway`)** — Edge caching and API proxy layer.

### Methodology & Evidence Classification
To eliminate speculative claims or unjustified certainty, every finding in this report is classified under an explicit evidence-based confidence label:
- **`Confirmed (Source + Video)`**: Directly observed in the 228.59-second Android screen recording **and** traced to the exact file, symbol, and line in the current repository (`8a472fa`).
- **`Confirmed (Source Only — Uncaptured in Video)`**: Verified directly in the current source tree (`8a472fa`) with exact file and line citations, on a route or interaction branch not traversed during the video recording.
- **`Confirmed (Video APK Only — Diverges from Current Source)`**: Directly observed in the recorded APK, where inspection of `8a472fa` proves the source code was modified *after* the APK was built (establishing a concrete APK-to-HEAD provenance gap).
- **`Probable`**: Strongly supported by runtime symptoms and code structure, with a clearly stated remaining environmental or runtime variable to confirm.
- **`Unverified`**: Not directly demonstrated by the video or static source inspection; requires targeted runtime or database verification.

---

## 2. Repository Hygiene, Workspace State & Provenance Analysis

### 2.1 Repository, Working-Tree & Post-Implementation State
- **Git Metadata Availability (`Confirmed`)**: The workspace is an exported snapshot without a live `.git` directory (`git status` returns `fatal: not a git repository`). Baseline commit provenance is established via repository snapshot artifacts in root:
  - `/_head.txt` & `/_git_log.txt`: Commit `8a472fa0583254325c0da1bb3a2dd9b0f8bb7703` (`fix(mobile): resolve CI static analysis issues and formatting`), preceded by `ba04ee0` (`Phase 14: Full Real End-to-End Verification and Zero-Defect Sign-Off`).
  - `/_git_diff.txt`: Empty (`0` bytes) at snapshot capture time.
- **27-File Remediation Pass & Zero-Modification Verification Audit (`Confirmed`)**: Following initial plan approval, a 27-file implementation pass (`25` modified files, `2` deleted dead theme files: `app_theme_final.dart` and `app_theme.dart.new`) was applied in the workspace. The subsequent Post-Implementation Safety Audit & Verification run operated strictly read-only and modified **zero** application source, configuration, asset, or test files. Because `flutter analyze`, `flutter test`, the Admin Web test suite, and live end-to-end runtime verification remain either blocked by environment or partially incomplete (see Section 10 & Section 11), **no remediation phase or defect is marked as fully verified/closed**.
- **`.flutter-plugins-dependencies` Verification (`Confirmed`)**: Inspected `/apps/mobile` via `list_dir`. The file `/apps/mobile/.flutter-plugins-dependencies` **does not exist** in the workspace (`apps/mobile` contains only `analysis_options.yaml`, `android`, `assets`, `lib`, `pubspec.yaml`, `test`, `web`).
- **Temporary Frame Artifacts Cleaned (`Confirmed`)**: All temporary frame extraction grids generated during video inspection (`/public/assets/aistudio/_audit_grid_*.jpg` and `/tmp/audit_frames`) were removed. Verified via `list_dir` that `/public/assets/aistudio` contains only the original screen recording `Screen_Recording_20261026_062348_1__17455fe3.mp4`.
- **Root Directory Artifact Clutter (`Confirmed`)**: The repository root contains **92+ leftover debug text and PowerShell log files** (`_br.txt`, `_ci*.txt`, `_git_*.txt`, `_p6_*` through `_p12_*`, `_e2e_*.ps1`, `_health_*.ps1`) alongside **24 competing root Markdown status reports** (`PHASE13_FORENSIC_AUDIT_REPORT.md`, `PHASE14_COMPLETION_EVIDENCE.md`, `FINAL_COMPLETION_REPORT.md`, etc.).

### 2.2 Development-Server Startup Classification (`Confirmed (Source Only)`)
- **Observed Symptom**: Initial workspace dev-server startup (`npm run dev`) failed to bring up the preview server cleanly.
- **Evidence-Based Cause**:
  1. **Workspace Build Order Dependency**: `@armsphere/api` imports compiled output (`dist/index.js`) from the local monorepo packages `@armsphere/types`, `@armsphere/core`, `@armsphere/cryptography`, and `@armsphere/db-schema`. Starting the API dev script before building those four workspace packages in topological order fails module resolution if `dist/` artifacts are absent or stale.
  2. **Unpublished npm Package Specifiers in Manifests**: Baseline `package.json` files contained version ranges that do not exist on the public npm registry (`esbuild@^0.28.2` in root `package.json`, `dotenv@^17.2.3` and `stripe@^22.3.1` in `apps/api/package.json`, and `lucide-react@^0.546.0` and `recharts@^3.9.2` in `apps/admin-web/package.json`), blocking fresh `npm install` operations until pinned to published versions (`esbuild@^0.25.0`, `dotenv@^16.4.7`, `stripe@^17.7.0`, `lucide-react@^0.475.0`, `recharts@^2.15.1`).
  3. **Preview Port Expectation**: The AI Studio preview environment expects port `3000` to be served, whereas `apps/admin-web/vite.config.ts` defaults to port `3001` unless overridden (`--port 3000`) or proxied.
- **Severity Classification**: **Medium — Build/Workspace Orchestration & Dependency Manifest Defect** (affects cold-start install and preview orchestration; does not alter mobile or backend domain logic).

### 2.3 APK-to-Source Provenance Gap (`Confirmed`)
Cross-referencing the 228.59-second screen recording against commit `8a472fa` proves that **the recorded APK was compiled from an earlier commit prior to `8a472fa`**. Five concrete divergences establish this provenance gap:

| Surface / Flow | Observed in Recorded APK (`Screen_Recording_...mp4`) | Present in Baseline Source (`8a472fa`) | Provenance Conclusion |
| :--- | :--- | :--- | :--- |
| **Welcome Screen (`00:00–00:10`)** | Displays `"DOMINATE THE TABLE"` with a single `ENTER ARENA` CTA that navigates directly to `/login`. No role selector cards exist on Welcome. | `welcome_screen.dart:205-378` displays `"ARMSPHERE"` / `"SELECT YOUR ROLE IN THE ARENA"`, a 4-card role selector (`ATHLETE`, `REFEREE`, `ORGANIZER`, `SPECTATOR`), `ENTER ARENA` -> `/register`, and `I ALREADY HAVE AN ACCOUNT` -> `/login`. | `welcome_screen.dart` was rewritten after the APK build. |
| **Athlete Profile Biometrics (`01:36–01:44`)** | Displays `WEIGHT —`, `HEIGHT —`, `REACH —`, `DOMINANT ARM RIGHT` when biometric fields are null. | `athlete_screens.dart:1158-1171` (`_buildBiometricsCard`) in `8a472fa` substituted hardcoded fallback numbers (`85kg`, `182cm`, `180cm`); subsequently updated in the 27-file pass to render `"—"` when null. | `8a472fa` introduced fake biometric defaults not present in the older APK. |
| **Grip Lock Recovery Card (`01:36–01:45`)** | Displays `GRIP LOCK RECOVERY` (`84% READY`, `48 kg`) on `AthleteProfileScreen`. | Neither `GripLockRecoveryWidget` nor `grip_lock_recovery_widget.dart` exists anywhere in `apps/mobile/lib` at commit `8a472fa`. | `GripLockRecoveryWidget` was already removed from source prior to `8a472fa`. |
| **Governance & Disputes (`02:07–02:35`)** | Displays `Arbitration & Disputes` with a top-right filter icon (`Icons.filter_list`) opening a radio filter modal (`All Severities`, `High Priority Only`, `Tournament Matches Only`, `Informal Challenges Only`). | `governance_screens.dart:79-253` (`GovernanceDashboardScreen`) replaces the filter modal with an operational metrics ribbon (`TOTAL`, `OPEN`, `ESCALATED`, `RESOLVED`), 4 horizontal `_FilterTab` chips, and an `Icons.add_moderator_outlined` AppBar button routing to `/governance/submit-complaint`. | `governance_screens.dart` was refactored after the APK build. |
| **Settings -> Support (`03:18–03:38`)** | Tapping `Support Requests` navigates to a full in-app `Support Requests` / `HELPDESK TRIAGE` screen with a `+ New Ticket` dialog (`Subject`, `Category`, `Priority`, `Description`) backed by `/api/v1/support`. | `settings_hub_screens.dart:95, 150-239` in `8a472fa` replaced navigation with `_showSupportModal(context)`, a static bottom sheet displaying `support@armsphere.pk` (restored in the 27-file pass via `SupportRequestsScreen` on `/settings/support`, pending runtime verification). | `8a472fa` regressed by replacing a working in-app support ticket flow with a static email modal. |

---

## 3. Corrections & Reconciliations to Preliminary Audit Draft

In accordance with Section 2 & Section 3 of the audit instructions, every claim from the preliminary audit draft was re-verified against the source tree (`8a472fa`). The following inaccuracies in the preliminary draft are explicitly retracted and replaced with verified facts:

1. **Retracted Claim: "`PROVANCIAL_DIRECTOR` Spelling Typo in DB Schema vs. Mobile"**
   - **Verification (`Confirmed`)**: Inspected `/packages/db-schema/index.ts:11-21`, `/packages/types/index.ts:1-10`, `/apps/admin-web/src/types.ts:1-10`, and `/apps/mobile/lib/core/routing/app_router.dart:60-101`. The role enum is spelled `'PROVINCIAL_DIRECTOR'` consistently across all four files. There is **no** `'PROVANCIAL_DIRECTOR'` typo in the repository.
   - **Actual Verified RBAC & Role-Routing Defects (`Confirmed (Source Only)`)**:
     - **Baseline (`8a472fa`) Defects**:
       1. In `TournamentDetailScreen` (`/apps/mobile/lib/features/tournament/screens/tournament_screens.dart`), `operatorRoles` omitted `'TOURNAMENT_OPERATOR'` (`{'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'}`).
       2. In `RoleAwareHomeScreen` and `routerProvider.redirect` (`/apps/mobile/lib/core/routing/app_router.dart`), `_isGovernanceLandingRole` included both `'TOURNAMENT_OPERATOR'` and `'SUPPORT_AGENT'`, routing both roles to `GovernanceDashboardScreen` (`/governance`).
       3. In `AccountRolesScreen` (`/apps/mobile/lib/features/settings/screens/account_roles_screen.dart`), `_formatRoleName()` and `_roleIcon()` only mapped 4 of the 9 RBAC roles.
     - **Post-Implementation Audit Status**: While `TOURNAMENT_OPERATOR` was moved to `_isTournamentLandingRole` (`/tournaments`), added to `operatorRoles` in `TournamentDetailScreen`, and all 9 roles were mapped in `AccountRolesScreen`, two role defects remain open:
       1. `'SUPPORT_AGENT'` is **still** included in `_isGovernanceLandingRole` (`app_router.dart:65, 97`), routing Support Agents to `GovernanceDashboardScreen` (`Arbitration & Disputes`) instead of a Support workspace.
       2. `RegisterScreen` (`register_screen.dart:69-71`) now calls `setRoleIntent()` *before* `register()` when a role is passed from `WelcomeScreen`, which sets `authState.needsRoleIntent = false` and causes `app_router.dart` to bypass `RoleIntentScreen`—skipping `applyForRole()` for users who selected `referee` or `organizer` on `WelcomeScreen`.
2. **Retracted Claims on `AthleteTrainingLogScreen` (No KG/LBS Toggle Bug; Dedicated Endpoints Exist, Blocked by Profile Envelope Unwrapping Defect)**
   - **Verification (`Confirmed (Source Only)`)**:
     - Inspected `/apps/mobile/lib/features/athlete/screens/training_log_screen.dart` (lines 1–331). There is **no** `_isMetric` state field or KG/LBS toggle in `AthleteTrainingLogScreen`; all weights are rendered in `kg`.
     - Furthermore, contrary to an earlier draft note, `AthleteTrainingLogScreen` (`training_log_screen.dart:64-65`) and `AthleteDashboardScreen` (`athlete_screens.dart:62-64`) do **not** filter the 50-post community feed client-side; they call dedicated endpoints `GET /api/v1/athletes/:id/training-log` (`trainingLogProvider(athleteId)`) and `GET /api/v1/athletes/:id/training-log/prs` (`trainingLogPRsProvider(athleteId)`), which are implemented on the backend by `CommunityService.getTrainingLog` and `CommunityService.getTrainingLogPRs` (`/apps/api/src/services/community.ts:593-698`, limit 100).
   - **Actual Verified Training Log & Profile Data-Retrieval Defect (`Confirmed (Source Only)`)**:
     - `AthleteController.getProfile` (`/apps/api/src/controllers/athlete.ts:175-178`) returns the JSON envelope `{ success: true, data: profile }`, and `DioClient` (`/apps/mobile/lib/core/api/dio_client.dart`) has no response-unwrapping interceptor.
     - Unlike `searchAthletes`, `getRankings`, `getHistory`, `getTrainingLog`, and `getTrainingLogPRs` in `AthleteRepository` (`/apps/mobile/lib/core/api/repositories.dart:235-330`) which explicitly unwrap `data['data']`, `AthleteRepository.getProfile` (`repositories.dart:258-265`) parses `Map<String, dynamic>.from(data)` **without unwrapping `data['data']`**.
     - Consequently, `profileAsync.value` on `AthleteDashboardScreen` (`athlete_screens.dart:59-64`) and `AthleteProfileScreen` (`athlete_screens.dart:892-894`) is `{ 'success': true, 'data': { 'id': ... } }`. Top-level field reads (`profileAsync.value?['id']`, `p['rightArmElo']`, `p['weight']`, `p['displayName']`) evaluate to `null`, causing `myProfileId` to fall back to `authState.userProfile['id']` (`users.id`, the auth user UUID).
     - Because `CommunityService.getTrainingLog` (`community.ts:598`) and `getTrainingLogPRs` (`community.ts:648`) query `eq(athleteProfiles.id, athleteId)` (expecting `athleteProfiles.id` rather than `users.id`), `trainingLogProvider(myProfileId)` and `trainingLogPRsProvider(myProfileId)` fail with `404 NotFoundError("Athlete profile not found")` whenever `users.id !== athleteProfiles.id`!
3. **Refined Finding: `PaymentMethodsScreen` Observed HTTP 500 vs. Proposed Root Cause (`Confirmed (Source + Video)`)**
   - **Observed Runtime Fact (`Confirmed in Video at 02:51–03:17`)**: Navigating to `/settings/payment-methods` (`PaymentMethodsScreen`) produces `DioException [bad response]: status code of 500` on `GET /api/v1/payments/methods`, and tapping `+ Add New Card` produces a snackbar `Could not start card setup: DioException [bad response]: status code of 500` on `POST /api/v1/payments/setup-intent`.
   - **Code-Level Explanation / Root-Cause Analysis (`Probable / Source-Grounded`)**: Inspection of `/apps/api/src/controllers/payment.ts:171-309` and `/apps/api/src/services/stripe.ts:1-19` shows that in baseline `8a472fa`, both endpoints unconditionally invoked `getStripe()` (which throws `Error("STRIPE_SECRET_KEY environment variable is required...")` if `STRIPE_SECRET_KEY` is unset) or threw errors if Stripe customer / `athleteProfiles` lookup failed, passing unhandled exceptions to Express error middleware as HTTP `500`.
   - **Strict Remediation Rule & Post-Implementation Status**: Fake or offline payment-card registration must **never** be used. In the 27-file pass, `PaymentController.getPaymentMethods` was updated to return HTTP `200` (`data: [], meta: { paymentConfigured: false }`) when Stripe is unconfigured, while `createSetupIntent` returns HTTP `503` (`PAYMENT_PROVIDER_UNAVAILABLE`). However, `PaymentMethodsScreen` ignores `meta.paymentConfigured`, displaying `"No saved cards"` on load and still showing a red error snackbar (`DioException [bad response]: status code of 503`) when the user taps `"+ Add New Card"`.
4. **Refined Finding: `ActiveSessionsListScreen` Session Revocation (`Confirmed (Source + Video)`)**
   - **Verification**: Inspected `/apps/mobile/lib/features/session/screens/session_screens.dart:14-388` and `/apps/api/src/services/sessionSecurity.ts`.
   - **Actual Behavior**: Tapping an individual row on `ActiveSessionsListScreen` navigates to `/athlete/session/:sessionId` (`ActiveSessionControlScreen`), which provides `Revoke This Session` and `Revoke All Other Sessions`. In the 27-file pass, a top-level `REVOKE OTHERS` AppBar action was added to `ActiveSessionsListScreen` and Dart/Flutter `User-Agent` parsing + session deduplication were added to `sessionSecurity.ts` (verified by unit tests in `apps/api`, pending live mobile runtime verification).

---

## 4. Reconciled Route & Screen Inventory (100% Internally Consistent)

### 4.1 Flutter Mobile Route Inventory (`/apps/mobile/lib/core/routing/app_router.dart`)
Line-by-line verification of `/apps/mobile/lib/core/routing/app_router.dart` (lines 223–1202) establishes the following exact, internally consistent route math:
- **Total `GoRoute` declarations in `app_router.dart`:** **`97` routes**
  - **`11` Pre-Shell Top-Level Routes** (lines 224–317)
  - **`10` `StatefulShellBranch` Routes across 5 bottom navigation tabs** (lines 323–392)
  - **`76` Post-Shell Top-Level Routes** (lines 395–1201)
  - **Sum Check:** `11 + 10 + 76 = 97` `GoRoute` declarations.
- **Total Unique Screen Widget Classes Mounted:** **`69` unique screen widget classes** (listed in Rows `1`–`69` of the table below).
- **Total Duplicate / Legacy Alias `GoRoute` Declarations:** **`28` alias `GoRoute` declarations** (listed in Column 3 of the table below):
  - `52` screen classes have exactly `1` `GoRoute` (`52 × 1 = 52` routes, `0` aliases)
  - `12` screen classes have `2` `GoRoute` declarations (`12 × 2 = 24` routes -> `12` canonical + `12` aliases: `TournamentsListScreen`, `TournamentDetailScreen`, `EventRegistrationScreen`, `TournamentOperationsScreen`, `DisputeDetailScreen`, `PostCommentsScreen`, `CreatePostScreen`, `VenueDetailScreen`, `NominateTalentScreen`, `InformalEventDetailScreen`, `MatchSubmissionScreen`, `AthleteAchievementsScreen`)
  - `1` screen class has `3` `GoRoute` declarations (`1 × 3 = 3` routes -> `1` canonical + `2` aliases: `GovernanceDashboardScreen`)
  - `3` screen classes have `4` `GoRoute` declarations (`3 × 4 = 12` routes -> `3` canonical + `9` aliases: `TournamentWeighInScreen`, `TournamentAwardsCeremonyScreen`, `HeadToHeadScreen`)
  - `1` screen class has `6` `GoRoute` declarations (`1 × 6 = 6` routes -> `1` canonical + `5` aliases: `TournamentBracketsScreen`)
  - **Sum Check:**
    - Unique Routed Screen Classes: `52 + 12 + 1 + 3 + 1 = 69` unique routed screen classes (in baseline `8a472fa`).
    - Alias `GoRoute` Declarations: `0 + 12 + 2 + 9 + 5 = 28` alias `GoRoute` declarations.
    - Total `GoRoute` Declarations: `69 + 28 = 97` `GoRoute` declarations (in baseline `8a472fa`).
- **Post-Implementation Route Note (`/settings/support`)**: During the 27-file remediation pass, `1` additional `GoRoute` (`path: '/settings/support'`, `SupportRequestsScreen` in `settings_screens.dart`) was added to `app_router.dart` (`98` total `GoRoute` declarations = `11` pre-shell + `10` shell + `77` post-shell; `70` unique routed screen classes + `28` alias `GoRoute` declarations).
- **Unrouted / Orphan Screen Widget Class (`Confirmed (Source Only)`)**:
  - `OfficialScorepadScreen` (`/apps/mobile/lib/features/referee/screens/official_scorepad_screen.dart`, 2,358 lines) exists in the mobile source tree (`class OfficialScorepadScreen extends ConsumerStatefulWidget` at line 58) with an embedded 5-step stepper, foul system, and custom signature painter, but has **zero** imports or `GoRoute` declarations in `app_router.dart`. Instead, `/referee/scorepad` and `/referee/submit-scorepad` mount `MatchSubmissionScreen` (`features/referee/screens/referee_screens.dart`), which uses `LiveScorepadController` (`features/referee/controllers/live_scorepad_controller.dart`).

#### Complete Reconciled Baseline Mobile Route Table (`69` Unique Screen Classes + `28` Alias Routes = `97` `GoRoute` Declarations; plus `/settings/support` added in 27-file pass)

| # | Canonical Path (`app_router.dart`) | Alias `GoRoute` Paths in `app_router.dart` (`28` total) | Target Widget Class (`69` unique) | Source File (`apps/mobile/lib/...`) | Video Coverage | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `/` (line 224) | — | `SplashScreen` | `features/auth/screens/splash_screen.dart` | Not in clip | `Confirmed (Source Only)` |
| 2 | `/welcome` (line 232) | — | `WelcomeScreen` | `features/auth/screens/welcome_screen.dart` | `00:00–00:10` | `Confirmed (Source + Video)` |
| 3 | `/login` (line 240) | — | `LoginScreen` | `features/auth/screens/login_screen.dart` | `00:10–00:34` | `Confirmed (Source + Video)` |
| 4 | `/register` (line 248) | — | `RegisterScreen` | `features/auth/screens/register_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 5 | `/forgot-password` (line 256) | — | `ForgotPasswordScreen` | `features/auth/screens/forgot_password_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 6 | `/reset-password` (line 264) | — | `ResetPasswordScreen` | `features/auth/screens/reset_password_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 7 | `/mfa/setup` (line 272) | — | `MfaSetupScreen` | `features/auth/screens/mfa_setup_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 8 | `/mfa/verify` (line 280) | — | `MfaVerificationScreen` | `features/auth/screens/mfa_verification_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 9 | `/recovery-codes` (line 294) | — | `RecoveryCodesScreen` | `features/auth/screens/recovery_codes_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 10 | `/role-intent` (line 302) | — | `RoleIntentScreen` | `features/auth/screens/role_intent_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 11 | `/onboarding` (line 310) | — | `OnboardingScreen` | `features/athlete/screens/onboarding_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 12 | `/home` (Tab 0, line 325) | — | `RoleAwareHomeScreen` | `core/routing/app_router.dart:105-124` | `00:35–00:46` | `Confirmed (Source + Video)` |
| 13 | `/athlete/dashboard` (Tab 0, line 330) | — | `AthleteDashboardScreen` | `features/athlete/screens/athlete_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 14 | `/referee/dashboard` (Tab 0, line 335) | — | `RefereeDashboardScreen` | `features/referee/screens/referee_screens.dart` | `01:48–02:06` | `Confirmed (Source + Video)` |
| 15 | `/governance` (Tab 0, line 340) | `/governance/federation` (823), `/governance/disputes` (831) *(+2 aliases)* | `GovernanceDashboardScreen` | `features/governance/screens/governance_screens.dart` | `02:07–02:35` | `Confirmed (Source + Video)` |
| 16 | `/discover` (Tab 1, line 349) | — | `DiscoverScreen` | `features/home/screens/discover_screen.dart` | `00:35–00:46` | `Confirmed (Source + Video)` |
| 17 | `/rankings` (Tab 1, line 354) | — | `RankingsScreen` | `features/athlete/screens/rankings_screen.dart` | `00:47–00:54` | `Confirmed (Source + Video)` |
| 18 | `/tournaments` (Tab 2, line 363) | `/tournament/dashboard` (368) *(+1 alias)* | `TournamentsListScreen` | `features/tournament/screens/tournament_screens.dart` | `00:55–01:07` | `Confirmed (Source + Video)` |
| 19 | `/community/feed` (Tab 3, line 377) | — | `CommunityFeedScreen` | `features/community/screens/community_feed_screen.dart` | `01:08–01:35` | `Confirmed (Source + Video)` |
| 20 | `/athlete/profile` (Tab 4, line 386) | — | `AthleteProfileScreen` | `features/athlete/screens/athlete_screens.dart` | `01:36–01:47` | `Confirmed (Source + Video)` |
| 21 | `/search` (line 395) | — | `GlobalSearchScreen` | `features/search/screens/search_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 22 | `/athlete/:athleteId` (line 403) | — | `PublicAthleteProfileScreen` | `features/athlete/screens/public_profile_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 23 | `/athlete/:athleteId/followers` (line 414) | — | `FollowersListScreen` | `features/athlete/screens/followers_list_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 24 | `/athlete/:athleteId/training-log` (line 425) | — | `AthleteTrainingLogScreen` | `features/athlete/screens/training_log_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 25 | `/athlete/:athleteId/following` (line 436) | — | `FollowingListScreen` | `features/athlete/screens/followers_list_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 26 | `/teams` (line 447) | — | `TeamsListScreen` | `features/team/screens/team_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 27 | `/teams/create` (line 455) | — | `CreateTeamScreen` | `features/team/screens/team_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 28 | `/teams/:teamId` (line 463) | — | `TeamDetailScreen` | `features/team/screens/team_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 29 | `/tournament/:tournamentId` (line 474) | `/tournament/details` (768) *(+1 alias)* | `TournamentDetailScreen` | `features/tournament/screens/tournament_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 30 | `/tournament/:tournamentId/register` (line 485) | `/events/:eventId/register` (757) *(+1 alias)* | `EventRegistrationScreen` | `features/tournament/screens/event_registration_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 31 | `/tournament/:tournamentId/brackets` (line 496) | `/tournament/:tournamentId/bracket` (507), `/tournaments/:tournamentId/brackets` (518), `/tournaments/:tournamentId/bracket` (529), `/tournaments/bracket` (540), `/tournament/brackets` (792) *(+5 aliases)* | `TournamentBracketsScreen` | `features/tournament/screens/tournament_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 32 | `/tournament/:tournamentId/operations` (line 555) | `/tournament/operations` (780) *(+1 alias)* | `TournamentOperationsScreen` | `features/tournament/screens/tournament_operations_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 33 | `/tournament/:tournamentId/weigh-in` (line 566) | `/tournaments/:tournamentId/weigh-in` (581), `/weigh-in` (596), `/tournaments/weigh-in` (618) *(+3 aliases)* | `TournamentWeighInScreen` | `features/tournament/screens/tournament_weigh_in_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 34 | `/awards` (line 640) | `/tournaments/awards` (656), `/tournament/:tournamentId/awards` (672), `/tournaments/:tournamentId/awards` (683) *(+3 aliases)* | `TournamentAwardsCeremonyScreen` | `features/championship/screens/tournament_awards_ceremony_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 35 | `/matches/head-to-head` (line 694) | `/compare` (710), `/matches/:matchId/head-to-head` (726), `/matches/h2h` (741) *(+3 aliases)* | `HeadToHeadScreen` | `features/match/screens/head_to_head_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 36 | `/championship/titles` (line 804) | — | `ChampionshipsListScreen` | `features/championship/screens/championship_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 37 | `/championship/:championshipId` (line 812) | — | `ChampionshipDetailScreen` | `features/championship/screens/championship_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 38 | `/governance/dispute/:disputeId` (line 839) | `/governance/disputes/detail` (850) *(+1 alias)* | `DisputeDetailScreen` | `features/governance/screens/governance_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 39 | `/governance/submit-complaint` (line 862) | — | `SubmitComplaintScreen` | `features/governance/screens/submit_complaint_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 40 | `/messages` (line 870) | — | `ConversationsListScreen` | `features/messaging/screens/messaging_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 41 | `/messages/:conversationId` (line 878) | — | `ChatScreen` | `features/messaging/screens/messaging_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 42 | `/notifications` (line 889) | — | `NotificationsListScreen` | `features/notifications/screens/notification_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 43 | `/announcements` (line 897) | — | `AnnouncementsListScreen` | `features/messaging/screens/announcement_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 44 | `/session` (line 905) | — | `ActiveSessionsListScreen` | `features/session/screens/session_screens.dart` | `02:40–02:50` | `Confirmed (Source + Video)` |
| 45 | `/athlete/session/:sessionId` (line 913) | — | `ActiveSessionControlScreen` | `features/session/screens/session_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 46 | `/settings/payment-methods` (line 924) | — | `PaymentMethodsScreen` | `features/settings/screens/payment_methods_screen.dart` | `02:51–03:17` | `Confirmed (Source + Video)` |
| 47 | `/settings/tickets` (line 932) | — | `MyTicketsScreen` | `features/settings/screens/settings_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 48 | `/settings/blocked` (line 940) | — | `BlockedUsersScreen` | `features/settings/screens/settings_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 49 | `/settings` (line 948) | — | `SettingsHubScreen` | `features/settings/screens/settings_hub_screens.dart` | `01:46–03:48` | `Confirmed (Source + Video)` |
| 50 | `/settings/roles` (line 956) | — | `AccountRolesScreen` | `features/settings/screens/account_roles_screen.dart` | `02:36–02:39` | `Confirmed (Source + Video)` |
| 51 | `/settings/roles/apply` (line 964) | — | `ApplyRoleScreen` | `features/settings/screens/apply_role_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 52 | `/settings/deletion` (line 972) | — | `AccountDeletionScreen` | `features/settings/screens/settings_hub_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 53 | `/settings/terms` (line 980) | — | `TermsScreen` | `features/settings/screens/settings_hub_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 54 | `/settings/privacy` (line 988) | — | `PrivacyPolicyScreen` | `features/settings/screens/settings_hub_screens.dart` | Uncaptured | `Confirmed (Source Only)` |
| 55 | `/community/posts/:postId/comments` (line 996) | `/community/post/:postId/comments` (1007) *(+1 alias)* | `PostCommentsScreen` | `features/community/screens/post_comments_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 56 | `/community/create` (line 1018) | `/community/post/create` (1026) *(+1 alias)* | `CreatePostScreen` | `features/community/screens/create_post_screen.dart` | `01:12–01:30` | `Confirmed (Source + Video)` |
| 57 | `/venues` (line 1034) | — | `VenueDirectoryScreen` | `features/venue/screens/venue_directory_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 58 | `/venues/submit` (line 1042) | — | `SubmitVenueScreen` | `features/venue/screens/submit_venue_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 59 | `/venues/:venueId` (line 1050) | `/venues/detail/:venueId` (1061) *(+1 alias)* | `VenueDetailScreen` | `features/venue/screens/venue_detail_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 60 | `/nominations/my` (line 1072) | — | `MyNominationsScreen` | `features/nomination/screens/my_nominations_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 61 | `/nominations/submit` (line 1080) | `/nominate` (1088) *(+1 alias)* | `NominateTalentScreen` | `features/nomination/screens/nominate_talent_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 62 | `/informal-events` (line 1096) | — | `InformalEventDirectoryScreen` | `features/informal_event/screens/informal_event_directory_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 63 | `/informal-events/create` (line 1104) | — | `CreateInformalEventScreen` | `features/informal_event/screens/create_informal_event_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 64 | `/informal-events/:eventId` (line 1112) | `/informal-events/detail/:eventId` (1123) *(+1 alias)* | `InformalEventDetailScreen` | `features/informal_event/screens/informal_event_detail_screen.dart` | Uncaptured | `Confirmed (Source Only)` |
| 65 | `/referee/certifications` (line 1134) | — | `RefereeCertificationsScreen` | `features/referee/screens/referee_screens.dart` | `01:55–01:57` | `Confirmed (Source + Video)` |
| 66 | `/referee/scorepad` (line 1142) | `/referee/submit-scorepad` (1153) *(+1 alias)* | `MatchSubmissionScreen` | `features/referee/screens/referee_screens.dart` | `02:02–02:04` | `Confirmed (Source + Video)` |
| 67 | `/referee/search-athletes` (line 1164) | — | `AthleteSearchScreen` | `features/referee/screens/referee_screens.dart` | `01:58–01:59` | `Confirmed (Source + Video)` |
| 68 | `/referee/upload-evidence` (line 1172) | — | `EvidenceUploadScreen` | `features/referee/screens/referee_screens.dart` | `02:00–02:01` | `Confirmed (Source + Video)` |
| 69 | `/achievements` (line 1180) | `/athlete/achievements` (1191) *(+1 alias)* | `AthleteAchievementsScreen` | `features/athlete/screens/athlete_screens.dart` | Uncaptured | `Confirmed (Source Only)` |

### 4.2 Admin Web Route Inventory (`/apps/admin-web/src/App.tsx`)
Static verification of `/apps/admin-web/src/App.tsx` (238 lines) and `/apps/admin-web/src/lib/authorizationPolicy.ts` confirms **`13` `<Route>` declarations** (`1` public route, `11` protected `RoleGuardedRoute` routes, `1` wildcard redirect) plus `ForbiddenPage` rendered inline when `canAccessRoute()` returns `allowed: false`:

| # | Route Path | Page Component | Allowed Roles (`authorizationPolicy.ts`) | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `/login` | `LoginPage` | Public (Redirects to `/` if authenticated) | `Confirmed (Source Only)` |
| 2 | `/` | `OverviewPage` | All 7 console roles (`PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `TOURNAMENT_OPERATOR`, `SYSTEM_ADMIN`, `REFEREE`, `COMPLIANCE_OFFICER`, `SUPPORT_AGENT`) | `Confirmed (Source Only)` |
| 3 | `/analytics` | `AnalyticsPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `TOURNAMENT_OPERATOR`, `SYSTEM_ADMIN`, `COMPLIANCE_OFFICER` | `Confirmed (Source Only)` |
| 4 | `/championships` | `ChampionshipsPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `TOURNAMENT_OPERATOR`, `SYSTEM_ADMIN` | `Confirmed (Source Only)` |
| 5 | `/governance` | `GovernancePage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`, `REFEREE`, `COMPLIANCE_OFFICER` | `Confirmed (Source Only)` |
| 6 | `/athletes` | `AthletesPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `TOURNAMENT_OPERATOR`, `SYSTEM_ADMIN`, `COMPLIANCE_OFFICER`, `SUPPORT_AGENT` | `Confirmed (Source Only)` |
| 7 | `/referees` | `RefereesPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`, `REFEREE` | `Confirmed (Source Only)` |
| 8 | `/moderation` | `ModerationPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`, `COMPLIANCE_OFFICER`, `SUPPORT_AGENT` | `Confirmed (Source Only)` |
| 9 | `/venues` | `VenuesPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `TOURNAMENT_OPERATOR`, `SYSTEM_ADMIN` | `Confirmed (Source Only)` |
| 10 | `/nominations` | `NominationsPage` | `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN` | `Confirmed (Source Only)` |
| 11 | `/audit` | `AuditPage` | `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`, `COMPLIANCE_OFFICER` | `Confirmed (Source Only)` |
| 12 | `/support` | `SupportPage` | `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`, `SUPPORT_AGENT` | `Confirmed (Source Only)` |
| 13 | `*` | `<Navigate to="/" replace />` | Wildcard fallback | `Confirmed (Source Only)` |

---

## 5. Runtime Video Walkthrough & Chronological Evidence Log (`00:00` – `03:48`)

The 228.59-second screen recording (`Screen_Recording_20261026_062348_1__17455fe3.mp4`) was inspected frame-by-frame. No personal email addresses or private credentials are reproduced below.

| Timestamp | Screen / Route Observed | Observed Runtime Behavior | Source Correlation & Provenance Status |
| :--- | :--- | :--- | :--- |
| `00:00–00:10` | `WelcomeScreen` (`/welcome`) | Displays `"DOMINATE THE TABLE"` hero typography and `ENTER ARENA` CTA. Tapping `ENTER ARENA` navigates directly to `/login`. | **`Confirmed (Video APK Only — Diverges from Current Source)`**: Current `welcome_screen.dart` displays `"ARMSPHERE"` + 4 role cards (`ATHLETE`, `REFEREE`, `ORGANIZER`, `SPECTATOR`) and routes `ENTER ARENA` to `/register`. |
| `00:10–00:34` | `LoginScreen` (`/login`) | User enters credentials and authenticates (`SIGN IN`). | **`Confirmed (Source + Video)`**: Matches `login_screen.dart`. |
| `00:35–00:46` | `DiscoverScreen` (`/discover` / `/home`) | Displays `ArmSphere` top bar with red fist icon, `"Command The Table"` hero banner, Coral Red (`#EF4444`) `ALL` filter pill and `View All` links, empty state `"No Matching Events"`, and `"Featured Champions"` horizontal cards. | **`Confirmed (Source + Video)`**: `discover_screen.dart:105, 158, 210, 267, 708, 811` explicitly uses `AppTheme.primaryAccent` (`#EF4444` Coral Red) instead of `AppTheme.goldPrimary` (`#D4AF37`). |
| `00:47–00:54` | `RankingsScreen` (`/rankings`) | Displays `NATIONAL RANKINGS`, search input, arm selector (`Right Arm` / `Left Arm` in Gold), weight class filter chips, and `"No Rankings Yet"`. | **`Confirmed (Source + Video)`**: Matches `rankings_screen.dart`. |
| `00:55–01:07` | `TournamentsListScreen` (`/tournaments`) | Displays `Tournaments`, province filter chips (`All`, `Punjab`, `Sindh`, `KPK`, `Balochistan`, `Islamabad`), search input, and `"No Tournaments Found"`. Notice there is **no** `+ Create Tournament` FAB or action even for an admin/operator user. | **`Confirmed (Source + Video)`**: Verified in `tournament_screens.dart:1-310`—no tournament creation UI exists in mobile. |
| `01:08–01:35` | `CommunityFeedScreen` (`/community/feed`) & `CreatePostScreen` (`/community/create`) | AppBar title row (`COMMUNITY ARENA` + `LIVE FEED` badge) collides horizontally with `POST CLIP` button (`COMMUNITY AR...`). User taps `POST CLIP`, opens `CreatePostScreen`, creates a post (`"Testing"`), and returns to feed. | **`Confirmed (Source + Video)`**: `community_feed_screen.dart:61-156` places a non-flexible badge + title + 2 actions inside a single `AppBar`. |
| `01:36–01:45` | `AthleteProfileScreen` (`/athlete/profile`) | Displays user profile header, `1200 ELO` (`RIGHT ARM` / `LEFT ARM`), `BIOMETRICS` (`WEIGHT —`, `HEIGHT —`, `REACH —`, `DOMINANT ARM RIGHT`), `Interactive ELO Calculator`, `GRIP LOCK RECOVERY` (`84% READY`, `48 kg`), and hardcoded `ACHIEVEMENTS & MILESTONES` (`SUPERMATCH MASTER`, `2000 ELO CLUB`, `NATIONAL CHAMPION`, `10 STREAK VICTOR`). | **`Confirmed (Source + Video)` / `Provenance Gap`**: `1200 ELO` comes from `ArmSwitchEloCard` (`athlete_screens.dart:1243-1244`); `GRIP LOCK RECOVERY` (`84%`, `48 kg`) was present in the older APK build but already removed from source prior to `8a472fa`; `ACHIEVEMENTS` were hardcoded in `achievements_section.dart:330-388`. |
| `01:46–01:48` | `SettingsHubScreen` (`/settings`) | User taps gear icon on profile (`athlete_screens.dart:73`), opening `Settings`. | **`Confirmed (Source + Video)`**: Matches `settings_hub_screens.dart`. |
| `01:48–02:06` | `RefereeDashboardScreen` (`/referee/dashboard`) & sub-routes | User opens Referee console, visits `Cert & Ledger` (`/referee/certifications`), `Athlete Search` (`/referee/search-athletes`), `Evidence Upload` (`/referee/upload-evidence`), and `Submit Match Result` (`/referee/scorepad`). | **`Confirmed (Source + Video)`**: Sub-routes match `referee_screens.dart`. |
| `02:07–02:35` | `GovernanceDashboardScreen` (`/governance`) | User opens `Arbitration & Disputes`, switches tabs, and opens the top-right filter modal in the APK (`02:14–02:34`). | **`Confirmed (Video APK Only — Diverges from Current Source)`**: Current `governance_screens.dart:79-253` replaced the old filter modal with a 4-stat metrics ribbon, 4 status chips (`ALL`, `OPEN`, `ESCALATED`, `RESOLVED`), and an `Icons.add_moderator_outlined` button routing to `/governance/submit-complaint`. |
| `02:36–02:39` | `AccountRolesScreen` (`/settings/roles`) | Displays active roles (`Athlete`, `Referee`, `Tournament Operator`, `System Admin`). | **`Confirmed (Source + Video)`**: Matches `account_roles_screen.dart`. |
| `02:40–02:50` | `ActiveSessionsListScreen` (`/session`) | Displays `Active Sessions` with `1 sessions` badge at top of section, followed by **15+ duplicate rows** of `Unknown Browser • Unknown... IP: 127.0.0.1`. | **`Confirmed (Source + Video)`**: Matches `session_screens.dart:14-229`. |
| `02:51–03:17` | `PaymentMethodsScreen` (`/settings/payment-methods`) | Displays red error banner (`DioException [bad response]: status code of 500`) on load (`GET /api/v1/payments/methods`). Tapping `+ Add New Card` triggers a red snackbar (`Could not start card setup: DioException [bad response]: status code of 500` from `POST /api/v1/payments/setup-intent`). | **`Confirmed (Source + Video)`**: Traced to `controllers/payment.ts:171-309` and `services/stripe.ts:6-18`. |
| `03:18–03:38` | `Support Requests` (in APK) | User taps `Support Requests` in `Settings`, opening a dedicated `Support Requests` / `HELPDESK TRIAGE` screen and creating a support ticket (`"Payment error"`). | **`Confirmed (Video APK Only — Diverges from Current Source)`**: Current `settings_hub_screens.dart:95, 150-239` replaced this screen with a static bottom sheet (`_showSupportModal`). |
| `03:39–03:48` | `SettingsHubScreen` (`/settings`) | User scrolls to bottom of Settings and signs out. | **`Confirmed (Source + Video)`**: Matches `settings_hub_screens.dart`. |

---

## 6. Design Archaeology & Design-Authority Matrix

### 6.1 Archaeological Evidence of Competing Design Eras
Inspection of the repository's theme files and documentation reveals **three distinct design eras** layered on top of each other:

1. **Era 1 — "Kinetic Brutalism / Coral Crimson (`#EF4444`)"**:
   - **Evidence**: `/apps/mobile/lib/core/theme/app_theme_final.dart` (201 lines) and `/apps/mobile/lib/core/theme/app_theme.dart.new` (203 lines).
   - **Characteristics**: Defined `primaryAccent = Color(0xFFEF4444)` (Coral Crimson) as `ThemeData.primaryColor` and `ElevatedButton` fill color, paired with `#0B0F19` obsidian slate.
   - **Status**: Both `app_theme_final.dart` and `app_theme.dart.new` are **unreferenced dead files**, yet `AppTheme.primaryAccent` (`#EF4444`) and `AppTheme.primaryRed` (`#EF4444`) were retained inside `app_theme.dart:13, 35` as compatibility aliases and are still actively used on `DiscoverScreen` (`discover_screen.dart:105, 158, 210, 267, 708, 811`), `RefereeDashboardScreen` (`referee_screens.dart:669, 1369, 1498`), and `SubmitComplaintScreen` (`submit_complaint_screen.dart:108-113`).

2. **Era 2 — "Obsidian Sanctuary / Championship Gold (`#D4AF37`)"**:
   - **Evidence**: `/apps/mobile/lib/core/theme/app_theme.dart` (586 lines, imported by `main.dart`) and `/UI_UX_DESIGN_STATE.md`.
   - **Characteristics**: Deep obsidian void backgrounds (`voidBackground = #070A11`, `background = #0B0F19`, `cardSurface = #121826`), `goldPrimary = #D4AF37` (`goldHighlight = #F3E5AB`, `goldMuted = #997A2C`), `Space Grotesk` display typography, `Plus Jakarta Sans` body typography, and `JetBrains Mono` for telemetry/tabular metrics.
   - **Status**: **Authoritative active mobile theme**, used across Auth, Rankings, Tournaments, Profile, Governance, and Settings—but undermined by Era 1 `#EF4444` remnants on `DiscoverScreen`, `RefereeDashboardScreen`, and `SubmitComplaintScreen`.

3. **Era 3 — "Admin Web Tactical Slate + Red Primary (`#EF4444`)"**:
   - **Evidence**: `/apps/admin-web/src/index.css` and `/apps/admin-web/src/App.tsx`.
   - **Characteristics**: Uses `#0B0F19` background and `#111827` surface cards, but defines `--primary: #EF4444` (Crimson Red) for active navigation indicators, primary action buttons, and focus rings, while using `#F59E0B` (Amber) as secondary.
   - **Status**: Active in `apps/admin-web`, creating a brand disconnect where the mobile app's primary identity is Championship Gold (`#D4AF37`) while the federation web console's primary identity is Crimson Red (`#EF4444`).

### 6.2 Design-Authority Matrix

| Artifact / File | Claimed Role | Actual Status in `8a472fa` | Key Conflicts Identified | Recommended Disposition |
| :--- | :--- | :--- | :--- | :--- |
| `/apps/mobile/lib/core/theme/app_theme.dart` (586 lines) | Active Mobile Design System ("Obsidian Sanctuary") | **Active & Authoritative** (`main.dart:6`) | Exposes legacy `primaryAccent = #EF4444` and `primaryRed = #EF4444` alongside `goldPrimary = #D4AF37`, enabling split-brain screen styling. | **Retain & Harden**: Keep `#070A11`/`#0B0F19`/`#121826` surfaces and `#D4AF37` Championship Gold as primary; restrict `#EF4444` strictly to semantic `error`/`danger`/`live-bout` badges. |
| `/apps/mobile/lib/core/theme/app_theme_final.dart` (201 lines) | Previous "Final" Theme | **Dead / Unreferenced** | Sets `primaryColor: #EF4444` and lacks gold tokens, gradients, and text styles used by current screens. | **Retire & Delete**: Remove during cleanup phase so engineers/agents do not import it by mistake. |
| `/apps/mobile/lib/core/theme/app_theme.dart.new` (203 lines) | Abandoned Theme Draft | **Dead / Unreferenced** | Duplicate of `app_theme_final.dart` with `#EF4444` primary. | **Retire & Delete**: Remove during cleanup phase. |
| `/apps/mobile/lib/core/theme/theme.dart` (4 lines) | Barrel Export (`export 'app_theme.dart'`) | **Active Barrel** | Some files import `theme.dart` while others import `app_theme.dart`. | **Retain or Standardize**: Standardize imports on `app_theme.dart`. |
| `/UI_UX_DESIGN_STATE.md` | Design State Documentation | **Partially Outdated** | Claims 100% completion of unified tokens while `DiscoverScreen` and `RefereeDashboardScreen` still render `#EF4444` Coral Red accents. | **Supersede** with this Master Audit and updated token rules. |
| `/ArmSphere_Current_Repository_Complete_Product_Flow_Master_Spec.md` | Product Flow Specification | **Historical Reference** | Describes intended flows, some of which were stubbed or regressed (e.g., Support Tickets in mobile, H2H mock metrics). | **Use as Domain Reference Only**; rely on verified source + audit roadmap for implementation. |
| `/PHASE13*.md`, `/PHASE14*.md`, `/FINAL_*.md` (24 root files) | Prior AI Session Sign-off Reports | **Historical / Overstated** | Claim "Zero-Defect Sign-Off" despite confirmed crashes (`TournamentOperationsScreen`), HTTP 500s (`PaymentMethodsScreen`), and fabricated data (`HeadToHeadScreen`, `AchievementsSection`). | **Archive to `/docs/archive/`**: Do not treat prior completion claims as authoritative. |

### 6.3 Cohesive Target Product-Wide Design Direction
- **Visual Identity**: **"Obsidian Sanctuary & Championship Gold"** across **both** Mobile and Admin Web:
  - **Surfaces**: Void `#070A11`, Primary Background `#0B0F19`, Elevated Card Surface `#121826`, Glass/Interactive Surface `#1A2234`, Hairline Border `#1E293B`.
  - **Primary Brand & Championship Accent**: Metallic Gold `#D4AF37` (Highlight `#F3E5AB`, Muted `#997A2C`) for primary CTAs, active tabs, championship badges, and ELO highlights.
  - **Semantic Status Tokens Only for Red/Green/Amber/Blue**:
    - Crimson `#EF4444`: Reserved strictly for **Live Table / Bout In-Progress indicators**, **Dispute/Foul alerts**, and **Destructive actions**—never for generic filter chips (`ALL`), `View All` links, or default avatars on `DiscoverScreen` or `RefereeDashboardScreen`.
    - Emerald `#10B981`: Verified clearances, weigh-in pass, completed wins.
    - Amber `#F59E0B`: Pending confirmation, weigh-in pending, provisional ratings.
    - Cobalt `#3B82F6`: Informational telemetry and left-arm comparison series.
  - **Typography**: `Space Grotesk` (headers/titles), `Plus Jakarta Sans` (body/labels), `JetBrains Mono` with `FontFeature.tabularFigures()` (ELO ratings, weight classes, bout timers, foul counters, scorelines).

---

## 7. Confirmed Functional, Data-Integrity & UX Defects (Categorized & Evidence-Graded)

### Category 1: Fabricated / Hardcoded Data & Metric Contradictions

#### F-01: `HeadToHeadScreen` Fabricates Win Rates, Arm ELOs, and Anthropometrics (`Confirmed (Source Only)`)
- **Exact Location**: `/apps/mobile/lib/features/match/screens/head_to_head_screen.dart:157-257` and `/apps/api/src/services/athlete.ts:693-779`.
- **Source Proof**:
  - Lines `173-174` & `224-225`: Sets `'eloRight': elo` and `'eloLeft': elo` to the exact same `eloRating` value because `AthleteService.compareAthletes` (`athlete.ts:724-760`) only returns a single `eloRating` field (`rightArmElo || eloRating || 1500`) and omits `leftArmElo` and `rightArmElo`.
  - Lines `175-176`: Hardcodes `'winRateRight': 75.0` and `'winRateLeft': 70.0` for Athlete 1.
  - Lines `226-227`: Hardcodes `'winRateRight': 72.0` and `'winRateLeft': 68.0` for Athlete 2.
  - Lines `177-181` & `228-232`: Falls back to hardcoded fake measurements (`40.0cm / 42.0cm / 21.0cm / 180.0cm / 80.0kg` for Athlete 1 vs. `41.0cm / 43.0cm / 21.5cm / 182.0cm / 82.0kg` for Athlete 2), causing every Head-to-Head comparison with missing measurements to award fake physical advantages to Athlete 2!
- **Impact**: Completely undermines competitive trust in the Tale of the Tape feature.

#### F-02: Three Contradictory Default ELO Ratings (`1000` vs `1200` vs `1500`) (`Confirmed (Source + Video)`)
- **Exact Locations**:
  1. **Database Schema (`/packages/db-schema/index.ts:60-61`)**: `leftArmElo: integer('left_arm_elo').default(1000).notNull()`, `rightArmElo: integer('right_arm_elo').default(1000).notNull()`.
  2. **Mobile Profile Card (`/apps/mobile/lib/features/athlete/screens/athlete_screens.dart:1243-1244`)**: `ArmSwitchEloCard` falls back to `(data['rightArmElo'] as num?)?.toInt() ?? (data['elo'] as num?)?.toInt() ?? 1200`. Observed in video at `01:36–01:44` where `1200 ELO` is rendered!
  3. **H2H Comparison (`/apps/mobile/lib/features/match/screens/head_to_head_screen.dart:161, 195, 212, 246` & `/apps/api/src/services/athlete.ts:724-725`)**: Both fall back to `1500` ELO!
- **Impact**: An unranked athlete has `1000` ELO in PostgreSQL, sees `1200` ELO on their Profile if `userProfile` fallback is used, and is evaluated at `1500` ELO in Head-to-Head comparisons.

#### F-03: Hardcoded Fake Biometrics (`85kg`, `182cm`, `180cm`), APK Recovery Telemetry (`84%`, `48 kg`), and Achievements (`Confirmed (Source + Video)`)
- **Exact Locations**:
  1. **`_buildBiometricsCard` (`/apps/mobile/lib/features/athlete/screens/athlete_screens.dart:1158-1171` in `8a472fa`)**: Fell back to `'${data['weight'] ?? 85}kg'`, `'${data['height'] ?? 182}cm'`, `'${data['reach'] ?? 180}cm'`. *(Updated in the 27-file pass to render `'—'`, but still impacted by the `AthleteRepository.getProfile` envelope unwrapping bug in `F-11` below).*
  2. **`GRIP LOCK RECOVERY` (`84% READY`, `48 kg` observed in Video at `01:36–01:45`)**: Confirmed as an APK-to-source provenance artifact—already removed from the codebase prior to `8a472fa` (zero occurrences in `apps/mobile/lib`).
  3. **`AchievementsSection` (`/apps/mobile/lib/core/widgets/achievements_section.dart:330-388` in `8a472fa`)**: Ignored `widget.athleteData` and rendered 4 hardcoded achievements (`SUPERMATCH MASTER - MAY 10, 2026`, `2000 ELO CLUB - APR 24, 2026`, `NATIONAL CHAMPION - DEC 18, 2025`, `10 STREAK VICTOR`) for every user. *(Post-implementation note: while `AchievementsSection` now derives achievements from `widget.athleteData`, `AthleteAchievementsScreen` at `athlete_screens.dart:1619` invokes `const AchievementsSection()` with `athleteData: null`, causing `/achievements` and `/athlete/achievements` to display `0 / 4 UNLOCKED` for all users).*

---

### Category 2: Broken Journeys, Runtime Exceptions & Regressions

#### F-04: `TournamentOperationsScreen` Fatal Dropdown Crash & Single/Double Elimination Mismatch (`Confirmed (Source Only)`)
- **Exact Location**: `/apps/mobile/lib/features/tournament/screens/tournament_operations_screen.dart:16-17, 147-180, 252, 273` vs. `/apps/mobile/lib/features/tournament/screens/event_registration_screen.dart:333-373`.
- **Source Proof**:
  - `EventRegistrationScreen` allows athletes to register for division `'MASTERS'` (`line 334`) and weight class `'-78kg'` (`line 369`).
  - `TournamentOperationsScreen` defines `_kDivisions = ['SENIOR', 'JUNIOR', 'FEMALE']` (`line 16`, missing `'MASTERS'`) and `_kWeightClasses = ['-70kg', '-85kg', '-95kg', '+95kg']` (`line 17`, missing `'-78kg'`).
  - When an operator taps "Reassign Division / Weight Class" (`_reassignDialog`, `lines 147-180`) on an athlete registered in `MASTERS` or `-78kg`, `DropdownButtonFormField` receives an `initialValue` not present in `items`, throwing a fatal Flutter assertion exception!
  - Furthermore, `_createBracketDialog` (`line 252`) renders `'Format: Double Elimination Bracket Engine'`, but `line 273` hardcodes `format: 'SINGLE_ELIMINATION'` in the `createBracket` API call!

#### F-05: `PaymentMethodsScreen` Observed HTTP 500 on Load & SetupIntent (`Confirmed (Source + Video)`)
- **Exact Location**: `/apps/mobile/lib/features/settings/screens/payment_methods_screen.dart:24-75`, `/apps/api/src/controllers/payment.ts:171-309`, `/apps/api/src/services/stripe.ts:6-18`.
- **Observed Runtime Evidence vs. Root-Cause Explanation**:
  - **Observed Runtime Failure (`Confirmed in Video at 02:51–03:17`)**: `PaymentMethodsScreen` displays `DioException [bad response]: status code of 500` on initial load (`GET /api/v1/payments/methods`) and `Could not start card setup: DioException [bad response]: status code of 500` when tapping `+ Add New Card` (`POST /api/v1/payments/setup-intent`).
  - **Code-Level Root-Cause Explanation (`Probable / Source-Grounded`)**: In baseline `8a472fa`, `PaymentController.getPaymentMethods` and `createSetupIntent` called `getStripe()` unconditionally (throwing an unhandled error when `STRIPE_SECRET_KEY` is unset/invalid) and required an existing `athleteProfiles` record.
  - **Post-Implementation Audit Finding**: Fake or offline card registration must never be used. While `PaymentController` now returns `200 OK` (`data: [], meta: { paymentConfigured: false }`) on `getPaymentMethods` and `503` (`PAYMENT_PROVIDER_UNAVAILABLE`) on `createSetupIntent`, `PaymentMethodsScreen` does not inspect `meta.paymentConfigured`—so the screen shows `"No saved cards"` and still fails with a red `503` snackbar when the user taps `"+ Add New Card"`.

#### F-06: Regression — In-App Support Ticket System Replaced by Static Email Modal (`Confirmed (Source + Video)`)
- **Exact Location**: `/apps/mobile/lib/features/settings/screens/settings_hub_screens.dart:95, 150-239`.
- **Video & Source Proof**: At `03:18–03:38` in the video, tapping `Support Requests` opened a functional `Support Requests` / `HELPDESK TRIAGE` screen where the user submitted a real ticket (`"Payment error"`). In commit `8a472fa`, `settings_hub_screens.dart:95` called `_showSupportModal(context)`, which only showed a static bottom sheet with `support@armsphere.pk`—leaving `/api/v1/support` (`apps/api/src/routes/support.ts`) and Admin Web's `/support` (`SupportPage.tsx`) orphaned from mobile. *(In the 27-file pass, `SupportRequestsScreen` was added at `/settings/support`, pending `flutter analyze` and runtime verification).*

#### F-07: Redundant & Disconnected Auth/Onboarding Role Selection (`Confirmed (Source + Video)`)
- **Exact Location**: `/apps/mobile/lib/features/auth/screens/welcome_screen.dart:350-352`, `/apps/mobile/lib/features/auth/screens/register_screen.dart:10-75`, `/apps/mobile/lib/core/routing/app_router.dart:164-166`, `/apps/mobile/lib/features/auth/screens/role_intent_screen.dart:29-120`.
- **Source Proof & Post-Implementation Regression Risk**:
  1. In baseline `8a472fa`, `WelcomeScreen` asked the user to select a role (`athlete`, `referee`, `organizer`, `spectator`) and passed `extra: {'role': _selectedRole}` to `/register`, which ignored `extra` completely and forced the user to `/role-intent` (`RoleIntentScreen`) to select their role a second time.
  2. In the 27-file pass, `RegisterScreen` (`register_screen.dart:69-71`) was modified to call `authStateProvider.notifier.setRoleIntent(mappedIntent)` **before** calling `register()`. Because `setRoleIntent()` persists `role_intent_completed = true`, `authState.needsRoleIntent` becomes `false` immediately upon registration, causing `app_router.dart` to bypass `RoleIntentScreen` and **never invoke `applyForRole('REFEREE')` or `applyForRole('TOURNAMENT_OPERATOR')`** for users who chose `referee` or `organizer` on `WelcomeScreen`!

#### F-08: Role-Based Home & Operator Access Mismatches (`Confirmed (Source + Video)`)
- **Exact Locations**:
  1. `/apps/mobile/lib/core/routing/app_router.dart:64-101, 119-123, 194-198`: In `8a472fa`, `_isGovernanceLandingRole` included `'TOURNAMENT_OPERATOR'` and `'SUPPORT_AGENT'`. After the 27-file pass, `'TOURNAMENT_OPERATOR'` routes to `/tournaments`, but `'SUPPORT_AGENT'` **still** remains in `_isGovernanceLandingRole` (`app_router.dart:65, 97`), routing Support Agents to `GovernanceDashboardScreen` (`Arbitration & Disputes`).
  2. `/apps/mobile/lib/features/tournament/screens/tournament_screens.dart:357`: Baseline `TournamentDetailScreen` omitted `'TOURNAMENT_OPERATOR'` from `operatorRoles` (updated in the 27-file pass).
  3. `/apps/mobile/lib/features/tournament/screens/tournament_screens.dart:1-310`: Baseline had no mobile UI to create a tournament (`POST /api/v1/tournaments/events`; a creation dialog was added to `TournamentsListScreen` in the 27-file pass, pending runtime verification).

#### F-09: Split-Brain Accent Styling Across `DiscoverScreen`, `RefereeDashboardScreen` & `SubmitComplaintScreen` (`Confirmed (Source + Video)`)
- **Exact Locations**:
  - `discover_screen.dart:105, 158, 210, 267, 708, 811` (used `AppTheme.primaryAccent` `#EF4444` for filter chips, `View All`, and icons, observed at `00:35–00:46`).
  - `referee_screens.dart:669, 1369, 1498` (used `AppTheme.primaryRed` `#EF4444` for action card icons and athlete search avatars, observed at `01:48–02:01`).
  - `submit_complaint_screen.dart:108-113` (used `AppTheme.primaryAccent` `#EF4444` for the arbitration shield badge).

#### F-10: `AthleteSearchScreen` Rows Render a Chevron With No `onTap` Handler (`Confirmed (Source + Video)`)
- **Exact Location**: `/apps/mobile/lib/features/referee/screens/referee_screens.dart:1492-1530`.
- **Source Proof**: In baseline `8a472fa`, each search result on `/referee/search-athletes` (`AthleteSearchScreen`) was wrapped in an `ElevatedActionCard` with `Icons.chevron_right` at the right edge (`line 1526`), but `onTap` was omitted (`null`). *(Wired to `context.push('/athlete/$athleteId')` in the 27-file pass, pending runtime verification).*

#### F-11: `CommunityFeedScreen` AppBar Horizontal Collision & `AthleteRepository.getProfile` Envelope Unwrapping / Training-Log ID Mismatch (`Confirmed (Source + Video)`)
- **Exact Locations**:
  - `/apps/mobile/lib/features/community/screens/community_feed_screen.dart:56-157`: Observed at `01:08–01:35` in video. The `AppBar` title row + `LIVE FEED` badge + `POST CLIP` CTA overflowed horizontally on 360dp-wide mobile viewports (`COMMUNITY AR...`).
  - `/apps/mobile/lib/core/api/repositories.dart:258-265`, `/apps/mobile/lib/features/athlete/screens/athlete_screens.dart:59-64, 892-894`, and `/apps/api/src/services/community.ts:593-698`:
    - `AthleteController.getProfile` (`apps/api/src/controllers/athlete.ts:175-178`) returns `{ success: true, data: profile }`, and `DioClient` (`dio_client.dart`) does not unwrap response envelopes.
    - `AthleteRepository.getProfile` (`repositories.dart:258-265`) parses `Map<String, dynamic>.from(data)` **without unwrapping `data['data']`**.
    - As a result, `profileAsync.value?['id']` on `AthleteDashboardScreen` (`athlete_screens.dart:60`) and `AthleteProfileScreen` (`athlete_screens.dart:893`) is `null` and falls back to `authState.userProfile['id']` (`users.id`). When `trainingLogProvider(myProfileId)` (`GET /athletes/:id/training-log`) and `trainingLogPRsProvider(myProfileId)` (`GET /athletes/:id/training-log/prs`) are called with `users.id`, `CommunityService.getTrainingLog` (`community.ts:598`) and `getTrainingLogPRs` (`community.ts:648`) query `eq(athleteProfiles.id, athleteId)` and throw `404 NotFoundError("Athlete profile not found")` whenever `users.id !== athleteProfiles.id`!

#### F-12: `ActiveSessionsListScreen` Duplicate Unparsed Session Clutter (`Confirmed (Source + Video)`)
- **Exact Location**: `/apps/mobile/lib/features/session/screens/session_screens.dart:14-229` and `/apps/api/src/services/sessionSecurity.ts`.
- **Video & Source Proof**: Observed at `02:40–02:50` in video. Displayed `1 sessions` in the header badge and 15+ duplicate rows of `Unknown Browser • Unknown... IP: 127.0.0.1` without parsing the Dart/Flutter `User-Agent` or providing a direct "Revoke All Other Sessions" CTA on the list screen itself.

---

## 8. Remaining Evidence Gaps & What Would Resolve Them

To maintain strict epistemic honesty, the following areas were verified in static source (`Confirmed (Source Only)`) but were **not** exercised at runtime in the 228.59-second video recording:
1. **Live Tournament Bracket, Weigh-In, and Table Calling Workflows (`/tournament/:id/operations`, `/tournament/:id/weigh-in`, `/tournament/:id/brackets`)**:
   - *Why uncaptured in video*: The database in the recorded environment returned `0` tournaments (`"No Tournaments Found"` at `00:55–01:07`).
   - *How to resolve during implementation verification*: Seed or create a sanctioned tournament event with `MASTERS` and `-78kg` registrations, run weigh-in, generate brackets, and verify table calling end-to-end.
2. **Head-to-Head (`HeadToHeadScreen`) & Public Athlete Profile (`PublicAthleteProfileScreen`) Runtime Rendering**:
   - *Why uncaptured in video*: Never navigated to during the 228.59-second recording.
   - *How to resolve during implementation verification*: Compare two real athlete profiles via `/matches/head-to-head?athleteId1=...&athleteId2=...` after removing the hardcoded win-rate and anthropometric fallbacks.
3. **Admin Web Console (`apps/admin-web`) Runtime Execution**:
   - *Why uncaptured in video*: The provided recording captures the Android mobile client only; Admin Web was audited via full static source inspection (`App.tsx`, `authorizationPolicy.ts`, and page components).
   - *How to resolve during implementation verification*: Run the Admin Web console against the API and verify all 11 `RoleGuardedRoute` modules.

---

## 9. Prioritized, Dependency-Ordered Remediation Roadmap

To prevent wasted effort (such as polishing screens before fixing underlying data contracts, routing, or theme tokens), implementation MUST proceed in the following **5 dependency-ordered phases**:

### Phase 1: Repository Hygiene, Design System Consolidation & Shared Constants (Foundation)
1. **Archive Root Clutter**: Move the 92+ temporary `_*.txt`/`_*.ps1` debug logs and 24 historical phase reports out of root (delete scratch logs; move historical phase docs to `/docs/archive/`).
2. **Delete Dead Theme Files & Unify Brand Tokens**:
   - Delete unreferenced `/apps/mobile/lib/core/theme/app_theme_final.dart` and `/apps/mobile/lib/core/theme/app_theme.dart.new`.
   - Replace `AppTheme.primaryAccent` / `AppTheme.primaryRed` (`#EF4444`) usage on `DiscoverScreen` (`discover_screen.dart:105, 158, 210, 267, 708, 811`), `RefereeDashboardScreen` (`referee_screens.dart:669, 1369, 1498`), and `SubmitComplaintScreen` (`submit_complaint_screen.dart:108-113`) with `AppTheme.goldPrimary` (`#D4AF37`), restricting `#EF4444` to semantic live/error/destructive states.
   - Align `apps/admin-web/src/index.css` `--primary` token to Championship Gold (`#D4AF37`) so Mobile and Admin Web share one federation identity.
3. **Standardize Canonical Constants Across Backend & Mobile**:
   - Unify default baseline ELO to **`1000`** across PostgreSQL (`db-schema/index.ts`), API (`athlete.ts:724`), `ArmSwitchEloCard` (`athlete_screens.dart:1243`), and `HeadToHeadScreen` (`head_to_head_screen.dart:161`).
   - Extract shared division (`SENIOR`, `JUNIOR`, `MASTERS`, `FEMALE`) and weight class (`-63kg`, `-70kg`, `-78kg`, `-85kg`, `-86kg`, `-95kg`, `+95kg`) constants so `EventRegistrationScreen` and `TournamentOperationsScreen` can never drift out of sync.

### Phase 2: Authentication, Onboarding & Role-Based Routing Architecture
1. **Unify Welcome -> Register -> Role Setup Flow**:
   - Eliminate the duplicate role selection between `WelcomeScreen` (`/welcome`) and `RoleIntentScreen` (`/role-intent`). Pass the selected role intent from `WelcomeScreen` into `RegisterScreen` and `RoleIntentScreen` so the user is never asked to pick their role twice.
2. **Fix Role-Aware Home & RBAC Formatting**:
   - Update `RoleAwareHomeScreen` and `routerProvider.redirect` (`app_router.dart:66-76, 119-121, 192-194`) so `TOURNAMENT_OPERATOR` lands on the Tournament/Operations workspace (`/tournaments`) and `SUPPORT_AGENT` lands on Support/Settings rather than `GovernanceDashboardScreen`.
   - Add `'TOURNAMENT_OPERATOR'` to `operatorRoles` in `TournamentDetailScreen` (`tournament_screens.dart:357`).
   - Complete `_formatRoleName()` and `_roleIcon()` in `AccountRolesScreen` (`account_roles_screen.dart:29-42`) for all 9 RBAC roles.
3. **Canonicalize `app_router.dart` Routes**:
   - Consolidate the 28 duplicate alias `GoRoute` entries in `app_router.dart` into clean canonical routes (using `redirect` for legacy path compatibility rather than duplicating `GoRoute` builder blocks).

### Phase 3: Data Integrity & Removal of Fabricated Telemetry
1. **Fix `HeadToHeadScreen` & `AthleteService.compareAthletes`**:
   - Update `AthleteService.compareAthletes` (`apps/api/src/services/athlete.ts:693-779`) to return real `rightArmElo`, `leftArmElo`, computed right/left win rates from completed matches, and real `athleteMeasurements` / `athleteBiometrics` fields.
   - Remove all hardcoded `75% / 70% / 72% / 68%` win rates and `40cm / 41cm` fake measurements from `head_to_head_screen.dart:173-235`; display `"—"` when an athlete has not recorded a measurement.
2. **Fix `AthleteProfileScreen` Biometrics, Envelope Unwrapping & Achievements**:
   - Unwrap `data['data']` in `AthleteRepository.getProfile` (`apps/mobile/lib/core/api/repositories.dart:258-265`) so `profileAsync.value` exposes top-level profile fields (`id`, `rightArmElo`, `leftArmElo`, `weight`, `height`, `reach`, `matchesPlayed`, `matchesWon`) and passes the true `athleteProfiles.id` to `trainingLogProvider`, `trainingLogPRsProvider`, and `AthleteAchievementsScreen`.
   - Remove fake fallback numbers (`85kg`, `182cm`, `180cm`) in `_buildBiometricsCard` (`athlete_screens.dart:1158-1171`); display `"—"` when null.
   - Pass real athlete profile data into `AchievementsSection` on both `AthleteProfileScreen` and `AthleteAchievementsScreen` (`athlete_screens.dart:1619`).
3. **Fix Training Log & PR Retrieval (`AthleteDashboardScreen`, `AthleteProfileScreen`, `CommunityService`)**:
   - Ensure `GET /api/v1/athletes/:id/training-log` and `GET /api/v1/athletes/:id/training-log/prs` receive the unwrapped `athleteProfiles.id` (and/or allow `CommunityService.getTrainingLog` and `getTrainingLogPRs` in `apps/api/src/services/community.ts:598, 648` to resolve by either `athleteProfiles.id` or `athleteProfiles.userId`) so training logs and PRs never fail with `404 Athlete profile not found`.

### Phase 4: Core Operational Workflows (Tournaments, Referee, Governance)
1. **Fix `TournamentOperationsScreen` Crash & Bracket Engine Selection**:
   - Align `_kDivisions` and `_kWeightClasses` (`tournament_operations_screen.dart:16-17`) with all supported registration divisions/classes (`SENIOR`, `JUNIOR`, `MASTERS`, `FEMALE` and `-63kg`, `-70kg`, `-78kg`, `-85kg`, `-86kg`, `-95kg`, `+95kg`) and guard `DropdownButtonFormField.initialValue` so unknown values never throw an assertion crash.
   - Add a `SINGLE_ELIMINATION` vs `DOUBLE_ELIMINATION` selector in `_createBracketDialog` (`tournament_operations_screen.dart:252, 273`) so the UI label and API payload match.
   - Provide mobile Tournament Creation (`POST /api/v1/tournaments/events`) gated to authorized organizers (`TOURNAMENT_OPERATOR`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`).
2. **Complete Referee Search Navigation & Scorepad Consolidation**:
   - Wire `onTap` on `AthleteSearchScreen` (`referee_screens.dart:1492-1530`) to navigate to `/athlete/:athleteId`.
   - Decide disposition of the unrouted `OfficialScorepadScreen` (`official_scorepad_screen.dart`, 2,358 lines) vs. the routed `MatchSubmissionScreen` (`referee_screens.dart`) so only one authoritative scorepad implementation remains in the codebase.

### Phase 5: Settings, Payments Resilience, Support Restoration & Layout Polish
1. **Restore In-App Support Tickets in Mobile**:
   - Restore `SupportRequestsScreen` (`/settings/support`) wired to `GET /api/v1/support/tickets` and `POST /api/v1/support/tickets` (matching `apps/api/src/routes/support.ts` and the working flow observed in the video at `03:18–03:38`), and route `SUPPORT_AGENT` users to `/settings/support` instead of `GovernanceDashboardScreen`.
2. **Graceful Stripe Payment Availability Handling (No Fake/Offline Cards)**:
   - Ensure `PaymentController` (`apps/api/src/controllers/payment.ts:171-309`) checks Stripe configuration (`Boolean(env.STRIPE_SECRET_KEY)`) and `athleteProfiles` existence before invoking `getStripe()`, returning `meta: { paymentConfigured: false }` on `GET /payments/methods` and HTTP `503` (`PAYMENT_PROVIDER_UNAVAILABLE`) on `POST /payments/setup-intent`.
   - Update `PaymentMethodsScreen` (`payment_methods_screen.dart`) to inspect `meta.paymentConfigured` from `GET /payments/methods`, display an explicit informational banner when online card vaulting is unavailable, and disable/hide the `"+ Add New Card"` action rather than triggering a `503` snackbar.
3. **Session Management & `CommunityFeedScreen` AppBar Polish**:
   - Parse Flutter/Dart `User-Agent` strings in `sessionSecurity.ts` (e.g., `ArmSphere Mobile (Android)`), deduplicate active sessions per device family, and provide a top-level `"Revoke All Other Sessions"` action on `ActiveSessionsListScreen`.
   - Refactor `CommunityFeedScreen` `AppBar` (`community_feed_screen.dart:56-157`) so the title and `LIVE FEED` indicator never collide with `POST CLIP` on narrow screens.

---

## 10. Post-Implementation Verification & Test-Run Addendum

Following the 27-file remediation pass (`25` modified files, `2` deleted dead theme files), an independent, strictly read-only verification audit was executed. **Zero application files were modified during the verification run.**

### 10.1 Automated Check & Test Execution Matrix

| Verification Target | Command Executed | Actual Result | Verification Classification |
| :--- | :--- | :--- | :--- |
| **API Production TypeScript Check (`@armsphere/api`)** | `npm run lint --workspace=@armsphere/api` (`tsc --noEmit`) | **Exit Code `0`** (`0` TypeScript errors) | **Verified (Passed)** |
| **API Automated Test Suite (`@armsphere/api`)** | `./apps/api/node_modules/.bin/vitest run --coverage=false` (in `apps/api`) | **Exit Code `0`**: **`47` test files passed, `721` tests passed, `0` failed** (`16.71s`) | **Verified (Passed)** |
| **Admin Web Production TypeScript Check (`@armsphere/admin-web`)** | `npm run lint --workspace=@armsphere/admin-web` (`tsc --noEmit`) | **Exit Code `0`** (`0` errors on `src/` excluding `src/test`; note `apps/admin-web/tsconfig.json` was modified to add `"exclude": ["src/test"]`) | **Partially Verified** (Production `src/` compiles; `src/test` excluded from `tsc`) |
| **Admin Web Automated Test Suite (`@armsphere/admin-web`)** | `npm test --workspace=@armsphere/admin-web` & cross-runner invocation | **Blocked / Unverified**: `npm test --workspace=@armsphere/admin-web` exits `127` (`sh: 1: vitest: not found`) because `apps/admin-web/node_modules` is not populated; running `apps/api`'s Vite 5 Vitest binary against `apps/admin-web` (Vite 6) fails with missing `jsdom` or `Error: Failed to load url react/jsx-dev-runtime`. | **Unverified — Toolchain / Environment Blocker** (Neither passed nor a confirmed application-code test failure) |
| **Flutter Mobile Static Analysis & Tests (`apps/mobile`)** | `which flutter dart` | **Blocked / Unverified**: Neither `flutter` nor `dart` is installed in the container environment (`Exit Code 1`). | **Unverified — Environment Blocker** |

### 10.2 Summary of Remaining Technical & Environmental Blockers Before Final Sign-Off

No phase or defect in this report is marked as fully closed until the following remaining blockers are resolved and verified:
1. **`AthleteRepository.getProfile` Envelope Unwrapping (`apps/mobile/lib/core/api/repositories.dart:258-265`)**: Must unwrap `data['data']` from `{ success: true, data: profile }` so `AthleteDashboardScreen` and `AthleteProfileScreen` read real top-level fields (`id`, `rightArmElo`, `leftArmElo`, `weight`, `height`, `reach`) and pass `athleteProfiles.id` (instead of `users.id`) to `GET /athletes/:id/training-log` and `GET /athletes/:id/training-log/prs`.
2. **`RegisterScreen` Premature `setRoleIntent()` Call (`apps/mobile/lib/features/auth/screens/register_screen.dart:69-71`)**: Calling `setRoleIntent()` before `register()` sets `needsRoleIntent = false` and bypasses `RoleIntentScreen`'s `applyForRole()` call for `REFEREE` and `TOURNAMENT_OPERATOR` signups.
3. **`SUPPORT_AGENT` Landing Route (`apps/mobile/lib/core/routing/app_router.dart:65, 97`)**: `_isGovernanceLandingRole` still includes `'SUPPORT_AGENT'`, routing Support Agents to `GovernanceDashboardScreen` instead of `/settings/support`.
4. **`AthleteAchievementsScreen` Null `athleteData` (`apps/mobile/lib/features/athlete/screens/athlete_screens.dart:1619`)**: Invokes `const AchievementsSection()` without passing `athleteData`, rendering `0 / 4 UNLOCKED` on `/achievements` and `/athlete/achievements`.
5. **`PaymentMethodsScreen` Unconfigured-Stripe UX (`apps/mobile/lib/features/settings/screens/payment_methods_screen.dart`)**: Does not inspect `meta.paymentConfigured == false` from `GET /payments/methods`, leaving `"+ Add New Card"` active to trigger a `503` error snackbar.
6. **Admin Web Test Runner & `src/test` Typecheck (`apps/admin-web`)**: Requires workspace test dependencies (`vitest`, `jsdom`, `@testing-library/react`) installed for Vite 6 and `"exclude": ["src/test"]` reconciled in `apps/admin-web/tsconfig.json`.
7. **Flutter SDK Availability (`apps/mobile`)**: Requires a CI or local environment with `flutter` / `dart` installed to run `flutter analyze` and `flutter test` across the 18 modified Dart files.

