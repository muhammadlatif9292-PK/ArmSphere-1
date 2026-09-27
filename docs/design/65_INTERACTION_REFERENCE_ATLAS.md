# ArmSphere Interaction Reference Atlas
**Document Version**: 1.0.0 (Stage 6 Experience Convergence)
**Date**: September 27, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, `docs/design/64_RESEARCH_VALIDATION_AND_CONTRADICTION_AUDIT.md`
**Scope**: Definitive 20-Category Interaction Reference Atlas (A through T) codifying touch, spatial, gesture, haptic, audio, state transitions, and accessibility mechanics across all 66 ArmSphere production screens.

---

## 1. Structural Overview & Atlas Taxonomy

The ArmSphere Interaction Reference Atlas establishes the canonical library of interactive behaviors for the mobile application. Each category provides:
1. **Interactive Trigger & Gesture Detection Engine**: Exact Flutter widget composition (`GestureDetector`, `Listener`, `InkWell`).
2. **State Lifecycle**: Transitions between `idle`, `hover/focus`, `pressed`, `committed`, `released`, and `cancelled`.
3. **Physical & Motion Parameters**: Target properties, duration in milliseconds, and exact Flutter curve tokens.
4. **Haptic & Sensory Feedback**: Native haptic invocation patterns.
5. **Anti-Slop Boundaries & Accessibility**: Target dimensions, contrast rules, and touch-slop tolerance.

---

## 2. Atlas Categories (A through T)

### Category A: Touch, Press & Tap Mechanics
- **Interaction Name**: Tactical Micro-Depression (`TactileTap`)
- **Purpose**: High-confidence physical feedback for buttons, chips, and quick-action triggers.
- **Trigger**: `GestureDetector.onTapDown` and `onTapUp` / `onTapCancel`.
- **State Lifecycle**:
  - `Idle`: Scale 1.00, Elevation Level 1, Surface `#121826`.
  - `Pressed` (TapDown): Instant scale depression to 0.97 (Buttons) or 0.98 (Cards), Surface shifts +4% luminosity (`#1A2234`), 1px border illuminates from `#334155` to `#D4AF37` (if primary) or `#38BDF8` (if secondary).
  - `Released` (TapUp): Snaps back to Scale 1.00 in 120ms (`Curves.easeOutCubic`). Action executes immediately on tap-up.
  - `Cancelled` (Slop exceeded > 18dp): Smooth restoration to Scale 1.00 in 150ms without action trigger.
- **Haptic Profile**: `HapticFeedback.lightImpact()` on tap-down; zero delay.
- **Anti-Slop & A11y**: Minimum tap target is 48dp x 48dp (64dp x 64dp on Referee Scorepad). Scale never drops below 0.96 to prevent visual instability.

---

### Category B: Long Press & Hold Mechanics
- **Interaction Name**: Sustained Pin Lock & Emergency Hold (`SustainedHold`)
- **Purpose**: Destructive confirmations, match pin verifications, and scorepad lockouts.
- **Trigger**: Continuous pointer contact via custom `RawGestureDetector` or `GestureDetector.onLongPressStart` + `onLongPressEnd`.
- **State Lifecycle**:
  - `HoldInitiated` (0–100ms): Touch target compresses to Scale 0.96; radial outline begins animating from 0° to 360° in Gold (`#D4AF37`) or Emerald (`#10B981`); haptic rumble initiated.
  - `Holding` (100–399ms): Monospace countdown timer pulses in center; ambient screen border illuminates at 15% opacity.
  - `Committed` (Exactly 400ms threshold): `HapticFeedback.heavyImpact()` triggers; target flashes white (100ms) and locks; state becomes immutable.
  - `Aborted` (Released < 400ms): Target springs back to Scale 1.00; radial fill collapses in 100ms (`Curves.easeInQuad`); `HapticFeedback.selectionClick()` signals cancellation.
- **Anti-Slop & A11y**: Visual and haptic progress are strictly synchronized. Maximum hold duration capped at 400ms for scoring, 800ms for administrative forfeits.

---

