# ArmSphere — Native Flutter Administrative Experience Plan

## 1. Product Philosophy: One App, Role-Adaptive Workspaces

ArmSphere's administrative experience is designed from first principles as a native **Titanium Luxe & Crystal Glassmorphic** mobile workspace inside `apps/mobile`—never a WebView or a shrunk desktop spreadsheet.

### Core Experience Pillars
1. **Single Unified Authentication**:
   - All users—whether competing athletes, referees, provincial directors, or system administrators—authenticate through ArmSphere's primary Flutter sign-in, sign-up, and MFA flow.
2. **Settings-Only Persona Switching (`/settings/roles`)**:
   - Users with verified administrative roles switch between their personal **Athlete Mode** and **Admin Mode** exclusively inside **Settings → Account Roles & Persona**.
   - Main headers remain clean and uncluttered; switching roles immediately updates the 5-tab floating Crystal Glass bottom dock and resets navigation cleanly to the active workspace's Home tab (`/home`).
3. **Role-Adaptive 5-Tab Crystal Glass Bottom Dock (`MainShellScreen`)**:
   - **When Active Role = Athlete / Competitor (`ATHLETE`, `REFEREE`, `TOURNAMENT_OPERATOR`, `ORGANIZATION_LEADER`)**:
     1. `Arena` (`/home`)
     2. `Discover` (`/discover`)
     3. `Events` (`/tournaments`)
     4. `Community` (`/community/feed`)
     5. `Passport` (`/athlete/profile`)
   - **When Active Role = Administrator (`SYSTEM_ADMIN`, `NATIONAL_DIRECTOR`, `PROVINCIAL_DIRECTOR`, `COMPLIANCE_OFFICER`, `SUPPORT_AGENT`)**:
     1. `Command` (`/home` → `AdminCommandScreen`)
     2. `Roster` (`/discover` → `AdminRosterScreen`)
     3. `Arena Ops` (`/tournaments` → `AdminArenaOpsScreen`)
     4. `Governance` (`/community/feed` → `AdminGovernanceScreen`)
     5. `Dossier` (`/athlete/profile` → `AdminDossierScreen`)
4. **Searchable Crystal Glass Cards + Root-Overlay Bottom Sheet Action Panels (`CrystalModalSheet`)**:
   - Every list view features a frosted search bar, horizontal status/province filter chips, and high-contrast Crystal Glass cards with tabular numerals.
   - Tapping a card or action button opens a `CrystalModalSheet` rendered in the root overlay above the bottom dock with a **pinned bottom confirmation bar**, keyboard-safe scrolling, and tap-outside-to-unfocus behavior.

---

## 2. Detailed Design of the 5 Native Admin Tabs

### Tab 1: `Command` (`AdminCommandScreen`)
- **Official Authority Banner**: Displays the administrator's name, active federation role chip, jurisdiction scope badge (e.g., `NATIONAL CLEARANCE` or `JURISDICTION: PUNJAB`), and a subtle link to Settings (`Account Roles & Persona`).
- **Actionable Priority Backlog (2x2 Crystal Grid)**:
  - *Pending Verifications* → Deep-links to `Roster → Athletes (PENDING)`
  - *Open Match Disputes* → Deep-links to `Governance → Disputes (OPEN)`
  - *Role Applications* → Opens the Role Applications Review sheet
  - *Partner Gyms & Tickets* → Deep-links to `Governance → Partner Gyms / Helpdesk`
- **Role Applications & Direct Role Grants**:
  - Inspect pending applications (`GET /admin/roles/applications`) and Approve/Reject with review notes (`POST /admin/roles/applications/:id/review`).
  - Open the **Grant Federation Role** `CrystalModalSheet` (`POST /admin/roles/grant`) to assign verified roles and provincial jurisdictions.
- **Ecosystem Telemetry & Data Export Deck**:
  - Visualizes **Match Volume Trend** (`GET /analytics/overview`) and **Left vs. Right Arm ELO Distribution** (`GET /analytics/elo-distribution`) using custom Titanium Luxe bar/sparkline renderers, plus a **Federation Report Export** sheet (`POST /admin/reports/export` for `ATHLETES`, `MATCHES`, `DISPUTES`, `AUDIT` in `CSV` or `JSON`).

### Tab 2: `Roster` (`AdminRosterScreen`)
- **Segmented Crystal Deck**: `[ Athletes ]` • `[ Referees ]` • `[ Scouting ]`
- **Segment 1 — Athletes Registry**:
  - Search by name/ID + filter by status (`ALL`, `PENDING`, `VERIFIED`, `REJECTED`, `SUSPENDED`, `BLACKLISTED`) and province (locked to assigned jurisdiction for `PROVINCIAL_DIRECTOR`).
  - Tapping an athlete opens the **Athlete Regulatory Dossier `CrystalModalSheet`**:
    - *Identity Verification*: Approve (`VERIFIED`) or Reject (`REJECTED`) with mandatory reason.
    - *Manual Biometric & ELO Override*: Correct display name, weight class, province, city, Right ELO, or Left ELO (`PATCH /admin/athletes/:id/correct`) with audit reason.
    - *Referee Certifications*: View, issue (`POST /referees/certifications`), or revoke (`DELETE /referees/certifications/:id`) official certifications.
    - *Disciplinary Sanctions*: Suspend (`POST /admin/athletes/:id/suspend`), Blacklist (`POST /admin/athletes/:id/blacklist`), or Recover (`POST /admin/athletes/:id/recover`).
