# ArmSphere Design QA Checklist & Verification Rubric
**Pre-Implementation & Post-Implementation Quality Verification Protocol**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Visual & Aesthetic Quality Rubric

| Verification Item | Acceptance Criteria | Pass / Fail |
| :--- | :--- | :---: |
| **Color Fidelity** | Substrates strictly use `#070A11` (void) or `#0B0F19` (elevated). Zero washed-out gray backgrounds. | [ ] |
| **Gold Restraint** | `AppTheme.goldPrimary` (`#D4AF37`) is applied strictly to primary actions, championships, and medals. | [ ] |
| **Single Primary Action**| Exactly ONE gold primary filled button exists per view or modal surface. | [ ] |
| **Surface Integrity** | No `GlassCard` is nested inside another `GlassCard`. Dense vertical lists use solid `ElevatedActionCard`. | [ ] |
| **Anti-Pill Geometry** | Buttons and cards use 12dp or 16dp geometric radii. Zero 999dp pill-shaped rectangular cards. | [ ] |
| **Status Mapping** | Green = Win/Passed, Amber = Pending/Published, Coral = Loss/Failed across all 66 screens. | [ ] |
| **Zero Floating Blobs** | Zero arbitrary floating geometric shapes, decorative glowing rings, or floating crypto-style blobs. | [ ] |

---

## 2. Typography & Readability Rubric

| Verification Item | Acceptance Criteria | Pass / Fail |
| :--- | :--- | :---: |
| **Font Role Separation**| `SpaceGrotesk` used exclusively for display, headings, ELO numbers, and scores. `Inter` used for all UI body prose. | [ ] |
| **Contrast Compliance** | All text against dark substrates passes WCAG AA (>= 4.5:1 for body; >= 7.0:1 for headers). | [ ] |
| **Tabular Numbers** | All countdown clocks, ELO scores, and match points use `FontFeature.tabularFigures()`. | [ ] |
| **200% Font Scaling** | Screen content flexes without text clipping or overflow errors when Android font size is set to 200%. | [ ] |

---

## 3. Ergonomics & Handheld Touch Rubric

| Verification Item | Acceptance Criteria | Pass / Fail |
| :--- | :--- | :---: |
| **48dp Hit Target** | All buttons, icon triggers, and form fields possess a minimum bounding box of 48×48dp. | [ ] |
| **Scorepad Geometry** | Referee scorepad buttons possess an extra-large minimum touch bounding box of **64×64dp**. | [ ] |
| **Haptic Actuation** | Tapping scorepad counters triggers `HapticFeedback.selectionClick()`; match pins trigger `heavyImpact()`. | [ ] |
| **Keyboard Avoidance**| Sticky action buttons remain pinned above the software keyboard when typing into forms. | [ ] |
| **Unsaved Work Guard**| Back gestures on scorepad and event registration trigger a confirmation bottom sheet before discarding state. | [ ] |

---

## 4. Motion & Performance Rubric

| Verification Item | Acceptance Criteria | Pass / Fail |
| :--- | :--- | :---: |
| **Duration Compliance**| Navigation transitions strictly 250–300ms; micro-interactions 100–150ms. Zero bouncy overshooting curves. | [ ] |
| **Reduced Motion Mode**| When `disableAnimations` is true, all slides, rotations, and scale transforms are replaced with instant cuts. | [ ] |
| **60fps Scroll Lock** | List views (Rankings, Feed, Tournaments) maintain a steady 60fps with zero jank on mid-tier hardware. | [ ] |
| **No Video Autoplay** | Community feed video posts display lightweight static thumbnails; video plays strictly on-demand in modal. | [ ] |
| **Memory Ceiling** | RAM consumption does not exceed 140 MB steady state or 210 MB during bracket pan/zoom. | [ ] |
| **Offline Resilience** | Disconnecting WiFi/cellular surfaces the non-intrusive offline banner and loads cached Hive state cleanly. | [ ] |
