# ArmSphere Master Component Taxonomy
**Canonical Component Specifications, Variants & Usage Constraints**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Master Component Hierarchy

```
┌────────────────────────────────────────────────────────────────────────┐
│                        COMPONENT SYSTEM TAXONOMY                       │
├────┬────────────────────────────┬────┬─────────────────────────────────┤
│ 01 │ Shell & App Navigation     │ 06 │ Data Visualization Painters     │
│ 02 │ Structural & Glass Cards   │ 07 │ Interactive Bracket Components  │
│ 03 │ Badges, Chips & Indicators │ 08 │ Table-side Scoring Instruments  │
│ 04 │ Buttons & Action Triggers  │ 09 │ Skeletons & Empty States        │
│ 05 │ Form Fields & Pickers      │ 10 │ Modals, Sheets & Overlays       │
└────┴────────────────────────────┴────┴─────────────────────────────────┘
```

---

## 2. Component Specifications

### 2.1 Shell & Navigation Components
- **`MainShellScreen`**:
  - 5-branch persistent bottom navigation container with 90% opaque dark slate background (`#1E293B @ 0.90`) and 1px top border (`#334155 @ 0.15`).
  - Active icon uses `accentIceBlue` or `accentGold`; unselected icons use `textSecondary @ 0.40`.
- **`TactilePressWrapper`** (`core/widgets/tactile_press_wrapper.dart`):
  - Micro-scale down to `0.97` on user tap down; bounces back to `1.0` on release with subtle haptic tick. Wraps all clickable cards.

### 2.2 Structural & Glass Cards
- **`GlassCard`** (`core/widgets/glass_card.dart`):
  - Surface: `#121622` at 0.85 opacity.
  - Border: 1px `#26D4AF37` (15% Gold) or `#334155 @ 0.20`.
  - Radius: 12dp standard (`radiusMedium`), 16dp for hero sections (`radiusLarge`).
  - Internal Padding: 16dp default.
- **`ElevatedActionCard`**:
  - Non-glass, high-performance alternative for dense lists (Rankings, Discussions).
  - Background: solid `#141C2E`, 1px border `#1E293B`. Zero GPU raster blur.

### 2.3 Badges, Chips & Indicators
- **`StatusChip`**:
  - Compact rounded pill (`radiusSmall`: 8dp) displaying event or registration status.
  - Emerald (`#10B981`) for `ONGOING` / `WIN` / `PASSED`.
  - Amber (`#F59E0B`) for `PUBLISHED` / `PENDING`.
  - Coral (`#FF5252`) for `CANCELLED` / `LOSS` / `FAILED`.
- **`ArmIndicatorPill`**:
  - Distinguishes Right Arm vs Left Arm competitions:
  - `Right Arm`: Ice Blue outline (`#38BDF8`).
  - `Left Arm`: Amber outline (`#F59E0B`).
- **`PulseIndicator`** (`core/widgets/pulse_indicator.dart`):
  - 8dp glowing dot pulsating between 0.3 and 1.0 opacity over 1200ms. Signals live matches or ongoing events.

### 2.4 Buttons & Action Triggers
- **Primary Button (`FilledButton`)**:
  - Background: `accentGold` (`#D4AF37`) with black bold text for highest focal priority.
  - Height: 48dp on mobile forms; 56dp for referee scorepads.
  - Radius: 12dp.
- **Secondary Button (`OutlinedButton`)**:
  - Background: Transparent with 1.2px border (`#334155`).
  - Text: `textPrimary` (`#F8FAFC`).
- **Destructive Button**:
  - Background: `#FF5252 @ 0.15` with coral text and red border. Requires 2-step confirmation sheet.

### 2.5 Form Fields & Pickers
- **`AppTextField`**:
  - Background: `#0B0F19` with `#334155` border.
  - Focused state: 1.5px border in `accentIceBlue` (`#38BDF8`).
  - Error state: 1.5px border in `errorCoral` with caption text.
  - Prefix icon in `textSecondary`.
- **`SearchInputField`**:
  - Embedded inside AppBar or sticky header with instant clear button (`X`) and debounced listener.

### 2.6 Data Visualization Painters
- **`EloSparklinePainter`**:
  - Lightweight canvas painter rendering an athlete's last 10 match ELO trajectory.
  - Green gradient stroke if positive trend; coral stroke if negative.
- **`PerformanceRadarChartPainter`**:
  - 5-axis polygon chart comparing Arm Reach, Forearm Girth, Wrist Flexion, Cup Torque, and ELO Rank.

### 2.7 Interactive Bracket Components
- **`BracketNodeCard`**:
  - 180×64dp compact card housing athlete name, seed, score, and winner highlight.
- **`BracketLinesPainter` & `BracketConnectorsPainter`**:
  - Custom canvas curves connecting Winner and Loser bracket seeds with 2px steel-gray lines (`#334155`).

### 2.8 Table-Side Scoring Instruments
- **`OfficialScorepadCounter`**:
  - Massive 64dp touch cells for Referee table-side thumb tapping.
  - High-contrast numbers in `SpaceGrotesk` (36sp).
  - Physical haptic click on increment.

### 2.9 Skeletons & Empty States
- **`ShimmerBox` & `GlassShimmerSkeletonList`**:
  - Shimmer placeholders matching card footprints.
- **`AppEmptyState`** (`core/widgets/app_empty_state.dart`):
  - Standardized empty view: 56dp icon, title, contextual explanation, and direct action CTA.

### 2.10 Modals & Sheets
- **`ConfirmationBottomSheet`**:
  - Draggable modal bottom sheet with top grab handle (4×32dp `#64748B`), title, body warning, and dual buttons (Cancel vs Confirm).
