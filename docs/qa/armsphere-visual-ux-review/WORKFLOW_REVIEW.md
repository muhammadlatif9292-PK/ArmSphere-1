# ArmSphere Master Workflow Continuity & Journey Audit

**Task Reference**: ARMSPHERE TASK 31 — Contextual Visual & UX Audit  
**Target Repository**: `E:\ArmSphere\`  
**Target Platform**: Android (Physical Device: TECNO_BG6 / Android 13, 720×1612)  
**Evidence Baseline**: Tasks 28–30 (62 Screenshot Captures across 49 Unique Screens)  
**Output Directory**: `E:\ArmSphere\docs\qa\armsphere-visual-ux-review\`  

---

## 1. Executive Summary of Cross-Role Workflows

ArmSphere is designed as an end-to-end combat sports operating system spanning five distinct functional personas: **Athlete**, **Certified Referee**, **Tournament Operator**, **Governance Administrator**, and **Universal Community Member**.

Through our comprehensive visual inventory and interaction testing across 49 unique Flutter screens, this audit traces the complete navigational graph connecting these personas. While individual screens demonstrate high visual craft and thematic coherence (dark gold athletic aesthetic), the transitions between screens frequently suffer from **broken feedback loops**, **dead ends in empty/error states**, **keyboard occlusion in intake funnels**, and **conflicting persona boundary controls**.

This document maps out each primary workflow, identifies critical friction points, and prescribes concrete navigational remedies.

---

## 2. End-to-End Workflow Analysis

```
                                  ARMSPHERE CORE WORKFLOW MAP
                                  
  [Athlete Journey]
  /discover ---------> /tournaments ---------> /events/:id/register ---------> /settings/tickets
          |                                                                            |
          +----------> /matches/head-to-head <--- [Match Callout] <--------------------+
          |                     |
          +----------> /athlete/profile <=====> /athlete/achievements & /athlete/training-log
          
  [Referee Journey]
  /settings/roles ---> /referee/dashboard ---> /referee/search-athletes ---> /referee/submit-scorepad
          ^                   |                                                       |
          |                   +--------------> /referee/upload-evidence <-------------+
          |                   |
          +-------------------+--------------> /referee/certifications
          
  [Operator Journey]
  /home (OPERATOR) --> /tournaments/bracket -> /weigh-in ------------------> /awards
  
  [Governance Journey]
  /governance -------> /governance/dispute/:id <---------------------------- /governance/submit-complaint
  
  [Community & Grassroots]
  /community/feed ---> /community/create & /community/reels
  /venues -----------> /venues/submit
  /informal-events --> /informal-events/create
  /teams ------------> /teams/create
  /nominations/my ---> /nominate
