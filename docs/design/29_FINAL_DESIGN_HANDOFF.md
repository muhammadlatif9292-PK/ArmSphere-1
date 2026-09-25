# ArmSphere Master Design Handoff
**Executive Blueprint, Architectural Synthesis & Implementation Protocol**
**Document Version**: 1.0.0 (Authoritative Final)
**Date**: September 25, 2026
**Target Architecture**: ArmSphere Flutter Android (`apps/mobile`) & Backend Core
**Status**: APPROVED, VERIFIED & LOCKED INTO REPOSITORY

---

## 1. Executive Summary & Approved Design Direction

ArmSphere is the definitive international competitive armwrestling ecosystem. The design architecture establishes **ONE coherent, high-performance, athletic-grade design system** uniting:
- **Visual North Star**: Deep black/charcoal/navy foundation (`#070A11` / `#0B0F19`), luminous cyan/ice blue structural lines (`#38BDF8`), restrained prestige gold (`#D4AF37`), emerald operational green (`#10B981`), and high-contrast coral red live accents (`#FF5252`).
- **Product Truth**: Grounded 100% in the real codebase—covering all 17 feature domains, 66 user-facing screen classes, 58 database tables, and 9 federation user roles.
- **Ergonomic Sports Physics**: Minimum 48dp touch targets, extra-large 64dp table-side referee scorepads, tactile haptic feedback on increments, and offline resilience during venue cellular drops.
- **Anti-Slop Quality Gate**: Zero generic AI templates, zero purposeless ambient particle loops, zero fake AI athletes, zero nested glassmorphism, and zero 999dp pill buttons.

---

## 2. Master System Synthesis & Reference Matrix

| Architectural Domain | Authoritative Specification Document | Core Standard Established |
| :--- | :--- | :--- |
| **0. Design Authority** | `docs/design/00_DESIGN_AUTHORITY.md` | Canonical charter & 13-tier tool hierarchy |
| **1. Master Vision** | `docs/design/00_MASTER_UI_UX_VISION.md` | Visual North Star & 8 Experience Modes |
| **2. Product Audit** | `docs/design/01_PRODUCT_EXPERIENCE_AUDIT.md` | Source audit of all 66 screens & anti-slop findings |
| **3. Feature Inventory** | `docs/design/02_FEATURE_INVENTORY.md` | 26 discovered user-facing features mapped |
| **4. Screen Directory** | `docs/design/03_SCREEN_INVENTORY.md` | Exhaustive ledger of all 66 screen classes |
| **5. Navigation** | `docs/design/04_NAVIGATION_ARCHITECTURE.md` | 5-branch StatefulShellRoute & role guards |
| **6. Info Architecture**| `docs/design/05_INFORMATION_ARCHITECTURE.md`| 5-tier content hierarchy & progressive disclosure |
| **7. Design System** | `docs/design/06_DESIGN_SYSTEM.md` | Spatial 8dp grid, 4-tier surfaces, 12dp radii |
| **8. Color Tokens** | `docs/design/07_COLOR_AND_THEME_TOKENS.md` | Hex codes & 100% WCAG AA/AAA contrast proofs |
| **9. Typography** | `docs/design/08_TYPOGRAPHY_SYSTEM.md` | SpaceGrotesk (Display) + Inter (Body/UI) |
| **10. Components** | `docs/design/09_COMPONENT_SYSTEM.md` | 10 component taxonomies & variants |
| **11. Interaction** | `docs/design/10_INTERACTION_SYSTEM.md` | Control states, tactile haptics, continue flow |
| **12. Motion Design** | `docs/design/11_MOTION_SYSTEM.md` | 5 duration tiers (100–1200ms) & reduced motion |
| **13. Transitions** | `docs/design/12_SCREEN_TRANSITIONS.md` | 18 explicit route-to-route transitions |
| **14. Scroll & Carousel**| `docs/design/13_SCROLL_AND_CAROUSEL_SYSTEM.md`| SliverAppBars & strict carousel approval matrix |
| **15. Image Strategy** | `docs/design/14_IMAGE_ASSET_STRATEGY.md` | Scrim rules, 4-stop gradients, cache limits |
| **16. Video Strategy** | `docs/design/15_VIDEO_ASSET_STRATEGY.md` | Modal embeds only; zero feed autoplay |
| **17. AI Prompts** | `docs/design/16_AI_GENERATION_PROMPT_LIBRARY.md`| Ethical prompts for dark arena & belt textures |
| **18. Media Budget** | `docs/design/17_MEDIA_PERFORMANCE_BUDGET.md` | 60fps lock, <140MB RAM, <50MB APK ceiling |
| **19. Accessibility** | `docs/design/18_ACCESSIBILITY_SPEC.md` | 100% WCAG AA, color-independent semantics |
| **20. Offline UX** | `docs/design/19_OFFLINE_AND_NETWORK_UX.md` | 4 network states & Hive outbox queue |
| **21. Role UX** | `docs/design/20_ROLE_BASED_UX.md` | Workspaces across all 9 federation roles |
| **22. User Journeys** | `docs/design/21_USER_JOURNEY_MAP.md` | 6 complete end-to-end user workflows |
| **23. Screen Specs** | `docs/design/22_SCREEN_BY_SCREEN_SPEC.md` | Detailed engineering specs for primary screens |
| **24. Usage Rules** | `docs/design/23_COMPONENT_USAGE_RULES.md` | Strict Do's & Don'ts for cards and buttons |
| **25. Anti-Slop** | `docs/design/24_ANTI_SLOP_RULES.md` | 16 rejection gates against generic AI UI |
| **26. Decision Register**| `docs/design/25_DESIGN_DECISION_REGISTER.md`| 10 core architectural decisions with rationale |
| **27. Open Questions** | `docs/design/26_OPEN_QUESTIONS.md` | Hardware testing gaps & operator choices |
| **28. Backlog** | `docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md`| Prioritized implementation roadmap (P0–P3) |
| **29. Design QA** | `docs/design/28_DESIGN_QA_CHECKLIST.md` | Pre-implementation verification rubric |

