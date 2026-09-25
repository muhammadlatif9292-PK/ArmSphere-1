# ArmSphere Anti-UI-Slop & Quality Gate Specification
**Definitive Rejection Gates Against Generic, Cluttered & Artificial Interfaces**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. The Quality Gate Philosophy

"Anti-Slop" is the hard visual and architectural filter that protects ArmSphere from becoming a generic AI template, a cluttered crypto dashboard, or an unplayable mobile spreadsheet. 

ArmSphere must feel like an **authentic international sports federation platform**—serious, athletic, precise, and expensive.

---

## 2. The 16 Explicit Anti-Patterns & Rejection Gates

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE 16 REJECTION GATES                          │
├────┬─────────────────────────────┬────────────────────────────────────┤
│ #  │ Prohibited Anti-Pattern     │ Architectural Rejection Criteria   │
├────┼─────────────────────────────┼────────────────────────────────────┤
│ 01 │ The Home Screen Dump        │ Reject any PR adding raw feeds or  │
│    │                             │ tables directly onto Tab 0.        │
│ 02 │ Desktop Squeezed to Mobile  │ Reject multi-column desktop tables │
│    │                             │ crammed without card refactoring.  │
│ 03 │ Universal Glassmorphism     │ Reject glass surfaces applied to   │
│    │                             │ high-density vertical lists.       │
│ 04 │ Meaningless Glow Rings      │ Reject box shadows with blur >12dp │
│    │                             │ on standard unselected cards.      │
│ 05 │ Floating Decorative Geometry│ Reject floating rings, blobs, or   │
│    │                             │ arbitrary floating particles.      │
│ 06 │ Purposeless Ambient Particles│ Reject active particle renderers  │
│    │                             │ running continuous loops on idle.  │
│ 07 │ Fake AI Athletes / Faces    │ Immediate rejection. Only real     │
│    │                             │ user photos or initials permitted. │
│ 08 │ Uncontrolled Pill Shapes    │ Reject 999dp corner radii on cards │
│    │                             │ and primary rectangular buttons.   │
│ 09 │ The "Fade Everything" Motion│ Reject pure cross-fades between    │
│    │                             │ screens without directional vector.│
│ 10 │ Carousels for Data Tables   │ Reject horizontal carousels for    │
│    │                             │ leaderboards and rankings.         │
│ 11 │ Text Over Raw Photos        │ Reject text over imagery without   │
│    │                             │ a verified 4-stop gradient scrim.  │
│ 12 │ Hidden Critical Actions     │ Reject referee/operator actions    │
│    │                             │ buried deeper than 2 taps.         │
│ 13 │ Dialog Fatigue              │ Reject full alert dialogs for non- │
│    │                             │ destructive routine operations.    │
│ 14 │ Low-Contrast Gray Typography│ Reject text color failing WCAG AA  │
│    │                             │ 4.5:1 against dark surfaces.       │
│ 15 │ Video Autoplay Everywhere   │ Reject inline video autoplaying    │
│    │                             │ inside scrollable feeds.           │
│ 16 │ Inconsistent Back Behavior  │ Reject back button popping that    │
│    │                             │ destroys tab scroll positions.     │
└────┴─────────────────────────────┴────────────────────────────────────┘
```

---

## 3. The Athletic Prestige Checklist

Before any screen design is cleared for implementation, it must pass this 5-question test:

1. **Does this look like an official armwrestling federation platform?**
   - If it looks like a generic web3 dashboard or neon gaming app, **REJECT**.
2. **Can a referee use this with chalked, sweaty hands?**
   - If buttons are under 48dp or lack physical haptic confirmation, **REJECT**.
3. **Does the visual hierarchy answer "What matters now?" in < 1 second?**
   - If primary actions compete with secondary metadata, **REJECT**.
4. **Is every animation explaining a state change or spatial origin?**
   - If motion is purely decorative or slows down task completion, **REJECT**.
5. **Does the screen function gracefully with zero internet connectivity?**
   - If network failure produces an unformatted error dialog or crash, **REJECT**.