```

---

### Journey A: The Athlete Competition Lifecycle

#### 1. Pathway Steps:
1. **Discovery & Exploration**: Athlete launches onto **Athlete Dashboard** (`S-001`, `/home`), inspects their Left/Right arm ELO rating and the **Sanctioned Arena Radar** banner, or taps Tab 1 **Discover Hub** (`S-007`, `/discover`) to browse featured tournaments and athlete showcases.
2. **Event Selection**: Navigates to **Events & Competitions Hub** (`S-008`, `/tournaments`), reviews tournament cards, filters by sanction level, and taps an event card to view **Tournament Detail** (`S-038`, `/tournament/:id`).
3. **Registration & Entry**: Taps `[Register Now]` to open **Official Event Registration** (`S-044`, `/events/:id/register`), chooses division, weight class, and arm preference, accepts the liability waiver, and completes registration.
4. **Credential Issuance**: Upon completion, the issued registration badge is routed to **Competition Tickets & Passes** (`S-019`, `/settings/tickets`), displaying the digital QR gate pass.
5. **Weigh-In Clearance & Bracketing**: Athlete presents the QR badge at the weigh-in desk (`S-040`, `/weigh-in`). Once cleared, their seed appears in **Live Tournament Brackets** (`S-039`, `/tournaments/bracket`).
6. **Pre-Bout Intel & Sparring**: Athlete compares opponents via **Head-to-Head Comparison** (`S-037`, `/matches/head-to-head`), coordinates via **Match Discussion Chat** (`S-046`, `/messages/:id`), and receives summons via **Notifications Hub** (`S-002`, `/notifications`).
7. **Post-Bout Reconciliation**: Following table-side bout confirmation, the athlete checks official podium standings (`S-041`, `/awards`), inspects updated ELO ratings on **Athlete Passport** (`S-010`, `/athlete/profile`), and views minted cryptographic medals on **Athletic Honors** (`S-011`, `/athlete/achievements`).

#### 2. Friction Points & Defect Observations:
* **The Registration Disconnect**: In `S-044`, the `[Complete Registration]` button is detached from the division selectors by large vertical void space. When the user selects multiple arms, the entry fee calculation fails to update dynamically, forcing the user to submit without financial clarity.
* **The Post-Registration Dead End**: Upon registration completion, the app redirects to the tickets list (`S-019`), which lacks an immediate `[Add to Google Wallet]` or `[View Tournament Schedule]` button. If the user navigates back, they are returned to the empty registration form rather than the tournament details screen.
* **The Bracket Navigation Wall**: In `S-039`, the canvas viewer lacks interactive node taps in loading or unseeded states. Tapping a matchup box does not reveal the `Head-to-Head` preview directly, breaking what should be a seamless scouting loop.

---

### Journey B: The Certified Referee Officiating Workflow

#### 1. Pathway Steps:
1. **Console Activation**: Official switches persona via **Account Roles** (`S-017`, `/settings/roles`) or toggles the `[Official Mode]` switch on **Athlete Passport** (`S-010`, `/athlete/profile`), transforming the primary dashboard into the **Referee Operations Console** (`S-012`, `/referee/dashboard`).
2. **Roster Verification**: Referee searches assigned athletes and verifies weigh-in certificates using **Referee Athlete Search Directory** (`S-028`, `/referee/search-athletes`).
3. **Table-Side Bout Officiating**: Upon calling athletes to the table, referee taps `[Open Scorepad]` to launch **Official Referee Scorepad** (`S-014`, `/referee/submit-scorepad`), tracking fouls, warnings, strap applications, and pin falls in real time.
4. **Result Confirmation & Protest Handling**: Referee confirms the round winner. In the event of a disputed foul or official protest, referee navigates directly to **Referee Evidence Uploader** (`S-016`, `/referee/upload-evidence`) to attach video clips and file an incident statement.
5. **Credential Maintenance**: Referee audits license expiration and accreditation grade via **Referee Certifications** (`S-015`, `/referee/certifications`).

#### 2. Friction Points & Defect Observations:
* **Persona Ambiguity on Passport**: In `S-010`, the `[Official Mode]` switch appears as an arbitrary toggle switch within an athlete card rather than a full app-wide persona role transformation. Toggling it unexpectedly alters Tab 1 of the bottom navigation dock without a clear confirmation banner.
* **High-Stakes Scorepad Ergonomics**: In `S-014`, `[Confirm Winner]` sits immediately adjacent to `[Reset Score]`. Under high-adrenaline arena table conditions, an accidental tap can erase a multi-round match tally without a required confirmation step.
* **Scorepad Exit Trap**: If an official accidentally swipes the Android back gesture while scoring, the screen pops to dashboard immediately without warning that active match scoring data will be lost.

---

### Journey C: The Tournament Operator Command Center

#### 1. Pathway Steps:
1. **Command Console Launch**: Operator activates `TOURNAMENT_OPERATOR` persona, viewing **Arena Operations Command Center** (`S-034`, `/home`).
2. **Desk Administration**: Oversees registrations, monitors the weigh-in queue via **Official Weigh-In Desk** (`S-040`, `/weigh-in`), and verifies division thresholds.
3. **Bracket & Table Seeding**: Generates double-elimination brackets in **Tournament Brackets** (`S-039`, `/tournaments/bracket`) and assigns matches to active table queues.
4. **Ceremony & Medal Awards**: Following championship finals, launches **Awards & Podium Ceremony** (`S-041`, `/awards`), validates podium finishes (Gold, Silver, Bronze), and triggers cryptographic achievement minting.

#### 2. Friction Points & Defect Observations:
* **The Missing Live Queue Surface**: `TournamentOperationsScreen` (`/tournament/:id/operations`) is currently inaccessible unless an active event ID is assigned to the operator in the backend database. Deep-linking results in an unpopulated container, leaving no operator fallback desk.
* **Weigh-In Desk Queue Emptiness**: When the weigh-in queue is clear (`S-040`), the screen renders a generic error card rather than an active scanning standby interface with a `[Scan Athlete QR Code]` button.
* **Podium Ceremony Isolation**: In `S-041`, the `OFFICIAL PODIUM PENDING` state contains a single `[Refresh Results]` button floating in space, with no contextual links to jump back to Table Operations or Brackets.

---

### Journey D: The Governance & Disciplinary Docket

#### 1. Pathway Steps:
1. **Docket Oversight**: Governance official opens **Governance & Arbitration Dashboard** (`S-035`, `/governance`), viewing active disputes, ethical complaints, and eligibility protests.
2. **Case Dossier Examination**: Selects a dispute docket item to view **Dispute Dossier** (`S-045`, `/governance/dispute/:id`), inspecting attached evidence, referee reports, and participant statements.
3. **Formal Complaint Intake**: Athletes or officials submit complaints via **Submit Arbitration Complaint** (`S-036`, `/governance/submit-complaint`).
4. **Ruling Execution & Sanctioning**: Arbitral panel logs final ruling, which updates federation standings and issues public notices on **Federation Bulletins** (`S-047`, `/announcements`).

#### 2. Friction Points & Defect Observations:
* **Technical Error Leakage**: In `S-045`, unauthenticated requests or expired sessions leak raw `[401] Session Expired: Please log in again.` text inside an error card, with an isolated `[Retry]` button that fails in a perpetual loop without re-authenticating.
* **Complaint Filing Keyboard Occlusion**: In `S-036`, the `[Submit Formal Grievance]` CTA is pinned at the very bottom of a long scroll view. While typing detailed violation narratives, the soft keyboard completely occludes the submit button, requiring manual keyboard dismissal to proceed.
* **No Docket Back-Link**: When trapped on an error dossier (`S-045`), there is no button to return to the active cases docket (`S-035`), leaving the user stranded.

---

### Journey E: Settings, Security & Persona Administration

#### 1. Pathway Steps:
1. **Settings Hub**: User taps the gear icon on Athlete Passport (`S-010`) to open **Account & Security Settings Hub** (`S-013`, `/settings`).
2. **Session Auditing**: User inspects active devices in **Security Vault & Active Sessions** (`S-018`, `/session`) and revokes suspicious logins.
3. **Role Management**: User accesses **Account Roles & Persona Selection** (`S-017`, `/settings/roles`), reviews verified grants, switches persona, or taps `[Apply for New Role]` to open **Apply for Federation Role** (`S-033`, `/settings/roles/apply`).
4. **Billing & Passes**: Manages saved payment cards via **Payment Methods & Billing** (`S-026`, `/settings/payment-methods`) and checks tickets via **Tickets Screen** (`S-019`, `/settings/tickets`).
5. **Privacy & Danger Zone**: Blocks users via **Blocked Users** (`S-027`, `/settings/blocked`) and enters **Account Deletion** (`S-032`, `/settings/deletion`) for data purge.

#### 2. Friction Points & Defect Observations:
* **Catastrophic Destructive Proximity**: In `S-018`, `[Revoke All Other Sessions]` is located in the top-right corner of the active devices card, dangerously close to benign navigation elements. In `S-032`, `[Delete Account Permanently]` activates immediately upon typing a phrase without an enforced time delay or biometric re-authentication.
* **Instant Role Switch Disorientation**: In `S-017`, tapping a role card immediately switches the app-wide persona without a confirmation dialogue. If tapped accidentally, the user's dashboard and navigation dock change immediately, causing severe confusion.

---

### Journey F: Community & Grassroots Ecosystem

#### 1. Pathway Steps:
1. **Community Stream & Reels**: User scrolls **Community Feed** (`S-009`, `/community/feed`), watches short-form technique videos via **Vertical Clip Reels Player** (`S-021`, `/community/reels`), or taps `[+]` to open **Post Clip Creation Sheet** (`S-020`, `/community/create`).
2. **Training Venues**: User discovers gyms via **Venues Directory** (`S-048`, `/venues`) or registers a club via **Register Training Venue Intake** (`S-049`, `/venues/submit`).
3. **Grassroots Sparring**: User finds local meetups via **Practice Meetups Directory** (`S-050`, `/informal-events`) or creates one via **Host Practice Meetup Form** (`S-051`, `/informal-events/create`).
4. **Talent Scouting**: Scout tracks prospects in **My Talent Nominations** (`S-052`, `/nominations/my`) or submits a recommendation via **Nominate Talent Form** (`S-053`, `/nominate`).
5. **Team Registration**: Coaches browse squads in **Teams Directory** (`S-054`, `/teams`) or register a squad via **Register New Team Form** (`S-055`, `/teams/create`).

#### 2. Friction Points & Defect Observations:
* **The Dual-Action Antipattern**: Across `S-048` (Venues), `S-050` (Meetups), and `S-054` (Teams), creation is split between a subtle AppBar `(+)` icon and a giant empty-state button (`[Submit Venue]`, `[Host Meetup]`, `[Register Team]`). When items exist, the central button disappears, leaving users hunting for the small top icon.
* **Floating Dock vs FAB Collision**: On `S-009`, the floating post creation `[+]` FAB sits immediately above Tab 3 on the floating glass dock. One-handed thumb reach frequently triggers accidental tab navigation instead of post creation.
* **Form Keyboard Blocker**: On all intake forms (`S-020`, `S-049`, `S-051`, `S-053`, `S-055`), submission CTAs are placed at the bottom of the scroll view and lack keyboard docking, resulting in complete occlusion while typing.

---

## 3. Navigational Dead Ends & Circular Loops Catalog

| Scenario / Screen | Cause | Observed User Impact | Required Navigational Remedy |
|:---|:---|:---|:---|
| **S-043 Championship Titles (401 Error)** | Token expiry returns raw error card with lone `[Retry]` button. | User cannot retry successfully or navigate away without system back gesture. | Add explicit `[Back to Discover]` button and trigger proactive auth refresh. |
| **S-045 Dispute Dossier (401 Error)** | Unauthenticated deep link renders isolated error card. | User is marooned on blank error card with no path to docket. | Add `[Return to Governance Docket]` button. |
| **S-047 Federation Bulletins (Empty State)** | "No active bulletins" text with no actionable controls. | User reaches dead end with no refresh or archive option. | Add `[Refresh Bulletins]` and `[View Archived Rules]` action links. |
| **S-042 Athlete Inbox (Empty State)** | "No conversations yet" card with sparring partner tip but no button. | User prompted to find partners but given no link to search. | Add gold `[Find Sparring Partners]` button linking to `/search`. |
| **S-019 Competition Passes (Empty State)** | "No Active Passes" text with no link to tournament registration. | User has no ticket and no intuitive way to acquire one. | Add `[Browse Sanctioned Events]` button linking to `/tournaments`. |
| **S-020 Post Clip Creation (Modal Sheet)** | Modal dismiss (X) discards user's video and caption without warning. | Accidental tap loses all entered content. | Add `PopScope` with confirmation dialogue: "Discard draft?". |

---

## 4. Cross-Role Navigational Governance Rules

To eliminate friction and ensure seamless role switching, the following architectural rules must be enforced:

1. **Role Switch Confirmation**: Persona switching must never occur upon single-tap card selection. Every role switch must trigger a confirmation sheet indicating the specific toolsets being enabled.
2. **Unified Role Badge in AppBar**: The `[Official Mode]` toggle must be removed from `AthleteProfileScreen` and unified into an AppBar Persona Badge across all screens, allowing verified multi-role users to switch contexts globally.
3. **Uniform Error & Empty State Components**: Raw technical error strings (`[401] Session Expired`) must be prohibited across all screens. All empty and error states must utilize the standardized `FederationErrorCard` featuring a clear message, a retry action, and an escape navigation route.
4. **Sticky Keyboard-Aware Submission Bar**: All intake forms must anchor their primary submit CTA in a sticky bottom container that floats above the software keyboard, providing persistent progress and submit affordances.
