# ArmSphere Master Feature Inventory & Experience Mapping
**Comprehensive Source-Grounded Feature Matrix**
**Document Version**: 1.0.0
**Source Authority**: Verified across `apps/mobile/lib/features`, `packages/db-schema`, and `apps/api`
**Status**: APPROVED & LOCKED

---

## Master Feature Matrix (All 26 Discovered User-Facing Features)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FEATURE DOMAIN OVERVIEW                         │
├────┬─────────────────────────────┬────┬───────────────────────────────┤
│ 01 │ Authentication & Security   │ 14 │ Tournament Operator Console   │
│ 02 │ Role Intent & Onboarding    │ 15 │ Official Referee Scorepad     │
│ 03 │ Athlete Dashboard & Ratings │ 16 │ Referee Certification Engine  │
│ 04 │ Athlete Profile & Biometrics│ 17 │ Governance & Disputes         │
│ 05 │ Public Competitor Profiles  │ 18 │ Community Video Feed          │
│ 06 │ Training Log & PR Tracking  │ 19 │ Direct Messaging & Chat       │
│ 07 │ Athletic Honors & Medals    │ 20 │ Federation Announcements      │
│ 08 │ National ELO Rankings       │ 21 │ Venue Partner Directory       │
│ 09 │ Global Athlete Search       │ 22 │ Informal Pickup Meetups       │
│ 10 │ Tournament Discovery        │ 23 │ Grassroots Talent Nominations │
│ 11 │ Tournament Details & Spec   │ 24 │ Team Rosters & Clubs          │
│ 12 │ Competition Registration    │ 25 │ Championship Belts & Lineage  │
│ 13 │ Interactive Brackets Engine │ 26 │ Account Settings & Compliance │
└────┴─────────────────────────────┴────┴───────────────────────────────┘
```

---

### Feature 01: Authentication & Security Vault
- **Feature Name**: Authentication & Identity Management
- **Target User**: All visitors and returning users
- **Role**: All 9 roles (Athlete, Referee, Operator, Directors, Compliance, Support, Admin)
- **Purpose**: Secure authentication into the ArmSphere federation platform via credentials, MFA TOTP, or recovery codes.
- **Entry Point**: App launch redirect or `/welcome`
- **Primary Screen**: `LoginScreen` (`/login`), `RegisterScreen` (`/register`)
- **Secondary Screens**: `ForgotPasswordScreen` (`/forgot-password`), `ResetPasswordScreen` (`/reset-password`), `MfaSetupScreen` (`/mfa/setup`), `MfaVerificationScreen` (`/mfa/verify`), `RecoveryCodesScreen` (`/recovery-codes`)
- **Primary Action**: "Sign In" / "Create Account"
- **Secondary Actions**: "Forgot Password?", "Use Recovery Code", "Set up Biometric Login"
- **Data Shown**: Email input, password input with visibility toggle, TOTP 6-digit input, recovery key display.
- **Important States**: Unauthenticated, MFA Required, Account Locked, Session Restoring.
- **Error States**: Invalid credentials (401), rate-limited (429), expired session, network failure.
- **Empty States**: N/A (form screen).
- **Loading States**: Button spinner with disabled form inputs during crypto hash and token exchange.
- **Success States**: Direct route transition to `/role-intent` (if onboarding required) or `/home` (if authenticated).
- **Permission States**: Publicly accessible.
- **Navigation Destination**: `/home` or `/role-intent`
- **Back Behavior**: Back from login returns to `/welcome`. Back from MFA verification prompts logout or retry.
- **Animation**: 280ms smooth horizontal slide between Sign In and Sign Up tabs.
- **Interaction Type**: Form entry with keyboard auto-fill and software keyboard dismissal on submit.
- **Image Requirement**: ArmSphere shield insignia vector.
- **Video Requirement**: None (keep auth ultra-clean and fast).
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: High-contrast labels (4.5:1), form field accessibility descriptors, error announcements.
- **Performance Requirements**: Form interactive in <100ms; zero frame drops on keyboard open.
- **Offline Behavior**: Displays cached session status or connection-required banner.
- **Related Features**: Feature 02 (Role Intent), Feature 26 (Settings & Active Sessions).
- **Dependencies**: `authProvider`, `DioClient`, `FlutterSecureStorage`.
- **Implementation Notes**: Implemented and verified in `features/auth`.

---

### Feature 02: Role Intent & Guided Onboarding
- **Feature Name**: Role Intent Selection & Athlete Guided Setup
- **Target User**: Newly registered accounts
- **Role**: Athlete (default), with intent declared for Referee, Organizer, or Club Leader.
- **Purpose**: Collect intent and mandatory physical/location biometrics required for competitive matchmaking.
- **Entry Point**: Auto-redirect after registration via `/role-intent`
- **Primary Screen**: `RoleIntentScreen` (`/role-intent`), `OnboardingScreen` (`/onboarding`)
- **Secondary Screens**: Official Verification Explanatory Modal.
- **Primary Action**: "Continue" (progressive advancement)
- **Secondary Actions**: "Pick another intent", "Back to previous step"
- **Data Shown**: 
  - Intent choices: Compete as Athlete, Officiate Matches, Organize Tournaments, Lead a Club.
  - Step 1: Ring name / Display Name, Date of Birth (DatePicker), Gender.
  - Step 2: Province (7 provinces of Pakistan), City.
  - Step 3: Measured Weight (kg), Height (cm), Arm Reach (cm), Dominant Arm (Right/Left).
- **Important States**: Step 0 (Identity), Step 1 (Location), Step 2 (Physical Specs).
- **Error States**: Missing mandatory fields, age under federation threshold, invalid weight.
- **Empty States**: Initial default values (2000-01-01, 75kg, 175cm, Punjab).
- **Loading States**: Primary button displays centered spinner while sending payload to backend.
- **Success States**: Success haptic, profile saved in database, smooth route push into `/home`.
- **Permission States**: Authenticated user with `onboardingRequired: true`.
- **Navigation Destination**: `/home`
- **Back Behavior**: Previous step button decrements step counter; on step 0, warns before cancelling registration.
- **Animation**: Directional horizontal slide between steps (280ms).
- **Interaction Type**: Stepper progress bar, card selection with gold border, segmented toggle.
- **Image Requirement**: None.
- **Video Requirement**: None.
- **Generative Asset Requirement**: Optional subtle athletic background silhouette.
- **Accessibility Requirements**: Stepper announces "Step 1 of 3: Identity" to screen readers.
- **Performance Requirements**: Instant step transitions; zero jank during date picker opening.
- **Offline Behavior**: Offline banner displayed; onboarding requires server sync to establish official profile.
- **Related Features**: Feature 03 (Athlete Dashboard), Feature 04 (Profile).
- **Dependencies**: `authProvider`, `athleteProvider`.
- **Implementation Notes**: Verified in `features/athlete/screens/onboarding_screen.dart`.

---

### Feature 03: Athlete Dashboard & Live Rating Hub
- **Feature Name**: Personalized Athlete Dashboard
- **Target User**: Signed-in athletes and competitors
- **Role**: Athlete (also accessible by officials via navigation)
- **Purpose**: Immediate high-impact overview of current ELO ratings (Right & Left arm), upcoming matches, quick actions, and recent verified match results.
- **Entry Point**: Main Shell Bottom Nav Tab 0 (`/home` -> `/athlete/dashboard`)
- **Primary Screen**: `AthleteDashboardScreen`
- **Secondary Screens**: Quick shortcuts to `/tournaments`, `/messages`, `/teams`, `/referee/submit-scorepad`.
- **Primary Action**: Contextual (e.g. "Record Match" or "Browse Tournaments")
- **Secondary Actions**: "Notifications", "Referee Console" (if certified), "View All Matches"
- **Data Shown**:
  - Athlete Greeting + Notification Bell with badge.
  - ELO Rating Card: Right Arm ELO, Left Arm ELO, Assigned Weight Class.
  - Quick Shortcuts Grid (Record Match, Tournaments, Training Log, My Team, Inbox).
  - Recent Verified Matches: Opponent name, Arm used, Date, Outcome (WIN in Emerald / LOSS in Coral).
  - Personal Records (PR) chips: Exercise name + Max weight (kg).
- **Important States**: First-time puller (1000 ELO base, no matches), active competitor, unverified rating.
- **Error States**: Network error displays retry card with `ref.invalidate(athleteProfileProvider)`.
- **Empty States**: "No verified matches yet — record your first result to start climbing the rankings."
- **Loading States**: Shimmer placeholder cards matching exact dimensions of ELO card and match rows.
- **Success States**: Live updates when new matches are verified.
- **Permission States**: Requires authenticated session.
- **Navigation Destination**: Respective feature routes.
- **Back Behavior**: Exits app (root level of navigation stack).
- **Animation**: Subtle count-up animation on ELO numbers (`CountUpText` widget).
- **Interaction Type**: Tap to drill down; pull-to-refresh.
- **Image Requirement**: User profile photo with fallback to initials avatar.
- **Video Requirement**: None.
- **Generative Asset Requirement**: Atmospheric dark navy background.
- **Accessibility Requirements**: Rating card reads "Right Arm ELO 1450, Left Arm ELO 1320, Weight Class 85 kilograms".
- **Performance Requirements**: Cold render in <200ms from Hive cache while revalidating.
- **Offline Behavior**: Displays cached profile and matches with subtle "Viewing cached ratings" chip.
- **Related Features**: Feature 04 (Profile), Feature 08 (Rankings), Feature 15 (Matches).
- **Dependencies**: `athleteProfileProvider`, `liveMatchesProvider`, `trainingLogPRsProvider`.
- **Implementation Notes**: Verified in `features/athlete/screens/athlete_screens.dart`.

---

### Feature 04: Athlete Profile & Biometric Specifications
- **Feature Name**: Personal Athlete Profile & Biometric Specs
- **Target User**: Signed-in athlete
- **Role**: All authenticated users
- **Purpose**: Detailed display of user biometrics, physical reach, arm dominance, account security, and settings access.
- **Entry Point**: Main Shell Bottom Nav Tab 4 (`/athlete/profile`)
- **Primary Screen**: `AthleteProfileScreen`
- **Secondary Screens**: `SettingsHubScreen` (`/settings`), `AthleteAchievementsScreen` (`/athlete/achievements`), `FollowersListScreen` (`/athlete/:id/followers`), `FollowingListScreen` (`/athlete/:id/following`).
- **Primary Action**: "Account & Settings"
- **Secondary Actions**: "Log Out", "Edit Biometrics"
- **Data Shown**: Avatar, Display Name, Email, Weight (kg), Height (cm), Reach (cm), Arm Dominance (Right/Left), Settings list.
- **Important States**: Complete profile, missing biometrics.
- **Error States**: Graceful fallback avatar if image URL fails.
- **Empty States**: Default placeholders if reach or height are unrecorded.
- **Loading States**: Skeleton circles for avatar and spec cards.
- **Success States**: Live reflection of edited profile details.
- **Permission States**: Authenticated user.
- **Navigation Destination**: `/settings`
- **Back Behavior**: Resets to home tab or exits app.
- **Animation**: Micro-scale tap feedback on list items.
- **Interaction Type**: Tap list items; avatar tap.
- **Image Requirement**: Profile photo uploaded via secure S3/R2 presigned URL.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Biometric stats formatted as key-value pairs with semantic labels.
- **Performance Requirements**: Instant rendering from local memory state.
- **Offline Behavior**: Fully functional from cached Hive storage.
- **Related Features**: Feature 05 (Public Profile), Feature 26 (Settings).
- **Dependencies**: `authProvider`, `athleteProfileProvider`.
- **Implementation Notes**: Verified in `features/athlete/screens/athlete_screens.dart`.

---

### Feature 05: Public Competitor Profile & Head-to-Head
- **Feature Name**: Public Athlete Profile & Follow System
- **Target User**: Any athlete or fan exploring competitors
- **Role**: All roles
- **Purpose**: Inspect a rival's verified record, arm dominance, physical stats, ELO history, follow them, or initiate a direct challenge/chat.
- **Entry Point**: Tap athlete name anywhere in app (Rankings, Tournaments, Discover, Search) -> `/athlete/:athleteId`
- **Primary Screen**: `PublicAthleteProfileScreen`
- **Secondary Screens**: `ChatScreen` (`/messages/:conversationId`), `AthleteAchievementsScreen` (`/achievements`), `AthleteTrainingLogScreen` (`/athlete/:id/training-log`).
- **Primary Action**: "Follow" / "Following" toggle
- **Secondary Actions**: "Message Athlete", "View Training Log", "View Honors"
- **Data Shown**: Competitor photo, verified federation badge, club affiliation, province, ELO ratings, physical measurements, followers/following count, head-to-head match history.
- **Important States**: Followed, Not Followed, Self (Follow button hidden if viewing own profile).
- **Error States**: Athlete not found (404) with "Athlete profile not found" empty state.
- **Empty States**: "No public matches on record for this athlete."
- **Loading States**: Shimmer card placeholders for bio and stats.
- **Success States**: Instant optimistic toggle on Follow button with background API call.
- **Permission States**: Respects `profileVisibility: "PUBLIC"` vs `"PRIVATE"`.
- **Navigation Destination**: `/messages/:id` or `/athlete/:id/training-log`
- **Back Behavior**: Returns to previous screen (Search, Ranking, Bracket, etc.).
- **Animation**: 300ms forward slide transition; subtle scale animation on Follow button.
- **Interaction Type**: Tap buttons, scrollable profile body.
- **Image Requirement**: Competitor profile avatar.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Follow button announces "Follow [Name]" or "Unfollow [Name]".
- **Performance Requirements**: Image cached via `cached_network_image`.
- **Offline Behavior**: Displays cached profile data if previously viewed; otherwise offline notice.
- **Related Features**: Feature 08 (Rankings), Feature 19 (Messaging), Feature 24 (Teams).
- **Dependencies**: `athletePublicProfileProvider`, `socialProvider`.
- **Implementation Notes**: Implemented in `features/athlete/screens/public_profile_screen.dart`.

---

### Feature 06: Athlete Training Log & PR Engine
- **Feature Name**: Athlete Training Log & Personal Records (PR)
- **Target User**: Athletes logging strength metrics
- **Role**: Athlete
- **Purpose**: Record and track specific armwrestling strength exercises: Bicep Curl, Wrist Wrench, Cup, Pronation, Rising, Multi-spinner, Hammer Curl.
- **Entry Point**: Dashboard shortcut or `/athlete/:athleteId/training-log`
- **Primary Screen**: `AthleteTrainingLogScreen`
- **Secondary Screens**: New PR Entry Modal.
- **Primary Action**: "Log Workout / PR"
- **Secondary Actions**: Filter by exercise type, view history curve.
- **Data Shown**: Exercise type chips, date of session, weight lifted (kg), reps, notes, best PR badge.
- **Important States**: Empty log, active logs, personal record broken.
- **Error States**: Submission validation errors (e.g. negative weight).
- **Empty States**: "No training sessions logged yet. Log your first lift to track strength progression."
- **Loading States**: Shimmer list rows.
- **Success States**: Audio cue (`pr_achieved.wav`) + celebration confetti overlay on new personal best.
- **Permission States**: Owner only can log; public can view if profile is public.
- **Navigation Destination**: Modal sheet.
- **Back Behavior**: Returns to Athlete Profile or Dashboard.
- **Animation**: Micro-scale badge pop on PR achieved.
- **Interaction Type**: Tap exercise chips, numeric form inputs.
- **Image Requirement**: None.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Clear numeric inputs with kg unit announced.
- **Performance Requirements**: Instant local state update.
- **Offline Behavior**: Logs saved locally to Hive `pendingActions` queue and synced when online.
- **Related Features**: Feature 03 (Dashboard PR chips), Feature 04 (Profile).
- **Dependencies**: `trainingLogProvider`, `audioPlayerProvider`.
- **Implementation Notes**: Implemented in `features/athlete/screens/training_log_screen.dart`.

---

### Feature 07: Athletic Honors & Cryptographic Medals
- **Feature Name**: Athlete Honors & Verified Achievement Badges
- **Target User**: Athletes celebrating verified tournament accolades
- **Role**: All roles (viewable)
- **Purpose**: Showcase verified podium finishes, championship belts, and referee certifications backed by cryptographic state hashing.
- **Entry Point**: Profile -> Honors or `/athlete/achievements`
- **Primary Screen**: `AthleteAchievementsScreen`
- **Secondary Screens**: Achievement detail modal with cryptographic verification signature.
- **Primary Action**: "Share Achievement"
- **Secondary Actions**: "View Tournament Bracket"
- **Data Shown**: Gold, Silver, Bronze medals, Championship Title badges, tournament name, date, division, weight class, SHA-256 verification hash.
- **Important States**: No medals earned, active medals showcase.
- **Error States**: Error loading honors.
- **Empty States**: "No tournament honors on record yet. Compete in sanctioned events to earn official medals."
- **Loading States**: Shimmer medal tiles.
- **Success States**: Celebratory golden shimmer animation when opened immediately after a tournament final.
- **Permission States**: Publicly viewable.
- **Navigation Destination**: `/tournaments/:id`
- **Back Behavior**: Returns to profile.
- **Animation**: Subtle golden sheen animation across medal borders (`goldGlow`).
- **Interaction Type**: Tap medal to view verification certificate.
- **Image Requirement**: Vector medal icons (Gold, Silver, Bronze, Championship Belt).
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: High-contrast medal badges with textual level ("Gold Medalist - Senior -85kg").
- **Performance Requirements**: Lightweight vector rendering.
- **Offline Behavior**: Cached achievements displayed offline.
- **Related Features**: Feature 11 (Tournaments), Feature 25 (Championships).
- **Dependencies**: `achievementsProvider`.
- **Implementation Notes**: Verified in `core/widgets/achievements_section.dart`.

---

### Feature 08: National ELO Rankings & Leaderboards
- **Feature Name**: National Leaderboard & Weight Class Rankings
- **Target User**: Athletes, coaches, referees, fans
- **Role**: All roles
- **Purpose**: Browse the official national armwrestling ranking ladder filtered by arm (Right/Left), weight class, and province.
- **Entry Point**: Main Shell Tab 1 (Discover -> View Rankings) or `/rankings`
- **Primary Screen**: `RankingsScreen`
- **Secondary Screens**: Drill-down to `PublicAthleteProfileScreen` (`/athlete/:id`).
- **Primary Action**: Tap athlete row to view full competitor profile.
- **Secondary Actions**: Segmented button toggle (Right Arm / Left Arm), Province dropdown filter, Search query input.
- **Data Shown**:
  - Rank number (#1, #2, #3 podium icons; #4+ numerical).
  - Athlete Name, Club, Province tag.
  - Current ELO score (e.g. 1845), win/loss record, recent trend arrow (green up / red down).
- **Important States**: Ranked list, filtered empty state.
- **Error States**: "Could not load leaderboard" with retry CTA.
- **Empty States**: "No ranked athletes found in this category / province."
- **Loading States**: Shimmer rows with rank numbers and avatar skeletons.
- **Success States**: Real-time position updates when new tournament matches finalize.
- **Permission States**: Public.
- **Navigation Destination**: `/athlete/:athleteId`
- **Back Behavior**: Returns to Discover or previous tab.
- **Animation**: Smooth list item fade-in on filter change.
- **Interaction Type**: Segmented button tap, text search input with 400ms debounce.
- **Image Requirement**: Athlete avatar thumbnail.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Table semantics; row reads: "Rank 1, Muhammad Ali, ELO 1845, Punjab".
- **Performance Requirements**: 60fps scrolling list with up to 500 ranked athletes using `ListView.builder`.
- **Offline Behavior**: Renders latest cached ranking snapshot from Hive.
- **Related Features**: Feature 03 (Athlete ELO), Feature 05 (Competitor Profile).
- **Dependencies**: `rankingsProvider`, `rankingsArmProvider`, `rankingsProvinceProvider`.
- **Implementation Notes**: Verified in `features/athlete/screens/rankings_screen.dart`.

---

### Feature 09: Global Athlete Search
- **Feature Name**: Global Search Directory
- **Target User**: Any user finding training partners, rivals, or officials
- **Role**: All roles
- **Purpose**: Search for any registered athlete by full name, ring name, or province with instant debounced server search.
- **Entry Point**: Discover Screen AppBar Search Icon (`/search`)
- **Primary Screen**: `GlobalSearchScreen`
- **Secondary Screens**: `PublicAthleteProfileScreen` (`/athlete/:id`).
- **Primary Action**: Tap athlete result to open profile.
- **Secondary Actions**: Clear search text query.
- **Data Shown**: Search text bar with clear button, list of athlete results (avatar, display name, province, weight class, primary arm).
- **Important States**: Initial empty search hint, search results returned, no matches found.
- **Error States**: Search failure notice with retry.
- **Empty States**: "No athletes match your query. Try searching by full name or city."
- **Loading States**: Linear progress bar beneath search input.
- **Success States**: Instant results population.
- **Permission States**: Public.
- **Navigation Destination**: `/athlete/:id`
- **Back Behavior**: Returns to previous screen with keyboard auto-dismissal.
- **Animation**: Smooth list transition on query response.
- **Interaction Type**: Search input field with auto-focus; tap row.
- **Image Requirement**: Thumbnail avatar.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Search input has clear button with accessible label; screen reader announces result count.
- **Performance Requirements**: 350ms debounced network query; minimal bandwidth.
- **Offline Behavior**: Searches against locally cached athletes if offline.
- **Related Features**: Feature 05 (Public Profile), Feature 08 (Rankings).
- **Dependencies**: `athleteSearchProvider`, `athleteSearchQueryProvider`.
- **Implementation Notes**: Implemented in `features/search/screens/search_screen.dart`.

---

### Feature 10: Tournament Directory & Competition Discovery
- **Feature Name**: Tournament & Championship Directory
- **Target User**: Athletes searching for sanctioned events to enter
- **Role**: All roles
- **Purpose**: Discover upcoming, live, and past sanctioned armwrestling tournaments across Pakistan.
- **Entry Point**: Main Shell Bottom Nav Tab 2 (`/tournaments`)
- **Primary Screen**: `TournamentsListScreen`
- **Secondary Screens**: `TournamentDetailScreen` (`/tournament/:tournamentId`), `EventRegistrationScreen` (`/tournament/:id/register`).
- **Primary Action**: Tap tournament card to view event overview, schedule, and rules.
- **Secondary Actions**: Filter by province or status (Upcoming / Live / Completed).
- **Data Shown**:
  - Tournament Title, Organizer name, Province / Venue city.
  - Event Date (`14 Oct 2026`), Registration Fee (`Free` or `PKR 1,500`).
  - Status Chip: `PUBLISHED` (Amber), `ONGOING` (Emerald/Green), `COMPLETED` (Slate Grey).
  - Registered puller count vs maximum capacity slots (e.g. `84/100 SLOTS`).
- **Important States**: Upcoming events list, Ongoing live tournaments, Completed archive.
- **Error States**: "Could not load competitions" with retry CTA button.
- **Empty States**: "No competitions published yet. Check back soon for upcoming sanctioned events."
- **Loading States**: Shimmer card placeholders matching tournament card aspect ratio.
- **Success States**: Live indicator pulsates when a tournament status flips to ONGOING.
- **Permission States**: Public. Draft tournaments are filtered out from public view.
- **Navigation Destination**: `/tournament/:tournamentId`
- **Back Behavior**: Resets to Home tab or exits app.
- **Animation**: Staggered card entrance on initial load (300ms).
- **Interaction Type**: Tap card; pull-to-refresh.
- **Image Requirement**: Tournament banner art or venue photography.
- **Video Requirement**: None for list cards (prevents list scrolling stutter).
- **Generative Asset Requirement**: Optional dark arena graphic for default banners.
- **Accessibility Requirements**: Card announces: "Tournament: Pakistan National Championship, Status: Registration Open, Date: 14 October 2026".
- **Performance Requirements**: Smooth 60fps scrolling; image assets lazily loaded.
- **Offline Behavior**: Displays cached tournament schedule from Hive storage.
- **Related Features**: Feature 11 (Details), Feature 12 (Registration), Feature 13 (Brackets).
- **Dependencies**: `tournamentProvider`.
- **Implementation Notes**: Verified in `features/tournament/screens/tournament_screens.dart`.

---

### Feature 11: Tournament Details, Schedule & Rules
- **Feature Name**: Tournament Overview, Rules & Schedule
- **Target User**: Competitors, spectators, organizers
- **Role**: All roles
- **Purpose**: Complete institutional briefing for a competition: prize pool, live countdown, registration status, categories, weigh-in timeline, rulebook, organizer contacts, and brackets entrance.
- **Entry Point**: Tap any tournament card -> `/tournament/:tournamentId`
- **Primary Screen**: `TournamentDetailScreen`
- **Secondary Screens**: `EventRegistrationScreen` (`/tournament/:id/register`), `TournamentBracketsScreen` (`/tournament/:id/brackets`), `TournamentOperationsScreen` (`/tournament/:id/operations`).
- **Primary Action**: "Register for Event" (sticky bottom bar if registration open)
- **Secondary Actions**: "View Brackets", "Operator Console" (for operators), "View Rules", "Contact Organizer".
- **Data Shown**:
  - Hero Card (`TournamentDetailsHeroWidget`): Name, organizer, location, status badge, live countdown timer (`04d : 12h : 30m`), prize pool (`PKR 500,000`).
  - Important Dates Timeline: Weigh-in start, Brackets draw, First match, Finals.
  - Weight Categories Grid: Senior, Junior, Female; Left & Right arms.
  - Rulebook Accordion: Weight tolerance, foul rules, strap match policies.
  - Organizer Contact Card: Federation contact email and official phone.
- **Important States**: Registration Open, Registration Closed, Live / In Progress, Finished / Results Published.
- **Error States**: Error loading tournament details with retry.
- **Empty States**: N/A (valid tournament ID required).
- **Loading States**: Comprehensive skeleton layout (`TournamentSkeletonLoadingWidget`).
- **Success States**: Direct feedback when user is already registered ("You are registered for Senior -85kg").
- **Permission States**: Publicly readable. Operator console button visible only to assigned organizers and admins.
- **Navigation Destination**: Registration, Brackets, or Operator Console.
- **Back Behavior**: Returns to Tournament Directory.
- **Animation**: Ambient breathing light gradient on Hero card; smooth accordion expansion on rules.
- **Interaction Type**: Scrollable page, expandable accordions, sticky CTA button.
- **Image Requirement**: High-resolution arena/banner photo for hero backdrop with 80% dark gradient mask.
- **Video Requirement**: Optional subtle 5-second seamless arena ambient video loop in hero header on high-end devices.
- **Generative Asset Requirement**: Atmospheric tournament stage visual.
- **Accessibility Requirements**: Sticky CTA stays above screen reader focus order; rules accordions properly announce expanded/collapsed states.
- **Performance Requirements**: Hero gradient animation must not drop frames during scroll.
- **Offline Behavior**: Displays cached tournament details if previously viewed.
- **Related Features**: Feature 12 (Registration), Feature 13 (Brackets), Feature 14 (Operations).
- **Dependencies**: `tournamentProvider`, `tournamentRepositoryProvider`.
- **Implementation Notes**: Verified in `features/tournament/screens/tournament_screens.dart` and `tournament_details_hero_widget.dart`.

---

### Feature 12: Competition Event Registration & Payments
- **Feature Name**: Athlete Tournament Entry & Stripe Checkout
- **Target User**: Athletes entering a competition
- **Role**: Athlete
- **Purpose**: Select division, weight class, and arm choice, agree to athlete conduct rules, and pay registration fee via Stripe or manual QR payment.
- **Entry Point**: Tournament Details -> "Register" (`/tournament/:tournamentId/register`)
- **Primary Screen**: `EventRegistrationScreen`
- **Secondary Screens**: Stripe Payment Sheet modal or Manual QR Verification dialog.
- **Primary Action**: "Confirm & Pay Entry Fee" / "Submit Registration"
- **Secondary Actions**: "Cancel"
- **Data Shown**: Tournament name, division dropdown (Senior, Junior, Female), weight class selector (-70kg, -85kg, -95kg, +95kg), arm choice (Right / Left / Both), fee calculation.
- **Important States**: 
  - `PENDING`: Awaiting organizer approval.
  - `WAITLISTED`: Event at capacity.
  - `PENDING_PAYMENT`: Requires Stripe card payment or manual fee proof.
  - `APPROVED`: Fully confirmed.
- **Error States**: Duplicate registration (already entered), weight class mismatch, Stripe payment declined.
- **Empty States**: N/A (form screen).
- **Loading States**: Button shows spinner while creating registration record or launching Stripe sheet.
- **Success States**: Confirmatory green dialog: "Registered! Your entry has been recorded."
- **Permission States**: Authenticated athletes only.
- **Navigation Destination**: Returns to Tournament Details or My Tickets (`/settings/tickets`).
- **Back Behavior**: Confirms before abandoning unsaved registration inputs.
- **Animation**: 250ms modal push.
- **Interaction Type**: Form inputs, radio selectors, Stripe native payment sheet.
- **Image Requirement**: QR code image for manual bank transfer fallback.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: High-contrast form fields, explicit pricing readout ("Entry fee: 1,500 Pakistani Rupees").
- **Performance Requirements**: Zero memory leaks during Stripe SDK lifecycle.
- **Offline Behavior**: Disabled when offline (requires active payment gateway).
- **Related Features**: Feature 11 (Tournament Details), Feature 26 (Tickets & Payments).
- **Dependencies**: `tournamentProvider`, `flutter_stripe`, `DioClient`.
- **Implementation Notes**: Implemented in `features/tournament/screens/event_registration_screen.dart`.

---

### Feature 13: Interactive Brackets & Match Progression
- **Feature Name**: Tournament Brackets & Double-Elimination Trees
- **Target User**: Athletes, spectators, officials, coaches
- **Role**: All roles
- **Purpose**: Visualize real-time match progression across Winners Bracket, Losers Bracket, and Grand Finals with interactive nodes and custom connector lines.
- **Entry Point**: Tournament Details -> "View Brackets" (`/tournament/:tournamentId/brackets`)
- **Primary Screen**: `TournamentBracketsScreen`
- **Secondary Screens**: `FullInteractiveBracketModal`, `PublicAthleteProfileScreen` (on tapping athlete seed).
- **Primary Action**: Tap match node to view match details, table number, or score breakdown.
- **Secondary Actions**: Filter by Division & Weight Class, toggle Winners/Losers bracket view, zoom in/out.
- **Data Shown**:
  - Bracket seed slots, athlete display names, club tags, ELO ratings.
  - Set scores (e.g. `3 - 1`), winner indicator pill.
  - Table assignment (e.g. `Table 2`), match status (`READY`, `CALLED`, `COMPLETED`).
  - Custom canvas painters: `BracketLinesPainter`, `BracketConnectorsPainter`.
- **Important States**: Bracket unseeded (pre-tournament), active bracket in progress, completed bracket with champion crowned.
- **Error States**: "Could not load bracket data" with retry CTA.
- **Empty States**: "Brackets not generated yet. The organizer will seed brackets following official weigh-ins."
- **Loading States**: Shimmer bracket nodes and lines.
- **Success States**: Live node updates when referee scores are submitted.
- **Permission States**: Publicly viewable.
- **Navigation Destination**: Athlete profile or match details.
- **Back Behavior**: Returns to Tournament Details.
- **Animation**: Smooth interactive pan and zoom via `InteractiveViewer`.
- **Interaction Type**: Two-finger pinch-to-zoom, pan drag, tap node.
- **Image Requirement**: Athlete avatar inside bracket card.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Semantic text equivalent for screen readers: "Match 4: Ali vs Khan, Winner: Ali 3-1".
- **Performance Requirements**: Bracket custom canvas painter must maintain 60fps during pan/zoom.
- **Offline Behavior**: Displays cached bracket state.
- **Related Features**: Feature 14 (Operations), Feature 15 (Referee Scorepad).
- **Dependencies**: `bracketProvider`, `tournamentProvider`.
- **Implementation Notes**: Verified in `features/tournament/widgets/bracket_tree_widget.dart` and `bracket_lines_painter.dart`.

---

### Feature 14: Tournament Operator Console & Live Logistics
- **Feature Name**: Tournament Operations & Weigh-In Logistics
- **Target User**: Tournament Operators, Provincial Directors, Admins
- **Role**: `TOURNAMENT_OPERATOR`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`
- **Purpose**: Control center for running a live armwrestling event: approve registrations, record official weigh-in weights, seed double-elimination brackets, and manage match tables.
- **Entry Point**: Tournament Details -> "Operator Console" (`/tournament/:tournamentId/operations`)
- **Primary Screen**: `TournamentOperationsScreen`
- **Secondary Screens**: Weigh-In Dialog, Table Assignment Modal, Manual Bracket Seed Screen.
- **Primary Action**: "Record Weigh-in" / "Seed Bracket" / "Call Match to Table"
- **Secondary Actions**: Approve registration, override payment, disqualify competitor.
- **Data Shown**:
  - Competitor list with weigh-in status (`PENDING`, `PASSED`, `FAILED`).
  - Measured weight input field against category limit.
  - Table status list (`Table 1: ACTIVE`, `Table 2: IDLE`).
  - Bracket generation trigger button.
