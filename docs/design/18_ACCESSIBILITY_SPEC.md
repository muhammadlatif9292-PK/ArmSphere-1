# ArmSphere Accessibility Specification (A11y)
**WCAG 2.1 AA/AAA Compliance, Semantics & Inclusive Sports UX**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Compliance Mandate

ArmSphere is engineered to meet **WCAG 2.1 Level AA across 100% of surfaces**, and **Level AAA across high-stakes match officiating and dispute arbitration flows**. Visual prestige is never achieved by sacrificing accessibility.

---

## 2. Touch Target Geometry & Bounding Boxes

Athletes at competition venues often have taped wrists, chalked fingers, or sweaty hands. Touch targets strictly observe:

```
┌─────────────────────────────────────────────────────────────────┐
│                     TOUCH TARGET STANDARDS                      │
├─────────────────┬──────────────┬────────────────────────────────┤
│ Element Type    │ Minimum Area │ Implementation Guardrail       │
├─────────────────┼──────────────┼────────────────────────────────┤
│ Primary Buttons │ 48 × 48 dp   │ Minimum height: 48dp           │
│ Form Inputs     │ 48 × 48 dp   │ Text field tap target padding  │
│ Icon Buttons    │ 48 × 48 dp   │ 24dp icon wrapped in 12dp pad  │
│ List Items      │ Full Width × │ Minimum tile height: 56dp      │
│ Referee Scorepad│ **64 × 64 dp**│ Extra-large table-side target  │
└─────────────────┴──────────────┴────────────────────────────────┘
```

---

## 3. Color-Independent Semantic Communication

**Rule: Never rely on color alone to communicate status or outcome.**

Every semantic status is dual-coded with an explicit text label and distinctive iconography:

| Status Meaning | Color Code | Accompanying Icon | Text Label Displayed |
| :--- | :--- | :--- | :--- |
| **Match Victory** | `#10B981` (Green) | `Icons.check_circle` | Explicit text: `WIN` |
| **Match Loss** | `#FF5252` (Coral) | `Icons.cancel` | Explicit text: `LOSS` |
| **Pending Review** | `#F59E0B` (Amber) | `Icons.hourglass_top` | Explicit text: `PENDING` |
| **Weigh-in Failed** | `#FF5252` (Coral) | `Icons.scale` (alert)| Explicit text: `OVERWEIGHT` |
| **Table Foul** | `#EF4444` (Crimson)| `Icons.gavel` | Explicit text: `FOUL (1/2)` |

---

## 4. Screen Reader Semantics & Announcements

Custom canvas elements and non-standard widgets wrap their rendering in Flutter's `Semantics` widget:

1. **Bracket Match Node**:
   ```dart
   Semantics(
     label: 'Match between ${p1.name} and ${p2.name}, score is ${p1.score} to ${p2.score}',
     button: true,
     child: BracketMatchCard(...),
   )
   ```
2. **Referee Score Counter**:
   ```dart
   Semantics(
     label: 'Increment score for ${p1.name}. Current score: ${p1.score}',
     button: true,
     onTap: () => _incrementScore(1),
     child: ScoreIncrementButton(...),
   )
   ```
3. **Live Table Callout**:
   - When a match is called to table, the app announces an accessibility alert using `SemanticsService.announce('Match called to Table 1: Ali vs Khan', TextDirection.ltr)`.
