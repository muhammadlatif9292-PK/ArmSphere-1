# ARMSPHERE — MASTER PROJECT HANDOFF & DAILY WORKFLOW GUIDE
**Target Audience**: Any AI assistant (Antigravity, Claude, GPT, Argon) or Developer taking over this repository.
**Last Updated**: 2026-11-15  
**Active Working Branch**: `feat/aistudio-flutter-sync-v16-20261111`  
**Latest CI Commit**: `cf9c67f` (All 4/4 Workflows 100% GREEN & Release APK/AAB Verified)  
**Pull Request**: PR #17 open against `main`  
**Active Workspaces**: `e:\ArmSphere` (Windows OS / PowerShell)

---

## 🌟 1. EXECUTIVE CONTEXT & FOUNDER VISION

ArmSphere is the premier, world-class competitive arm-wrestling digital ecosystem. The Founder has poured months of dedicated effort, meticulous care, and technical collaboration across multiple frontier AI systems into this project with the help of **ALLAH**.

### Core Tenets of the Project:
1. **Zero Hallucinated Dependencies**: Never import packages not verified in `pubspec.yaml` (e.g., strictly NO `lucide_icons`).
2. **Zero Unwanted Diffs**: Never blindly overwrite screens, revert past bug fixes, or introduce regressions.
3. **Build & CI Invariants**: Never modify Android Gradle Plugin (AGP), Gradle wrappers, compileSdkVersion, or Java versions without explicit necessity.
4. **Visual Prestige (ArmSphere Design Language)**:
   - Machined Titanium specular borders: `AppTheme.machinedTitaniumDecoration()`
   - Pure Crystal Glass surfaces: `CrystalStageScaffold`, `CrystalGlassNavControls`
   - Deep Obsidian recessed wells: `AppTheme.recessedObsidianWellDecoration()`
   - 9:16 Full-Height Championship Stadium backdrops: `VoidStageScaffold` / `CrystalStageBackdrop`
   - Canonical Color Tokens: Primary Gold (`#D4AF37`), Emerald (`#10B981`), Crimson (`#EF4444`), Cyan (`#06B6D4`).

---

## 🏗️ 2. SYSTEM ARCHITECTURE SNAPSHOT

ArmSphere is structured as a monorepo:
* **Mobile Client (`apps/mobile/`)**: Flutter (Dart 3) using Riverpod for reactive state management and GoRouter for declarative routing.
* **Backend API (`apps/api/src/`)**: Node.js / TypeScript REST API built with Express, Zod validation, and Drizzle ORM. Runs on port `4000` (`http://localhost:4000/health`).
* **Shared Database Schema (`packages/db-schema/index.ts`)**: 63 PostgreSQL tables mapped with Drizzle ORM.
* **Database Migrations (`supabase/migrations/`)**: 17 versioned migrations (`0000_...` up to `0016_provincial_jurisdiction.sql`). The next migration is `0017_create_organizations_table.sql`.
* **Tunnel & External Access**: Cloudflare Tunnel (`E:\tools\cloudflared\cloudflared.exe`) running as a daemon, routing public mobile traffic securely to local port `4000` via high-availability QUIC edge nodes (`khi01` - Karachi, `sin12` - Singapore).

---

## 🔄 3. THE DAILY FOUNDER WORKFLOW (STEP-BY-STEP SOP)

