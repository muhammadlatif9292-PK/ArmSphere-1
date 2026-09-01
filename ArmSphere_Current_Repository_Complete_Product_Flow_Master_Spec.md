# ARMSPHERE — CURRENT-REPOSITORY PRODUCT BLUEPRINT & MASTER COMPLETION SPECIFICATION
## Exact user journey • screen architecture • role-aware behavior • feature connections • missing-work discovery • production launch plan

**Source reviewed:** `armsphere(3).zip` supplied for this task.  
**Mode of this document:** Repository-grounded product blueprint and master implementation specification.  
**Important:** This document describes the product that must be built from the actual current repository. It does not assume that the existing UI or previous completion claims are correct.

---

# 0. WHAT THIS DOCUMENT IS FOR

The current ArmSphere repository contains a substantial backend, database, Flutter application, Admin Web application, shared packages, authentication, tournaments, matches, rankings, community, messaging, governance, payments, ticketing, clubs/teams, notifications and other infrastructure.

However, the current repository should **not** be treated as a finished consumer product simply because those pieces exist.

The product must be rebuilt/finished around the **real user's journey**:

> A person who knows nothing about the codebase opens ArmSphere for the first time → understands what ArmSphere is → can register without already having an account → completes the correct onboarding → receives only the capabilities they are actually authorized to use → reaches a coherent home → discovers real ArmSphere content → performs real actions → sees persisted results → can return later → can recover from errors → can manage account/security/privacy → can use role-specific workflows when legitimately authorized → can eventually complete the entire competitive or operational lifecycle.

The coding agent must therefore treat this file as the **master product-completion contract**, while still verifying every item against the live repository before implementing it.

---

# 1. VERIFIED CURRENT REPOSITORY SNAPSHOT

The supplied repository contains, at minimum:

## Applications

### Mobile
`apps/mobile`

The current archive contains approximately **187 mobile files** and **44 screen files** under `apps/mobile/lib/**/screens/`.

The mobile app has:

- Flutter
- Riverpod
- GoRouter
- Dio
- secure storage
- Hive/local persistence
- Firebase messaging
- notifications
- Stripe
- audio
- offline/differential sync
- image picker
- WebView
- social/community functionality
- tournaments
- rankings
- athlete profiles
- referee functionality
- governance
- teams
- venues
- nominations
- informal events
- ticketing/session/settings functionality

### Admin Web
`apps/admin-web`

Current application contains:

- login
- dashboard
- analytics
- championships
- governance
- athletes
- moderation
- venues
- nominations

### API
`apps/api`

Current repository contains:

- 23 route modules
- 19 controller modules
- 30 service modules
- database/migration infrastructure
- security/authentication
- scheduled jobs
- storage
- payments
- social auth
- notifications
- sync
- governance
- tournament engine
- rankings
- ELO-related match processing

### Shared packages

- `packages/types`
- `packages/core`
- `packages/cryptography`
- `packages/db-schema`

Canonical role enum currently contains exactly:

- `SYSTEM_ADMIN`
- `NATIONAL_DIRECTOR`
- `PROVINCIAL_DIRECTOR`
- `REFEREE`
- `TOURNAMENT_OPERATOR`
- `COMPLIANCE_OFFICER`
- `SUPPORT_AGENT`
- `ATHLETE`
- `ORGANIZATION_LEADER`

---

# 2. CRITICAL CURRENT-PRODUCT FINDINGS FROM THE ACTUAL ZIP

These are not theoretical requirements; they are important observations from the supplied repository that must be verified and addressed during implementation.

## 2.1 Registration currently does NOT establish the authenticated mobile session

Current `apps/mobile/lib/features/auth/providers/auth_provider.dart`:

- `register()` calls `AuthRepository.register(...)`
- caches the returned profile in Hive
- marks state as `AuthStatus.onboardingRequired`
- does **not** acquire/store access and refresh tokens before entering onboarding

Current backend `apps/api/src/services/auth.ts`:

- public registration creates the account
- forces `UserRole.ATHLETE`
- returns the user record without access/refresh tokens

Current repository `apps/mobile/lib/core/api/repositories.dart`:

- registration calls `POST /auth/register`
- login calls `POST /auth/login`
- onboarding calls `POST /athletes`

Therefore the actual production path currently needs to be verified carefully:

`Register → authenticated session → onboarding`

must not become:

`Register → onboarding UI → POST /athletes → 401`

This is a critical flow-level requirement.

---

## 2.2 The current mobile router still contains legacy role checks

Current `apps/mobile/lib/core/routing/app_router.dart` contains:

- `REFEREE`
- `TOURNAMENT_DIRECTOR`
- `ADMIN`
- `TOURNAMENT_ADMIN`

The canonical shared role enum does not contain those legacy names.

The router currently sends ordinary authenticated users to `/discover`, which currently resolves to `RankingsScreen`, while a separate `DiscoverScreen` exists but is not the `/discover` destination in this router.

This must be redesigned, not merely patched.

---

## 2.3 The first authenticated destination is not yet a proper personalized product home

Current router:

- `/` → Splash
- authenticated fallback → `/discover`
- `/discover` → `RankingsScreen`

The product requirement is different:

> authenticated user → role-aware home shell → useful personalized dashboard/discovery

The existing screens should be reused where appropriate, but the navigation model must be redesigned around actual user goals.

---

## 2.4 Current mobile onboarding is athlete-specific only

`OnboardingScreen` is explicitly:

> `Athlete Onboarding`

and currently collects:

- display/ring name
- city
- province/state
- weight
- height
- reach
- dominant arm
- gender
- date of birth

That may be valid for an athlete, but it is NOT a complete onboarding system for the entire role model.