- **Important States**: Check-in phase, Weigh-in phase, Bracket Generation phase, Tournament Live phase, Event Finalized.
- **Error States**: Server validation error (e.g. athlete exceeds weight class limit).
- **Empty States**: "No registered athletes for this division."
- **Loading States**: Action buttons show spinners with disabled state to prevent duplicate operations.
- **Success States**: Green snackbar feedback ("Weigh-in recorded: 84.2kg. Status: PASSED").
- **Permission States**: Strictly guarded by role check in `app_router.dart`.
- **Navigation Destination**: Table scorepads or brackets.
- **Back Behavior**: Returns to Tournament Details.
- **Animation**: 200ms list item status update.
- **Interaction Type**: Form inputs, dialog confirmations, destructive action prompts.
- **Image Requirement**: None.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: High-contrast action buttons; destructive actions require confirmation dialogs.
- **Performance Requirements**: Fast response; zero UI freezes during bracket seeding calculation.
- **Offline Behavior**: Disabled; operator actions require live server state reconciliation.
- **Related Features**: Feature 12 (Registration), Feature 13 (Brackets), Feature 15 (Referee Scorepad).
- **Dependencies**: `tournamentProvider`, `tournamentRepositoryProvider`.
- **Implementation Notes**: Verified in `features/tournament/screens/tournament_operations_screen.dart`.

