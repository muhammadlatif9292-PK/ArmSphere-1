# ArmSphere Navigation Architecture
**Authoritative Routing, Shell & State Navigation Blueprint**
**Document Version**: 1.0.0
**Source Authority**: Grounded in `apps/mobile/lib/core/routing/app_router.dart` and `page_transitions.dart`
**Status**: APPROVED & LOCKED

---

## 1. Global Navigation Topology

ArmSphere employs **GoRouter 10.2** with a **persistent 5-branch StatefulShellRoute** (`StatefulShellRoute.indexedStack`), ensuring that bottom navigation tab switches never destroy or re-render child screen state.

```
                                    ┌──────────────────────┐
                                    │    Cold App Launch   │
                                    │      (Splash /)      │
                                    └──────────┬───────────┘
                                               │
                        ┌──────────────────────┴──────────────────────┐
                        ▼                                             ▼
             [Unauthenticated Status]                       [Authenticated Status]
                        │                                             │
             ┌──────────┴──────────┐                        ┌─────────┴─────────┐
             │      /welcome       │                        ▼                   ▼
             └──────────┬──────────┘                  [Onboarding Req]    [MFA Required]
                        │                                   │                   │
             ┌──────────┴──────────┐                        │             /mfa/verify
             │  /login & /register │                        │
             └──────────┬──────────┘                        ▼
                        │                            /role-intent
                        │                                   │
                        │                            /onboarding
                        │                                   │
                        └─────────────────┬─────────────────┘
                                          ▼
                     ┌─────────────────────────────────────────┐
                     │           PERSISTENT MAIN SHELL         │
                     │          (MainShellScreen 5-Tab)        │
                     ├─────────┬─────────┬─────────┬───────────┤
                     │ Branch 0│ Branch 1│ Branch 2│ Branch 3 │ Branch 4
                     │  /home  │/discover│ /tourn  │/community │ /athlete
                     │         │/rankings│ /ops    │  /feed    │  /profile
                     └─────────┴─────────┴─────────┴───────────┴───────────┘
```

---

## 2. Shell Branch Hierarchy & Route Allocation

The persistent shell hosts 5 distinct navigation branches. Each branch maintains its own independent back-stack:

| Branch Index | Tab Label | Primary Route | Sub-Routes in Branch | Purpose & Mental Model |
| :---: | :--- | :--- | :--- | :--- |
| **0** | **Home** | `/home` | `/athlete/dashboard`<br>`/referee/dashboard`<br>`/governance` | **Personal Operational Hub**: Changes dynamically based on verified server-side user role. |
| **1** | **Discover** | `/discover` | `/rankings` | **Exploration & Leaderboards**: Federation announcements, upcoming events, national ELO ladder. |
| **2** | **Competitions** | `/tournaments` | `/tournament/dashboard` | **Sanctioned Events**: Public tournament schedule, brackets, event registration, operator desks. |
| **3** | **Community** | `/community/feed` | | **Social Camaraderie**: Video posts, technique breakdowns, community discussions. |
| **4** | **Profile** | `/athlete/profile` | | **Personal Identity**: Biometric specs, reach, weight class, honors, settings portal. |

---

## 3. Role-Based Navigation Dispatcher & Boundary Guards

### 3.1 The Role-Aware Home Dispatcher (`RoleAwareHomeScreen`)
When a user navigates to `/home`, the app inspects `authState.userProfile['role']`:
1. **Referee & Federation Directors** (`REFEREE`, `PROVINCIAL_DIRECTOR`, `NATIONAL_DIRECTOR`, `SYSTEM_ADMIN`):
   - Renders `RefereeDashboardScreen` inside Tab 0. Displays live tournament match board, assigned tables, and scorepad triggers.
2. **Governance & Compliance Officers** (`TOURNAMENT_OPERATOR`, `COMPLIANCE_OFFICER`, `SUPPORT_AGENT`, `ORGANIZATION_LEADER`):
   - Renders `GovernanceDashboardScreen` inside Tab 0. Displays open dispute arbitration cases, disciplinary sanctions, and complaint queues.
3. **Athletes & Default Pullers** (`ATHLETE`):
   - Renders `AthleteDashboardScreen` inside Tab 0. Displays dual ELO ratings (Right/Left), upcoming matches, training PRs, and quick shortcuts.

### 3.2 Server-Side Role Boundary Protection
`GoRouter.redirect` strictly enforces route security. Direct deep links or manual navigation attempts to restricted routes are blocked:
```dart
// Role-based boundary enforcement in app_router.dart:
final userRole = authState.userProfile?['role']?.toString().toUpperCase();

if (location.startsWith('/referee') && !_isRefereeLikeRole(userRole)) {
  return '/home'; // Unauthorized -> Kick back to safe athlete home
}

if (location.startsWith('/governance') && !_isGovernanceRole(userRole)) {
  return '/home'; // Unauthorized -> Kick back to safe athlete home
}
```

