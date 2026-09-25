# ArmSphere Screen-by-Screen Specification
**Detailed Engineering & Interaction Blueprints for Core Product Surfaces**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Specification Index

This document provides structured engineering specifications for the primary user-facing screens across the ArmSphere ecosystem, adhering to the mandatory schema.

---

### Screen Spec 01: `SplashScreen`
- **Screen Name**: `SplashScreen`
- **File**: `apps/mobile/lib/features/auth/screens/splash_screen.dart`
- **Purpose**: App boot, initial cryptographic session verification, smooth branded entry into ArmSphere.
- **User Role(s)**: All users (prior to authentication resolution).
- **Entry Routes**: App cold start (`/`).
- **Exit Routes**: `/welcome` (if unauthenticated), `/role-intent` (if onboarding pending), `/home` (if authenticated).
- **Visual Structure**:
  - **Background**: Canvas void `#070A11` with subtle ambient radial glow (`#0F1B2A4A`).
  - **Hero**: Central gold-embossed ArmSphere insignia inside circular glass badge.
  - **Header**: N/A.
  - **Sections**: Single centered brand stack.
  - **Cards**: N/A.
  - **Controls**: None (automated transition).
  - **Primary CTA**: None.
  - **Secondary CTA**: None.
- **Content Hierarchy**:
  1. ArmSphere Insignia Icon (56dp, gold primary `#D4AF37`).
  2. Brand Wordmark (`ArmSphere` in `SpaceGrotesk` 32sp bold).
  3. Federation Subtitle (`THE COMPETITIVE ARMWRESTLING ECOSYSTEM`).
  4. Subtle inline progress indicator (24dp).
- **Components**: `AmbientParticleBackground` (static in reduced motion), `CurvedAnimation`.
- **Data**: Read `authProvider.status` from `HiveStorage` and `FlutterSecureStorage`.
- **States**:
  - `first load`: Centered emblem fades in from 0 to 1 over 800ms.
  - `loading`: Session token verified with backend `/api/ready` or local storage.
  - `error`: Network offline fallback allows cached session restoration.
  - `success`: Seamless morph into `/home` or `/welcome`.
- **Interactions**: Tap anywhere skips animation to instant load.
- **Motion**: Level 4 (800ms ease-in curve).
- **Transitions**: Morph into Welcome or Home via `AppTransitionPage`.
- **Scroll**: None (fixed viewport).
- **Images**: Vector brand seal.
- **Video**: None.
- **Generative Assets**: Ambient light cone gradient.
- **Accessibility**: Screen reader announces: "ArmSphere Mobile. Verifying session."
- **Performance**: Zero GPU memory allocations; finishes in <1200ms.
- **Responsive Variation**: Centered identically on all phone and tablet aspect ratios.

---

### Screen Spec 02: `WelcomeScreen`
- **Screen Name**: `WelcomeScreen`
- **File**: `apps/mobile/lib/features/auth/screens/welcome_screen.dart`
- **Purpose**: First-touch institutional onboarding for unauthenticated visitors.
- **User Role(s)**: Unauthenticated visitors.
- **Entry Routes**: `/welcome` (redirect from splash or logout).
- **Exit Routes**: `/register`, `/login`, `/settings/terms`.
- **Visual Structure**:
  - **Background**: Deep slate `#0B0F19` with ambient radial light gradient.
  - **Hero**: Circular glass badge with gold armwrestling icon.
  - **Header**: "ArmSphere: Armwrestling, organized."
  - **Sections**: "Inside ArmSphere" benefit card.
  - **Cards**: `GlassCard` featuring 4 core platform pillars with icons.
  - **Controls**: Primary filled button and secondary outlined button.
  - **Primary CTA**: "Create your account" (`/register`).
  - **Secondary CTA**: "I already have an account" (`/login`).
- **Content Hierarchy**:
  1. Central Brand Emblem & Wordmark.
  2. Mission value statement.
  3. "Inside ArmSphere" 4-benefit breakdown (Tournaments, Rankings, Athletes, Community).
  4. Dual action button stack.
  5. Terms of Service disclaimer.
- **Components**: `GlassCard`, `FilledButton`, `OutlinedButton`.
- **Data**: Static marketing copy.
- **States**:
  - `normal`: Fully rendered landing page.