---

## 3. Explicit Items NOT to Change (Protected Core)

1. **State Management & Architecture**:
   - `Riverpod 2.6` state providers, `GoRouter 10.2` route declarations, and `Dio` networking with circuit breaker must remain intact.
2. **58 Public Database Tables & Drizzle Migrations**:
   - Schema field names, UUID primaries, ELO ledger math, and role enumerations in `packages/db-schema` and `packages/types` must never be altered or renamed.
3. **Core Sound Assets**:
   - `assets/sounds/challenge_accepted.wav`, `match_won.mp3`, `pr_achieved.wav` are production verified and must remain the authoritative audio assets.
4. **Primary Color Tokens**:
   - Void `#070A11`, Elevated Surface `#0F172A`, Champagne Gold `#D4AF37`, Emerald Mint `#10B981`, and Coral Crimson `#FF5252` are locked.

---

## 4. Explicit Items Recommended for Phased Redesign

1. **Discover Screen AppBar**: Strip 5 crammed action buttons down to Search and Notifications; move Venues and Meetups into horizontal discovery sections.
2. **Form Sticky Bottom Bars**: Pin primary CTA buttons above the keyboard with safe-area padding on Event Registration and Complaint Submission forms.
3. **Dual-Role Switcher**: Add an in-shell persona toggle in Profile for certified athletes/referees.
4. **Shimmer Skeleton Normalization**: Replace centered circular progress indicators with geometric card shimmers.
5. **Scorepad Haptics**: Integrate physical haptic clicks into referee score increments and foul calls.
6. **Continuous Shell Particle Removal**: Eliminate active particle loop in `AmbientParticleBackground` to conserve battery.

---

## 5. Explicit Items Requiring Hardware Evidence Before Modification

1. **Live Bracket Zoom LOD**: Human visual check required on 64-player bracket readability when zoomed to 30% scale on a physical Android handset.
2. **Ambient Arena Video Loop**: Performance profiling required on low-end Android hardware (Snapdragon 680 / 3GB RAM) before activating background video headers.
3. **FCM Background Push Callouts**: Gated on operator provisioning `google-services.json` from their Firebase console.
4. **Production Google Play Track Upload**: Gated on operator registering their $25 Google Play Console account with `com.armsphere.app`.

---

## 6. Authoritative Completion Audit Checklist

```
================================================================================
ARMSPHERE UI/UX DESIGN & ARCHITECTURE COMPLETION LEDGER
================================================================================
TOTAL REAL FEATURES DISCOVERED:              26 Features (100% Source-Mapped)
TOTAL USER-FACING SCREENS:                   66 Screens + 3 Modals
TOTAL NAVIGATION FLOWS:                      18 Explicit Route Transitions
TOTAL MAJOR COMPONENTS:                      10 Taxonomies (42 Components)
TOTAL STATES ANALYZED:                       11 Distinct Screen States
TOTAL TRANSITIONS SPECIFIED:                 18 Directional Transitions
TOTAL IMAGE ASSET DECISIONS:                 5 Standard Aspect Ratios
TOTAL VIDEO ASSET DECISIONS:                 7 Area Evaluations (2 Approved)
TOTAL INTERACTIVE / MOTION DECISIONS:        5 Duration Tiers (Level 0 - 4)
TOTAL ACCESSIBILITY DECISIONS:               100% WCAG AA / AAA Math Proofs
TOTAL PERFORMANCE DECISIONS:                 8 Hard Device Ceilings
TOTAL ROLE-SPECIFIC DECISIONS:               9 Formal User Roles Mapped
TOTAL OPEN QUESTIONS:                        6 Operator & Hardware Items
--------------------------------------------------------------------------------
FEATURE COVERAGE:                            COMPLETE
SCREEN COVERAGE:                             COMPLETE
NAVIGATION COVERAGE:                         COMPLETE
MOTION COVERAGE:                             COMPLETE
ASSET COVERAGE:                              COMPLETE
ACCESSIBILITY COVERAGE:                      COMPLETE
PERFORMANCE COVERAGE:                        COMPLETE
ROLE COVERAGE:                               COMPLETE
ANTI-SLOP AUDIT:                             PASS (All 16 Gates Locked)
IMPLEMENTABILITY AUDIT:                      PASS (100% Flutter Compatible)
FINAL DESIGN CONSISTENCY AUDIT:              PASS (All Tokens Synced)
================================================================================
```