---

### Feature 15: Official Referee Scorepad & Match Officiating
- **Feature Name**: Official Referee Scorepad
- **Target User**: Certified Referees table-side
- **Role**: `REFEREE`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`
- **Purpose**: Official table-side scorekeeping instrument: increment rounds, log fouls, warnings, pin declarations, and submit verified match results directly into the ELO rating engine.
- **Entry Point**: Referee Dashboard (`/referee/dashboard`) -> Tap Assigned Match -> `/referee/submit-scorepad`
- **Primary Screen**: `OfficialScorepadScreen`, `MatchSubmissionScreen`
- **Secondary Screens**: Fouls and Warnings bottom sheet, Evidence Upload (`/referee/upload-evidence`).
- **Primary Action**: "Submit Official Result"
- **Secondary Actions**: "Add Round Win", "Declare Foul", "Declare Warning", "Reset Score".
- **Data Shown**:
  - Puller 1 vs Puller 2 names, avatars, clubs, and arm dominance.
  - Current Set Score (e.g. `2 - 1` in best of 5).
  - Assigned Table Number (`Table 1`).
  - Round-by-round ledger: Winner of Round 1, Round 2, Round 3.
  - Foul counter (2 fouls = 1 loss).
- **Important States**: Match Ready, In Progress, Set Decided (e.g. 3-0 pin), Match Submitted.
- **Error States**: Network error on result submission with retry button.
- **Empty States**: "No active match assigned to this table."
- **Loading States**: Fullscreen semi-transparent overlay with "Submitting official scorepad...".
- **Success States**: Haptic vibration (`HapticFeedback.heavyImpact()`) + audio cue (`match_won.mp3`) + green confirmation.
- **Permission States**: Certified referee assigned to event.
- **Navigation Destination**: Returns to Referee Dashboard.
- **Back Behavior**: Prompts confirmation: "Abandon scorepad? Unsubmitted scores will be lost."
- **Animation**: Score numbers pop with scale bounce on increment.
- **Interaction Type**: Massive 56dp+ touch buttons for table-side thumb operation.
- **Image Requirement**: Puller avatars.
- **Video Requirement**: None (strict low-latency instrument).
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Haptic feedback on every tap; high-contrast buttons (7:1 contrast against dark background).
- **Performance Requirements**: Zero touch lag (<50ms response); screen wake lock active so display does not sleep mid-match.
- **Offline Behavior**: Stores scorepad locally in SQLite/Hive queue if table connectivity drops; syncs immediately upon reconnect.
- **Related Features**: Feature 03 (Dashboard), Feature 08 (Rankings), Feature 13 (Brackets).
- **Dependencies**: `refereeProvider`, `tournamentRepositoryProvider`, `audioPlayerProvider`.
- **Implementation Notes**: Verified in `features/referee/screens/official_scorepad_screen.dart` and `referee_screens.dart`.

---

### Feature 16: Referee Certifications & Federation Licensing
- **Feature Name**: Referee Certification & Official Badges
- **Target User**: Referees checking licensing status
- **Role**: `REFEREE`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`
- **Purpose**: Verify referee certification level (National Grade 1, Provincial Grade 2, Junior Official), renewal dates, and sanctioned match count.
- **Entry Point**: Referee Dashboard -> Certifications (`/referee/certifications`)
- **Primary Screen**: `RefereeCertificationsScreen`
- **Secondary Screens**: N/A.
- **Primary Action**: "Request Re-certification / Renewal"
- **Secondary Actions**: "View Officiated Match History"
- **Data Shown**: Official License ID, Federation Seal, Grade Level, Valid Until Date, Total Matches Officiated, Disciplinary Standing (`IN GOOD STANDING`).
- **Important States**: Active License, Expired License, Pending Federation Review.
- **Error States**: Error loading certifications.
- **Empty States**: "No official referee certifications on record."
- **Loading States**: Shimmer card.
- **Success States**: Verified gold seal displayed.
- **Permission States**: Certified officials only.
- **Navigation Destination**: Returns to Referee Dashboard.
- **Back Behavior**: Returns to previous screen.
- **Animation**: Subtle gold glow on valid badge.
- **Interaction Type**: Tap to inspect license terms.
- **Image Requirement**: Federation digital seal.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Clear expiration date readout.
- **Performance Requirements**: Instant local rendering.
- **Offline Behavior**: Cached license available offline.
- **Related Features**: Feature 15 (Referee Scorepad), Feature 17 (Governance).
- **Dependencies**: `refereeCertificationProvider`.
- **Implementation Notes**: Implemented in `features/referee/screens/referee_screens.dart`.