- **Segment 2 — Referees Corps**:
  - Searchable list of referees (`GET /admin/referees`) showing license level (`PROVINCIAL`, `NATIONAL`, `INTERNATIONAL`) and regional coverage.
  - **Referee Credentials Sheet**: Update license grade (`POST /admin/referees/:id/license`), update regional coverage (`POST /admin/referees/:id/region`), or suspend referee (`POST /admin/referees/:id/suspend`).
- **Segment 3 — Talent Scouting & Nominations**:
  - Pipeline KPI strip (`PENDING`, `CONTACTED`, `REGISTERED`, `DECLINED`) + search and province filters (`GET /nominations`).
  - One-tap status progression (`PATCH /nominations/:id/status`) inside the card or detail sheet.

### Tab 3: `Arena Ops` (`AdminArenaOpsScreen`)
- **Segmented Crystal Deck**: `[ Match Oversight ]` • `[ Belt Titles ]` • `[ Tournaments ]`
- **Segment 1 — Official Match Oversight**:
  - Search and filter official matches (`GET /admin/matches`).
  - **Bout Override & Void `CrystalModalSheet`**: Override winner and scores (`POST /admin/matches/:id/correct` with automatic ELO recalculation) or void a match (`POST /admin/matches/:id/void`) with mandatory audit justification.
- **Segment 2 — Championship Belt Titles & Challenges**:
  - Active championship belts (`GET /championships/titles`) + Pending Challenges queue (`GET /championships/challenges?status=PENDING`).
  - **Create Belt Sheet** (`POST /championships/titles`), **Belt Lineage History Sheet** (`GET /championships/titles/:id/lineage`), **Vacate/Strip Belt Sheet** (`POST /championships/vacate`), and one-tap **Accept / Decline Challenge** actions.
- **Segment 3 — Sanctioned Tournaments & Weigh-In Desk**:
  - Operational overview of tournaments with direct launch into Tournament Creation (`/tournament/create`), Weigh-In Desk, Live Brackets, and Podium Ceremonies.

### Tab 4: `Governance` (`AdminGovernanceScreen`)
- **Segmented Crystal Deck**: `[ Disputes ]` • `[ Moderation ]` • `[ Partner Gyms ]` • `[ Helpdesk ]`
- **Segment 1 — Disputes & Sanctions Docket**:
  - Filter disputes by status (`OPEN`, `UNDER_REVIEW`, `RESOLVED_UPHELD`, `RESOLVED_OVERTURNED`, `CLOSED`).
  - **Arbitration Ruling `CrystalModalSheet`**: Inspect complaint, bout details, and evidence URLs; issue binding ruling (`POST /admin/disputes/:id/resolve` for `RESOLVED_UPHELD` or `RESOLVED_OVERTURNED`) or close resolved dispute (`POST /governance/disputes/:id/close`).
- **Segment 2 — Community Video Moderation Queue**:
  - Pending community video link submissions (`GET /community/links/pending`) with platform (`YOUTUBE`, `TIKTOK`, `FACEBOOK`) and category (`HIGHLIGHTS`, `TUTORIALS`, `GYM`) badges.
  - Native external link launcher + instant `Approve & Publish` or `Reject & Remove` (`POST /community/links/:id/moderate`).
- **Segment 3 — Official Partner Gyms**:
  - Search and filter gyms (`GET /venues`) by province and city; one-tap **Verify Official Gym Partner** (`POST /venues/:id/verify`) respecting Provincial Director jurisdiction locks.
- **Segment 4 — Member Support Helpdesk**:
  - Filter tickets (`GET /support/tickets`) by status, category, and `Assigned to Me`.
  - **Ticket Thread & Resolution `CrystalModalSheet`**: Assign/unassign to self, read conversation history, send public replies or locked **Staff Internal Notes** (`POST /support/tickets/:id/messages`), and Resolve/Close (`PATCH /support/tickets/:id/status`).

### Tab 5: `Dossier` (`AdminDossierScreen`)
- **Official Administrator Credential Passport**: Displays verified role, jurisdiction clearance, and active session security status.
- **Persona Switcher Entry Card**: Prominent Crystal Glass card that opens **Settings → Account Roles & Persona (`/settings/roles`)** so the administrator can switch back to **Athlete Mode** in one tap.
- **Cryptographic SHA-256 Audit Ledger**:
  - Live **Verify Hash Chain Integrity** scanner (`GET /admin/audit/verify`) displaying `VALID` or `TAMPERED` chain status.
  - Searchable, filterable chronological stream of immutable audit events (`GET /admin/audit/events`) with expandable metadata inspection inside a `CrystalModalSheet`.
