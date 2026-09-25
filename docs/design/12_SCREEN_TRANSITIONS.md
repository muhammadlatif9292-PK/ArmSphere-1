# ArmSphere Screen Transition Specifications
**Explicit Transition Physics, Continuity & Handoff Specifications**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Master Route Transition Ledger

Every route exchange in ArmSphere has an explicit transition specification defining the starting state, ending state, directional physics, duration, and visual continuity elements:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      SCREEN TRANSITION SPECIFICATIONS                  │
├────┬────────────────────────────┬──────────────┬───────────────────────┤
│ ID │ Route Pair                 │ Motion Class │ Physics / Continuity  │
├────┼────────────────────────────┼──────────────┼───────────────────────┤
│ T01│ Splash -> Welcome          │ Level 4 (800)│ Logo fade-and-settle  │
│ T02│ Splash -> Home             │ Level 2 (300)│ Direct entry morph    │
│ T03│ Welcome -> Login/Register  │ Level 2 (280)│ Upward sheet push     │
│ T04│ Login <-> Register         │ Level 1 (250)│ Directional slide-fade│
│ T05│ Login -> MFA Verification  │ Level 2 (280)│ Forward slide push    │
│ T06│ Register -> Role Intent    │ Level 2 (300)│ Forward slide push    │
│ T07│ Role Intent -> Onboarding  │ Level 2 (300)│ Stepper forward slide │
│ T08│ Onboarding -> Home         │ Level 3 (450)│ Shell reveal fade-up  │
│ T09│ Home -> Tournament Details │ Level 2 (300)│ Card expansion push   │
│ T10│ Details -> Registration    │ Level 2 (280)│ Upward sheet push     │
│ T11│ Details -> Brackets        │ Level 2 (300)│ Fullscreen zoom push  │
│ T12│ Bracket Node -> Match Modal│ Level 1 (220)│ Modal bottom sheet up │
│ T13│ Ref Dashboard -> Scorepad  │ Level 3 (400)│ Fullscreen desk lock  │
│ T14│ Governance -> Dispute Detail│ Level 2 (280)│ Forward slide push   │
│ T15│ Feed -> Video Player Modal │ Level 1 (220)│ Dark overlay backdrop │
│ T16│ Profile -> Settings Hub    │ Level 2 (280)│ Forward slide push    │
│ T17│ Settings -> Sub-Settings   │ Level 2 (250)│ Forward slide push    │
│ T18│ Reverse Pop (Any Detail)   │ Level 2 (250)│ Slide pop + unscale   │
└────┴────────────────────────────┴──────────────┴───────────────────────┘
```

---

## 2. Detailed Transition Physics

### T01: Splash (`/`) → Welcome (`/welcome`)
- **Initial State**: Centered gold federation seal on void black `#070A11` with pulsating ambient glow.
- **Trigger**: Session check completes with `AuthStatus.unauthenticated`.
- **Duration**: 800ms total.
- **Physics**:
  - The gold emblem scales down from 1.0 to 0.70 while sliding vertically into the top third of the viewport.
  - The Welcome title (`ArmSphere`) and benefit cards fade in from 0.0 to 1.0 with a 15dp upward drift (`Offset(0, 0.05)`).
- **User Control**: Tap anywhere skips directly to fully loaded Welcome screen.

### T04: Login (`/login`) ↔ Register (`/register`)
- **Initial State**: One auth mode is visible.
- **Trigger**: User taps "Create account" or "I already have an account".
- **Duration**: 250ms (`Curves.easeInOutCubic`).
- **Physics**:
  - Going from Login to Register: Login form slides left (-15% X) and fades out. Register form slides in from right (+15% X) and fades in.
  - Going from Register to Login: Exact inverse directional movement.
  - Brand header and background gradient remain stationary (zero visual jump).

### T07: Role Intent (`/role-intent`) → Onboarding (`/onboarding`)
- **Initial State**: Selected role intent card is highlighted with gold illuminated border.
- **Trigger**: Tapping "Continue" on Role Intent.
- **Duration**: 300ms.
- **Physics**:
  - Selected card expands slightly (1.02 scale) and fades out.
  - Onboarding Step 1 ("Identity") slides in from the right. Top stepper indicator animates from 0% to 33% fill.

### T09: Home / List → Tournament Details (`/tournament/:id`)
- **Initial State**: Tournament card inside list.
- **Trigger**: Tapping tournament card.
- **Duration**: 300ms (`Curves.easeOutCubic`).
- **Physics**:
  - Standard push via `AppCustomPageTransition`.
  - The card's hero artwork and title transition seamlessly into the `TournamentDetailsHeroWidget` header.
  - Bottom navigation bar drops down off-screen (-100% Y) over 200ms.

### T13: Referee Dashboard → Official Scorepad (`/referee/submit-scorepad`)
- **Initial State**: Table match board in Referee Dashboard.
- **Trigger**: Referee taps "Officiate Match" on an active table.
- **Duration**: 400ms (`Curves.easeOutCubic`).
- **Physics**:
  - Screen transitions into high-contrast dark console mode.
  - Player names and set score counters slide in from opposing sides (Puller 1 from left, Puller 2 from right) meeting at the center table dividing line.
  - Phone emits `AppHaptics.scoreIncrement()` and locks Android screen wake-lock.

### T18: Reverse Pop (Back Gesture or AppBar Back Arrow)
- **Initial State**: Any active drill-down screen.
- **Trigger**: Android system back gesture or tap back arrow.
- **Duration**: 250ms.
- **Physics**:
  - Active screen slides to the right from `0% X` to `+30% X` while fading from 1.0 to 0.0.
  - Underlying parent screen scales back up from `0.98` to `1.0` and brightens from 85% opacity to 100%.
  - Preserves exact scroll offset and previous tab index.
