# ArmSphere Stage 4 — Surface & Depth Architecture Specification
**Document Version**: 1.0.0 (Authoritative Stage 4 Architecture)
**Date**: September 26, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, & Stage 4 Master Directive
**Scope**: 6-Level Surface Hierarchy, Physical Material Specifications, 7-Tier Depth Stack, and the Mandatory Card Unbundling Protocol.

---

## 1. Executive Purpose & Anti-Cardification Mandate

A pervasive failure mode in modern mobile design is **Card Soup Syndrome**: wrapping every sentence, button, statistic, and avatar inside an identical rounded box. This creates visual stutter, consumes valuable screen real estate with redundant margins, and flattens the hierarchy of the screen.

ArmSphere replaces undifferentiated card containers with a **Tactile Physical-Material Surface System**. Surfaces are treated as physical plates of cold-rolled steel, high-density table rubber, machined alloy, and ceremonial gold. 

A component earns a bordered card boundary **only when a physical surface threshold improves comprehension or touch interaction**.

---

## 2. 6-Level Surface Hierarchy

```
+-----------------------------------------------------------------------------------+
|                           6-LEVEL SURFACE HIERARCHY                               |
|                                                                                   |
|  LEVEL 5: CEREMONIAL OVERLAY   -> Full-screen modal, gold sweeping sheen (12dp)   |
|  LEVEL 4: FOCUSED / ACTIVE     -> 1px Cyan/Gold outline, micro-elevation (8dp)    |
|  LEVEL 3: ELEVATED INTERACTIVE -> Knurled plate, touchable inputs/CTAs (4dp)     |
|  LEVEL 2: STRUCTURAL CONTENT   -> Machined composite, grouped records (2dp)       |
|  LEVEL 1: CONTEXT BASE         -> Cold-rolled steel viewport plates (0dp)         |
|  LEVEL 0: ENVIRONMENT VOID     -> Deep obsidian canvas (#070A11) (0dp)            |
+-----------------------------------------------------------------------------------+
```

### Level-by-Level Specification Table

| Surface Level | Physical Material Logic | Background Token | Border Token | Elevation / Shadow | Blur & Glow | Radius | Internal Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Level 0: Environment Substrate** | Raw Obsidian Canvas | `substrateVoid (#070A11)` | None | 0dp (No shadow) | None | 0dp | Edge-to-edge |
| **Level 1: Context Surfaces** | Cold-Rolled Steel Plate | `backgroundBase (#0B0F19)` | `borderSubtle (#1E293B)` (1px bottom) | 0dp (Planar) | None | 0dp (Full width) | `space16` (16dp) |
| **Level 2: Structural Content** | Machined Composite Plate | `surfacePrimary (#121826)` | `borderVisible (#334155)` (1px solid) | 2dp (`Color(0x1F000000)`, blur: 4, offset: (0, 2)) | None | `radiusMedium` (12dp) | `space12` or `space16` |
| **Level 3: Elevated Interactive** | Knurled Grip Alloy | `surfaceSecondary (#1E293B)` | Directional: `borderLight (#475569)` top, `borderVisible (#334155)` bottom | 4dp (`Color(0x33000000)`, blur: 8, offset: (0, 4)) | None | `radiusMedium` (12dp) | `space12` (12dp) |
| **Level 4: Focused / Active State** | Edge-Lit Table Instrument | `surfaceSecondary (#1E293B)` | `borderActiveCyan (#38BDF8)` or `borderActiveGold (#D4AF37)` (1.5px) | 8dp (`Color(0x40000000)`, blur: 12, offset: (0, 6)) | 4dp Micro-Glow (`0x3338BDF8` or `0x33D4AF37`) | `radiusMedium` (12dp) | `space12` (12dp) |
| **Level 5: Transient Overlay** | Ceremonial Glass & Gold | `surfacePrimary (#121826)` at 95% opacity | Specular Gold Chamfer (`#D4AF37` at 1.5px) | 16dp (`Color(0x66000000)`, blur: 24, offset: (0, 8)) | 12dp Backdrop Blur on modal background | `radiusLarge` (16dp) | `space20` (20dp) |

---

## 3. The 7-Layer Z-Axis Depth Stack

To avoid conflicting visual depths, all UI layers exist within an immutable Z-axis coordinate space:

```
[TOP / Z-AXIS +6]  LAYER 7: TRANSIENT FEEDBACK
                   -> Toast notifications, referee pin confirm pulses, tactile ripples
-------------------------------------------------------------------------------------
[Z-AXIS +5]        LAYER 6: ACTIVE CEREMONIAL / MODAL
                   -> EloSurgeModal, ChampionshipGoldCard, WeighInClearanceStamp
-------------------------------------------------------------------------------------
[Z-AXIS +4]        LAYER 5: ELEVATED INTERACTION
                   -> Sticky bottom action bars, floating referee scorepad controls
-------------------------------------------------------------------------------------
[Z-AXIS +3]        LAYER 4: STRUCTURAL CONTENT TIERS
                   -> Match brackets, athlete telemetry cards, form field groups
-------------------------------------------------------------------------------------
[Z-AXIS +2]        LAYER 3: HERO MEDIA & EDITORIAL PANELS
                   -> Tournament arena backdrops, athlete face-off imagery with scrims
-------------------------------------------------------------------------------------
[Z-AXIS +1]        LAYER 2: ATMOSPHERIC OVERLAYS
                   -> Subtle arena vignette, directional top spotlights (0° down)
-------------------------------------------------------------------------------------
[BOTTOM / Z-AXIS 0] LAYER 1: BACKDROP SUBSTRATE
                   -> Permanent Obsidian Canvas (#070A11)
```