There is currently no coherent first-run role-selection experience that asks a user what they intend to do and then routes them into an appropriate onboarding path while keeping actual privileged authorization server-side.

---

## 2.5 Several visible production screens still contain simulated/fake behavior

Current repository scan found production-facing occurrences including:

- forgot password: `Future.delayed(...)`
- reset password: `Future.delayed(...)`
- MFA setup: `Future.delayed(...)`
- create community post: `Future.delayed(...)`
- governance complaint submission: `Future.delayed(...)`
- create informal event: `Future.delayed(...)`
- talent nomination: `Future.delayed(...)`
- team creation: `Future.delayed(...)`
- event registration: `Future.delayed(...)`
- venue submission: `Future.delayed(...)`
- referee evidence upload: `"Video file selector mock"`
- global search: explicit local `mockItems`
- discovery screen: `"Rankings coming soon"`
- tournament registration UI contains mock QR/barcode presentation
- some visual widgets contain animation delays which may be legitimate and must not be confused with network simulation

Every occurrence must be classified as:

1. legitimate UI animation
2. test-only
3. development-only
4. acceptable static configuration
5. production feature simulation that must be replaced

Category 5 must be eliminated.

---

## 2.6 A support-agent product surface is not present in the current mobile screen inventory

The current supplied mobile archive contains role-related features for athlete, referee, tournaments, teams, governance, community, etc., but there is no dedicated `support` screen folder in the mobile screen inventory.

If `SUPPORT_AGENT` is part of the intended product, it requires a real operational surface or an explicit decision that it is an Admin Web-only role.

Do not silently assume one.

---

## 2.7 Organization Leader has a route/screen family but requires end-to-end verification

The current repository contains:

- `TeamsListScreen`
- `TeamDetailScreen`
- `CreateTeamScreen`

and backend social routes include:

- `POST /teams`
- `POST /teams/:teamId/members`
- `DELETE /teams/:teamId/members/:athleteId`
- `GET /teams/:teamId`

But this is only the beginning of a complete organization workflow.

The final product must define:

- organization identity
- ownership
- roster
- invitations
- approval
- removal
- tournament participation
- organizer permissions
- club/team relationship
- geographic scope
- auditability

---

# 3. THE PRODUCT MODEL — HOW ARMSpHERE SHOULD FEEL

ArmSphere should feel like a **real competitive sports platform**, not an internal database console.

The visual and interaction language should communicate:

- athletic
- premium
- serious
- modern
- trustworthy
- competition-focused
- community-aware
- international/federation-grade
- easy enough for a first-time athlete

The system may retain the strong dark/glass/sport aesthetic already present, but technical vocabulary should not leak into user-facing screens.

Never present:

- route names
- API paths
- database language
- developer debug labels
- raw role constants
- raw server errors
- fake/demo indicators
- unfinished “coming soon” operations

---

# 4. THE FIRST CLICK — COLD START USER JOURNEY

This is the most important product flow.

## State A — Completely new user

### Step 1 — App opens

Show:

- ArmSphere identity
- polished splash
- short loading
- local state restoration check

Do NOT immediately show a developer/admin login.

Do NOT force an already-registered email.

---

## Step 2 — First-run welcome

If there is no account and no completed onboarding:

Show a true public welcome experience:

### Hero message
What ArmSphere is.

### Core benefits
- compete
- discover athletes
- track performance/rankings
- find tournaments
- connect with the community
- use official competition tools when authorized

### Primary actions

`Create account`

`Sign in`

Optional:

`Explore ArmSphere`

Only include anonymous exploration if the backend and privacy model support it safely.

---

## Step 3 — Account creation

The user chooses `Create account`.

Required UX:

- full name
- email
- password
- confirm password
- terms/privacy acceptance
- clear password requirements
- show/hide password
- validation
- duplicate account handling
- loading
- retry
- success
- safe error messages

The registration API must create the account.

The mobile app must then establish the correct authenticated state before attempting protected onboarding APIs.

---

# 5. ROLE DISCOVERY — IMPORTANT INTERPRETATION

The user's statement that the app may look different at different times is correct, but it should be interpreted as:

> **The interface changes according to the user's current role, permissions, onboarding state, verification status, event context, and available data — not randomly and not by exposing arbitrary hidden screens.**

This is a core product principle.

## Examples

An athlete sees:

- rankings
- upcoming competitions
- profile
- training
- community
- registrations

A referee sees the same safe public/athlete-compatible foundation where appropriate, plus:

- referee dashboard
- certification
- assigned events
- scorepad
- verification actions

A tournament operator sees:

- event management
- participants
- seeding
- brackets
- tables
- live operations

A national director sees:

- federation management
- championships
- analytics
- governance

A support agent sees:

- support operations

A system administrator sees:

- system-wide administration

The user must never receive an elevated permission merely because they selected a role during signup.

---

# 6. ROLE SELECTION / ROLE REQUEST MODEL

Separate these concepts:

## Intent

What the user wants to do.

Example:

`I am an athlete`

`I am a referee`

`I organize competitions`

`I represent an organization`

## Verified role

What the backend has granted.

## Permissions

What this role can actually perform.

The UI may allow a role request.

The backend must decide whether that request is granted, pending, rejected or needs verification.

Never trust a role passed by Flutter/React.

---

# 7. ROLE-SPECIFIC ONBOARDING

## 7.1 ATHLETE / ARMWRESTLER

Flow:

Account
→ Athlete intent
→ Athlete profile
→ competition information
→ body/competition information
→ location
→ club/federation
→ profile privacy
→ finish

Current athlete onboarding fields should be retained where correct:

- display/ring name
- city
- province/state
- weight
- height
- reach
- dominant arm
- gender
- date of birth

Add missing information only where the backend/domain already supports it or where it is clearly necessary.

