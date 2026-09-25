# ArmSphere Premium Experience Pattern Library
**Competitive Benchmarking, Pattern Extraction & Sports UX Synthesis**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`
**Scope**: 20 Core UX Categories Benchmarked Across Tier-1 Sports Applications (Nike Run Club, Strava, WHOOP, UFC Mobile, Formula 1) and Adapted for Armwrestling Federation Realities.

---

## 1. Executive Benchmarking Methodology

To ensure ArmSphere achieves world-class athletic credibility without falling into generic "AI dashboard" traps or misaligned fitness clichés, we benchmark five premier sports and athletic applications. 

### Benchmark Applications Analyzed:
1. **Nike Run Club (NRC)**: Gold standard for typography-driven emotional coaching, celebratory post-workout feedback, and bold athletic punchiness.
2. **Strava**: Premier reference for community competition, segment leaderboards, personal records (PRs), and social recognition feeds.
3. **WHOOP**: Benchmark for high-density physiological and recovery data presentation, dark-mode data visualization, and minimalist restraint.
4. **UFC Mobile**: The definitive combat sports reference for tale-of-the-tape athlete comparisons, bracket ladders, weight-cut tracking, and bout outcome graphics.
5. **Formula 1 (F1 App)**: Benchmark for live telemetry, split-second timing boards, high-contrast operational status cards, and multi-tier session tracking.

### Evidence Classification Legend:
- `[SOURCE-GROUNDED]`: Derived from verified Flutter/Riverpod contracts in `apps/mobile` or PostgreSQL schema in `packages/db-schema`.
- `[REFERENCE-GROUNDED]`: Synthesized from tier-1 benchmark UI principles adapted to ArmSphere's design tokens.
- `[PRODUCT-DERIVED]`: Required by physical armwrestling rules, referee table operations, or tournament hall realities.
- `[EXPERIMENTAL]`: Novel interaction pattern requiring real-device testing in training clubs.

---

## 2. The 20 Core Experience Pattern Specifications

### Category 1: Profile / Fighter Card
- **Benchmark Reference**: UFC Mobile Fighter Profile & WHOOP Strain Card. UFC provides dramatic high-contrast athlete cutouts with weight division headers; WHOOP provides austere, typography-first metrics.
- **Extracted Principle**: The athlete is the hero. Numbers must feel hard-earned. Avoid corporate LinkedIn-style cards; use bold athletic stance, division badges, and dominant grip/style stats.
- **ArmSphere Adaptation**:
  - Top Hero: Athlete portrait with 4-stop radial gradient scrim fading into `#0B0F19`.
  - Stance Banner: Dominant Hand (`RIGHT`, `LEFT`, or `DUAL-PULLER`) and Preferred Technique (`TOP-ROLL`, `HOOK`, `PRESS`, `OUTSIDE-PULL`) displayed in monospace `SpaceGrotesk` with high-contrast pills.
  - Vital Combat Stats: Biceps circumference, forearm girth, wrist diameter, grip dynamometer PR, official ELO rating (`2450 ± 18`), and official WAF/IFA weight class (`Senior Men 85kg`).
- **Anti-Patterns to Avoid**:
  - Generic circular avatar with centered bio text and social media icons.
  - Blurry AI-generated fighter graphics with neon borders.
  - Squeezing win/loss pie charts that require horizontal panning.
- **Concrete Flutter Implementation**:
  - Widget: `AthleteFighterCard` using `SliverAppBar` with `FlexibleSpaceBar` and `Stack`.
  - State: `athleteProfileProvider(userId)`.
  - Contrast: WCAG AAA 18.2:1 text on `#0B0F19` canvas. `[REFERENCE-GROUNDED]`

---

### Category 2: Live Scorepad / Match Controller
- **Benchmark Reference**: F1 Timing Screen & Boxing Digital Corner Clock.
- **Extracted Principle**: Ergonomic invulnerability under stress. High-contrast, giant touch targets, single-action operation, and immediate tactile confirmation without needing to look at the screen.
- **ArmSphere Adaptation**:
  - Screen split into two symmetrical combatant zones: Corner Red (`#EF4444`) vs Corner White/Cyan (`#38BDF8`).
  - Scorepad Buttons: 64×64dp minimum hit zones for `POINT`, `WARNING`, `FOUL`, and `SLIP/STRAP`.
  - Pin Declaration: Long-press gesture (400ms) with circular filling progress indicator and `HapticFeedback.heavyImpact()` to prevent accidental match termination.
  - Chalk/Sweat Tolerance: High-contrast borders (2px `#334155`), zero delicate sliders or swipe-to-confirm elements.
