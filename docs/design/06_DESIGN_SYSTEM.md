# ArmSphere Canonical Design System Specification
**Foundational Visual Grammar, Surfaces, Elevation & Spatial System**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Spatial Foundation & 4dp/8dp Grid

ArmSphere enforces a strict **8dp baseline grid** (with 4dp sub-steps for compact micro-spacing), ensuring mathematical rhythm and visual alignment across all Android display densities (mdpi to xxxhdpi):

```dart
// Canonical Spacing Tokens (core/theme/app_theme.dart)
static const double space4  = 4.0;   // Micro gap (icon-to-text, badge internal padding)
static const double space8  = 8.0;   // Tight spacing (stack elements, subtitle offsets)
static const double space12 = 12.0;  // Standard inner card item padding
static const double space16 = 16.0;  // Canonical content inset & card internal padding
static const double space20 = 20.0;  // Page margin padding (default for mobile viewports)
static const double space24 = 24.0;  // Section divider gap
static const double space32 = 32.0;  // Major section header separation
static const double space48 = 48.0;  // Hero bottom separation & modal footers
```

### Layout Constraints:
- **Screen Edge Margin**: Strict **20dp horizontal padding** on mobile viewports.
- **Maximum Content Width**: On tablets or foldable displays, content wraps within a centered **480dp max-width column** for forms, and **640dp max-width** for dashboards.

---

## 2. Surface & Elevation Architecture

To eradicate "glassmorphism fatigue" and achieve crisp structural depth, ArmSphere uses a **4-tier surface model**:

```
┌─────────────────────────────────────────────────────────────────┐
│                 SURFACE & ELEVATION HIERARCHY                   │
├───────┬──────────────────────┬─────────────┬────────────────────┤
│ Tier  │ Role                 │ Base Color  │ Treatment & Border │
├───────┼──────────────────────┼─────────────┼────────────────────┤
│ L0    │ Canvas Substrate     │ #070A11     │ Solid, zero blur   │
│ L1    │ Structural Base Card │ #0B0F19     │ 1px border #1E293B │
│ L2    │ Elevated Action Cell │ #121826 @90%│ 1px border #334155 │
│ L3    │ Focal / Glass Hero   │ #1E293B @85%│ 1px border gold/ice│
└───────┴──────────────────────┴─────────────┴────────────────────┘
```

### Surface Specifications:
1. **Tier 0: Canvas Substrate (`#070A11` / `#0B0F19`)**:
   - The root viewport background. Completely opaque to maximize OLED pixel shutoff on Android displays.
2. **Tier 1: Structural Base Card (`#0B0F19` with `#1E293B` Border)**:
   - Used for high-volume content: rankings rows, message bubbles, settings tiles, form text fields. Zero backdrop blur; highly performant.
3. **Tier 2: Elevated Action Cell (`#121826` @ 90% opacity)**:
   - Used for interactive dashboard shortcuts, tournament list cards, team roster tiles. Features a subtle 1px border (`#334155 @ 0.20`) and soft ambient elevation (`BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))`).
4. **Tier 3: Focal / Glass Hero Card (`#1E293B` @ 85% opacity with 12px BackdropFilter)**:
   - Reserved strictly for high-prestige focal elements: Tournament Details Hero, ELO Rating Card, Active Match Table Callout, and Championship Belt Lineage.

---

## 3. Corner Radius Scale

All interactive controls, cards, and dialogs adhere to a 4-tier radius system:

```dart
static const double radiusSmall    = 8.0;   // Status chips, badges, input fields
static const double radiusMedium   = 12.0;  // Standard content cards, shortcut buttons
static const double radiusLarge    = 16.0;  // Hero cards, bottom sheets, dialog modals
static const double radiusCircular = 999.0; // Athlete avatars, active status indicator dots
```

### Anti-Slop Corner Guard:
- **Never use 999dp pill shapes for standard cards or rectangular buttons.** Buttons must use `radiusMedium` (12dp) to maintain a modern, athletic silhouette.

---

## 4. Border & Illumination Model

Every card in ArmSphere uses **precision boundary illumination** instead of heavy, fuzzy drop shadows:

- **Subtle Resting Border**: `Border.all(color: AppTheme.border.withOpacity(0.25), width: 1.0)`
- **Selected / Focused Border**: `Border.all(color: AppTheme.info, width: 1.5)` (Sky Blue)
- **Prestige / Title Border**: `Border.all(color: AppTheme.goldPrimary, width: 1.5)` (Champagne Gold)
- **Live Match Table Border**: `Border.all(color: AppTheme.primaryAccent, width: 1.5)` (Coral Crimson with 4dp pulse)

---

## 5. Shadow & Glow Rules

1. **Ambient Shadows**:
   - Deep, natural shadows simulating table lighting:
   ```dart
   static BoxShadow ambientCardShadow() => BoxShadow(
     color: Colors.black.withOpacity(0.40),
     blurRadius: 12.0,
     spreadRadius: 0.0,
     offset: const Offset(0, 4),
   );
   ```
2. **Restrained Glow Effects**:
   - Glow is **strictly prohibited** on general text, common list tiles, and secondary buttons.
   - Glow is permitted only on:
     - Active championship title badge (`goldGlow`: `0x33D4AF37`)
     - Live match callout (`liveGlow`: `0x40EF4444`)
     - Online table status dot (`mintGlow`: `0x3310B981`)

---

## 6. Iconography System

- **Icon Family**: Google Material Symbols Outlined (`Icons.*_outlined` by default).
- **Weight**: 400 regular weight for unselected; filled variant (`Icons.*`) for active tab/selection.
- **Sizes**:
  - `16dp`: Micro metadata (arm indicators, date icons, table tags).
  - `20dp`: Standard list tile leading icons, form field prefixes.
  - `24dp`: Bottom navigation bar icons, AppBar actions.
  - `48–56dp`: Hero status illustrations and empty state icons.