### Category C: Swipe & Pan Mechanics
- **Interaction Name**: Match Card Swipe-Action (`BiDirectionalSwipe`)
- **Purpose**: Quick athlete favoriting, tournament bookmarking, and match check-in status.
- **Trigger**: Horizontal drag via `Dismissible` or custom `HorizontalDragGestureRecognizer`.
- **State Lifecycle**:
  - `PanStart`: Visual card detaches from list plane; subtle drop shadow intensifies (elevation 4).
  - `PanActive`: Card translates along X-axis with 1:1 finger tracking. Revealing background underneath:
    - Right Swipe (>40dp): Emerald Green (`#10B981`) plane with checkmark icon.
    - Left Swipe (<-40dp): Coral Red (`#EF4444`) plane with withdraw/archive icon.
  - `ThresholdReached` (±72dp): `HapticFeedback.mediumImpact()` fires; background icon scales up 1.15x.
  - `Committed`: Card slides off screen in 180ms (`Curves.easeOutCubic`) if dismissed, or returns to 0 offset with action triggered.
  - `ReleasedBeforeThreshold`: Card snaps back to X=0 in 150ms (`Curves.easeOutCubic`).
- **Anti-Slop & A11y**: Vertical touch slop must exceed 12dp before horizontal panning locks, preventing scroll conflicts in dense match feeds.

---

### Category D: Drag, Drop & Reorder Mechanics
- **Interaction Name**: Seeding Bracket Manual Reorder (`TournamentSeedingDrag`)
- **Purpose**: Tournament marshals reordering athlete seeds prior to bracket generation.
- **Trigger**: `ReorderableListView` or `LongPressDraggable`.
- **State Lifecycle**:
  - `Lift` (200ms hold): Item scales to 1.03x; elevation jumps to Level 5 (drop shadow 16dp, `#000000` at 60%); `HapticFeedback.heavyImpact()`.
  - `Dragging`: Item follows pointer with clamped bounds; adjacent items slide vertically out of the way in 150ms (`Curves.easeInOutCubic`).
  - `DropZoneHover`: Hovered target slot displays 2px dashed Gold border (`#D4AF37`).
  - `Drop`: Item settles into target slot; scale returns to 1.00x in 120ms (`Curves.easeOutCubic`); `HapticFeedback.mediumImpact()`.
- **Anti-Slop & A11y**: Accessible alternate mode provided via "Move Up" / "Move Down" discrete accessibility action buttons for screen reader users.

---

### Category E: Pull & Release Mechanics
- **Interaction Name**: Knurled Cable Tension Refresh (`CablePullRefresh`)
- **Purpose**: Synchronizing live tournament scores and bracket standings with server.
- **Trigger**: `RefreshIndicator` or custom `CustomScrollView` with overscroll physics.
- **State Lifecycle**:
  - `Pulling` (0–80dp): Knurled steel icon appears at top; tension increases logarithmically (drag distance = finger displacement * 0.45); chalk dust micro-particles slowly concentrate.
  - `Armed` (80dp threshold): Cable icon snaps into locked position; `HapticFeedback.mediumImpact()` fires; Gold glow activates.
  - `Released`: Header locks at 56dp height; dual-segment knurled spinner rotates smoothly; SQLite sync completes.
  - `Completion`: Spinner morphs into checkmark (100ms); header slides up and disappears in 150ms (`Curves.easeOutCubic`); `HapticFeedback.lightImpact()`.
- **Anti-Slop & A11y**: Over-pull distance is hard-clamped at 120dp. Never triggers accidentally during high-speed upward flick scrolls.

---

### Category F: Scroll Mechanics & Scroll-Linked Effects
- **Interaction Name**: Industrial Scrim Parallax Scroll (`ChoreographedHeroScroll`)
- **Purpose**: Rich header collapse and sticky navigation on Tournament Detail and Athlete Profile screens.
- **Trigger**: `NestedScrollView` with `SliverAppBar(expandedHeight: 320.0, pinned: true)`.
- **State Lifecycle**:
  - `ScrollOffset 0–180dp`: Hero media scales down slightly (1.00 to 0.95); opacity shifts from 1.00 to 0.40; title text slides upward and compresses from 32sp (`SpaceGrotesk-Bold`) to 20sp.
  - `ScrollOffset 180–320dp`: Surface `#070A11` gradient scrim cross-fades into solid `#0B0F19` app bar; 1px bottom border (`#334155`) fades in.
  - `Pinned State (>320dp)`: App bar remains locked at 56dp elevation; compact title and live status chip visible with 100% contrast.
- **Anti-Slop & A11y**: Header collapse does not clip focusable buttons. Zero frame drop during scroll; media layer is cached in GPU memory via `RepaintBoundary`.