Do not force a long form on first launch.

Use staged onboarding.

---

## 7.2 REFEREE / OFFICIAL

Flow:

Account
→ Referee intent
→ official profile
→ federation/region
→ experience
→ certification application
→ supporting information/documents
→ pending verification
→ active once approved
→ referee dashboard

Important:

Selecting `Referee` must NOT grant referee permissions.

The backend must keep the user in the correct pending/approved state.

---

## 7.3 TOURNAMENT / EVENT ORGANIZER

Flow:

Account
→ Organizer intent
→ organization profile
→ contact information
→ region
→ organizer verification
→ approved event-creation capabilities
→ organizer dashboard

Potential capabilities:

- create event
- venue
- divisions/categories
- registration
- payments
- check-in
- weigh-in
- seeding
- bracket generation
- table assignment
- referee assignment
- match operations
- results

---

## 7.4 ORGANIZATION LEADER / CLUB

Flow:

Account
→ Organization intent
→ organization/club creation or invitation
→ organization profile
→ verification
→ team creation
→ roster
→ invitations
→ permissions
→ organization dashboard

Must eventually support:

- roster additions
- athlete invitations
- approval
- removal
- role/manager permissions
- club profile
- event participation
- tournament/team registration where product rules allow

---

## 7.5 GOVERNANCE / DIRECTOR / COMPLIANCE / SYSTEM ADMIN

These are NOT ordinary self-service public signup roles.

They must be provisioned/approved through secure administrative mechanisms.

The public UI must never contain a:

`Become System Admin`

button.

The Admin Web remains a controlled privileged surface.

---

# 8. ROLE-AWARE HOME

After authentication/onboarding, the user enters a role-aware shell.

The shell should preserve common identity/navigation while changing the content and action set appropriately.

## Common bottom/navigation model

Possible universal sections:

- Home
- Discover
- Competitions
- Community
- Profile

Role-specific actions should appear contextually.

Do not add five separate bottom-nav systems merely because five roles exist.

---

# 9. ATHLETE HOME — END-TO-END

The athlete dashboard should answer:

> What matters to me today?

Possible order:

1. greeting/profile summary
2. current rank
3. left/right arm ratings
4. upcoming competition
5. registration reminders
6. recent results
7. training/PRs
8. live competitions
9. recommended athletes/content
10. community
11. achievements

The current repository already contains many widgets such as:

- hero athlete card
- performance graph
- stats overview
- upcoming match card
- achievements
- PR card
- telemetry radar
- prestige
- XP
- trophy sections

These must be tied to trustworthy real state rather than invented numbers.

---

# 10. DISCOVER

The existing repository contains both:

- `DiscoverScreen`
- `RankingsScreen`

but `/discover` currently resolves to `RankingsScreen`.

This must be intentionally resolved.

Recommended Discover contains:

- athletes
- competitions
- rankings
- clubs
- venues
- community
- live events

Search and filters must use the real API.

The existing `GlobalSearchScreen` currently uses `mockItems`; that must become real search or be explicitly scoped to a safe local-only feature.

---

# 11. ATHLETE PROFILE

Build complete profile:

- identity
- photo
- country/region
- club
- verification status
- left/right ELO
- ranking
- recent matches
- achievements
- PRs
- competition history
- followers/following
- public/private visibility

Owner actions:

- edit profile
- edit biometrics
- privacy
- profile photo
- security

Public actions:

- follow
- message if allowed
- report
- block

Privacy must be enforced at API/service level.

---

# 12. RANKINGS

Current backend:

- ranking leaderboard
- ranking snapshots
- ELO

Current mobile ranking screen exists.

Complete the product flow:

Discover
→ Rankings
→ filters
→ ranking result
→ athlete profile
→ match/history

Filters should be based on actual supported dimensions such as:

- arm
- weight class
- region
- season
- competition context

Do not manufacture unsupported filter dimensions.

---

# 13. COMPETITION DISCOVERY

Current repository supports tournament screens and backend event/tournament routes.

Final UX:

Competitions
→ list
→ filters
→ event details
→ categories
→ eligibility
→ registration
→ payment if required
→ confirmation
→ registration status
→ event dashboard

Event cards must have real state:

- registration open
- closing soon
- full
- completed
- cancelled

---

# 14. EVENT REGISTRATION — CURRENT KNOWN DEFECT

`EventRegistrationScreen` currently contains `Future.delayed(...)`.

This must become a real transaction:

1. choose event
2. choose category/division
3. verify athlete eligibility
4. verify profile completeness
5. calculate required payment if any
6. confirm rules
7. process payment
8. persist registration
9. show confirmation
10. expose registration status

Never show success before backend confirmation.

---

# 15. PAYMENT FLOW

Current API supports:

- payment methods
- setup intent
- payment webhook

Current app has `PaymentMethodsScreen`.

Complete payment where the product actually requires it.

Do not pretend that saved payment method management equals event checkout.

If an event is free, show clearly that no payment is required.

---

# 16. TOURNAMENT OPERATIONS

For authorized operator users:

Event dashboard:

- event details
- status
- participant count
- registrations
- payment state
- venue
- categories
- divisions
- weigh-ins
- check-in
- seeding
- brackets
- tables
- referees
- live matches
- results
- final standings
- medals

Operations screens already exist but require complete connectivity.

---

# 17. WEIGH-IN

The product should support:

Athlete registration
→ eligibility
→ check-in
→ weigh-in
→ certification
→ category confirmation

Officials must have appropriate authorization.

Weight tolerance must be enforced by backend rules, not merely sliders or labels in UI.

---

# 18. BRACKETS

Current repository includes extensive bracket widgets:

- bracket trees
- winner/loser bracket
- match cards
- connector painters
- live cards
- timeline
- tournament status

These should become dynamic.

Verify:

- single elimination
- double elimination
- byes
- seeding
- advancement
- losers bracket
- grand final
- match references
- real UUIDs
- real backend state

Never create fake match IDs.

---

# 19. REFEREE EXPERIENCE

Current screens include:

- RefereeDashboardScreen
- RefereeCertificationsScreen
- MatchSubmissionScreen
- OfficialScorepadScreen
- AthleteSearchScreen
- EvidenceUploadScreen

Final referee flow:

Login
→ role/verification check
→ certification status
→ assigned events
→ current matches
→ athlete lookup
→ match
→ scorepad
→ result submission
→ evidence
→ verification
→ next match
→ officiated history

Only authorized assigned referees should perform the appropriate match operations.

---

# 20. REFEREE CERTIFICATION

Current backend has certification endpoints.

Final product must provide:

- application
- pending state
- active state
- expired state
- suspended/revoked state where supported
- renewal
- visible certification status

Certification expiration must be automatic where intended.

Never make an expired credential remain active merely because a screen still displays a badge.

---

# 21. MATCH / ELO USER FLOW

Full competitive pipeline:

Registration
→ eligibility
→ weigh-in
→ assignment
→ match scheduled
→ match in progress
→ score submitted
→ verification
→ ELO transaction
→ result published
→ ranking updated
→ athlete history updated

ELO must only change after a legitimate authorized verification.

Never allow a UI action to directly assign ELO.

---

# 22. MATCH STATES

The UI must distinguish state such as:

- scheduled
- in progress
- completed/pending verification
- verified
- disputed
- voided

Use only states actually supported by the authoritative backend model, and formalize missing transitions before UI depends on them.

---

# 23. COMMUNITY

Current repository includes:

- feed
- create post
- comments
- likes
- links/moderation
- video player

Current `CreatePostScreen` uses `Future.delayed(...)`.

Replace the fake submission with the real endpoint.

Flow:

Community
→ feed
→ open post
→ comment
→ react
→ create post
→ publish
→ moderation if needed
→ update feed

Add:

- report
- block
- moderation-safe behavior
- content loading
- failed upload recovery

---

# 24. MESSAGING

Current repository includes:

- conversations
- chat
- announcements
- unread counts
- read status
- typing/presence

Final product:

Inbox
→ conversation
→ messages
→ send
→ delivery state
→ read state
→ errors
→ retry

Do not show a message as successfully delivered merely because the local text field was cleared.

---

# 25. NOTIFICATIONS

Current backend/mobile support:

- notifications
- device tokens
- preferences
- announcements
- unread counts

Final app:

- notification inbox
- unread badge
- preference controls
- push permission explanation
- deep links
- event reminders
- competition results
- governance notices where appropriate

Do not force notification permission on first launch.

---

# 26. CLUBS / ORGANIZATIONS / TEAMS

Current routes include team creation/membership.

Final structure:

Organization
→ organization profile
→ teams
→ roster
→ athlete relationship
→ invitation
→ approval
→ removal
→ event registration/participation
→ club standings

Ownership must be enforced.

A user must never manipulate another organization's team merely by changing a URL/ID.

---

# 27. INFORMAL EVENTS

Current feature:

- directory
- details
- create
- join
- leave

Current create screen contains `Future.delayed(...)`.

Final flow:

Create
→ validate
→ persist
→ publish
→ browse
→ details
→ join
→ participant list
→ leave/cancel

Clarify whether these events are official competitions or community meetups; UI and permissions must communicate the distinction.

---

# 28. VENUES

Current feature:

- directory
- detail
- submission
- admin verification

Current `SubmitVenueScreen` contains `Future.delayed(...)`.

Final flow:

Discover venue
→ details
→ submit venue
→ moderation/verification
→ published listing

Do not allow unverified user submissions to appear as official federation venues unless the product deliberately distinguishes submitted vs verified.

---

# 29. NOMINATIONS / AWARDS

Current feature:

- my nominations
- submit nomination
- admin review/status

Current submission screen contains `Future.delayed(...)`.

Final flow:

Discover award/nomination
→ submission
→ validation
→ status
→ review
→ approved/rejected
→ public result if applicable

---

# 30. GOVERNANCE / DISPUTES

Current feature includes:

- dispute dashboard
- dispute detail
- complaint submission
- evidence
- comments
- assignment
- resolution
- escalation
- appeal
- sanctions
- audit verification

Current complaint screen uses `Future.delayed(...)`.

Final flow:

Authorized user
→ file valid complaint/dispute
→ match/subject relation validated
→ evidence
→ review
→ assignment
→ investigation
→ decision
→ sanction if appropriate
→ audit trail
→ notification

Never permit arbitrary users to create disputes against unrelated matches.

---

# 31. CHAMPIONSHIPS / BELTS

Current mobile screens include:

- championship list
- championship detail

Backend includes:

- titles
- challenges
- accept/decline
- defend
- vacate
- lineage
- prestige recompute

Final product must show:

- active title
- champion
- lineage
- challenges
- defenses
- vacancy/interim/retired state where supported

Admin governance must be separated from ordinary athlete viewing.

---

# 32. TICKETS / SPECTATOR EXPERIENCE

Current backend includes:

- event ticket types
- purchase
- refund
- my tickets

Current mobile settings include `MyTicketsScreen`.

Final flow:

Event
→ ticket types
→ checkout
→ purchase
→ ticket wallet
→ event access

Use real state.

QR/barcode presentation must represent a real ticket credential, not merely a decorative mock.

---

# 33. SESSION / ACCOUNT SECURITY

Current mobile includes:

- active sessions
- session control
- secure storage
- refresh logic
- logout