- **Anti-Patterns to Avoid**:
  - Small 32dp icons in a top corner.
  - Confirmation popups asking "Are you sure you want to award a foul?" during live action.
  - Dropdown selectors to change points.
- **Concrete Flutter Implementation**:
  - Widget: `RefereeScorepadView` inside `WakelockPlus` wrapper to prevent screen timeout.
  - State: Local Hive outbox synced via `matchScoreNotifierProvider`.
  - Key constraint: Zero layout shifts during point increment. `[PRODUCT-DERIVED]`

---

### Category 3: Bracket / Elimination Tree
- **Benchmark Reference**: UFC Tournament Tree & Battlefy Esports Bracket.
- **Extracted Principle**: Spatial navigation must feel infinite and buttery, while allowing instant focus on the active match and personal progression path.
- **ArmSphere Adaptation**:
  - Double Elimination Support: Instant toggle between `WINNERS BRACKET`, `LOSERS BRACKET`, and `SUPERMATCH CARDS`.
  - Interactive Canvas: Two-dimensional smooth panning with snap-to-round columns.
  - Active Bout Highlighting: Luminous cyan outline (`#38BDF8`) pulsing at 0.5Hz with live table assignment ("Table 3 — Next Up").
  - Athlete's Own Path: Subtle gold marker trail highlighting the user's trajectory through the rounds.
- **Anti-Patterns to Avoid**:
  - Rendering 256 HTML nodes on a single canvas causing memory crashes.
  - Tiny unreadable text that forces aggressive pinch-to-zoom just to read competitor names.
- **Concrete Flutter Implementation**:
  - Widget: `InteractiveViewer` with `CustomPainter` rendering connecting bezier lines.
  - Virtualization: Only render visible match cards in current viewport bounds.
  - Package: Custom lightweight render object over raw Flutter canvas. `[SOURCE-GROUNDED]`

---

### Category 4: Ranking / Leaderboard
- **Benchmark Reference**: Strava Segment Leaderboards & F1 Drivers' Championship.
- **Extracted Principle**: Contextual hierarchy. Athletes don't just want to see #1 to #3; they want to know their exact gap to the person above them and their defense against the person below them.
- **ArmSphere Adaptation**:
  - Top 3 Podium Cards: Elevated cards with Champagne Gold (`#D4AF37`), Silver (`#94A3B8`), and Bronze accents.
  - Sticky Anchor Bar: The logged-in athlete's ranking row is permanently pinned at the bottom of the viewport (`Position #42 • 1,840 ELO • +24 this month`).
  - Division & Arm Filtering: Instant horizontal chip bar (`RIGHT ARM`, `LEFT ARM`, `OVERALL`, `MASTERS`, `SENIOR 85KG`).
- **Anti-Patterns to Avoid**:
  - Squeezing a 7-column desktop spreadsheet with scroll bars onto a 360dp phone screen.
  - Generic pagination buttons (Page 1, 2, 3) instead of smooth infinite scrolling with index jumping.
- **Concrete Flutter Implementation**:
  - Widget: `CustomScrollView` with pinned bottom `AthleteRankingStickyBar`.
  - State: `rankingsProvider.select((s) => s.currentTier)`. `[REFERENCE-GROUNDED]`

---

### Category 5: Training Log / PR Tracker
- **Benchmark Reference**: WHOOP Strain & Recovery Journal & Stronglifts 5×5.
- **Extracted Principle**: Focus on physical progression and mechanical specificity. Armwrestling strength is measured in kilograms on cupping, pronation, rising, and backpressure.
- **ArmSphere Adaptation**:
  - Mechanical Exercise Taxonomy: Cupping (Wrist Flexion), Pronation through Thumb, High Cable Rise, Hammer Backpressure, Side Pressure Static Lock.
  - Visual PR Spike: When a new 1RM is logged, display a sharp upward trajectory spike with `pr_achieved.wav` audio trigger and gold numeric callout.
  - Velocity/Angle Notation: Optional strap angle and pulley height tags.
