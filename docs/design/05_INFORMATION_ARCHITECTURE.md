# ArmSphere Information Architecture
**Data Hierarchy, Content Distribution & Progressive Disclosure**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Information Distribution Philosophy

A fatal flaw in many sports and enterprise applications is the **"Home Screen Dumping Ground"**—attempting to squeeze every feature, table, bracket, and social feed onto the initial dashboard until it becomes an overwhelming wall of cards.

ArmSphere enforces a disciplined **5-Tier Content Hierarchy**:

```
┌─────────────────────────────────────────────────────────────────┐
│                 5-TIER CONTENT HIERARCHY                        │
├─────────────────────────────────────────────────────────────────┤
│ Tier 1: PRIMARY (Instant Orientation - Top of Home & Tab Roots) │
│ • "Who am I?" (Athlete identity, assigned weight class)         │
│ • "What is my standing?" (Left & Right arm ELO rating)          │
│ • "What is happening now?" (Active match call or live event)    │
├─────────────────────────────────────────────────────────────────┤
│ Tier 2: SECONDARY (Quick Execution - Home shortcuts & feeds)    │
│ • Record Match, Browse Tournaments, Log Lift, Team Roster       │
│ • Recent verified match outcomes (Win/Loss status badges)       │
├─────────────────────────────────────────────────────────────────┤
│ Tier 3: CONTEXTUAL (Targeted Exploration - Deep Tab surfaces)   │
│ • Weight class rankings filter, Double-elimination brackets     │
│ • Community video posts, Gym venue partner directory            │
├─────────────────────────────────────────────────────────────────┤
│ Tier 4: ADVANCED (Detailed Inquiry - Fullscreen Drill-downs)    │
│ • ELO ledger calculation, Belt reign lineage, Training curves   │
│ • Head-to-head match history between two specific athletes      │
├─────────────────────────────────────────────────────────────────┤
│ Tier 5: GOVERNANCE & ADMIN (Protected Operator Surfaces)        │
│ • Weigh-in scale calibration, Table assignments, Arbitration    │
│ • Active device session audit, GDPR account deletion            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Feature Distribution Mapping Across Surfaces

To guarantee every user-facing feature has a clear, non-competing home:

| Product Feature | Designated Surface | Justification & User Mental Model |
| :--- | :--- | :--- |
| **Dual ELO Rating** | Athlete Dashboard (Tab 0) | Core competitive identity. Must be visible within 1 second of app open. |
| **Live Match Callouts** | Home Banner / Referee Dashboard | Urgent operational status. Demands instant, unmistakable focus. |
| **Upcoming Tournaments** | Competitions Tab (Tab 2) | Users intentionally open this tab to plan their competitive schedule. |
| **National Rankings Ladder** | Discover Tab (Tab 1) | Exploration & discovery. Users browse competitors and check rivals. |
| **Global Athlete Search** | Discover AppBar (`/search`) | Search is an exploratory behavior; belongs in the Discovery hub. |
| **Training PR Tracker** | Profile -> Training Log | Self-improvement metric. Secondary to active tournament competition. |
| **Community Video Clips** | Community Tab (Tab 3) | Social leisure. Kept separate from institutional tournament brackets. |
| **Weigh-in & Table Logistics**| Operator Console (`/tournament/:id/operations`)| High-risk operational task; strictly isolated behind operator permissions. |
| **Dispute Arbitration** | Governance Hub (`/governance`) | Formal legal process; separated from casual match browsing. |
| **Active Login Sessions** | Settings -> Security (`/session`) | Critical security audit; housed cleanly in settings vault. |

---

## 3. Progressive Disclosure Architecture

ArmSphere uses a **3-Layer Disclosure Model** to preserve clean visual scanning while providing deep analytical power:

```
                  ┌─────────────────────────────────┐
                  │ Layer 1: GLANCEABLE OVERVIEW    │
                  │ (Card on Dashboard or List Row) │
                  └───────────────┬─────────────────┘
                                  │ Tap to inspect
                                  ▼
                  ┌─────────────────────────────────┐
                  │ Layer 2: STRUCTURED DETAIL      │
                  │ (Fullscreen Dedicated Screen)   │
                  └───────────────┬─────────────────┘
                                  │ Contextual action
                                  ▼
                  ┌─────────────────────────────────┐
                  │ Layer 3: ACTIONABLE CONSOLE     │
                  │ (Modal Bottom Sheet / Dialog)   │
                  └─────────────────────────────────┘
```

### Case Study: Tournament Match Flow
1. **Layer 1 (Glanceable)**: Bracket node displays athlete names, seed numbers, and set score (`3 - 1`).
2. **Layer 2 (Structured Detail)**: Tapping the node opens `MatchDetailScreen`, revealing round-by-round pin times, foul records, referee signatures, and table assignment.
3. **Layer 3 (Actionable Console)**: If the user is the assigned referee, tapping "Officiate" launches the fullscreen `OfficialScorepadScreen` to log live points and pins.

---

## 4. Content Density & Readability Matrix

Different surfaces demand different visual density:

| Surface Type | Density Profile | Touch Target | Typography Size | Background |
| :--- | :--- | :--- | :--- | :--- |
| **Hero Sections** | Low (Cinematic, breathable) | 48dp | 24–32sp bold | Deep gradient with subtle atmosphere |
| **Dashboard Shortcuts**| Medium (2-column grid) | 52dp height | 13sp bold | Semi-transparent card with colored icon pill |
| **Rankings Leaderboard**| High (Compact rows, 64dp) | Full row width | 14sp name, 13sp ELO | Solid dark slate `#0B0F19` with thin border |
| **Interactive Bracket**| High (Grid canvas nodes) | 48dp node | 12sp mono | Dark canvas with dynamic line connectors |
| **Referee Scorepad** | High Ergonomic (Big controls)| **64dp** | 36sp score | High-contrast black with colored button states |
| **Forms & Settings** | Medium (Single column) | 48dp fields | 15sp labels | Elevated surface `#1E293B` |