Final UX:

Settings
→ Security
→ active sessions
→ revoke session
→ revoke others
→ password
→ MFA
→ recovery codes

---

# 34. MFA

Current screens:

- setup
- verification
- recovery codes

MFA flow must be coherent:

Password login
→ MFA required
→ verification
→ session/token issuance
→ role routing

Do not show MFA screens when no MFA challenge exists.

Do not skip required MFA because a client says it is complete.

---

# 35. PASSWORD RECOVERY — CURRENT KNOWN DEFECT

Current mobile screens use `Future.delayed(...)`.

They must call the existing backend reset APIs.

Flow:

Forgot password
→ request
→ safe generic response
→ email/out-of-band delivery
→ token link/code
→ reset password
→ invalidate token
→ success
→ login

Do not leak reset tokens through production responses/logging.

---

# 36. ACCOUNT / SETTINGS

Required sections:

- Profile
- Security
- Notifications
- Privacy
- Payments where applicable
- Tickets
- Blocked users
- Active sessions
- Support
- Terms
- Privacy policy
- Account deletion
- Logout

Account deletion must actually delete/deactivate according to the final retention policy.

For App Store submissions, Apple requires an in-app account deletion path for apps that support account creation. citeturn912459search1turn912459search4

---

# 37. SUPPORT

The current supplied archive does not have a dedicated mobile support screen family in the screen inventory.

Therefore decide and implement one of the valid product architectures:

### Option A — Support is Admin Web only
Document this explicitly.

### Option B — Support is also an end-user feature
Add:

- Help center
- contact support
- support tickets
- ticket status
- conversation
- attachments where needed

If `SUPPORT_AGENT` is a privileged role, provide a real support operations surface on the appropriate platform.

Do not leave the role as an invisible backend concept.

---

# 38. ROLE × EXPERIENCE MATRIX

The UI should be:

## ATHLETE
Mobile primary.

Home:
- performance
- competitions
- rankings
- community

## REFEREE
Mobile primary.

Home:
- assigned officiating
- certification
- scorepad
- current event

## TOURNAMENT_OPERATOR
Mobile + Admin Web as appropriate.

Home:
- events
- operations
- check-in
- brackets
- matches

## ORGANIZATION_LEADER
Mobile primary / organization surface.

Home:
- organization
- teams
- roster
- events

## NATIONAL_DIRECTOR
Admin Web.

Home:
- federation dashboard
- championships
- analytics
- governance

## PROVINCIAL_DIRECTOR
Admin Web.

Home:
- scoped regional operations

## COMPLIANCE_OFFICER
Admin Web.

Home:
- disputes
- sanctions
- evidence
- audit

## SUPPORT_AGENT
Admin/support surface.

Home:
- ticket queue
- conversations
- escalation

## SYSTEM_ADMIN
Admin Web.

Home:
- system health
- administration
- audits
- security
- operational controls

Do not automatically expose privileged roles to the mobile app merely because the shared role enum contains them.

---

# 39. SCREEN INVENTORY — CURRENT MOBILE SCREENS

The current repository contains these screen families and they must each be placed into a coherent user journey.

## Authentication

- `SplashScreen`
- `LoginScreen`
- `RegisterScreen`
- `ForgotPasswordScreen`
- `ResetPasswordScreen`
- `MfaSetupScreen`
- `MfaVerificationScreen`
- `RecoveryCodesScreen`

## Athlete

- `AthleteProfileScreen`
- `AthleteDashboardScreen`
- `AthleteAchievementsScreen`
- `FollowersListScreen`
- `FollowingListScreen`
- `OnboardingScreen`
- `PublicAthleteProfileScreen`
- `RankingsScreen`
- `AthleteTrainingLogScreen`

## Home

- `DiscoverScreen`

## Community

- `CommunityFeedScreen`
- `CreatePostScreen`
- `PostCommentsScreen`
- `VideoPlayerModal`

## Governance

- `FederationGovernanceScreen`
- `GovernanceDashboardScreen`
- `DisputeDetailScreen`
- `SubmitComplaintScreen`

## Informal events

- `InformalEventDirectoryScreen`
- `InformalEventDetailScreen`
- `CreateInformalEventScreen`

## Messaging

- `ConversationsListScreen`
- `ChatScreen`
- `AnnouncementsListScreen`

## Notifications

- `NotificationsListScreen`

## Nominations

- `MyNominationsScreen`
- `NominateTalentScreen`

## Referee

- `RefereeDashboardScreen`
- `RefereeCertificationsScreen`
- `MatchSubmissionScreen`
- `OfficialScorepadScreen`
- `AthleteSearchScreen`
- `EvidenceUploadScreen`

## Search

- `GlobalSearchScreen`

## Sessions

- `ActiveSessionsListScreen`
- `ActiveSessionControlScreen`

## Settings

- `PaymentMethodsScreen`
- `MyTicketsScreen`
- `BlockedUsersScreen`

## Teams

- `TeamsListScreen`
- `TeamDetailScreen`
- `CreateTeamScreen`

## Tournaments

- `TournamentsListScreen`
- `TournamentDetailScreen`
- `TournamentBracketsScreen`
- `TournamentOperationsScreen`
- `EventRegistrationScreen`

## Venues

- `VenueDirectoryScreen`
- `VenueDetailScreen`
- `SubmitVenueScreen`

All of these screens must have a declared role/state/context, an entry point, a real backend dependency if they mutate/fetch server data, and loading/error/empty/success behavior.

---

# 40. CURRENT ADMIN WEB SCREEN INVENTORY

Admin Web currently contains:

- `LoginPage`
- `DashboardPage`
- `AnalyticsPage`
- `ChampionshipsPage`
- `GovernancePage`
- `AthletesPage`
- `ModerationQueuePage`
- `VenuesPage`
- `NominationsPage`