- **Interactions**: Tap CTA buttons triggers immediate navigation.
- **Motion**: Level 2 (280ms forward slide into auth).
- **Transitions**: Upward slide into registration or login forms.
- **Scroll**: Vertically scrollable if screen height < 640dp to prevent button clipping.
- **Images**: Vector brand emblem.
- **Video**: None.
- **Generative Assets**: None.
- **Accessibility**: All buttons meet minimum 48dp height; high-contrast text (>7:1).
- **Performance**: Static layout; zero API calls required.
- **Responsive Variation**: Max width 480dp centered on tablets.

---

### Screen Spec 03: `AthleteDashboardScreen`
- **Screen Name**: `AthleteDashboardScreen`
- **File**: `apps/mobile/lib/features/athlete/screens/athlete_screens.dart`
- **Purpose**: Central command hub for competitors—displaying active ELO ratings, match alerts, shortcuts, recent results, and personal records.
- **User Role(s)**: `ATHLETE` (and all users in competitor view).
- **Entry Routes**: Main Shell Tab 0 (`/home` -> `/athlete/dashboard`).
- **Exit Routes**: Drill-downs to `/notifications`, `/referee/submit-scorepad`, `/tournaments`, `/teams`, `/messages`, `/athlete/:id/training-log`.
- **Visual Structure**:
  - **Background**: Void substrate `#070A11` with top gradient wash.
  - **Hero**: ELO Rating Glass Card with dual arm breakdown.
  - **Header**: Athlete Greeting ("Welcome back, [Name]") + Notification Bell with unread dot.
  - **Sections**: 1) Rating Specs Card, 2) Quick Shortcuts Grid, 3) Recent Matches List, 4) Personal Records Wrap.
  - **Cards**: `GlassCard` for rating, shortcut cells, match rows, and PR chips.
  - **Controls**: 2-column shortcut grid, notification icon button, retry buttons.
  - **Primary CTA**: Contextual shortcut ("Record Match" or "Tournaments").
  - **Secondary CTA**: "View All Matches".
- **Content Hierarchy**:
  1. Greeting & Notification Bell.
  2. Right Arm ELO & Left Arm ELO + Weight Class Badge.
  3. Quick Shortcuts (Referee Console, Record Match, Tournaments, Training Log, My Team, Inbox).
  4. Recent Verified Matches (Opponent, Arm, Date, WIN/LOSS badge).
  5. Personal Records (Exercise pills with max weight in kg).
- **Components**: `GlassCard`, `CountUpText`, `TactilePressWrapper`, `StatusChip`, `SkeletonPlaceholder`.
- **Data**: `athleteProfileProvider`, `liveMatchesProvider`, `trainingLogPRsProvider`.
- **States**:
  - `first load`: Shimmer skeleton boxes for ELO card and match list.
  - `normal`: Real ELO numbers, live shortcuts, up to 5 verified match history rows.
  - `loading`: Local cache shown with silent background network refresh.
  - `empty`: "No verified matches yet — record your first result to start climbing the rankings."
  - `error`: Error banner with direct "Retry" button.
  - `offline`: Amber offline chip; displays cached ELO and matches from Hive.
- **Interactions**: Tap shortcut opens route; pull-to-refresh invalidates providers.
- **Motion**: Level 3 (count-up animation on ELO numbers, 500ms).
- **Transitions**: Tab persistence in shell; 300ms forward push for drill-down routes.
- **Scroll**: Vertical scroll with physics preserving exact position on tab switch.
- **Images**: Athlete profile avatar thumbnail.
- **Video**: None.
- **Generative Assets**: Subtle dark atmosphere gradient.
- **Accessibility**: Rating announced as: "Right Arm ELO 1520, Left Arm ELO 1380, Class -85kg".
- **Performance**: Cached render in <150ms from Hive local storage.
- **Responsive Variation**: 2-column shortcut grid adapts to 3 columns on tablet screens.

---

### Screen Spec 04: `TournamentDetailScreen`
- **Screen Name**: `TournamentDetailScreen`
- **File**: `apps/mobile/lib/features/tournament/screens/tournament_screens.dart`
- **Purpose**: Institutional competition briefing: countdown, prize purse, weight categories, rulebook, venue map, and registration.
- **User Role(s)**: All roles (with operator tools visible to authorized staff).
- **Entry Routes**: Tap event card on Tournaments list (`/tournament/:tournamentId`).
- **Exit Routes**: `/tournament/:id/register`, `/tournament/:id/brackets`, `/tournament/:id/operations`.
- **Visual Structure**:
  - **Background**: Deep slate `#0B0F19`.
  - **Hero**: `TournamentDetailsHeroWidget` with arena banner, live countdown, and prize pool.
  - **Header**: Pinned SliverAppBar on scroll.
  - **Sections**: 1) Important Dates Timeline, 2) Weight Categories Grid, 3) Registered Pullers Carousel, 4) Rulebook Accordion, 5) Organizer Contact.
  - **Cards**: `GlassCard` containers for each section.
  - **Controls**: Sticky bottom bar with "Register for Event" and "View Brackets".
  - **Primary CTA**: "Register for Event" (Gold `FilledButton`).
  - **Secondary CTA**: "View Brackets" (`OutlinedButton`).