- **Anti-Patterns to Avoid**:
  - Treating armwrestling training like standard bodybuilding (sets of 12 bench press).
  - Vague effort sliders ("Rate workout 1-10") without quantifiable load metrics.
- **Concrete Flutter Implementation**:
  - Widget: `TrainingLogEditor` with custom numpad input for rapid kg entry.
  - State: `trainingLogNotifierProvider`. `[PRODUCT-DERIVED]`

---

### Category 6: Challenge / Matchmaking Flow
- **Benchmark Reference**: Chess.com Live Challenge & UFC Matchup Reveal.
- **Extracted Principle**: Tension and mutual respect. A challenge is a duel agreement with specific stakes (rules, weight, table location, referee verification).
- **ArmSphere Adaptation**:
  - Split Card Presentation: Challenger on left, Target opponent on right, separated by a sharp diagonal slash with ELO delta (`+32 / -18`).
  - Bout Contract Parameters: Arm (`RIGHT` / `LEFT`), Format (`Best of 3`, `Best of 5`), Sanction Level (`Official Rated`, `Club Sparring`), Table Location.
  - Acceptance State: Dual-lock slider requiring 1.2s slide to prevent accidental acceptance.
- **Anti-Patterns to Avoid**:
  - Simple modal popup saying "John invited you to a match. [Yes] [No]".
  - Missing rule parameters that lead to disputes at the table.
- **Concrete Flutter Implementation**:
  - Widget: `ChallengeNegotiationScreen` with animated slider confirmation.
  - Sound: `challenge_accepted.wav` on mutual lock. `[SOURCE-GROUNDED]`

---

### Category 7: Onboarding / Persona Selection
- **Benchmark Reference**: Nike Training Club Onboarding & Strava Sport Onboarding.
- **Extracted Principle**: Progressive calibration without friction. Ask only what directly changes the application experience immediately.
- **ArmSphere Adaptation**:
  - 3-Step Guided Setup:
    1. Primary Persona: `ATHLETE`, `REFEREE / OFFICIAL`, or `FAN / SPECTATOR`.
    2. Physical Profile: Dominant Pulling Arm, Weight Class, Pulling Style.
    3. Club & Region: Local Federation / Province / Club affiliation.
  - Visual Feedback: Animated athletic posture illustration adapting in real-time as choices are tapped.
- **Anti-Patterns to Avoid**:
  - 10-step multi-page form demanding address, credit card, and national ID during initial app launch.
  - Unskippable 60-second video introductions.
- **Concrete Flutter Implementation**:
  - Widget: `PageView` with smooth indicator pills, wrapped in `OnboardingController`.
  - Storage: Flags saved locally to Hive before cloud sync. `[REFERENCE-GROUNDED]`

---

### Category 8: Discovery / Search & Filter
- **Benchmark Reference**: F1 Calendar & Spotify Search Grid.
- **Extracted Principle**: Fast, multi-faceted filtering with instant zero-state suggestions.
- **ArmSphere Adaptation**:
  - Unified Search Bar: Single entry point parsing athletes, tournaments, training clubs, and official rulebooks.
  - Quick Filter Pills: `TOURNAMENTS THIS WEEKEND`, `VERIFIED CLUBS NEAR ME`, `TOP 10 RANKED`, `REFEREE CLINICS`.
  - Location Radius: Visual distance slider (25km, 50km, 250km, Nationwide).
- **Anti-Patterns to Avoid**:
  - Multiple disconnected search bars in different tabs.
  - Resetting filter state when navigating into a tournament detail and pressing back.
- **Concrete Flutter Implementation**:
  - Widget: `DiscoverScreen` with sticky `SliverPersistentHeader` search bar.
  - Debounce: 300ms on text input using Riverpod `family` providers. `[SOURCE-GROUNDED]`

---