Current routes also expose:

- `/`
- `/analytics`
- `/championships`
- `/governance`
- `/athletes`
- `/registrations`
- `/moderation`
- `/venues`
- `/nominations`
- `/records`
- `/verification`
- `/audit`
- `/platform-health`

Several routes currently reuse a different page as a target (for example `/registrations` → `AthletesPage`, `/records` → `GovernancePage`, `/verification` → `AthletesPage`, `/audit` → `GovernancePage`, `/platform-health` → `AnalyticsPage`).

This must be intentional and clearly modeled, not accidental aliasing.

---

# 41. API DOMAIN INVENTORY FROM THE CURRENT REPOSITORY

The backend currently exposes these domains.

## Authentication
- registration
- login
- refresh
- logout
- current user
- sessions
- session revocation
- MFA
- recovery
- Google auth
- Apple auth
- password reset
- email verification

## Athlete
- create onboarding profile
- current profile
- visibility
- search
- clubs
- club creation
- uploads
- verification
- biometrics
- public profile
- matches
- training log
- PRs
- profile patch

## Community
- feed
- post deletion
- links
- link moderation
- pending links
- likes
- comments

## Matches
- create
- recent
- retrieve
- verify
- dispute
- void

## Rankings
- leaderboard
- snapshots

## Championships
- titles
- challenges
- accept/decline
- defend
- vacate
- lineage
- prestige

## Governance
- disputes
- assignments
- evidence
- comments
- resolve
- escalate
- appeal
- sanctions
- sanction sweep
- audit
- correction/replay

## Tournament/Event
- event list
- event details
- create/edit
- registration
- approval
- payment confirmation
- weigh-in
- reassignment
- certification
- brackets
- seeds
- overrides
- lock
- generation
- tables
- referee assignment
- match calls
- results
- event statistics
- participation metrics
- medals
- club standings

## Communication
- notifications
- preferences
- device tokens
- conversations
- messages
- typing/presence
- read states
- announcements
- metrics

## Payments
- webhook
- methods
- setup intent

## Tickets
- ticket types
- patch ticket type
- refund
- event ticket types
- purchase
- own tickets

## Referee certifications
- issue/create
- get
- revoke

## Social
- follow
- unfollow
- follow status
- followers/following
- block/unblock
- blocked list
- teams
- team membership

## Sync
- history
- queue
- metrics

## Venues
- create
- list
- detail
- update
- verify

## Nominations
- create
- mine
- list
- status

## Informal events
- create
- list
- detail
- join
- leave
- delete

Every screen must use these APIs consistently rather than creating duplicate fake logic.

---

# 42. API ↔ SCREEN CONNECTION RULE

For every production screen make a contract entry:

`Screen`
→ `Provider/Notifier`
→ `Repository/API Client`
→ `HTTP endpoint`
→ `Controller`
→ `Service`
→ `Database`
→ `response model`
→ `screen state`

The agent must identify any gap.

Examples:

### Registration
`RegisterScreen`
→ `AuthNotifier.register`
→ `AuthRepository.register`
→ `POST /auth/register`
→ `AuthController.register`
→ `AuthService.register`
→ `users`

then:

`authenticated session`
→ `OnboardingScreen`
→ `AthleteRepository.submitOnboarding`
→ `POST /athletes`

### Event registration
`EventRegistrationScreen`
→ repository/provider
→ real event registration endpoint
→ tournament service
→ registration DB
→ confirmation state

### Referee
`RefereeDashboardScreen`
→ referee provider/repository
→ certification/match/event endpoints
→ authorized DB records
→ official UI

---

# 43. UI STATE MACHINE

Every important screen should have:

## Initial
Loading/skeleton.

## Loaded
Real content.

## Empty
Helpful next action.

## Error
Human explanation + retry.

## Unauthorized
Explain permission boundary and route user appropriately.

## Session expired
Restore or return to sign in.

## Mutating
Button disabled + progress.

## Success
Persisted success response.

## Offline
Use cache/offline mode where supported; never fake network success.

---

# 44. VISUAL SYSTEM

Use the existing visual foundation where it genuinely supports the product:

- Inter
- Space Grotesk
- dark theme
- glass cards
- premium transitions
- subtle motion
- tactile interactions
- athlete imagery/content
- strong hierarchy

But rationalize the design.

Build reusable components for:

- AppShell
- AppBar
- bottom navigation
- primary CTA
- secondary action
- cards
- chips
- badges
- dialogs
- bottom sheets
- skeletons
- empty states
- error states
- confirmation dialogs
- secure input
- search field
- filters
- paginated list
- profile header
- competition card
- match card
- ranking row

---

# 45. DO NOT MIX ADMIN WEB DESIGN INTO MOBILE

The current Admin Web is intentionally a dark enterprise console.

That does not mean mobile should become a miniature developer console.

Mobile should be:

- human
- athletic
- content-driven
- personal
- task-oriented

Admin Web should be:

- dense
- operational
- auditable
- data-rich
- role-restricted

---

# 46. STORE-READY REQUIREMENTS

For Apple App Store, apps supporting account creation must provide an in-app account deletion path, and Apple expects submitted apps to be complete, functional, tested on-device, and to provide review access/demo credentials when account-based features require it. citeturn912459search0turn912459search1turn912459search3

For Google Play, Android target SDK requirements are time-sensitive. As of the current 2026 requirements, from August 31, 2026, new apps and updates must target Android 16 / API 36 or higher (with platform-specific exceptions). Verify the project's actual Android target configuration before submission. citeturn912459search2

The coding agent must therefore inspect:

- Android application ID
- target SDK
- minimum SDK
- version/build number
- signing
- permissions
- notification permissions
- network security
- production API URL
- launcher icon
- splash
- release builds
- App Store/Play Store metadata dependencies
- privacy policy
- account deletion
- reviewer/test account
- demo/test data
- deep links
- crash behavior

Do not claim App Store/Play Store readiness without actual platform-build verification.

---

# 47. PRIVACY / LEGAL PRODUCT REQUIREMENTS

The final app needs accessible:

- Privacy Policy
- Terms
- account deletion
- support/contact
- data-management information

Privacy and deletion behavior must describe actual implementation.

Do not fabricate legal compliance.

---

# 48. PERFORMANCE / QUALITY

Verify:

- first launch
- startup
- navigation
- scrolling
- images
- large lists
- network retry
- memory
- offline/cache
- background sync
- notifications
- app resume
- session expiry
- crash recovery

Avoid:

- unnecessary repeated requests
- unbounded lists
- large synchronous parsing
- fake progress
- blocking UI

---

# 49. SECURITY

Security is a product feature.

Re-audit:

- authentication
- password storage
- access/refresh tokens
- MFA
- session revocation
- CSRF
- CORS
- rate limiting
- captcha
- OAuth
- IDOR/BOLA
- role authorization
- jurisdiction
- referee assignment
- event ownership
- organization ownership
- dispute ownership
- ticket ownership
- payment webhooks
- uploads
- secrets
- logs
- error messages

The client may hide a button, but the API remains the authoritative security boundary.

---

# 50. PRODUCTION MOCK AUDIT

Search all production code for:

- `Future.delayed`
- `mock`
- `Mock`
- `sample`
- `dummy`
- `fake`
- `demo`
- `coming soon`
- `placeholder`
- `hardcoded`
- `TODO`
- `FIXME`
- `test compatibility`
- `bypass`
- `disable`
- `disabled`

For each hit, document:

- file
- line
- purpose
- legitimate or not
- production impact
- action

Do not remove legitimate animation delays merely because they contain `Future.delayed`.

---

# 51. CURRENT HIGH-PRIORITY PRODUCT GAPS TO RESOLVE

At minimum, the implementation agent must investigate and resolve:

1. registration → authenticated session → onboarding handoff
2. public-first-launch experience
3. explicit Sign Up path
4. separation of ordinary login from admin login
5. canonical role-aware routing
6. actual role-based onboarding
7. `/discover` semantics vs `DiscoverScreen`/`RankingsScreen`
8. production event-registration integration
9. production password-reset integration
10. production search instead of mock search
11. production community-post creation
12. production venue submission
13. production nomination submission
14. production informal-event creation
15. production governance complaint submission
16. team/organization workflows
17. referee evidence workflow
18. support role decision/workflow
19. dynamic home content
20. loading/empty/error/unauthorized states
21. account/security/settings completeness
22. account deletion
23. store-build readiness
24. real-user end-to-end journeys for each supported role

These are **starting points**, not the complete list. The agent must discover additional missing functionality.

---

# 52. EXACT COMPLETE USER FLOW

## UNIVERSAL

Cold launch
→ splash
→ restore local state
→ determine:
  - new
  - signed out
  - signed in
  - MFA required
  - onboarding required
  - role pending
  - verified role
→ correct next screen

---

## NEW USER

Welcome
→ Create account
→ account validation
→ create account
→ authentication
→ role-intent selection
→ role-specific onboarding
→ permission/verification state
→ personalized home

---

## RETURNING USER

Launch
→ session restoration
→ token refresh if required
→ personalized home

---

## SIGN-IN

Welcome
→ Sign in
→ credentials
→ optional MFA
→ authenticated state
→ role/verification resolution
→ correct home

---

## ATHLETE

Home
→ Discover
→ Competition
→ Event details
→ Register
→ Payment if necessary
→ Confirmation
→ My registration
→ Check-in
→ Weigh-in
→ Bracket
→ Match
→ Result
→ ELO
→ Ranking
→ History

Parallel:

Home
→ Profile
→ Training
→ PR
→ Community
→ Messaging
→ Notifications
→ Settings

---

## REFEREE

Login
→ certification state
→ referee dashboard
→ assigned event
→ assigned match
→ athlete verification
→ scorepad
→ submit
→ evidence
→ verification
→ audit
→ next assignment

---

## ORGANIZER

Login
→ organizer verification
→ organization/event dashboard
→ create event
→ categories
→ venue
→ registration
→ payments
→ participant approval
→ weigh-in
→ seed
→ bracket
→ tables
→ referee assignment
→ live operations
→ results
→ final standings

---

## ORGANIZATION LEADER

Login
→ organization
→ team
→ roster
→ invite
→ athlete approval
→ team permissions
→ event participation
→ club standings

---

## PROVINCIAL DIRECTOR

Admin login
→ jurisdiction
→ regional dashboard
→ athletes
→ clubs
→ events
→ venues
→ referees
→ disputes
→ compliance

Every resource must be province-scoped.

---

## NATIONAL DIRECTOR

Admin login
→ federation dashboard
→ analytics
→ national tournaments
→ championships
→ referee licensing
→ governance
→ national operations

---

## COMPLIANCE OFFICER

Admin login
→ governance
→ disputes
→ evidence
→ assignment
→ investigation
→ sanctions
→ resolution
→ audit

---

## SUPPORT AGENT

Support surface
→ queue
→ ticket
→ conversation
→ notes
→ escalation
→ resolution

If product architecture defines this as Admin Web-only, keep it there.

---

## SYSTEM ADMIN

Admin login
→ MFA
→ system dashboard
→ users/roles
→ operations
→ audit
→ security
→ workers
→ system health

---

# 53. SESSION / STATE DIFFERENCES

