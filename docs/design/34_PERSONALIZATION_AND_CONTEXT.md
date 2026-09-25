# ArmSphere Personalization & Context-Awareness Architecture
**The Dynamic Briefing Model, Proximity Triggers & Contextual Intelligence**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md` & `docs/design/05_INFORMATION_ARCHITECTURE.md`
**Scope**: Dynamic Home Screen (Tab 0) Personalization, Time-of-Day Adaptation, Event Proximity Triggers, and Offline Snapshot Architecture.

---

## 1. The Dynamic Briefing Philosophy (Home Tab 0)

A modern premium athletic application must not greet the user with a static, generic dashboard or a raw chronological social feed. When an athlete or referee opens ArmSphere, the app must demonstrate an acute awareness of:
1. **Who they are** (Persona: Athlete, Referee, Organizer, Spectator).
2. **Where they are in the competitive cycle** (Off-season training, 24 hours before weigh-ins, standing in an arena waiting for Table 3, or post-match recovery).
3. **What time of day it is** (Morning readiness, afternoon gym prep, evening tournament prime-time).
4. **Their critical pending actions** (Weigh-in cut, pending bout challenge, active table assignment).

### The Golden Rule of Home Tab 0:
> "Never dump raw databases or generic feeds on Home. The first viewport must always present the **Single Most Urgent Athletic Context** followed by the user's personal active briefing."

---

## 2. The Dynamic Briefing Engine Architecture

```
[SYSTEM INPUTS]
  ├── Time of Day (Local Handset Clock)
  ├── Active User Role (Athlete, Referee, Operator, Spectator)
  ├── Event Proximity Engine (T-7 Days, T-24 Hours, Day-of-Event, Post-Event)
  ├── Network State (Online vs Fully Offline Cached Snapshot)
  └── Rivalry & Social Graph (Tracked Rivals, Club Teammates)
            │
            ▼
[DYNAMIC BRIEFING CONTROLLER] (Riverpod dynamicHomeBriefingProvider)
            │
            ▼
[DYNAMIC HOME VIEWPORT HIERARCHY]
  1. Top Hero: The Context-Urgent Action Card (e.g. "ON DECK: TABLE 3")
  2. Quick Telemetry Row: ELO Rating, Division Rank, Weight Delta
  3. Actionable Briefing Modules (Customized per Role & Time)
  4. Curated Club & Rival Highlights (On-demand video, zero autoplay)
```

---

## 3. Time-of-Day Adaptive Modes

The dynamic greeting and primary module layout adapt automatically based on the athlete's local time:

### Mode 1: Morning Focus (05:00 – 11:59)
- **Aesthetic Tone**: Crisp, calm, high clarity.
- **Top Greeting**: *"Good morning, [First Name]. Focus on tendon readiness."*
- **Primary Hero Card**: 
  - Off-Season: **Today's Training Target** (e.g. *"Heavy Pronation & Rising Isometric Day — Target: 47.5 kg"*).
  - Tournament Week: **Weight Cut Countdown** (e.g. *"86.2 kg recorded yesterday. 1.2 kg to make Senior 85kg in 3 days."*).
- **Secondary Surface**: Recent recovery notes and upcoming club sparring schedule for the weekend.

### Mode 2: Afternoon Prep (12:00 – 17:59)
- **Aesthetic Tone**: Active, energetic, operational.
- **Top Greeting**: *"Good afternoon, [First Name]. Arena doors open in 3 hours."*
- **Primary Hero Card**: 
  - Tournament Day: **Weigh-In Status Card** (e.g. *"Weigh-In Station Active. Table Marshall Room B. Scale closes at 16:30."*).
  - Training Day: **Club Sparring Roster** (e.g. *"8 pullers confirmed for 18:00 table practice at Iron Arm Club."*).
- **Secondary Surface**: Quick video study of anticipated bracket opponents.

### Mode 3: Evening Competition & Review (18:00 – 04:59)
- **Aesthetic Tone**: Deep arena contrast, gold accents, prime-time focus.
- **Top Greeting**: *"Good evening, [First Name]. Live table action in progress."*
- **Primary Hero Card**: 
  - Tournament Night: **Live Table Telemetry Card** (e.g. *"Table 1: Ontario Open Semifinals — 2 bouts remaining before your division."*).
  - Post-Workout: **Workout Summary & PR Logging Card**.
- **Secondary Surface**: Rival challenge inbox and community sparring highlights.

---

## 4. Event Proximity Lifecycle Triggers

ArmSphere tracks the athlete's registered tournament schedule and shifts the Home Tab 0 layout across four distinct temporal stages:

```
[TOURNAMENT PROXIMITY TIMELINE]
   T-7 Days        T-24 Hours          Day of Event         Post-Event (+24h)
──────┼────────────────┼────────────────────┼───────────────────────┼──────►
  Checklist        Weigh-In Radar      Table Telemetry        Results & ELO
  & Weight Cut     & Bracket Alerts    "On Deck" Pushes       Highlight Reel