### Category 9: Community Feed / Post Card
- **Benchmark Reference**: Strava Athlete Feed & Instagram Athletic Reels.
- **Extracted Principle**: High-signal sport content. Armwrestlers share table practice footage, strap technique breakdowns, and tournament podium photos.
- **ArmSphere Adaptation**:
  - Media First: High-contrast 4:5 image cards or video thumbnails with play badge.
  - Video Safety: Strictly on-demand playback via `VideoPlayerModal`; no battery-draining autoplay.
  - Technical Badges: Post author tagged with official division (`Senior Men 90kg`) and Club badge.
  - Interaction Bar: Respectful athletic interactions (`GRIP UP` instead of generic heart, `COMMENT`, `SHARE RECORD`).
- **Anti-Patterns to Avoid**:
  - Generic social feed with autoplay videos, endless meme spam, and tiny unreadable text.
  - Unbounded nested comment trees that break screen borders.
- **Concrete Flutter Implementation**:
  - Widget: `CommunityPostCard` with cached network image and pre-computed aspect ratios.
  - State: `communityFeedNotifierProvider`. `[REFERENCE-GROUNDED]`

---

### Category 10: Federation / Governance Dashboard
- **Benchmark Reference**: Stripe Dashboard Mobile & F1 FIA Steward Portal.
- **Extracted Principle**: Uncompromising administrative clarity. Legal compliance, referee certification expirations, sanctioning fees, and anti-doping records require zero ambiguity.
- **ArmSphere Adaptation**:
  - Role-Switching Pill: Instant toggle between Athlete view and Official Governance portal.
  - Sanction Queue: Color-coded status rows (`PENDING APPROVAL` in amber `#F59E0B`, `SANCTIONED` in green `#10B981`, `INSPECTION REQUIRED` in coral `#FF5252`).
  - One-Tap Table Roster: Provincial directors see active tables and referee assignments across all venues.
- **Anti-Patterns to Avoid**:
  - Burying official governance features in an external web view with tiny desktop buttons.
  - Lack of audit logging when approving tournament sanctions.
- **Concrete Flutter Implementation**:
  - Widget: `FederationWorkspaceView` protected by `roleGuardProvider`.
  - Tables: Custom horizontally scrollable data card rows with fixed frozen column. `[SOURCE-GROUNDED]`

---

### Category 11: Notification Center / Inbox
- **Benchmark Reference**: Apple Fitness Notification Tray & GitHub Mobile Inbox.
- **Extracted Principle**: Actionable grouping. Notifications must be categorized by operational urgency rather than a chronological pile.
- **ArmSphere Adaptation**:
  - 3 Clear Buckets:
    1. `MATCH ALERTS` (Table call, weigh-in open, bout ready) — Pinned to top with high-contrast coral/cyan badge.
    2. `CHALLENGES & ELO` (Bout challenges, rank shifts).
    3. `COMMUNITY & CLUB` (Sparring session scheduled, comment replies).
  - Direct Action Buttons inline: `ACCEPT BOUT`, `VIEW TABLE`, `CHECK IN`.
- **Anti-Patterns to Avoid**:
  - Unclear notifications like "You have a new update!" that require navigating 3 screens to understand.
  - Notification dots that never clear.
- **Concrete Flutter Implementation**:
  - Widget: `NotificationInboxScreen` with dismissible slide-to-archive actions.
  - State: `notificationListProvider`. `[REFERENCE-GROUNDED]`

---

### Category 12: Event / Tournament Detail
- **Benchmark Reference**: UFC Fight Card Screen & CrossFit Games Event Guide.
- **Extracted Principle**: Chronological narrative of the tournament day. Athletes need to know weigh-in times, venue rules, bracket start times, and table assignments.
- **ArmSphere Adaptation**:
  - Top Hero: Venue photo with dark arena scrim, dates, city, and federation sanction seal.
  - Action Sticky Bar: "REGISTER ATHLETE ($45)" or "WEIGH-IN STATUS: CLEARED" depending on user state.
  - Live Table Telemetry: Current active bouts on Table 1, Table 2, Table 3 with live scores.
  - Division Tabs: Instant switching between Left Arm and Right Arm weight brackets.
- **Anti-Patterns to Avoid**:
  - Cluttered 3000-word text documents pasted into a scroll view.
  - Hidden registration buttons below unformatted PDF schedule tables.