---

### Feature 17: Governance, Arbitration & Dispute Resolution
- **Feature Name**: Dispute Arbitration & Formal Complaints
- **Target User**: Athletes, Referees, Compliance Officers
- **Role**: All roles can file; `COMPLIANCE_OFFICER`, `ORGANIZATION_LEADER`, `SYSTEM_ADMIN` arbitrate.
- **Purpose**: File formal complaints against match outcomes, referee conduct, or weigh-in irregularities, and review ongoing arbitration evidence.
- **Entry Point**: Main Shell Tab 0 (for Governance role) or `/governance`
- **Primary Screen**: `GovernanceDashboardScreen`, `DisputeDetailScreen` (`/governance/dispute/:id`)
- **Secondary Screens**: `SubmitComplaintScreen` (`/governance/submit-complaint`).
- **Primary Action**: "File Dispute / Complaint"
- **Secondary Actions**: "Upload Video Evidence", "Add Arbitration Comment", "Resolve Dispute".
- **Data Shown**: Dispute ID, Event Name, Involved Pullers, Status Badge (`OPEN`, `ESCALATED`, `AWAITING_EVIDENCE`, `RESOLVED`, `REJECTED`), formal complaint text, uploaded evidence files.
- **Important States**: Open case, awaiting evidence, resolved with ruling.
- **Error States**: Form validation error, upload timeout.
- **Empty States**: "No disputes filed. Open arbitration cases will appear here once submitted."
- **Loading States**: Skeleton card list.
- **Success States**: Green snackbar: "Complaint filed successfully. Assigned Case ID #1042."
- **Permission States**: All authenticated users can file; resolution controls restricted to Compliance Officers.
- **Navigation Destination**: Dispute details or complaint submission.
- **Back Behavior**: Returns to Governance Dashboard.
- **Animation**: 250ms slide transition.
- **Interaction Type**: Form submission, file picker for photo/video evidence.
- **Image Requirement**: Evidence image previews.
- **Video Requirement**: Evidence video playback via modal player.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: High-contrast status badges (Emerald, Coral, Amber).
- **Performance Requirements**: Chunked evidence upload with progress indicator.
- **Offline Behavior**: Disabled (requires direct server case creation).
- **Related Features**: Feature 15 (Referee Scorepad), Feature 11 (Tournaments).
- **Dependencies**: `disputeProvider`.
- **Implementation Notes**: Verified in `features/governance/screens/governance_screens.dart`.