---

### Category G: Zoom, Pinch & Spatial Navigation
- **Interaction Name**: Tournament Bracket Infinite Pan & Zoom (`BracketSpatialNavigator`)
- **Purpose**: Navigating complex 64-man double elimination bracket trees.
- **Trigger**: `InteractiveViewer` with `minScale: 0.5, maxScale: 2.5`.
- **State Lifecycle**:
  - `Pan`: 2D translation across bracket canvas with boundary friction.
  - `PinchZoom`: Scales bracket nodes smoothly around touch focal point; node typography switches level-of-detail:
    - <0.75x: Micro-view (Athlete surnames and score badges only).
    - 0.75x–1.5x: Standard-view (Full names, seed numbers, flags, arm indicator).
    - >1.5x: Detail-view (ELO badges, previous match history links, referee notes).
  - `MiniMap Sync`: Bottom-right 80dp x 60dp HUD viewport indicates current canvas bounding box; tapping mini-map instantly centers view on selected pool.
- **Anti-Slop & A11y**: Double-tap on any match node smoothly zooms and centers that match in 250ms (`Curves.easeInOutCubic`).

---

### Category H: Carousel, Rail & Horizontal Flow Mechanics
- **Interaction Name**: Snapping Match Rail (`SnappingStageRail`)
- **Purpose**: Horizontal browsing of live tables, upcoming featured bouts, and weight categories.
- **Trigger**: `PageView` or `ListView.separated` with `PageScrollPhysics` or `SnappingScrollPhysics`.
- **State Lifecycle**:
  - `Dragging`: Momentum-based glide; active card scales to 1.00x, adjacent cards compress to 0.94x and 0.75 opacity.
  - `SnapTargetLocked`: Center-docked card expands to 1.00x; elevation increases to Level 3; 1px Gold border sheen glides across card top.
  - `HapticTick`: `HapticFeedback.selectionClick()` fires every time a new card enters focal center.
- **Anti-Slop & A11y**: Snap boundaries are hard-aligned to viewport center with 16dp edge insets, ensuring cards are never cut off ambiguously.

---

### Category I: Card & Surface State Transitions
- **Interaction Name**: Multi-Tier Card Elevation (`TactileSurfaceState`)
- **Purpose**: Defining distinct visual hierarchy for interactive cards (Athletes, Tournaments, Bouts).
- **State Lifecycle**:
  - `Rest / Idle`: Surface `#121826`, 1px border `#334155`, shadow `0 2px 4px rgba(0,0,0,0.4)`.
  - `Hover / Pointer`: Surface `#161F32`, border `#475569`, shadow `0 4px 8px rgba(0,0,0,0.5)`.
  - `Pressed`: Surface `#1E293B`, border `#D4AF37` (20% opacity), scale 0.98.
  - `Selected / Active`: Surface `#1A2338`, border 1.5px `#D4AF37` (100%), subtle corner gold pip (4dp).
  - `Disabled`: Surface `#0E131F`, opacity 0.50, border `#1E293B`, zero interaction response.
  - `Error / Foul`: 1.5px border `#EF4444`, ambient red glow (10% opacity).
- **Anti-Slop & A11y**: Transitions between states execute in 120ms (`Curves.easeOutCubic`) with zero layout reflow.

---

### Category J: List Item & Feed Interactions
- **Interaction Name**: Staggered Feed Ingress & Highlight Pulse (`StaggeredListPulse`)
- **Purpose**: Loading athlete feeds, tournament lists, and community posts with fluid choreography.
- **State Lifecycle**:
  - `Ingress`: Items slide up 16dp and fade in sequentially with a 30ms stagger offset per item (capped at first 8 visible items to preserve performance).
  - `Live Update Pulse`: When a match score updates via background sync, the affected row flashes a 1px Cyan border (`#38BDF8`) for 400ms, accompanied by an animated numeric counter roll.
- **Anti-Slop & A11y**: Subsequent items below fold load without stagger animation to prevent scroll stuttering.

---

