# ArmSphere Master Experience Map
**End-to-End User Journey Traces Across Primary Federation Personas**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/20_ROLE_BASED_UX.md` & `docs/design/21_USER_JOURNEY_MAP.md`
**Scope**: Complete Step-by-Step Experience Mapping for Athlete, Referee, Tournament Operator, Spectator, and Club Coach Personas.

---

## 1. Journey Architecture & Trace Methodology

Every interaction in ArmSphere is traced across 8 continuous operational nodes:
```
[ENTRY POINT] ──► [PRIMARY ACTION] ──► [TRANSITION] ──► [RESULT STATE]
       │
       ▼
[FEEDBACK (HAPTIC/AUDIO)] ──► [NOTIFICATION ALERT] ──► [RETURN LOOP]
```

This guarantees zero dead ends, seamless navigation continuity, and full sensory feedback across every user role.

---

## 2. The 5 Core Persona Journey Traces

### Journey 1: The Competitive Athlete (Tournament Matchday)
*User Job: Arrive at arena, clear weigh-in, compete in bracket, review ELO delta, and share podium finish.*

1. **Discovery & Registration**:
   - **Entry Point**: Home Tab 0 > Discover > "Ontario Provincial Championships".
   - **Primary Action**: Tap `REGISTER ATHLETE ($45)` > Select `Senior Men 85kg Right Arm` > Accept Anti-Doping Waiver > Slide to Confirm.
   - **Transition**: Horizontal slide into `TournamentRegistrationSuccessScreen` with animated checkmark.
   - **Feedback**: `HapticFeedback.heavyImpact()` + Success tone.
2. **Weigh-In Clearance**:
   - **Entry Point**: Home Tab 0 dynamic prompt: "WEIGH-IN STATION ACTIVE".
   - **Primary Action**: Tap `DISPLAY WEIGH-IN QR PASS` > Present high-brightness QR code to Scale Marshall.
   - **Transition**: Marshall scans QR and confirms 84.6 kg; screen live-updates with green "OFFICIALLY CLEARED" rubber-stamp animation.
   - **Feedback**: `HapticFeedback.heavyImpact()` on status update.
3. **Table Call ("On Deck")**:
   - **Notification**: High-priority push + full-screen banner: `TABLE 3: YOU ARE ON DECK — LATIF VS JAXON`.
   - **Primary Action**: Tap notification > Opens `LiveTableMatchupView` with Tale of the Tape and table routing directions.
   - **Transition**: Athlete reports to Table 3; referee initiates grip setup.
4. **Bout Execution & Win**:
   - **Match Action**: Referee completes pin; cloud bracket syncs result.
   - **Result State**: `MatchWonCelebrationModal` slides up: "+28 ELO Rating Points" with gold count-up counter.
   - **Feedback**: `HapticFeedback.heavyImpact()` + `match_won.mp3` arena bell.
5. **Podium Crowning & Return Loop**:
   - **Result State**: Athlete wins finals; unlocks `ChampionshipCrowningScreen`.
   - **Return Loop**: Taps `SHARE CHAMPIONSHIP CARD` to export 9:16 story graphic; taps `RETURN TO PROFILE` to view updated trophy cabinet.

---

### Journey 2: The Certified Referee (Table Operations)
*User Job: Receive table assignment, score live bouts, issue warnings/fouls, confirm pins, and advance bracket.*

1. **Shift Login & Assignment**:
   - **Entry Point**: App launch > Tap `ROLE SWITCHER` in header > Toggle to `REFEREE / OFFICIAL`.
   - **Primary Action**: Tap `CHECK IN WITH HEAD OFFICIAL` > Assigned to `Table 2 (Senior Men 90kg)`.
   - **Transition**: Screen switches to `TableStationOverviewScreen` showing live competitor queue.
   - **Feedback**: `HapticFeedback.mediumImpact()`.
2. **Launch Scorepad Controller**:
   - **Entry Point**: Tap `OPEN SCOREPAD (BOUT #14)`.
   - **Transition**: Instant 150ms cross-fade into high-contrast `RefereeScorepadView` with `WakelockPlus` enabled.
   - **Interface**: Corner Red (Latif) vs Corner White (Vance).
3. **In-Match Scoring & Penalties**:
   - **Primary Action**: Competitor elbow leaves pad; referee taps `FOUL RED`.
   - **Feedback**: Instant `HapticFeedback.mediumImpact()`; Foul counter updates to `1/2`.
   - **Strap Applied**: Referee taps `NEUTRAL STRAP APPLIED`; status badge updates to amber "IN STRAPS".
4. **Pin Declaration**:
   - **Primary Action**: Red executes clean top-roll pin; referee presses and holds `CONFIRM PIN` for 400ms.
   - **Transition**: Radial progress ring fills; screen flashes subtle white scrim.
   - **Feedback**: Continuous selection ticks during hold culminating in authoritative `HapticFeedback.heavyImpact()` + `match_won.mp3`.
5. **Next Bout Dispatch**:
   - **Result State**: Result submitted to cloud; scorepad advances to Bout #15 in queue within 1.5 seconds.
   - **Return Loop**: Referee taps `CALL NEXT COMPETITORS TO TABLE` to trigger arena PA and push notifications.

---

### Journey 3: The Tournament Operator (Director & Brackets)
*User Job: Sanction tournament, configure double elimination tree, assign tables, and resolve disputes.*

1. **Tournament Creation & Sanctioning**:
   - **Entry Point**: Federation Workspace > `+ CREATE TOURNAMENT`.
   - **Primary Action**: Enter venue details, sanctioning tier (Provincial Gold), weight divisions, and fee structures > Submit Sanction Application.
   - **Transition**: Sanction moves to `PENDING PROVINCIAL APPROVAL` in amber card.
   - **Feedback**: `HapticFeedback.mediumImpact()`.
2. **Seeding & Bracket Generation**:
   - **Entry Point**: Weigh-ins close > Tournament Dashboard > `SEED BRACKETS`.
   - **Primary Action**: Select `AUTO-SEED BY ELO RATING` or manually drag seeds > Tap `PUBLISH OFFICIAL BRACKET`.
   - **Transition**: 128-athlete double elimination tree renders on interactive canvas with instant table assignments.
   - **Feedback**: `HapticFeedback.heavyImpact()`.
3. **Live Table Monitoring & Load Balancing**:
   - **Entry Point**: `TournamentLiveControlCenterScreen`.
   - **Telemetry View**: Grid of Tables 1 through 6 with active bout durations, referee names, and queue depth.
   - **Action**: Table 4 is running behind; Operator drags Losers Bracket Round 2 to Table 6 to balance flow.
   - **Transition**: Live updates broadcast to all athletes and referees via WebSockets.
4. **Final Standings & Sanction Closure**:
   - **Result State**: Final match concluded; Operator taps `CERTIFY & PUBLISH OFFICIAL RESULTS`.
   - **Return Loop**: Automated rating batch jobs fire; PDF federation report exported; Operator receives digital compliance seal.

---

### Journey 4: The Spectator / Fan (Live Stream & Community)
*User Job: Discover event, watch live table action, follow favorite pullers, and engage in community banter.*

1. **Discovery & Event Entry**:
   - **Entry Point**: Home Tab 0 > Live Banner: "SUPERMATCH SERIES 12 — LIVE NOW".
   - **Primary Action**: Tap event card > Opens `LiveTournamentStreamScreen`.
   - **Transition**: Seamless hero transition into live video view with synchronized bracket telemetry below.
   - **Feedback**: Subtle `HapticFeedback.selectionClick()`.
2. **Athlete Tracking & Bracket Follow**:
   - **Primary Action**: Tap athlete avatar in bracket tree > Opens `AthleteFighterCard`.
   - **Action**: Tap `FOLLOW ATHLETE` (optimistic update to "FOLLOWING").
   - **Feedback**: `HapticFeedback.selectionClick()`.
3. **Community Engagement ("Grip Up")**:
   - **Entry Point**: Post-match highlight clip in Community Feed.
   - **Primary Action**: Double-tap on video clip > Emits glowing amber fist burst.
   - **Feedback**: `HapticFeedback.mediumImpact()`.
4. **Return Loop**:
   - **Notification**: Fan receives alert 10 minutes before favored athlete's finals bout: "Latif is pulling on Table 1 next!"

---

### Journey 5: The Club Coach / Team Leader
*User Job: Monitor squad progress, log team PRs, analyze match film, and schedule club sparring.*

1. **Squad Dashboard Inspection**:
   - **Entry Point**: Profile > `MY CLUB (IRON ARM GUILD)`.
   - **Telemetry View**: Active roster, team collective ELO rating, upcoming tournament entries.
   - **Action**: View squad performance at Ontario Open: 3 Gold, 2 Silver.
2. **Film Study & Sparring Coordination**:
   - **Primary Action**: Tap bookmarked match film > Open `VideoPlayerModal` > Scrub frame-by-frame through referee strap setup.
   - **Action**: Tap `SCHEDULE TABLE PRACTICE` > Set Saturday 14:00 > Push invite to 16 club members.
   - **Feedback**: `HapticFeedback.mediumImpact()`.
3. **Strength Tracking**:
   - **Primary Action**: Coach records new trainee's cupping baseline in club log.
   - **Return Loop**: Trainee profile reflects verified club endorsement badge.

---

## 3. Journey Experience Matrix

| Persona | Primary Metric | Critical Touch Target | Key Audio Asset | Primary Return Loop |
| :--- | :--- | :--- | :--- | :--- |
| **Athlete** | ELO Rating & Weight | 48dp CTA / 64dp QR | `match_won.mp3` | Post-win share card & rankings |
| **Referee** | Table Bout Throughput | 64dp Scorepad / 72dp PIN | `match_won.mp3` | Automatic next-bout dispatch |
| **Operator** | Arena Schedule Adherence| 48dp Seeding Grid | Alert Chime | Certified standings PDF export |
| **Spectator** | Stream Engagement | 48dp Video Controls | Sound Muted | Table alert push notification |
| **Coach** | Team ELO Progression | 48dp Club Roster | `pr_achieved.wav` | Sparring session scheduler |

---

## 4. Verification & Non-Contradiction Proof
This Master Experience Map traces all primary user journeys through the exact 66 screens and 9 roles established in `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/03_SCREEN_INVENTORY.md`. It introduces zero unrouted screens, ensures bidirectional navigation loops, and guarantees tactile/auditory feedback for all critical state changes.