- **Concrete Flutter Implementation**:
  - Widget: `TournamentDetailScreen` using nested `CustomScrollView` with tabbed `SliverList`.
  - State: `tournamentDetailProvider(tournamentId)`. `[SOURCE-GROUNDED]`

---

### Category 13: Athlete Comparison / Head-to-Head
- **Benchmark Reference**: UFC Tale of the Tape & F1 Teammate Head-to-Head.
- **Extracted Principle**: Symmetrical confrontation. Two pullers compared across physical dimensions, stylistic matchups, and historical head-to-head records.
- **ArmSphere Adaptation**:
  - Split Portrait Visual: Challenger Left vs Opponent Right.
  - Tale of the Tape Metric Bars:
    - Arm Length & Reach (cm)
    - Forearm Girth (cm)
    - Biceps Circumference (cm)
    - Grip Dynamometer Max (kg)
    - Historical H2H Record (e.g., "Latif leads 3-1")
    - ELO Rating comparison with colored differential bar.
- **Anti-Patterns to Avoid**:
  - Plain textual table without visual comparison bars.
  - Unbalanced layouts that favor one athlete aesthetically.
- **Concrete Flutter Implementation**:
  - Widget: `HeadToHeadComparisonView` with animated horizontal bar meters (`TweenAnimationBuilder`).
  - Contrast: Standardized `#1E293B` metric tracks with `#38BDF8` and `#EF4444` fills. `[REFERENCE-GROUNDED]`

---

### Category 14: Analytics / Progress Charts
- **Benchmark Reference**: WHOOP Trends View & Strava Power Curve.
- **Extracted Principle**: High-density clarity. Armwrestlers track isometric tendon strength, recovery periods, and ELO rating trajectories over years.
- **ArmSphere Adaptation**:
  - ELO Progression Chart: Continuous smooth line chart with win/loss dots and major tournament milestone flags.
  - Metric Toggle: Switch between `ELO RATING`, `CUPPING 1RM`, `PRONATION 1RM`, and `WIN RATE %`.
  - Time Filters: `1M`, `3M`, `1Y`, `ALL-TIME`.
  - Scrubbing Tooltip: Drag finger across chart to inspect specific date, opponent, and score delta.
- **Anti-Patterns to Avoid**:
  - Generic bar charts with cartoonish rounded bars and rainbow colors.
  - Cluttered axis labels that overlap on narrow screens.
- **Concrete Flutter Implementation**:
  - Widget: Custom `RepaintBoundary` canvas chart or `fl_chart` configured with strict ArmSphere palette (`#38BDF8` line, `#D4AF37` PR markers, `#121826` grid).
  - Performance: Zero frame drops during horizontal touch scrubbing. `[PRODUCT-DERIVED]`

---

### Category 15: Form Submission / Multi-Step Wizard
- **Benchmark Reference**: Stripe Checkout Flow & Nike Member Registration.
- **Extracted Principle**: Zero cognitive overload, zero lost state, and absolute keyboard ergonomics.
- **ArmSphere Adaptation**:
  - Tournament Registration & Sanction Applications: 3 distinct steps with animated breadcrumb progress bar at top.
  - Sticky Action Bar: Floating submit button anchored above system navigation/keyboard.
  - Keyboard Avoidance: Automatic scroll-to-active-field with 80dp bottom padding.
  - Local Draft Caching: Every keystroke cached in Hive; app closure never loses entered weigh-in or match data.
- **Anti-Patterns to Avoid**:
  - Giant 20-field vertical forms that hide the submit button below the fold.
  - Losing all entered data when the screen rotates or a phone call interrupts.
- **Concrete Flutter Implementation**:
  - Widget: `TournamentRegistrationWizard` with `Form` and Riverpod `autoDispose` state with Hive draft persistence. `[SOURCE-GROUNDED]`

---

### Category 16: Empty State / Cold Start
- **Benchmark Reference**: Strava Empty Activity Feed & GitHub Mobile Blank Slate.
- **Extracted Principle**: An empty state is not a dead end; it is an invitation to athletic action.
- **ArmSphere Adaptation**:
  - Empty Training Log: High-contrast athletic grip silhouette with prompt: "No lifts recorded this week. Log your first cupping or pronation session to establish your baseline." CTA: `+ LOG FIRST LIFT`.
  - Empty Challenge Tray: "No pending challenges. Search your local club roster or issue an open challenge to pullers in your division." CTA: `FIND RIVALS`.
  - Empty Tournament Schedule: "No upcoming sanctioned tournaments in your province. Explore regional events or view referee clinics." CTA: `EXPLORE CALENDAR`.