### Depth Stack Rules:
1. **No Layer Inversion**: A Level 3 structural card may never sit above a Level 5 sticky action bar.
2. **Restrained Ambient Occlusion**: Drop shadows are directional (`offset: (0, Y)`), simulating an overhead spotlight. Horizontal shadow spreading (`offset: (X, 0)`) is forbidden.
3. **Glassmorphism Restriction**: `BackdropFilter` is restricted exclusively to **Layer 5 and Layer 6** (Sticky AppBars and Modal Overlays). It is strictly banned on Level 2 and Level 3 content cards to maintain 60/120fps scrolling performance on mobile hardware.

---

## 4. "Cards Are Not The Default": The Unbundling Protocol

Every component in the application must pass the **Unbundling Decision Tree** before being wrapped in a card:

```
+-----------------------------------------------------------------------------------+
|                        CARD UNBUNDLING DECISION TREE                              |
|                                                                                   |
|  QUESTION: Does this content item require independent touch dragging,             |
|  discrete modal grouping, or swipe-to-dismiss?                                    |
|                                                                                   |
|         YES --------------------------------------> [RENDER AS LEVEL 2/3 CARD]   |
|          |                                                                        |
|         NO                                                                        |
|          v                                                                        |
|  CAN IT BECOME:                                                                   |
|  1. An Editorial Text Block?     -> Seamless title + body with 1px divider rule   |
|  2. A Horizontal Telemetry Rail? -> Edge-to-edge scrollable statistic strip       |
|  3. A Borderless Media Canvas?   -> Full-width photographic backdrop with scrim   |
|  4. An Inline Segmented Control? -> Flat pill rail embedded directly in header    |
|  5. A Structured List View?      -> Clean alternating rows with hairline divider  |
+-----------------------------------------------------------------------------------+
```

### Component Alternative Catalog (Replacing Generic Cards)

| Current Pattern | Flaw | Elevated ArmSphere Replacement | Visual Architecture |
| :--- | :--- | :--- | :--- |
| **Tournament Info Card** | Boxed inside card with 4 margins; feels cramped. | **Full-Bleed Hero Media Canvas** | Image spans 100% viewport width with 4-stop directional gradient scrim; titles and fight clock sit directly on the scrim. |
| **Elo Rating Card** | Isolated floating box for a single number. | **Integrated Telemetry Header** | Monumental 36sp `SpaceGrotesk` number sits alongside the athlete's name on the primary background plate; zero enclosing box. |
| **Division List Cards** | 8 identical cards stacked vertically; suffocates scroll. | **Horizontal Segmented Chip Rail** | Borderless horizontal strip with 8dp chips; selected chip illuminates with Cyan border. |
| **Match History Cards** | Card for every past match; visual clutter. | **Continuous Bout Timeline** | High-density vertical timeline connected by a 1.5px metallic rail (`#334155`); outcome indicated by a micro-pip (Emerald Win / Crimson Loss). |
| **Rules & Regulations Card** | Plain text trapped in a bordered box. | **Editorial Document Section** | Left-aligned typography with a subtle gold accent bar on section headers; reads like an official federation charter. |
| **Referee Scorepad Buttons** | Small cards grouped in a grid. | **Full-Screen Ergonomic Touch Canvas** | Edge-to-edge split-screen tactile pads (64dp+ touch zones) directly integrated into the viewport base plate. |

---

## 5. Physical Edge & Chamfer Mechanics

To give digital surfaces the weight of machined sports equipment, ArmSphere utilizes **Directional Top-Edge Chamfers**:

```dart
/// Precision Machined Plate Decoration for Flutter
BoxDecoration athleticPlateDecoration({
  Color background = AppThemeTokens.surfacePrimary,
  Color topHighlight = AppThemeTokens.borderLight,
  Color bottomBorder = AppThemeTokens.borderVisible,
  double radius = AppRadii.radiusMedium,
}) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(radius),
    border: Border(
      top: BorderSide(color: topHighlight, width: 1.0),    // Top specular highlight
      bottom: BorderSide(color: bottomBorder, width: 1.0), // Grounded shadow border
      left: BorderSide(color: bottomBorder, width: 1.0),
      right: BorderSide(color: bottomBorder, width: 1.0),
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x26000000),
        blurRadius: 8.0,
        offset: Offset(0, 4),
      ),
    ],
  );
}
```

---

## 6. Architectural Sign-Off
This surface and depth architecture eliminates visual clutter and establishes a tangible, athletic materiality. It is authoritative for all screen layouts, modal overlays, and component decorators across the entire mobile application.
