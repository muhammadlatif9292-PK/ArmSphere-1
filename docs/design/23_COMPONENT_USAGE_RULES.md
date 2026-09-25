# ArmSphere Component Usage Rules
**Definitive Do's, Don'ts & Architectural Component Constraints**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Card & Container Rules

| Rule | Approved Pattern | Prohibited Anti-Pattern |
| :--- | :--- | :--- |
| **Card Nesting** | Place a solid card or flat cell inside a structural container. | **NEVER nest a `GlassCard` inside another `GlassCard`.** Stacking backdrop blurs causes GPU raster stalls and contrast degradation. |
| **Surface Hierarchy**| Reserve `GlassCard` for high-impact hero sections, live scorepads, and title lineages. | Do not use glass surfaces for long, dense lists (e.g. 50+ rankings rows). Use solid `ElevatedActionCard`. |
| **Card Padding** | Maintain consistent 16dp internal padding (`EdgeInsets.all(16)`). | Never use irregular padding (e.g. 7dp top, 23dp left) or zero padding without explicit clipping. |
| **Card Borders** | Use subtle 1px border (`#334155 @ 0.20`). | Never use heavy, 3px solid borders or ungrounded neon glow rings. |

---

## 2. Button & Action Rules

1. **The Single Primary Rule**:
   - Every screen or modal may have **at most ONE primary gold button** (`FilledButton` with `AppTheme.goldPrimary`).
   - All other actions on that surface must be secondary (`OutlinedButton`) or subtle icon triggers.
2. **Button Sizing**:
   - Mobile buttons must maintain a minimum height of **48dp** (56dp for referee scorepads).
   - Corner radius must strictly match `AppTheme.radiusMedium` (12dp). **Never use circular 999dp pill buttons for primary form submissions.**
3. **Loading Button State**:
   - When an action is in progress, the button must **never disappear** or shrink. It preserves its full width, disables touch events, and displays a centered 20dp spinner.

---

## 3. Modal Bottom Sheets vs Alert Dialogs

- **Use Modal Bottom Sheets (`showModalBottomSheet`) for**:
  - Filters, category selectors, comment threads, match score detail views, and action menus. Bottom sheets reside in the thumb zone.
- **Use Alert Dialogs (`showDialog`) strictly for**:
  - Irreversible destructive confirmations (Account deletion, bracket reset, match disqualification) or critical system errors. Dialogs demand two-handed deliberate confirmation.

---

## 4. Segmented Control vs TabBar

- **Segmented Control (`SegmentedButton`)**:
  - Use strictly for 2 or 3 mutually exclusive filter options within the same screen content (e.g. `Right Arm` vs `Left Arm` on Rankings).
- **TabBar (`TabBar`)**:
  - Use for switching between major independent page views within a sliver shell (e.g. `Upcoming` vs `Completed` tournaments).