- **Content Hierarchy**:
  1. Tournament Title, Location City, and Status Badge (`ONGOING` / `PUBLISHED`).
  2. Live Countdown Clock (`04d : 12h : 30m`) & Prize Purse (`PKR 500,000`).
  3. Important Dates (Weigh-in, Brackets draw, Matches).
  4. Competition Categories (Senior, Junior, Female; Left & Right).
  5. Rulebook Accordion (Foul rules, strap match guidelines).
- **Components**: `TournamentDetailsHeroWidget`, `ParticipantsCarouselWidget`, `RulebookAccordionWidget`, `ImportantDatesTimelineWidget`.
- **Data**: `tournamentProvider`, `tournamentRepositoryProvider`.
- **States**:
  - `first load`: `TournamentSkeletonLoadingWidget` shimmer layout.
  - `normal`: Live countdown ticking every second, registration slots count (`84/100 SLOTS`).
  - `empty`: N/A (valid ID required).
  - `error`: Error view with retry button.
  - `offline`: Cached details loaded from Hive.
- **Interactions**: Tap categories to view entrants; expand/collapse rulebook accordions; tap sticky CTA.
- **Motion**: Level 1 (accordion expansion, 200ms); Level 2 (sticky CTA entrance).
- **Transitions**: 300ms forward push from list; hero image smoothly transitions.
- **Scroll**: `CustomScrollView` with collapsing SliverAppBar.
- **Images**: High-res arena photography with dark gradient scrim.
- **Video**: Optional 4s ambient arena loop on high-end devices.
- **Generative Assets**: `arena_dark_atmosphere.jpg` default fallback.
- **Accessibility**: Sticky CTA avoids keyboard overlap; all accordions have semantic expansion labels.
- **Performance**: Collapsing header fades out image during scroll to optimize rasterization.
- **Responsive Variation**: Sticky bottom action bar centers within max-width 640dp on wide viewports.

---

### Screen Spec 05: `TournamentBracketsScreen`
- **Screen Name**: `TournamentBracketsScreen`
- **File**: `apps/mobile/lib/features/tournament/screens/tournament_screens.dart`
- **Purpose**: Fullscreen interactive double-elimination bracket tree: Winners Bracket, Losers Bracket, Grand Finals.
- **User Role(s)**: All roles.
- **Entry Routes**: `/tournament/:tournamentId/brackets` (from tournament details or discover).
- **Exit Routes**: Tap match node -> Match detail modal; tap athlete -> `/athlete/:id`.
- **Visual Structure**:
  - **Background**: Dark canvas substrate `#070A11` with grid coordinate markers.
  - **Hero**: Division & Weight Class segmented control (`Senior -85kg`).
  - **Header**: AppBar with bracket filter dropdowns and zoom reset button.
  - **Sections**: 2D infinite zoomable canvas (`InteractiveViewer`).
  - **Cards**: Compact match node cards (`CompactBracketMatchCard`).
  - **Controls**: Pinch-to-zoom, pan drag, Winners/Losers toggle, weight class switcher.
  - **Primary CTA**: Tap match node to view live scores.
  - **Secondary CTA**: Reset zoom to 100%.
- **Content Hierarchy**:
  1. Category Switcher (Division & Weight Class).
  2. Bracket Tree Rounds (Round 1, Quarter-Finals, Semi-Finals, Grand Final).
  3. Match Nodes (Seed number, Athlete names, Live score, Winner highlight).
  4. Custom Connecting Lines (`BracketLinesPainter`).
- **Components**: `BracketTreeWidget`, `WinnersBracketTreeWidget`, `LosersBracketTreeWidget`, `BracketLinesPainter`, `InteractiveViewer`.
- **Data**: `bracketProvider(tournamentId)`.
- **States**:
  - `first load`: Shimmer bracket nodes and connecting line paths.
  - `normal`: Interactive 2D tree with live node score updates.
  - `empty`: "Brackets not generated yet. The organizer will seed brackets following official weigh-ins."
  - `error`: Error view with retry.
  - `offline`: Displays cached bracket tree state.
