# ArmSphere — Administrative Capability Inventory

## 1. Classification of Administrative Capabilities Across the Ecosystem

Before converging administrative functionality into the primary Flutter application (`apps/mobile`), every administrative capability across `apps/admin-web`, `apps/api`, and `apps/mobile` was inventoried and classified into five categories:

### Category 1: Fully Implemented in Admin Web & Backend (Converged to Native Flutter)
1. **Executive Dashboard Telemetry (`GET /admin/dashboard/stats`)**:
   - Total registered athletes, pending verifications, active disputes, active tournaments, completed matches, and system health status.
2. **Athlete Identity Review & Lifecycle Management (`/admin/athletes/*`)**:
   - Search and filter athletes by verification status (`PENDING`, `VERIFIED`, `REJECTED`, `SUSPENDED`, `BLACKLISTED`) and province.
   - Verify or reject pending athlete dossiers (`POST /admin/athletes/:id/review`).
   - Suspend (`POST /admin/athletes/:id/suspend`), blacklist (`POST /admin/athletes/:id/blacklist`), or recover (`POST /admin/athletes/:id/recover`) athlete accounts with mandatory audit rationale.
   - Manual biometric and ELO rating override (`PATCH /admin/athletes/:id/correct`).
3. **Referee Corps & Certification Management (`/admin/referees/*` & `/referees/certifications/*`)**:
   - Update referee license grade (`PROVINCIAL`, `NATIONAL`, `INTERNATIONAL`).
   - Update assigned regional coverage provinces (`POST /admin/referees/:id/region`).
   - Suspend referee certification (`POST /admin/referees/:id/suspend`).
   - Issue and revoke per-athlete referee certifications.
4. **Championship Titles, Reign Lineage & Challenges (`/championships/*`)**:
   - List active championship belts (`GET /championships/titles`), create new belts (`POST /championships/titles`), inspect belt lineage history (`GET /championships/titles/:id/lineage`), vacate/strip belts (`POST /championships/vacate`), and accept/decline pending challenges (`POST /championships/challenges/:id/accept` & `/decline`).
5. **Talent Scouting & Nominations Pipeline (`/nominations/*`)**:
   - Filter nominations by status (`PENDING`, `CONTACTED`, `REGISTERED`, `DECLINED`) and province, and advance nominees through the recruitment funnel (`PATCH /nominations/:id/status`).
6. **Federation Analytics & Data Exports (`/analytics/*` & `/admin/reports/export`)**:
   - Match volume trend over time (`GET /analytics/overview`), Left vs. Right arm ELO rating distribution (`GET /analytics/elo-distribution`), and structured dataset exports (`POST /admin/reports/export`).
7. **Arbitration & Dispute Resolution (`/admin/disputes/*` & `/governance/disputes/*`)**:
   - Inspect dispute evidence, issue binding rulings (`RESOLVED_UPHELD` with automatic match winner flip and ELO reversal, or `RESOLVED_OVERTURNED`), and close resolved disputes.
8. **Community Video Moderation Queue (`/community/links/pending` & `/community/links/:id/moderate`)**:
   - Review athlete-submitted external video links (`YOUTUBE`, `TIKTOK`, `FACEBOOK`), preview externally, and approve or reject submissions.
9. **Official Partner Gym Verification (`/venues` & `/venues/:id/verify`)**:
   - Search and filter training venues by province and city, and grant Official Verified Gym Partner status.
10. **Support Helpdesk Triage (`/support/tickets/*`)**:
    - Filter tickets by status, category, and agent assignment; assign/unassign tickets; post public replies or internal staff-only notes; resolve and close tickets.
11. **Cryptographic SHA-256 Audit Ledger (`/admin/audit/events` & `/admin/audit/verify`)**:
    - Searchable immutable audit trail with live SHA-256 hash chain verification.

---

### Category 2: Available in Backend API (`apps/api/src/routes/admin.ts`) & Converged into Native Flutter
1. **Federation Role Applications Review (`GET /admin/roles/applications` & `POST /admin/roles/applications/:id/review`)**:
   - Allows `SYSTEM_ADMIN` and `NATIONAL_DIRECTOR` to approve or reject applications submitted by users from Flutter's `ApplyRoleScreen` (`/settings/roles/apply`).
2. **Direct Federation Role Grant (`POST /admin/roles/grant`)**:
   - Allows `SYSTEM_ADMIN` and `NATIONAL_DIRECTOR` to grant verified roles (with optional provincial jurisdiction) and mandatory audit rationale.
3. **Official Match Score Correction & Voiding (`GET /admin/matches`, `POST /admin/matches/:id/correct`, `POST /admin/matches/:id/void`)**:
   - Allows authorized administrators to inspect completed or disputed bouts, override scores/winners (triggering automatic ELO recalculation), or void compromised matches.

---

### Category 3: Previously Partial in Flutter (`apps/mobile`) — Now Upgraded & Unified
1. **Persona Switching (`AccountRolesScreen` at `/settings/roles`)**:
   - Previously formatted only 6 roles (missing `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `COMPLIANCE_OFFICER`) and did not adapt the 5-tab `MainShellScreen` dock when switching into an administrative persona.
   - **Upgraded**: Supports all 9 federation roles, preserves `ATHLETE` as the personal baseline role so any admin can switch back and forth in Settings, and dynamically transforms the 5-tab Crystal Glass bottom dock when in Admin Mode.
2. **Governance Dispute Screen (`GovernanceDashboardScreen`)**:
   - Previously lived at `/governance` outside `MainShellScreen` (causing the bottom navigation bar to disappear) and only showed basic dispute cards without full admin resolution (`RESOLVED_UPHELD` / `RESOLVED_OVERTURNED`) or the other 10 administrative modules.
   - **Upgraded**: Integrated directly into the 5-tab Admin Mode shell alongside Command, Roster, Arena Ops, Governance, and Dossier.

---

### Category 4: Intentional Retirements (Admin Web Artifacts Excluded from Mobile Product)
1. **Standalone Admin Web Login Screen (`/login` in `apps/admin-web`)**:
   - Replaced by ArmSphere's unified native Flutter authentication and MFA flow.
2. **Raw Server Worker & Cron Triggers (`POST /admin/workers/trigger`, `POST /admin/scheduled-jobs/run`)**:
   - Excluded from the mobile UI to keep the Federation Command Center focused on real sports governance rather than server dev-ops debugging.