This is the standard daily operating procedure whenever the founder tests the app, identifies changes, works with Google AI Studio (Argon), and brings code back into this repository:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DAILY WORKFLOW PIPELINE                         │
│                                                                        │
│  [Founder Tests & Identifies Needs]                                    │
│         │                                                              │
│         ▼                                                              │
│  [Architect Master Prompt for Google AI Studio (Argon)]                │
│         │                                                              │
│         ▼                                                              │
│  [Founder runs in Argon & receives Code / Zip (e.g., 13, 14, 15...)]   │
│         │                                                              │
│         ▼                                                              │
│  [Differential Analysis & Safe Extraction (compare zip vs local repo)]  │
│         │                                                              │
│         ▼                                                              │
│  [Local Code Verification: flutter analyze & npm run build]            │
│         │                                                              │
│         ▼                                                              │
│  [Git Commit & Push to active feature branch]                          │
│         │                                                              │
│         ▼                                                              │
│  [Monitor GitHub Actions CI (4 Workflows) & Auto-Repair Failures]       │
│         │                                                              │
│         ▼                                                              │
│  [Download Production Release Artifacts: APK & AAB]                    │
└────────────────────────────────────────────────────────────────────────┘
```

### Detailed Execution Steps:

### Step 1: Receiving & Inspecting the Argon Zip
* The founder works with Argon in Google AI Studio and downloads a zip file (e.g., `13.zip`, `14.zip`, `15.zip`).
* **NEVER blind-unzip directly over the repository.** Blind unzipping will overwrite working fixes, revert recent improvements, or inject broken imports.
* Extract the zip into a staging directory (e.g., `scratch/argon_stage/`).
* Run a differential comparison script (using Python `difflib` or PowerShell) to categorize files:
  1. *Brand new files*: inspect and copy if clean.
  2. *Modified screens*: perform line-by-line inspection to verify that only intentional changes are adopted, preserving existing bug fixes and design tokens.
  3. *Unwanted diffs*: discard regressions, formatting churn, or accidental rollbacks.

### Step 2: Code Hygiene & Hallucination Checks
Before committing any changes:
1. **Search for Forbidden Imports**: Check all Dart files for non-existent packages like `lucide_icons`. Use Flutter Material Icons (`Icons.*`).
2. **Check Android Files**: Ensure `build.gradle` and `gradle-wrapper.properties` were NOT touched or downgraded.
3. **Verify File Completeness**: Ensure no file is truncated (ends mid-statement) or zero-byte.
4. **Check Role Check Invariants**: Ensure UI visibility checks use `auth.activeRole` and NOT `auth.hasRole()` / `auth.hasAnyRole()`.

### Step 3: Local Verification
Run the following checks from PowerShell:
```powershell
# 1. Analyze Mobile Client
cd e:\ArmSphere\apps\mobile
flutter analyze