- **Interactions**: Two-finger pinch to zoom (0.5x to 2.5x), drag pan, node tap.
- **Motion**: Smooth canvas momentum scrolling; winner node highlights pop with scale bounce.
- **Transitions**: Fullscreen modal push (300ms).
- **Scroll**: 2D directional panning inside `InteractiveViewer`.
- **Images**: Athlete avatar thumbnails inside match cards.
- **Video**: None.
- **Generative Assets**: None.
- **Accessibility**: Alternative list view accessible via top AppBar icon for screen reader users.
- **Performance**: Strict 60fps canvas painting; cull off-screen nodes from render tree.
- **Responsive Variation**: Canvas scales infinitely across phones, foldables, and tablets.

---

### Screen Spec 06: `OfficialScorepadScreen`
- **Screen Name**: `OfficialScorepadScreen`
- **File**: `apps/mobile/lib/features/referee/screens/official_scorepad_screen.dart`
- **Purpose**: Mission-critical table-side officiating instrument: increment points, track fouls, log pins, and submit verified results.
- **User Role(s)**: `REFEREE`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`.
- **Entry Routes**: Referee Dashboard -> Table Match -> `/referee/submit-scorepad`.
- **Exit Routes**: Returns to Referee Dashboard upon submission.
- **Visual Structure**:
  - **Background**: Pitch black `#000000` with high-contrast dividing line between pullers.
  - **Hero**: Massive set score readout (e.g. `2 - 1`).
  - **Header**: Table Number (`Table 1`) + Match ID + Time Elapsed Clock.
  - **Sections**: 1) Puller 1 Touch Zone (Left), 2) Puller 2 Touch Zone (Right), 3) Foul & Warning Bar, 4) Submit Result Footer.
  - **Cards**: High-contrast action cells.
  - **Controls**: Extra-large 64dp score increment buttons, Foul buttons, Pin confirmation dialog.
  - **Primary CTA**: "Submit Verified Result" (Gold button, requires match point reached).
  - **Secondary CTA**: "Declare Foul", "Reset Score".
- **Content Hierarchy**:
  1. Table Number & Assigned Arm (Right/Left).
  2. Puller 1 vs Puller 2 Names, Avatars, and Clubs.
  3. Massive Live Score Numbers (`SpaceGrotesk` 48sp).
  4. Foul Counters (2 fouls = 1 round loss).
  5. Round Pin History Ledger (Round 1: Ali, Round 2: Khan).
- **Components**: `TactilePressWrapper`, `PulseIndicator`, `Dialog`.
- **Data**: `refereeProvider`, `tournamentRepositoryProvider`.
- **States**:
  - `normal`: Ready for match start.
  - `in progress`: Active set points live updating.
  - `match decided`: Victory banner illuminates, submit button unlocks.
  - `submitting`: Fullscreen overlay during cryptographic ELO submission.
  - `error`: Red alert banner with offline local queue fallback.
- **Interactions**: Tap giant thumb cells to add score; physical haptic click on every tap; screen wake-lock active.
- **Motion**: Level 0 (100ms scale feedback); Level 3 (celebratory pop on match point).
- **Transitions**: 400ms console entrance; confirm dialog before exiting unsubmitted match.
- **Scroll**: None (strictly locked single-screen instrument).
- **Images**: Puller avatars.
- **Video**: None.
- **Generative Assets**: None.
- **Accessibility**: 100% WCAG AAA compliant; haptic feedback confirms every action without looking at screen.
- **Performance**: Zero touch latency (<50ms response); zero background garbage collection pauses.
- **Responsive Variation**: Touch targets scale up to 80dp on tablet devices.

---

### Screen Spec 07: `GovernanceDashboardScreen`
- **Screen Name**: `GovernanceDashboardScreen`
- **File**: `apps/mobile/lib/features/governance/screens/governance_screens.dart`
- **Purpose**: Judicial arbitration hub: review filed complaints, inspect slow-motion video evidence, issue rulings, and enforce athlete sanctions.
- **User Role(s)**: `COMPLIANCE_OFFICER`, `ORGANIZATION_LEADER`, `SYSTEM_ADMIN` (viewable by involved athletes).
- **Entry Routes**: Main Shell Tab 0 (for compliance role) or `/governance`.
- **Exit Routes**: `/governance/dispute/:id`, `/governance/submit-complaint`.
- **Visual Structure**:
  - **Background**: Substrate dark `#0B0F19`.
  - **Hero**: Active arbitration caseload summary card.
  - **Header**: AppBar with "Arbitration & Disputes" + "File Complaint" action.
  - **Sections**: Filterable list of dispute cases.
  - **Cards**: `GlassCard` dispute rows with status chips.
  - **Controls**: Filter tabs (`All`, `Open`, `Escalated`, `Resolved`).
  - **Primary CTA**: "File Dispute / Complaint" (`+` icon).
  - **Secondary CTA**: "View Case Evidence".
