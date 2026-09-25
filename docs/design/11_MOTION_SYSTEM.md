# ArmSphere Motion Design System
**Flutter-Native Animation Physics, Timing Classes & Reduced-Motion Rules**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Motion Philosophy

Motion in ArmSphere is an **informational tool**, not a decorative gimmick. Every animation must satisfy at least one of five criteria:
1. **Explain Spatial Origin**: Show where an element originated and where it returns.
2. **Confirm Touch Acknowledgment**: Reassure the user that a tap registered instantly (<100ms).
3. **Smooth State Transitions**: Prevent jarring visual pops during data updates.
4. **Direct Focus**: Guide attention toward live status changes (e.g. an active table call).
5. **Celebrate Athletic Breakthroughs**: Provide ceremonial emphasis for tournament wins and PRs.

*Rule: If an animation delays a user from completing an operational task, it is defective.*

---

## 2. Motion Hierarchy & Duration Tiers

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOTION DURATION TIERS                        │
├───────┬──────────────────┬──────────────┬───────────────────────┤
│ Tier  │ Class Name       │ Duration     │ Assigned Curve        │
├───────┼──────────────────┼──────────────┼───────────────────────┤
│ Level 0│ Micro Feedback   │ 100 – 150ms  │ Curves.easeOutQuad    │
│ Level 1│ Local Transition │ 200 – 250ms  │ Curves.easeInOutCubic │
│ Level 2│ Navigation Route │ 250 – 300ms  │ Curves.easeOutCubic   │
│ Level 3│ Feature Moment   │ 400 – 600ms  │ Curves.easeOutCubic   │
│ Level 4│ Cinematic Moment │ 800 – 1200ms │ Curves.easeInOutCubic │
└───────┴──────────────────┴──────────────┴───────────────────────┘
```

### Detailed Class Specifications:

#### Level 0: Micro Feedback (100–150ms)
- **Use Cases**: Button press down, checkbox toggle, segmented button switch, referee score tap.
- **Physics**: Scale transform down to `0.97` over 100ms; return to `1.0` over 120ms.
- **Implementation**: `TactilePressWrapper` (`core/widgets/tactile_press_wrapper.dart`).

#### Level 1: Local Transitions (200–250ms)
- **Use Cases**: Rulebook accordion expansion, comment thread slide-in, search bar expansion.
- **Physics**: Height expansion with simultaneous opacity fade (`SizeTransition` + `FadeTransition`).
- **Curve**: `Curves.easeInOutCubic`.

#### Level 2: Navigation Transitions (250–300ms)
- **Use Cases**: Page push (forward) and page pop (reverse).
- **Physics**:
  - Forward: Incoming screen slides from `+30% X` to `0%` (300ms); outgoing screen scales `1.0 -> 0.98` and dims to 85% opacity.
  - Reverse: Exiting screen slides from `0%` to `+30% X` (250ms); returning screen scales back to `1.0`.
- **Implementation**: `AppCustomPageTransition` (`core/routing/page_transitions.dart`).

#### Level 3: Feature Moments (400–600ms)
- **Use Cases**: Match result submitted, ELO score recalculation, weigh-in passed, ticket generated.
- **Physics**: ELO numbers roll up using `CountUpText`; checkmark draws with custom painter path animation.
- **Audio Cue**: Accompanied by `match_won.mp3` or `challenge_accepted.wav`.

#### Level 4: Cinematic Moments (800–1200ms)
- **Use Cases**: App cold launch splash seal reveal, championship title belt crowning.
- **Physics**: Subtle radial light beam rotation and gold particle burst (`CelebrationOverlay`).
- **Constraint**: User can tap screen at any point to skip the animation.

---

## 3. Approved vs Prohibited Easing Curves

```dart
// APPROVED CURVES:
static const Curve standardDecel = Curves.easeOutCubic;   // Incoming routes & dialogs
static const Curve standardMorph = Curves.easeInOutCubic; // Accordions & step sliders
static const Curve shimmerLoop   = Curves.linear;         // Skeleton gradient sweep

// FORBIDDEN CURVES:
// Curves.bounceOut  - Strictly banned. Bouncing feels childish and unathletic.
// Curves.elasticOut - Strictly banned. Wobbly rubber-band motion damages trust.
```

---

## 4. Accessibility & Reduced Motion Mode

ArmSphere natively respects Android system accessibility preferences (`disableAnimations`):

```dart
final bool reduceMotion = MediaQuery.of(context).disableAnimations;

if (reduceMotion) {
  // Override durations to 0ms or simple 50ms fade
  return child;
}
```

### Reduced-Motion Behaviors:
- All slide and scale transforms are disabled; transitions become instant cuts.
- Ambient particle backgrounds (`AmbientParticleBackground`) freeze into a static gradient.
- Shimmer skeleton loaders display a static high-contrast placeholder without sweep animation.
- Score counter roll-ups jump directly to final value.