- **Anti-Patterns to Avoid**:
  - Blank white screens with a sad face emoji or "Nothing here yet!".
  - Generic unstyled text without actionable CTAs.
- **Concrete Flutter Implementation**:
  - Widget: `ArmSphereEmptyState` component with customized SVG line icon, headline, subtext, and primary action button. `[REFERENCE-GROUNDED]`

---

### Category 17: Error State / Recovery Flow
- **Benchmark Reference**: Apple App Store Retry & F1 Telemetry Reconnect.
- **Extracted Principle**: Dignified resilience. Never blame the user; explain the breakdown in plain athletic language and provide a single-tap resolution.
- **ArmSphere Adaptation**:
  - Venue Connection Loss: "Tournament Network Disrupted. Your score entries are signed and safely queued in local storage. They will sync automatically once signal returns." Action: `RETRY SYNC NOW`.
  - Concurrency Conflict: "Match Score Divergence. Another official updated Table 2. Review the verified timestamps to resolve the discrepancy." Action: `RESOLVE WITH HEAD REFEREE`.
- **Anti-Patterns to Avoid**:
  - Raw JSON exceptions or `HttpException: 500 Internal Server Error`.
  - Trapping the user with an unclosable error alert modal.
- **Concrete Flutter Implementation**:
  - Widget: `ArmSphereErrorView` with fallback error boundary and retry callback. `[PRODUCT-DERIVED]`

---

### Category 18: Offline Banner / Sync Indicator
- **Benchmark Reference**: Google Maps Offline Bar & Spotify Download Indicator.
- **Extracted Principle**: Ambient, non-panicking transparency. Table-side referees must know their connectivity status at a glance without interrupting their scoring flow.
- **ArmSphere Adaptation**:
  - Ambient Pill: 24dp compact pill below AppBar with amber dot (`#F59E0B`) and text: "OFFLINE MODE — 4 ACTIONS QUEUED".
  - Tap Behavior: Expands into a lightweight bottom sheet listing pending queue items with timestamps.
  - Reconnect Event: Dot turns emerald green (`#10B981`) for 2 seconds with "SYNC COMPLETE" before smoothly animating out of view.
- **Anti-Patterns to Avoid**:
  - Full-screen blocking modals that stop referees from operating when cellular drops in concrete sports arenas.
  - Silently discarding scores when network fails.
- **Concrete Flutter Implementation**:
  - Widget: `OfflineSyncStatusBar` reacting to `connectivityStatusProvider` and `outboxQueueProvider`. `[SOURCE-GROUNDED]`

---

### Category 19: Bottom Sheet / Quick Action Menu
- **Benchmark Reference**: Apple Maps Bottom Sheet & Instagram Quick Share Sheet.
- **Extracted Principle**: Spatial context retention. The sheet surfaces secondary options while keeping the underlying screen visible and grounded.
- **ArmSphere Adaptation**:
  - Design Tokens: `#121826` surface, 16dp top corner radius, 1px `#334155` border, and top drag handle (32×4dp rounded bar).
  - Content Categories: Table quick actions (`DECLARE FOUL`, `REQUEST VIDEO REVIEW`, `SWAP CORNERS`, `ASSIGN STRAP`).
  - Haptic: `HapticFeedback.selectionClick()` on drag snap points.
- **Anti-Patterns to Avoid**:
  - Bottom sheets that occupy 100% of the screen without drag-down dismissibility.
  - Cluttered lists with 15 tiny text items and no icons.
- **Concrete Flutter Implementation**:
  - Widget: `showModalBottomSheet` with `isScrollControlled: true` and `DraggableScrollableSheet`. `[REFERENCE-GROUNDED]`

---