---

### Feature 18: Community Video Feed & Social Highlights
- **Feature Name**: Community Video Feed & Technical Discussion
- **Target User**: Armwrestling community, athletes, fans
- **Role**: All authenticated users
- **Purpose**: Share training clips, practice match highlights, and technical breakdowns via YouTube, TikTok, or Facebook video links; like and comment on community posts.
- **Entry Point**: Main Shell Bottom Nav Tab 3 (`/community/feed`)
- **Primary Screen**: `CommunityFeedScreen`
- **Secondary Screens**: `CreatePostScreen` (`/community/create`), `PostCommentsScreen` (`/community/posts/:id/comments`), `VideoPlayerModal`.
- **Primary Action**: "Share a Video Link" (`+` icon in AppBar)
- **Secondary Actions**: Like post (heart icon), Open comment thread, Tap athlete author avatar, Play video.
- **Data Shown**:
  - Author Avatar, Display Name, Timestamp.
  - Post caption / title.
  - Video Embed Preview (YouTube thumbnail, TikTok embed, or WebView player).
  - Like count, Comment count.
- **Important States**: Feed active, empty feed, infinite scrolling pagination.
- **Error States**: "Could not load feed" with retry CTA.
- **Empty States**: "No posts yet. Be the first to share a training or match video."
- **Loading States**: Shimmer skeleton cards (`SkeletonPlaceholder(height: 180)`).
- **Success States**: Instant optimistic increment on like count; new post prepended to feed.
- **Permission States**: Authenticated users can post, like, and comment; public can browse.
- **Navigation Destination**: `/community/posts/:postId/comments` or `/community/create`
- **Back Behavior**: Resets to Home tab or exits app.
- **Animation**: Subtle heart scale bounce on like toggle; smooth infinite scroll loading.
- **Interaction Type**: Vertical scroll, tap video to play in modal WebView, text input for comments.
- **Image Requirement**: Author avatars and external video thumbnails.
- **Video Requirement**: In-app embedded video player via `webview_flutter` modal.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Video play buttons have descriptive labels ("Play video: Bicep training by Ali").
- **Performance Requirements**: Video embeds do not autoplay in list (prevents severe memory leaks and battery drain).
- **Offline Behavior**: Cached feed posts displayed with offline indicator.
- **Related Features**: Feature 04 (Profile), Feature 05 (Public Profile).
- **Dependencies**: `communityFeedProvider`, `EmbedUrlBuilder`, `webview_flutter`.
- **Implementation Notes**: Verified in `features/community/screens/community_feed_screen.dart`.