```

### Stage 1: T-7 Days to Event (Preparation & Compliance)
- **Hero Module**: **Tournament Compliance Checklist**
  - Item 1: Federation Membership Status (`VERIFIED` in Green).
  - Item 2: Weight Division Declaration (`Senior Men 85kg Right Arm`).
  - Item 3: Digital Waiver & Anti-Doping Consent (`SIGNED`).
  - Item 4: Target Weight Delta Bar: Current logged scale weight vs division ceiling.
- **Action CTA**: `LOG CURRENT SCALE WEIGHT`

### Stage 2: T-24 Hours to Event (Weigh-In & Bracket Radar)
- **Hero Module**: **Weigh-In Operations Card**
  - Official Weigh-In Location & Hours (with Google Maps venue link).
  - Digital Weigh-In QR Pass: One tap generates high-brightness full-screen QR credential for the scale Marshall.
  - Bracket Status Indicator: *"Brackets seeding in progress by Tournament Director. Alert will notify once published."*
- **Action CTA**: `DISPLAY WEIGH-IN QR PASS`

### Stage 3: Day of Event (Live Arena Table Telemetry)
- **Hero Module**: **Real-Time Bout Dispatcher (The "On Deck" Engine)**
  - State A (In Waiting): *"Division: Senior Men 85kg Right Arm. Estimated Start: 13:45 (Table 2)."*
  - State B (On Deck): Bright Coral/Cyan Pulse Card:
    - **"REPORT TO TABLE 3 IMMEDIATELY"**
    - Opponent: Marcus Vance (2,410 ELO).
    - Corner: Corner Red.
    - Official Referee: Senior Ref Latif.
  - State C (In Match): Scorepad mirror showing live point telemetry.
- **Action CTA**: `VIEW TABLE 3 LIVE BRACKET`

### Stage 4: Post-Event (+24 Hours Review & Recovery)
- **Hero Module**: **Tournament Performance Summary**
  - Final Finish Badge: *"Silver Medalist — Senior Men 85kg Right Arm"*.
  - ELO Delta Breakdown: `+38 Rating Points` across 5 bouts (4-1 record).
  - Match Film Reel: Links to recorded bouts for film study.
  - Community Share: One tap generates a high-contrast athletic graphic for Instagram Stories / WhatsApp.
- **Action CTA**: `SHARE TOURNAMENT RECAP`

---

## 5. Role-Based Content Prioritization

Home Tab 0 dynamically reshapes its information architecture depending on which of the 9 roles is active:

| Active Role | Primary Hero Focus | Secondary Focus | Quick Action Bar |
| :--- | :--- | :--- | :--- |
| **Athlete** | Active Bout / Weigh-In Status / PR Target | Club Sparring / Rival Bouts | `LOG LIFT` • `FIND RIVAL` |
| **Referee** | Assigned Table Live Queue / Next Match | Foul History / Rulebook Lookup | `OPEN SCOREPAD` • `TABLE ROSTER` |
| **Tournament Operator** | Arena Table Overview / Bracket Progress | Sanction Status / Payouts | `DISPATCH TABLE` • `ADVANCE SEED` |
| **Provincial Director**| Sanction Applications Pending Review | Regional Club ELO Standings | `REVIEW SANCTIONS` • `AUDIT REFS` |
| **Spectator / Fan** | Top Live Match Stream / Active Supermatch | Regional Rivalry Highlights | `WATCH STREAM` • `VIEW BRACKET` |

---

## 6. Relationship & Rivalry Intelligence

ArmSphere builds a localized athletic relationship graph:
1. **Rivalry Tracker**: Athletes can mark up to 3 rivals as "Tracked Nemeses". Whenever a tracked rival registers for a tournament, logs a PR lift, or accepts a bout, an alert appears in the Home briefing.
2. **Club Roster Activity**: Home surfaces recent PRs and tournament podiums achieved by fellow members of the athlete's registered training club, fostering team camaraderie.
3. **Head-to-Head Reminders**: When browsing a tournament bracket, any competitor the user has previously pulled displays a badge with their historical record (e.g. *"Historical: You lead 2-1"*).

---

## 7. The Offline-Cached Personalized Snapshot

Armwrestling tournaments frequently take place in concrete armories, convention basements, or rural fairgrounds with zero cellular coverage. ArmSphere guarantees that opening the app offline never presents an empty loading spinner or broken UI.

### Offline Snapshot Architecture:
1. **Local Hive Cache**: Every time Home Tab 0 loads with network connectivity, the complete personalized state is serialized to a local Hive box (`cached_home_snapshot_box`).
2. **Offline Launch Behavior**:
   - App loads instantly from local cache (<100ms cold start).
   - An ambient status pill appears below the AppBar: `[OFFLINE MODE — LAST SYNCED 14:15]`.
   - The user sees their current weight class, active tournament division, their next scheduled table assignment, and their QR weigh-in pass without requiring a single byte of internet connectivity.
   - Referees can launch the scorepad directly from this cached state and begin scoring matches immediately; all scorecards queue into the local outbox.

---

## 8. Verification & Non-Contradiction Proof
This personalization specification complies with `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/05_INFORMATION_ARCHITECTURE.md`. It eliminates cluttered home screens, prioritizes urgent athletic contexts, respects battery life by running no ambient background timers, and guarantees full offline usability.