### Category 20: Settings / Preferences
- **Benchmark Reference**: Telegram Mobile Settings & WHOOP Device Preferences.
- **Extracted Principle**: Modular segmentation with clear visual categorization and instant toggle persistence.
- **ArmSphere Adaptation**:
  - Grouped Athletic Sections:
    1. `ATHLETIC PROFILE & WEIGH-IN` (Default arm, weight category, club affiliation).
    2. `FEDERATION CREDENTIALS` (Referee certification level, province sanction license).
    3. `MATCHDAY HARDWARE & HAPTICS` (Scorepad haptic intensity, audio feedback volume, keep-screen-awake mode).
    4. `DATA & PRIVACY` (Public profile visibility, challenge requests acceptance).
- **Anti-Patterns to Avoid**:
  - Single endless list of 40 unorganized switches.
  - Requiring a manual "SAVE" button for simple toggle switches.
- **Concrete Flutter Implementation**:
  - Widget: `SettingsScreen` with `SettingsSection` and `SettingsTile` components, persisting directly to Riverpod/Hive. `[SOURCE-GROUNDED]`

---

## 3. Pattern Implementation Matrix

| Category | Primary Benchmark | ArmSphere Adaptation Focus | Critical Widget | Minimum Touch Target |
| :--- | :--- | :--- | :--- | :--- |
| **1. Profile Card** | UFC / WHOOP | Dominant arm, grip style, ELO, division | `AthleteFighterCard` | 48×48dp |
| **2. Scorepad** | F1 / Boxing Clock | Symmetrical zones, pin long-press | `RefereeScorepadView` | 64×64dp |
| **3. Bracket** | UFC / Battlefy | Double elimination, active table glow | `InteractiveViewer` Canvas | 48×48dp |
| **4. Leaderboard** | Strava / F1 | Sticky personal rank, division chips | `AthleteRankingStickyBar` | 48×48dp |
| **5. PR Tracker** | WHOOP / Stronglifts | Isometric cupping/pronation 1RM | `TrainingLogEditor` | 48×48dp |
| **6. Challenge Flow**| Chess.com / UFC | Dual-lock slider, ELO stakes | `ChallengeNegotiationScreen`| 56×56dp |
| **7. Onboarding** | Nike / Strava | 3-step athletic calibration | `PageView` + Pills | 48×48dp |
| **8. Discovery** | F1 / Spotify | Unified search, radius chips | `DiscoverScreen` | 48×48dp |
| **9. Community Feed**| Strava / Instagram | On-demand video modal, grip-up | `CommunityPostCard` | 48×48dp |
| **10. Federation** | Stripe / FIA | Sanction queue, role switcher | `FederationWorkspaceView` | 48×48dp |
| **11. Notifications**| Apple / GitHub | Priority buckets, inline actions | `NotificationInboxScreen` | 48×48dp |
| **12. Event Detail** | UFC Fight Card | Weigh-in status, table telemetry | `TournamentDetailScreen` | 48×48dp |
| **13. Head-to-Head** | UFC Tale of Tape | Symmetrical metric comparison bars | `HeadToHeadComparisonView` | 48×48dp |
| **14. Analytics** | WHOOP / Strava | ELO line chart, touch scrubbing | `fl_chart` Custom Canvas | 48×48dp |
| **15. Form Wizard** | Stripe / Nike | Sticky keyboard bar, draft auto-save | `TournamentRegistrationWizard`| 52×52dp |
| **16. Empty State** | Strava / GitHub | Athletic silhouette + primary action | `ArmSphereEmptyState` | 48×48dp |
| **17. Error State** | Apple / F1 | Clear athletic copy, retry CTA | `ArmSphereErrorView` | 48×48dp |
| **18. Offline Sync** | Google Maps | Ambient top pill, outbox queue | `OfflineSyncStatusBar` | 48×48dp |
| **19. Bottom Sheet** | Apple Maps | 16dp rounded sheet, drag handle | `DraggableScrollableSheet`| 48×48dp |
| **20. Settings** | Telegram / WHOOP | Grouped sections, instant toggle | `SettingsSection` | 48×48dp |

---

## 4. Verification & Non-Contradiction Proof
This pattern library adheres strictly to `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/06_DESIGN_SYSTEM.md`. It introduces zero web-only animation dependencies, respects all established color tokens and WCAG contrast limits, preserves all 66 mapped screen classes, and optimizes specifically for physical combat sports tournament environments.