---

### Feature 19: Direct Messaging & Conversations
- **Feature Name**: Direct Peer Messaging & Chat
- **Target User**: Athletes, coaches, training partners
- **Role**: All authenticated users
- **Purpose**: Real-time communication between athletes to coordinate training sessions, arrange informal super-matches, or discuss competition logistics.
- **Entry Point**: Athlete Profile -> "Message" or `/messages`
- **Primary Screen**: `ConversationsListScreen`, `ChatScreen` (`/messages/:conversationId`)
- **Secondary Screens**: User blocking confirmation (`/settings/blocked`).
- **Primary Action**: Send text message (send button or keyboard submit)
- **Secondary Actions**: View participant profile, mute conversation, block user.
- **Data Shown**:
  - Conversation list: Other participant avatar, name, last message snippet, timestamp, unread badge.
  - Chat screen: Chronological message bubbles (incoming on left in dark slate; outgoing on right in primary accent), timestamp, delivered/read receipts.
- **Important States**: Empty inbox, active conversation, 10s background polling update.
- **Error States**: Failed message delivery with red warning icon and "Tap to retry".
- **Empty States**: "No conversations yet. Open an athlete's profile and tap Message to start a conversation."
- **Loading States**: Shimmer list items (`SkeletonPlaceholder(height: 72)`).
- **Success States**: Instant optimistic message append to chat bubble list.
- **Permission States**: Authenticated users. Respects blocked user list.
- **Navigation Destination**: `/messages/:conversationId`
- **Back Behavior**: Returns to inbox or previous profile screen.
- **Animation**: New messages slide up smoothly into view.
- **Interaction Type**: Keyboard input, scrollable chat list, tap bubble.
- **Image Requirement**: Participant profile avatars.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Message bubbles have semantic time and sender announcements.
- **Performance Requirements**: Reverse `ListView.builder` handles 1,000+ messages without frame drops.
- **Offline Behavior**: Queues outgoing messages in local Hive storage; sends when connection restores.
- **Related Features**: Feature 05 (Public Profile), Feature 20 (Notifications).
- **Dependencies**: `conversationsProvider`, `chatMessagesProvider`.
- **Implementation Notes**: Verified in `features/messaging/screens/messaging_screens.dart`.