---

## 4. Root Modal & Drill-Down Routes (Above the Shell)

To prevent visual clutter and provide focused workspaces, high-stakes and detail screens are pushed **above the main shell**, hiding the bottom navigation bar:

### 4.1 Global Drill-Down Routes
- `/search`: Fullscreen debounced athlete search.
- `/athlete/:athleteId`: Public competitor profile, head-to-head match history.
- `/athlete/:id/followers` & `/athlete/:id/following`: Follower lists.
- `/athlete/:id/training-log`: Personal strength training history.
- `/achievements`: Fullscreen honors and cryptographic medal viewer.
- `/tournament/:tournamentId`: Comprehensive tournament briefing and hero card.
- `/tournament/:tournamentId/register`: Athlete event entry and Stripe payment flow.
- `/tournament/:tournamentId/brackets`: Fullscreen interactive double-elimination brackets.
- `/tournament/:tournamentId/operations`: Tournament operator desk (check-in, weigh-in, seed).
- `/messages` & `/messages/:conversationId`: Fullscreen inbox and real-time chat.
- `/notifications` & `/announcements`: Notification center and federation bulletins.
- `/venues`, `/venues/:id`, `/venues/submit`: Venue partner directory and submission.
- `/informal-events`, `/informal-events/:id`, `/informal-events/create`: Grassroots practice meetups.
- `/teams`, `/teams/:id`, `/teams/create`: Armwrestling clubs and rosters.
- `/championship/titles` & `/championship/:id`: Championship belts and historical lineages.
- `/settings/*`: Account settings, active login sessions, payment methods, GDPR deletion, legal terms.

---

## 5. Screen Transition Language & Physics

All route transitions utilize `AppCustomPageTransition` (`core/routing/page_transitions.dart`), creating a bespoke, high-performance physical feel:

```
┌─────────────────────────────────────────────────────────────────┐
│                 APP TRANSITION MOTION PHYSICS                   │
├─────────────────────────────────────────────────────────────────┤
│ Forward Push (Duration: 300ms, Curves.easeOutCubic):            │
│ • Incoming Screen: Starts at X +30% width, fades from 0 to 1.   │
│ • Outgoing Screen: Slides to X -10% width, scales 1.0 -> 0.98,  │
│                     opacity dims 1.0 -> 0.85.                   │
│                                                                 │
│ Reverse Pop (Duration: 250ms, Curves.easeOutCubic):             │
│ • Returning Screen: Scales 0.98 -> 1.0, slides -10% -> 0%,      │
│                     opacity restores 0.85 -> 1.0.               │
│ • Exiting Screen: Slides 0% -> +30%, fades 1.0 -> 0.            │
└─────────────────────────────────────────────────────────────────┘
```

### Motion Constraints:
- **No Full Cross-Fades**: Avoid pure opacity fades between major screens; directional movement preserves the user's spatial orientation.
- **No Over-Springing**: Curves strictly use `Curves.easeOutCubic`. Bouncy springs are forbidden on navigation transitions to prevent disorientation during fast mobile navigation.
- **Zero Bottom Sheet Flicker**: Bottom sheets use `showModalBottomSheet` with `isScrollControlled: true` and dark slate barrier color `#000000 @ 0.70`.

---

## 6. Back-Navigation & State Preservation Rules

1. **Android Physical Back Button & Predictive Back**:
   - Tapping Back on any root shell tab (`/home`, `/discover`, `/tournaments`, `/community/feed`, `/athlete/profile`) does **not** jump between tabs randomly; if already on Tab 0, it exits the app. If on Tabs 1–4, pressing Back returns to Tab 0 (`Home`).
   - Tapping Back on any drill-down screen (e.g. `/tournament/:id`) pops the route, instantly returning to the previous scroll position in the parent tab.
2. **Scroll Position Retention**:
   - All `ListView` and `CustomScrollView` widgets in shell tabs use `key: const PageStorageKey<String>('unique_tab_key')`. Switching tabs and returning preserves the exact pixel scroll offset without re-fetching data.
3. **Form Cancellation Guards**:
   - `EventRegistrationScreen`, `OnboardingScreen`, and `OfficialScorepadScreen` intercept back gestures via `PopScope` (or `WillPopScope`) to prompt confirmation before discarding unsubmitted competition data.
4. **Session Expiry Redirect**:
   - If an API call encounters an unrecoverable 401 and refresh token failure, `authProvider` immediately updates status to `AuthStatus.unauthenticated`. `GoRouter.redirect` automatically routes the user to `/welcome` while preserving an in-memory alert snackbar explaining the timeout.