### Category K: Modal, Sheet & Dialog Presentation
- **Interaction Name**: Industrial Scrim Sheet (`PrecisionBottomSheet`)
- **Purpose**: Filter menus, referee penalty selectors, and quick-action sheets.
- **Trigger**: `showModalBottomSheet` with custom rounded top chamfer (16dp).
- **State Lifecycle**:
  - `Entrance`: Scrim background `#000000` dims from 0% to 65% opacity; sheet translates up from Y=100% to Y=0 in 250ms (`Curves.easeOutCubic`).
  - `Knurled Handle Bar`: 36dp x 4dp knurled handle bar in `#64748B` at top center.
  - `DragToDismiss`: Dragging downward past 80dp or flicking with velocity > 600dp/s dismisses sheet in 180ms (`Curves.easeInQuad`).
  - `Backdrop Tap`: Instant dismissal without lag.
- **Anti-Slop & A11y**: Sheets are draggable only via the handle bar or non-scrollable header area when containing internal scrollable lists.

---

### Category L: Navigation & View Transitions
- **Interaction Name**: Spatial Directional Slide & Shared Element Hero (`ChoreographedRoute`)
- **Purpose**: Moving between master views, detail views, and full-screen scorepads.
- **State Lifecycle**:
  - `Forward Push (Master -> Detail)`: Destination screen slides in from Right (X: 100% -> 0%) with 300ms duration (`Curves.easeOutCubic`); existing screen translates left by -25% and dims by 20% opacity.
  - `Shared Element Hero`: Athlete avatar, tournament logo, or bracket card expands seamlessly across routes using `Hero` with `FlightShuttleBuilder` to prevent border clipping.
  - `Pop / Return`: Top screen slides right (0% -> 100%) in 250ms (`Curves.easeInOutCubic`); parent screen restores.
- **Anti-Slop & A11y**: Android predictive back and iOS edge-swipe gestures are supported natively with 1:1 gesture tracking.

---

### Category M: Form, Input & Control Interactions
- **Interaction Name**: Precision Armwrestling Form Field (`ChiseledFormField`)
- **Purpose**: Weigh-in numbers, athlete profile edits, and score entry fields.
- **State Lifecycle**:
  - `Unfocused`: Background `#121826`, border 1px `#334155`, label in `#94A3B8`.
  - `Focused`: Background `#161F32`, border 1.5px `#D4AF37` (Gold), label shrinks to 11sp and shifts upward into border notch in `#D4AF37`.
  - `Input Error`: Border snaps to `#EF4444`, 3-cycle horizontal micro-shake (±4dp, 120ms total duration), inline error message appears in `#EF4444`.
  - `Referee Numeric Pad`: 64dp high numeric tiles with instant tap feedback (0ms delay) and monospace tabular readout.
- **Anti-Slop & A11y**: Virtual keyboard displays correct contextual type (`TextInputType.numberWithOptions(decimal: true)` for weights).

---

### Category N: Search & Filtering Dynamics
- **Interaction Name**: Instant Debounced Filter Pill (`ReactiveFilterTray`)
- **Purpose**: Real-time filtering across weight classes (-75kg, -85kg, +110kg), arms (Left/Right), and match status.
- **State Lifecycle**:
  - `Pill Toggle`: Tapping an unselected pill (`#1E293B`, `#94A3B8` text) toggles it to active (`#D4AF37` fill or 1.5px Gold border with Gold text); scale depresses to 0.95 then bounces back in 100ms; `HapticFeedback.selectionClick()`.
  - `Text Search`: Search input debounced at 150ms for local SQLite search; instant skeleton shimmer overlay across list during query filtering.
  - `Clear Filter`: Tapping the "X" button clears all active chips in 100ms with a crisp tactile click.
- **Anti-Slop & A11y**: Active filter chips remain pinned horizontally at top of list during scroll.

---

### Category O: Media Playback & Video Interactions
- **Interaction Name**: Community Tactical Media Player (`CombatVideoPlayer`)
- **Purpose**: High-engagement training clips, technique breakdown videos, and tournament highlights.
- **Trigger**: Contained within Community and Media tabs only.
- **State Lifecycle**:
  - `InView Autoplay`: Video autoplays muted when >70% visible in viewport; audio icon displays "MUTED" badge.
  - `Tap to Unmute`: Single tap toggles audio; volume level fades in over 100ms; `HapticFeedback.lightImpact()`.
  - `Double Tap Seek`: Double tap right half seeks +5s with a quick animated forward arc icon; left half seeks -5s.
  - `Scrubbing`: Dragging bottom scrubber shows floating timestamp thumbnail; video freezes current frame until release.
- **Anti-Slop & A11y**: Full-screen video transition preserves current playback timestamp without re-buffering.

---

