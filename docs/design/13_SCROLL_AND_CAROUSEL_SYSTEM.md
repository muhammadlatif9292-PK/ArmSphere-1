# ArmSphere Scroll & Carousel Architecture
**Viewport Physics, Collapsing Slivers & Carousel Discipline**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Scroll Physics & Viewport Architecture

ArmSphere uses tailored scroll physics aligned with Android hardware:

- **Primary Scroll Physics**: `ClampingScrollPhysics` with edge glow (Android native feel) or `AlwaysScrollableScrollPhysics` for pull-to-refresh compatibility.
- **Nested Scrolling**: Screens with horizontal carousels embedded inside vertical feeds wrap child lists in `NotificationListener<ScrollNotification>` to prevent horizontal swipes from locking the vertical scroll container.

---

## 2. Sliver App Bar & Collapsing Header Rules

High-density detail screens (`TournamentDetailScreen`, `PublicAthleteProfileScreen`) employ **SliverAppBars** to maximize screen real estate during downward scroll:

```
┌─────────────────────────────────────────────────────────────────┐
│                    SLIVER APP BAR LIFECYCLE                     │
├─────────────────────────────────────────────────────────────────┤
│ At Top (Expanded: 235dp):                                       │
│ • Full Hero image with gradient mask & breathing ambient light. │
│ • Tournament name (28sp bold) + Live countdown timer.           │
│                                                                 │
│ Scrolling Down (Collapsing):                                    │
│ • Hero image fades out (opacity 1.0 -> 0.0 over first 100dp).   │
│ • Background transitions to solid elevated dark slate (#0B0F19).│
│                                                                 │
│ Fully Collapsed (Pinned: 56dp standard AppBar height):          │
│ • Compact tournament title (18sp bold) fades into center/left.  │
│ • Pinned action buttons (Share, Bookmark, Register) stay visible│
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Carousel Strategy & Approval Matrix

Carousels are **strictly regulated**. A carousel is approved **only** if it serves rapid horizontal comparison without hiding critical vertical tasks:

| Candidate Area | Carousel Approved? | Technical Specification & Behavior |
| :--- | :---: | :--- |
| **Tournament Participants** | **APPROVED** | `ParticipantsCarouselWidget`: 0.82 viewportFraction with 16dp side peeking. Shows registered athlete avatars, club tags, and ELO. Drag-only (no autoplay). |
| **Discover Top Rankings** | **APPROVED** | Horizontal preview card of the #1 ranked pullers across Senior -70kg, -85kg, -95kg, +95kg. 0.88 viewportFraction. |
| **Category Filter Pills** | **APPROVED** | Compact horizontal chip list (`ListView(scrollDirection: Axis.horizontal)`). Height: 36dp. |
| **Main Rankings Ladder** | **FORBIDDEN** | Must remain a single vertical list. Horizontal carousels destroy comparative table scanning. |
| **Tournament Brackets** | **FORBIDDEN** | Brackets require 2D pan/zoom (`InteractiveViewer`), never a 1D carousel. |
| **Settings / Forms / Legal**| **FORBIDDEN** | Critical compliance and settings must be presented in clear vertical sequence. |

---

## 4. Carousel Touch & Autoplay Rules

1. **Autoplay Policy**:
   - **Autoplay is strictly banned across all mobile carousels.** Content must never shift under the user's thumb while they are reading.
2. **Side Peeking**:
   - Every carousel uses a `viewportFraction` between `0.80` and `0.88`. Seeing a 12–20% slice of the next card communicates that horizontal drag is possible without needing arrow buttons.
3. **Snap Physics**:
   - `PageScrollPhysics()` ensures each card snaps cleanly to the center of the viewport upon release.
4. **Pagination Indicators**:
   - Carousels feature compact pill indicators (4×16dp active pill in `accentGold`; 4×4dp dots in `textSecondary @ 0.30`).