The application should intentionally look different in these states:

## First-time user
Public welcome.

## Signed-out user
Public welcome/login/register.

## Signed-in but onboarding incomplete
Onboarding only.

## Role pending verification
Pending status + limited product access.

## Athlete active
Athlete home.

## Referee active
Referee home/official controls.

## Event organizer active
Operations dashboard.

## Admin role
Admin Web.

## Suspended/disabled
Safe account state with explanation and support path.

## Session expired
Secure re-authentication.

This is the correct meaning of "the app changes over time for the user."

---

# 54. FINAL ACCEPTANCE TEST — A REAL PERSON

A completely new tester must be able to:

1. install ArmSphere
2. open ArmSphere
3. understand what it is
4. tap Create Account
5. register without pre-existing credentials
6. complete onboarding
7. reach home
8. navigate without dead ends
9. find a competition
10. view details
11. register for a competition
12. return later
13. see registration state
14. view rankings
15. view an athlete
16. follow/message where permitted
17. use community
18. view notifications
19. open settings
20. recover account
21. log out
22. log back in
23. delete the account or initiate the supported deletion process
24. experience correct permissions for their role

Then separately test:

- referee
- organizer/operator
- organization leader
- directors
- compliance
- support
- system admin

with legitimate provisioned accounts.

---

# 55. FINAL IMPLEMENTATION METHOD

The coding agent must use this order.

## PHASE 0 — FORENSIC PRODUCT BASELINE
Audit actual repository and produce a discrepancy list.

## PHASE 1 — FIRST-OPEN / AUTH / ONBOARDING
Fix public entry, registration, session handoff, role intent, onboarding.

## PHASE 2 — ROLE-AWARE NAVIGATION
Build contextual shells and correct routing.

## PHASE 3 — ATHLETE CORE
Home, discover, profile, rankings, competition.

## PHASE 4 — COMPETITION LIFECYCLE
Registration → payment → check-in → weigh-in → bracket → match → result.

## PHASE 5 — OFFICIALS
Referee/certification/scorepad/evidence.

## PHASE 6 — ORGANIZATIONS
Clubs/teams/rosters/invitations/event participation.

## PHASE 7 — COMMUNITY / MESSAGING / NOTIFICATIONS
Remove all production mocks.

## PHASE 8 — GOVERNANCE / CHAMPIONSHIPS
Complete real user-facing operational paths.

## PHASE 9 — ADMIN WEB
Separate enterprise control plane and role-specific admin routes.

## PHASE 10 — SECURITY / DATA INTEGRITY
Final IDOR, authorization, ownership, jurisdiction, ELO, payment, secret, session checks.

## PHASE 11 — UX / VISUAL POLISH
Unify design system and all states.

## PHASE 12 — STORE READINESS
Android/iOS build, metadata, privacy, deletion, reviewer/test account.

## PHASE 13 — END-TO-END TESTING
Clean accounts + real backend.

## PHASE 14 — FINAL FALSIFICATION AUDIT
Try to break everything.

---

# 56. RULES FOR THE CODING AGENT

1. Inspect before editing.
2. Treat the current repository as the source of truth.
3. Do not trust previous completion reports.
4. Do not invent unsupported product features.
5. Reuse existing backend capabilities when available.
6. Do not duplicate APIs unnecessarily.
7. Do not create fake UI success.
8. Do not use mocks in production flows.
9. Do not trust client role selection for authorization.
10. Do not expose privileged screens merely because a route exists.
11. Do not mark a screen complete merely because it renders.
12. Never hide API failures.
13. Never remove negative tests to make CI green.
14. Never commit secrets.
15. Never alter database constraints casually.
16. Keep state transitions explicit.
17. Add regression tests for security/logic fixes.
18. Verify actual database behavior for concurrency-sensitive operations.
19. Verify production builds, not only debug builds.
20. If a requirement is impossible in the current environment, document the exact external dependency instead of pretending it works.
21. When a role differs by verification/state, show the correct limited UI rather than a fake full dashboard.
22. Prefer one coherent product architecture over dozens of disconnected screens.

---

# 57. DEFINITION OF DONE

ArmSphere is complete only when:

### New user
- first launch is polished
- account creation is obvious
- registration works
- onboarding works
- role intent works
- session establishment works
- personalized home works

### Athlete
- profile
- training
- PR
- ranking
- competition
- registration
- match/result
- ELO
- community
- messaging
- notifications
- settings

### Referee
- certification
- assignment
- scorepad
- evidence
- verification
- official history

### Organizer/operator
- event
- registration
- payment
- participants
- weigh-in
- seeding
- bracket
- tables
- referees
- live operations
- results

### Organization leader
- organization
- teams
- roster
- invitations
- permissions
- event participation

### Governance/admin
- secure admin login
- role-scoped dashboards
- jurisdiction
- governance
- championships
- moderation
- analytics
- audit

### System quality
- no production fake workflows
- no dead buttons
- no broken routes
- no developer UI
- no raw API errors
- correct loading/empty/error states
- secure sessions
- secure permissions
- clean database integrity
- correct API contracts
- release builds validated
- store-readiness validated

---

# 58. FINAL PRINCIPLE

The goal is **not to maximize the number of screens**.

The goal is to make every existing screen and feature fit into a believable, coherent real-world ArmSphere workflow.

Every screen must answer:

- Who is this for?
- Why does the user arrive here?
- What can they do here?
- Where did they come from?
- Where can they go next?
- What data powers it?
- What happens when the action succeeds?
- What happens when it fails?
- Who is allowed to do it?
- What happens if the user's role/state changes?

If those answers are not clear, the implementation is not finished.

**Build ArmSphere as a real product, not as a collection of developer screens.**