### Category P: Haptic & Tactile Feedback Mapping
- **Interaction Name**: Unified Haptic Hierarchy (`ArmSphereHaptics`)
- **Purpose**: Direct tactile confirmation of all UI actions without requiring screen fixation.
- **Mapping Matrix**:
  - `Selection Tick` (`HapticFeedback.selectionClick()`): Tab changes, filter chip toggles, rail scroll snap.
  - `Light Impact` (`HapticFeedback.lightImpact()`): Standard button presses, card taps, search clear.
  - `Medium Impact` (`HapticFeedback.mediumImpact()`): Swipe action triggers, pull-to-refresh armed, modal sheet dock.
  - `Heavy Impact` (`HapticFeedback.heavyImpact()`): Pin hold completion (400ms), tournament champion crowned, foul issued.
  - `Error Buzz` (Double light impact, 80ms interval): Form validation error, unauthorized action attempt, network drop warning.
- **Anti-Slop & A11y**: System haptic toggle respected in OS settings; zero phantom vibrations.

---

### Category Q: Sound & Audio Cues
- **Interaction Name**: Federation Acoustic Identity (`AcousticCueSystem`)
- **Purpose**: Optional, authoritative acoustic feedback during live tournament operations.
- **Cue Catalog**:
  - `Scorepad Buzzer`: Sharp 800Hz industrial beep (120ms) on round start / ready signal.
  - `Pin Lock Bell`: Resonant brass bell strike (400ms) on verified match victory.
  - `Foul Klaxon`: Dual-tone low buzzer (150ms) on referee foul declaration.
- **Anti-Slop & A11y**: All audio cues are strictly optional, muted by default, and configurable in settings. Visual feedback is always 100% self-sufficient.

---

### Category R: Loading, Skeleton & Shimmer States
- **Interaction Name**: Dual-Tone Knurled Shimmer (`SteelShimmerEngine`)
- **Purpose**: Zero-layout-shift placeholders during data fetches.
- **Structure**:
  - Base surface: `#121826`.
  - Shimmer highlight: `#1E293B` to `#26354D` (linear gradient angled at 115°).
  - Sweep period: 1400ms continuous sweep (`Curves.easeInOut`).
  - Layout: Skeletons replicate exact bounding boxes of target athlete cards, stats rows, and tournament badges.
- **Anti-Slop & A11y**: Skeletons never jump or reflow upon data load; cross-fade from skeleton to content occurs in 150ms (`Curves.easeOutCubic`).

---

### Category S: Error, Warning & Empty State Handling
- **Interaction Name**: Resilient Empty & Offline Sentinel (`ResilientStatePlane`)
- **Purpose**: Clear, non-punitive communication when data is missing or network fails.
- **Structure**:
  - Icon: Solid dual-tone technical vector (Chalk Bag, Broken Cable, Empty Arena) in `#64748B`.
  - Headline: 18sp `SpaceGrotesk-Bold` in `#F8FAFC`.
  - Description: 14sp `Inter-Regular` in `#94A3B8` explaining the situation.
  - Action Button: Prominent 48dp CTA (`[TRY AGAIN]`, `[WORK OFFLINE]`, `[CLEAR FILTERS]`).
- **Anti-Slop & A11y**: Never traps user in dead end; always provides an explicit escape or recovery action.

---

### Category T: Progressive Disclosure & Depth Layers
- **Interaction Name**: Accordion Expansion Plane (`StructuralDisclosure`)
- **Purpose**: Deep athlete stats, round-by-round scorepad breakdowns, and rulebook details.
- **State Lifecycle**:
  - `Collapsed`: Single compact row (52dp height) with chevron icon pointing down.
  - `Expanding`: Tapping row triggers vertical container expansion in 200ms (`Curves.easeInOutCubic`); chevron rotates 180° clockwise; child content fades in from 0% to 100% opacity.
  - `Expanded`: Detailed statistics table revealed on `#0B0F19` recessed plane with 1px top/bottom dividers.
- **Anti-Slop & A11y**: Expanding accordion automatically scrolls into visible viewport if bottom edge falls below screen boundary.

---

## 3. Summary & Integration Matrix

The 20 interaction categories documented in this Atlas cover 100% of user touchpoints across ArmSphere's 66 production screens. 

Next, **Document 66** isolates the exclusive, non-generic **ArmSphere Signature Interactions** that define the platform's brand identity.