- **Content Hierarchy**:
  1. Case ID (`Case #1042`) and Incident Date.
  2. Tournament Event & Disputed Match Title.
  3. Status Badge (`OPEN`, `ESCALATED`, `AWAITING_EVIDENCE`, `RESOLVED`, `REJECTED`).
  4. Brief complaint allegation snippet.
- **Components**: `GlassCard`, `StatusChip`, `AppEmptyState`, `RefreshIndicator`.
- **Data**: `disputeProvider`.
- **States**:
  - `first load`: Shimmer dispute rows.
  - `normal`: Case list sorted by urgency.
  - `empty`: "No disputes filed. Open arbitration cases will appear here once submitted."
  - `error`: Error state with retry CTA.
- **Interactions**: Tap case card opens full arbitration detail screen.
- **Motion**: Level 2 (280ms forward slide).
- **Transitions**: Standard push into dispute details.
- **Scroll**: Vertical scroll with pull-to-refresh.
- **Images**: None in list.
- **Video**: Video evidence reviewed in detail screen modal.
- **Generative Assets**: None.
- **Accessibility**: High-contrast status badges; case numbers explicitly announced.
- **Performance**: Fast list rendering.
- **Responsive Variation**: Max width 640dp on wide screens.

---

### Screen Spec 08: `CommunityFeedScreen`
- **Screen Name**: `CommunityFeedScreen`
- **File**: `apps/mobile/lib/features/community/screens/community_feed_screen.dart`
- **Purpose**: Grassroots technical video feed: athletes share training lifts, practice clips (YouTube, TikTok, FB), like posts, and discuss techniques.
- **User Role(s)**: All authenticated athletes and fans.
- **Entry Routes**: Main Shell Bottom Nav Tab 3 (`/community/feed`).
- **Exit Routes**: `/community/create`, `/community/posts/:id/comments`, `VideoPlayerModal`.
- **Visual Structure**:
  - **Background**: Void dark `#070A11`.
  - **Hero**: N/A (content-driven feed).
  - **Header**: AppBar with "Community" title + "Share a video link" (`+`) action.
  - **Sections**: Infinite scrolling feed of video cards.
  - **Cards**: `GlassCard` video post cards.
  - **Controls**: Like button (heart), Comment button, Share button, Play video tap area.
  - **Primary CTA**: "Share a video" (AppBar icon and empty state button).
  - **Secondary CTA**: "View Comments".
- **Content Hierarchy**:
  1. Author Avatar, Display Name, and Timestamp.
  2. Post Caption / Description.
  3. Video Thumbnail with centered Platform Play Badge.
  4. Interaction Bar: Like count, Comment count, Share icon.
- **Components**: `GlassCard`, `SkeletonPlaceholder`, `VideoPlayerModal`, `AppEmptyState`.
- **Data**: `communityFeedProvider`.
- **States**:
  - `first load`: `SkeletonPlaceholder(height: 180)` list.
  - `normal`: Video post feed with infinite scroll pagination.
  - `empty`: "No posts yet. Be the first to share a training or match video."
  - `error`: Error state with retry CTA.
  - `offline`: Displays cached community posts.
- **Interactions**: Tap video opens `VideoPlayerModal`; tap heart toggles like optimistically; tap comments opens discussion.
- **Motion**: Level 0 (heart pop animation); Level 1 (video modal entrance).
- **Transitions**: Modal popup for video playback; forward slide into comments.
- **Scroll**: Vertical feed with infinite scroll pre-fetching when 400px from bottom.
- **Images**: Author avatars and external video thumbnails.
- **Video**: In-app modal WebView player (zero background auto-play).
- **Generative Assets**: None.
- **Accessibility**: Play button announces: "Play video: [Caption]".
- **Performance**: Thumbnails lazily loaded; WebView process destroyed immediately upon modal close.
- **Responsive Variation**: Cards constrained to max-width 560dp centered on tablets.