---

### Feature 20: Federation Announcements & Broadcasts
- **Feature Name**: Official Announcements & Federation Broadcasts
- **Target User**: All users
- **Role**: All roles
- **Purpose**: Review official federation policy updates, emergency event schedule changes, and national championship announcements.
- **Entry Point**: Discover Screen banner or `/announcements`
- **Primary Screen**: `AnnouncementsListScreen`, `NotificationsListScreen` (`/notifications`)
- **Secondary Screens**: Announcement detail modal.
- **Primary Action**: Tap announcement card to read full executive notice.
- **Secondary Actions**: Mark all notifications as read.
- **Data Shown**: Official announcement title, publishing authority (e.g. "PAFF Executive Council"), priority flag (`URGENT` / `GENERAL`), published date, body content.
- **Important States**: Unread announcement badge, empty notifications inbox.
- **Error States**: "Could not load announcements."
- **Empty States**: "No announcements posted. Official federation broadcasts will appear here."
- **Loading States**: Shimmer notification rows.
- **Success States**: Badge clears upon opening.
- **Permission States**: Publicly viewable.
- **Navigation Destination**: Respective event or announcement.
- **Back Behavior**: Returns to Discover or previous screen.
- **Animation**: 250ms slide.
- **Interaction Type**: Tap row; pull-to-refresh.
- **Image Requirement**: Federation seal.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Urgent announcements announced immediately by screen reader.
- **Performance Requirements**: Instant rendering from cache.
- **Offline Behavior**: Displays cached announcements.
- **Related Features**: Feature 10 (Tournaments), Feature 17 (Governance).
- **Dependencies**: `announcementProvider`, `notificationProvider`.
- **Implementation Notes**: Verified in `features/messaging/screens/announcement_screens.dart`.

---

### Feature 21: Venue Partner Directory & Verification
- **Feature Name**: Approved Training Venues & Gym Partners
- **Target User**: Athletes looking for physical training tables
- **Role**: All roles
- **Purpose**: Directory of verified gyms, sports complexes, and clubs equipped with official armwrestling competition tables; athletes can also submit new training venues for federation verification.
- **Entry Point**: Discover Screen AppBar -> Venues (`/venues`)
- **Primary Screen**: `VenueDirectoryScreen`, `VenueDetailScreen` (`/venues/:venueId`)
- **Secondary Screens**: `SubmitVenueScreen` (`/venues/submit`).
- **Primary Action**: "Submit a Venue" (`+` button)
- **Secondary Actions**: Call venue, open directions in map, view table count.
- **Data Shown**: Venue name, address, city, province, official table count (e.g. `3 Mazurenko Tables`), operating hours, contact phone, verified partner badge.
- **Important States**: Directory list, venue submission form.
- **Error States**: Could not load venues.
- **Empty States**: "No venues listed yet. Know a training space with official tables? Submit it for verification."
- **Loading States**: Shimmer cards.
- **Success States**: Green snackbar: "Venue submitted for federation inspection."
- **Permission States**: Public.
- **Navigation Destination**: `/venues/:id` or `/venues/submit`
- **Back Behavior**: Returns to Discover.
- **Animation**: Standard page transition.
- **Interaction Type**: Tap venue card, map external link launch.
- **Image Requirement**: Venue photography.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Phone numbers and addresses properly formatted for OS actions.
- **Performance Requirements**: Bounded list rendering.
- **Offline Behavior**: Cached directory viewable offline.
- **Related Features**: Feature 22 (Informal Meetups).
- **Dependencies**: `venueListProvider`.
- **Implementation Notes**: Verified in `features/venue/screens/venue_directory_screen.dart`.

---

### Feature 22: Informal Pickup Meetups & Practice Tables
- **Feature Name**: Informal Meetups & Grassroots Practice Sessions
- **Target User**: Pullers organizing local sparring sessions
- **Role**: All authenticated athletes
- **Purpose**: Community-driven practice sessions: post a meetup time and table location, RSVP attendance, and connect with local training partners without formal ELO stakes.
- **Entry Point**: Discover Screen AppBar -> Meetups (`/informal-events`)
- **Primary Screen**: `InformalEventDirectoryScreen`, `InformalEventDetailScreen` (`/informal-events/:id`)
- **Secondary Screens**: `CreateInformalEventScreen` (`/informal-events/create`).
- **Primary Action**: "Create Practice Meetup" (`+` icon)
- **Secondary Actions**: "Join Session / RSVP", "View Attending Pullers".
- **Data Shown**: Session title, date and start time, host athlete, venue location, attending puller count, sparring notes.
- **Important States**: Upcoming meetups, meetup in progress, past meetups.
- **Error States**: Could not load meetups.
- **Empty States**: "No practice meetups scheduled. Host a session to pull with athletes in your city."
- **Loading States**: Shimmer cards.
- **Success States**: Instant RSVP update ("You're attending!").
- **Permission States**: Authenticated users can host and RSVP.
- **Navigation Destination**: `/informal-events/:id` or `/informal-events/create`
- **Back Behavior**: Returns to Discover.
- **Animation**: 250ms slide.
- **Interaction Type**: Tap card, RSVP toggle button, creation form.
- **Image Requirement**: Host athlete avatar.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Clear time and location formatting.
- **Performance Requirements**: Lightweight list.
- **Offline Behavior**: Cached meetups displayed offline.
- **Related Features**: Feature 21 (Venues), Feature 18 (Community).
- **Dependencies**: `informalEventListProvider`.
- **Implementation Notes**: Verified in `features/informal_event/screens/informal_event_directory_screen.dart`.

---

### Feature 23: Grassroots Talent Nominations
- **Feature Name**: Grassroots Talent Nomination Engine
- **Target User**: Athletes, coaches, provincial talent scouts
- **Role**: All authenticated users
- **Purpose**: Nominate undiscovered armwrestlers from rural or unrepresented areas for federation sponsorship, official training camps, and national team tryouts.
- **Entry Point**: Profile -> Nominations or `/nominate` (`/nominations/submit`)
- **Primary Screen**: `NominateTalentScreen`, `MyNominationsScreen` (`/nominations/my`)
- **Secondary Screens**: N/A.
- **Primary Action**: "Submit Nomination"
- **Secondary Actions**: View nomination review status.
- **Data Shown**: Candidate full name, city/province, estimated weight class, scouting notes / reason for nomination, review status (`PENDING_REVIEW`, `APPROVED_FOR_TRYOUT`, `DECLINED`).
- **Important States**: New form, submitted list with status stamps.
- **Error States**: Validation errors on required fields.
- **Empty States**: "You haven't nominated any athletes yet."
- **Loading States**: Spinner on submit button.
- **Success States**: Green snackbar: "Nomination filed successfully! Federation scouts will review the submission."
- **Permission States**: Authenticated users.
- **Navigation Destination**: Returns to My Nominations or Profile.
- **Back Behavior**: Returns to previous screen.
- **Animation**: Standard transition.
- **Interaction Type**: Form submission.
- **Image Requirement**: None.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Accessible form validation.
- **Performance Requirements**: Instant form response.
- **Offline Behavior**: Disabled when offline.
- **Related Features**: Feature 04 (Profile), Feature 17 (Governance).
- **Dependencies**: `nominationRepositoryProvider`.
- **Implementation Notes**: Implemented in `features/nomination/screens/nominate_talent_screen.dart`.