# 2. Build Backend
cd e:\ArmSphere\apps\api
npm run build
```
Both must pass with zero compilation errors.

### Step 4: Commit & Push
Use clean conventional commit formatting:
```powershell
cd e:\ArmSphere
git add <specific files>
git commit -m "feat(scope): concise description of functional improvement"
git push origin feat/aistudio-flutter-sync-v16-20261111
```

### Step 5: GitHub Actions CI Monitoring & Automated Repair
ArmSphere enforces 4 continuous integration workflows on every push:
1. **ArmSphere Mobile Flutter Analysis** (`.github/workflows/mobile-flutter-analysis.yml`):
   - Runs Flutter analyzer and 386+ mobile widget/unit tests.
   - Builds production release APK and AAB.
2. **ArmSphere Backend Production Testing CI** (`.github/workflows/backend-production.yml`):
   - Runs 762+ backend tests with PostgreSQL.
3. **ArmSphere Enterprise CI/CD Pipeline** (`.github/workflows/enterprise-cicd.yml`)
4. **ArmSphere Isolated Staging & Real PostgreSQL CI** (`.github/workflows/staging-isolated.yml`)

**Monitoring**:
Monitor the workflow run using `gh run list --branch feat/aistudio-flutter-sync-v16-20261111 --limit 4`.

**Repair Protocol**:
If a workflow fails:
1. Fetch the exact failed step logs via `gh run view <run_id> --log-failed`.
2. Locate the failing test name and file line.
3. Apply the minimal necessary patch (do not refactor unrelated code).
4. Re-commit and re-push. Repeat until all 4 workflows show **SUCCESS (GREEN)**.

### Step 6: Artifact Download
Once CI passes, download the production artifacts:
* `build_output/app-release.apk` (approx. 81-82 MB)
* `build_output/app-release.aab` (approx. 82-83 MB)

---

## 🎯 4. CURRENT ACTIVE INITIATIVE: TOURNAMENT & ORGANIZATION OVERHAUL

The project is currently executing a major architectural overhaul:
**The Tournament, Organization, and Athlete Lifecycle System**.

The complete, battle-tested prompt is saved at:
📄 `C:\Users\USER\.gemini\antigravity\brain\787fd34f-045b-4d47-b1b0-454a027518a1\MASTER_ARCHITECTURAL_PROMPT_ARGON.md`

### Core Components of this Initiative:
1. **Zero-Leak Role Security**:
   - *Bug Root Cause*: In `tournament_screens.dart`, `auth.hasAnyRole(operatorRoles)` checked historical role grants in `userRoleGrants`, allowing users in `ATHLETE` mode to access the "Event Operations Console" card.
   - *Fix*: Mandate `auth.activeRole` check. Implement redirect guards in `app_router.dart` on `/tournament/:id/operations`.
2. **The "Organization" Entity**:
   - Move from individual "Organizers" to "Organizations / Promotions" (e.g., East vs West, King of the Table, WAF, IFA, National Federations).
   - New `organizations` table in Drizzle schema (`packages/db-schema/index.ts`).
   - Migration file: `supabase/migrations/0017_create_organizations_table.sql`.
   - Explore showcase card in `discover_screen.dart` + `OrganizationProfileScreen`.
   - User-facing Organization creation/submission flow.
3. **The Athlete Competition Journey**:
   - Pure competitor dossier in `TournamentDetailScreen` (zero administrative leaks).
   - Category-First visual registration grid (tap to select weight classes/arms).
   - **Athlete Event QR Passport**: Signed QR code in Passport tab (`ArmSphereStageDomain.passport`) and "My Competitions" hub.
4. **The Organization Tournament Studio & War Room**:
   - 5-Step Guided Tournament Creation Wizard in `tournament_operator_dashboard_screen.dart`.
   - 4-Tab War Room in `tournament_operations_screen.dart`:
     * **Tab 1: Rapid-Fire QR Weigh-In Desk**: Scan athlete's QR with phone camera (`mobile_scanner`), auto-verify registration, enter scale weight, submit in 5 seconds.
     * **Tab 2: Bracket Engine**: ELO auto-seeding, manual reorder, double-elimination generation with Grand Final reset match.
     * **Tab 3: Live Table Queue & Dispatcher**: Table-by-table queue, referee dispatch, "CALL TO TABLE" push notification alerts.
     * **Tab 4: Podium Ceremony & Archival**: Auto-compute Gold/Silver/Bronze, lock tournament, distribute ELO points, archive to organization history.

---

## 🛡️ 5. GOLDEN RULES & TECHNICAL LESSONS LEARNED

Keep these critical lessons pinned in memory:

| Domain | Rule / Gotcha | Why It Matters |
|---|---|---|
| **PowerShell** | Use `;` not `&&` to chain commands in PowerShell | PowerShell 5.1 throws parser errors on `&&`. |
| **Auth Roles** | Never use `auth.hasRole()` or `hasAnyRole()` to gate UI visibility | `hasRole()` checks historical `verifiedRoles`, ignoring whether the user switched into `ATHLETE` mode. Use `auth.activeRole == '...'`. |
| **DB Naming** | The table is named `events`, NOT `tournaments` | The backend uses `events` table. Flutter screens say "tournament", but Drizzle queries `events`. |
| **Widgets** | Reuse the 50+ existing tournament widgets | `apps/mobile/lib/features/tournament/widgets/` has `bracket_tree_widget.dart`, `rulebook_accordion_widget.dart`, `important_dates_timeline_widget.dart`, etc. Don't reinvent them. |
| **Camera** | Add `<uses-permission android:name="android.permission.CAMERA" />` | Required for `mobile_scanner` in Android. |
| **Riverpod** | Never declare duplicate providers | A duplicate provider declaration causes analyzer fatal errors and CI failure. |
| **ELO Sort** | Check for arm-specific ELO keys before sorting | When rendering match history or rankings, test fixtures might lack `rightArmElo`/`leftArmElo`. Always guard with fallback. |
| **API Port** | The API server listens on port `4000` | Health check is `http://localhost:4000/health`. |

---

## 🚀 6. INSTRUCTIONS FOR THE NEXT CONVERSATION

When starting a new conversation with an agent:
1. **Instruct the agent**: *"Read `ARMSPHERE_MASTER_HANDOFF_AND_DAILY_WORKFLOW.md` first. Follow our daily SOP for zip integration, diff inspection, and GitHub Actions CI verification."*
2. **Current state**: We are waiting for Argon's implementation of `MASTER_ARCHITECTURAL_PROMPT_ARGON.md` (or the resulting zip/code output).
3. **When the zip arrives**: Apply the 7-step SOP: Staging ➔ Differential analysis ➔ Local analyze ➔ Conventional commit ➔ Push ➔ 4/4 Green CI ➔ APK download.
