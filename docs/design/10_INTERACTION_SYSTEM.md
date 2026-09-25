# ArmSphere Interaction System
**Tactile Feedback, Control States & Handheld Action Ergonomics**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Interaction State Taxonomy

Every interactive element in ArmSphere (buttons, cards, chips, list rows, form fields) implements an unambiguous state lifecycle:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTROL STATE LIFECYCLE                      │
├─────────────┬─────────────────────────┬─────────────────────────┤
│ State       │ Visual Appearance       │ Tactile / Audio Signal  │
├─────────────┼─────────────────────────┼─────────────────────────┤
│ 1. Idle     │ Standard surface/border │ None                    │
│ 2. Pressed  │ Scale 0.97, surface dim │ Selection click haptic  │
│ 3. Focused  │ 1.5px Ice Blue border   │ None                    │
│ 4. Loading  │ Inline spinner, disabled│ None (prevents re-tap)  │
│ 5. Success  │ Green border / checkmark│ Success notification haptic│
│ 6. Disabled │ Opacity 0.40, unclickable│ Error haptic if tapped  │
│ 7. Destruct │ Coral surface/red border│ Heavy impact haptic     │
└─────────────┴─────────────────────────┴─────────────────────────┘
```

---

## 2. Haptic Feedback Specifications

ArmSphere leverages Android system haptic actuators to provide **tactile physical confirmation**, critical for athletic table-side operation:

```dart
// Canonical Haptic Triggers
class AppHaptics {
  // Minor interactions: Segmented button switch, tab change, dropdown pick
  static void lightTick() => HapticFeedback.selectionClick();

  // Standard interactions: Card tap, checkbox toggle, follow/unfollow
  static void standardTap() => HapticFeedback.lightImpact();

  // Scorekeeper score increment, weigh-in approval
  static void scoreIncrement() => HapticFeedback.mediumImpact();

  // High-stakes actions: Winner declared, match pin, foul logged, dispute submitted
  static void matchPinConfirmed() => HapticFeedback.heavyImpact();

  // Form error, validation failure, card decline
  static void errorVibrate() => HapticFeedback.vibrate();
}
```

---

## 3. The "Continue / Next" Action Philosophy

In multi-step flows (Onboarding, Event Registration, Complaint Filing), tapping **"Continue"** or **"Next"** must communicate progression, not an abrupt cut:

1. **Tap Down**: Button scales to 0.98 with `AppHaptics.standardTap()`.
2. **Validation Pass**:
   - If form fields are valid, button morphs: text fades out and an inline 20dp spinner appears.
   - User inputs are locked to prevent duplicate submissions.
3. **Step Advancement**:
   - Outgoing step content slides -20% to the left while fading from 1.0 to 0.0 over 250ms.
   - Incoming step content slides from +20% right to center while fading from 0.0 to 1.0.
   - Top stepper progress bar fills smoothly (`Curves.easeOutCubic`).
4. **Validation Failure**:
   - Button performs a 3-cycle horizontal shake animation (5dp offset, 300ms total).
   - Phone emits `AppHaptics.errorVibrate()`.
   - The first invalid form field automatically receives focus and displays red caption text.

---

## 4. The "Go Back" Experience

Navigating backward must preserve visual continuity and user work:

- **Predictive Back Support**: Supports Android 14+ predictive back animation where the current screen smoothly scales down to reveal the underlying parent.
- **Scroll Restoration**: Returning to a list never jumps to top; exact pixel scroll offset is preserved.
- **Unsaved Work Interception**:
  - If a user has entered data into `EventRegistrationScreen` or `OfficialScorepadScreen`, tapping Back or using the edge-swipe gesture triggers a confirmation bottom sheet:
    - *"Discard unsaved scorepad? All active round points for this match will be lost."*
    - Actions: `Keep Editing` (default primary) vs `Discard & Exit` (secondary destructive).

---

## 5. Destructive Action Safeguards

Actions that irreversibly alter federation records or user accounts (Disqualify Athlete, Delete Account, Revoke Login Session, Reset Tournament Bracket) require a **2-Step Defensive Confirmation**:

1. **Step 1: Visual Warning**: Destructive button is colored in muted coral (`#FF5252 @ 0.15`).
2. **Step 2: Modal Confirmation Sheet**:
   - Tapping opens a bottom sheet with a warning triangle icon.
   - Body explicitly describes the consequences (e.g. *"This action permanently revokes all authentication tokens for this device."*).
   - The confirmation button requires a full tap-and-hold (500ms press) or explicit typed confirmation for account deletion.
   - Successful execution emits `AppHaptics.matchPinConfirmed()`.