---

### Feature 24: Team Rosters & Armwrestling Clubs
- **Feature Name**: Armwrestling Clubs & Team Rosters
- **Target User**: Athletes in organized clubs
- **Role**: All authenticated athletes; Team Captains
- **Purpose**: Create teams, invite teammates, view club rosters, manage captain privileges, and represent clubs at national championship tournaments.
- **Entry Point**: Dashboard shortcut "My Team" or `/teams`
- **Primary Screen**: `TeamsListScreen`, `TeamDetailScreen` (`/teams/:teamId`)
- **Secondary Screens**: `CreateTeamScreen` (`/teams/create`), Invite Athlete modal.
- **Primary Action**: "Create Team" or "Invite Athlete" (for captains)
- **Secondary Actions**: Leave team, remove member, view teammate profile.
- **Data Shown**: Team Name, City, Province, Captain display name, member roster count, list of member athletes with ELO scores and arm dominance, team achievements.
- **Important States**: Member of 1+ teams, not in any team, captain controls enabled.
- **Error States**: Could not load teams.
- **Empty States**: "You are not a member of any team. Create one and start building your roster."
- **Loading States**: Shimmer team cards (`SkeletonPlaceholder(height: 88)`).
- **Success States**: New teammate added immediately to roster list.
- **Permission States**: Authenticated users; edit controls restricted to team captains.
- **Navigation Destination**: `/teams/:id` or `/teams/create`
- **Back Behavior**: Returns to Dashboard.
- **Animation**: 250ms slide.
- **Interaction Type**: Tap team card, tap member row, form entry.
- **Image Requirement**: Team crest / logo.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Clear role designations (Captain vs Member).
- **Performance Requirements**: Fast list rendering.
- **Offline Behavior**: Displays cached team roster.
- **Related Features**: Feature 05 (Public Profile), Feature 10 (Tournaments).
- **Dependencies**: `myTeamsProvider`, `socialProvider`.
- **Implementation Notes**: Verified in `features/team/screens/team_screens.dart`.

---

### Feature 25: Championship Titles & Belt Lineages
- **Feature Name**: National Championship Titles & Belt History
- **Target User**: Athletes, fans, historians
- **Role**: All roles
- **Purpose**: Canonical registry of recognized national and provincial championship belts, current titleholders, defenses count, and historical reign lineages.
- **Entry Point**: Discover Screen or `/championship/titles`
- **Primary Screen**: `ChampionshipsListScreen`, `ChampionshipDetailScreen` (`/championship/:championshipId`)
- **Secondary Screens**: Historical Reign modal.
- **Primary Action**: Tap title card to view belt history and lineage.
- **Secondary Actions**: View champion's public profile.
- **Data Shown**: Title Name (e.g. "Pakistan Heavyweight Right Arm Title"), Arm (Right/Left), Weight Class (+95kg), Current Champion Avatar & Name, Total Defenses (`4 defenses`), Reign Duration (`312 days`), Complete historical reign list with reason for change (Pin, Forfeit, Vacated).
- **Important States**: Active champion crowned, Vacant title.
- **Error States**: Could not load championships with retry.
- **Empty States**: "No active titles. Championship titles will appear once the federation activates them."
- **Loading States**: Shimmer card placeholders.
- **Success States**: Gold championship laurel icon alongside reigning champion.
- **Permission States**: Publicly viewable.
- **Navigation Destination**: `/championship/:id`
- **Back Behavior**: Returns to Discover or previous tab.
- **Animation**: Gold sheen glow on active championship card.
- **Interaction Type**: Scrollable list, tap card.
- **Image Requirement**: Vector championship belt graphic.
- **Video Requirement**: None.
- **Generative Asset Requirement**: Premium dark leather / gold metallic texture for belt card.
- **Accessibility Requirements**: High-contrast gold accents against dark surface.
- **Performance Requirements**: Lightweight static card rendering.
- **Offline Behavior**: Cached title lineage available offline.
- **Related Features**: Feature 07 (Honors), Feature 10 (Tournaments).
- **Dependencies**: `championshipProvider`, `beltLineageProvider`.
- **Implementation Notes**: Verified in `features/championship/screens/championship_screens.dart`.

---

### Feature 26: Account Settings, Security & Legal Compliance
- **Feature Name**: Settings Hub, Security, Active Sessions & GDPR
- **Target User**: Signed-in user managing their account
- **Role**: All authenticated users
- **Purpose**: Complete account administration: biometric toggle, active login sessions management, Stripe payment methods, purchased event tickets, blocked users list, GDPR account deletion, Terms of Service, and Privacy Policy.
- **Entry Point**: Athlete Profile -> Settings (`/settings`)
- **Primary Screen**: `SettingsHubScreen`
- **Secondary Screens**: `ActiveSessionsListScreen` (`/session`), `PaymentMethodsScreen` (`/settings/payment-methods`), `MyTicketsScreen` (`/settings/tickets`), `BlockedUsersScreen` (`/settings/blocked`), `AccountDeletionScreen` (`/settings/deletion`), `TermsScreen` (`/settings/terms`), `PrivacyPolicyScreen` (`/settings/privacy`).
- **Primary Action**: Select settings category.
- **Secondary Actions**: Revoke session, delete account, toggle biometric authentication, log out.
- **Data Shown**: 
  - Biometric toggle (Face Unlock / Fingerprint).
  - Signed-in devices: Browser, OS, Device name, IP address, Last active date, "Revoke" button.
  - Saved payment cards (last 4 digits, brand icon).
  - Purchased tournament entry tickets with barcode/QR verification token.
  - Blocked users list with unblock button.
  - GDPR account deletion warning and confirmation prompt.
- **Important States**: Authenticated settings, destructive confirmation modal.
- **Error States**: Session revocation failure, deletion failure.
- **Empty States**: "No blocked users", "No active tickets purchased".
- **Loading States**: Spinner during session revocation or logout.
- **Success States**: Confirmation toast on settings change.
- **Permission States**: Authenticated user.
- **Navigation Destination**: Respective settings sub-screens.
- **Back Behavior**: Returns to Athlete Profile.
- **Animation**: 250ms slide.
- **Interaction Type**: Toggle switches, tap list tiles, destructive confirmation dialogs.
- **Image Requirement**: None.
- **Video Requirement**: None.
- **Generative Asset Requirement**: None.
- **Accessibility Requirements**: Destructive actions (Account Deletion) require explicit 2-step confirmation and high-contrast red warning labels.
- **Performance Requirements**: Instant toggle response.
- **Offline Behavior**: Legal terms cached locally; session revocation requires network connection.
- **Related Features**: Feature 01 (Auth), Feature 04 (Profile).
- **Dependencies**: `sessionProvider`, `authProvider`, `local_auth`.
- **Implementation Notes**: Verified in `features/settings/screens/settings_hub_screens.dart` and `session_screens.dart`.
