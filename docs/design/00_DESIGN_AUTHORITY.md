# ArmSphere Design Authority & Tool Selection Charter
**Canonical Design Governance Document**
**Document Version**: 1.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Scope**: All UI/UX planning, design synthesis, visual critique, component development, and implementation across ArmSphere.

---

## 1. Executive Purpose & Primacy

This document serves as the **canonical design governance authority** for the ArmSphere ecosystem. 

All future design planning, critique, synthesis, refactoring, and code implementation sessions **must read and adhere to this document** before proposing or executing design decisions. Design knowledge and governance rules are permanently persisted here and in `UI_UX_DESIGN_STATE.md`; they must never rely on ephemeral conversation memory.

The core objective is **ONE coherent, high-performance, athletic-grade ArmSphere design system** optimized for competitive armwrestling on mobile Android (Flutter) and companion administrative web surfaces.

---

## 2. Tool & Authority Hierarchy

When evaluating tools, design skills, frameworks, external libraries, or conflicting suggestions, the following strict hierarchy of authority must be applied:

| Tier | Authority Level | Mandate & Constraints |
| :--- | :--- | :--- |
| **1** | **ArmSphere Product Requirements** | **Highest Authority.** Never remove, invent, relocate, rename, or alter a product feature merely because a design system or external skill prefers an alternative pattern. |
| **2** | **Existing Source & Actual Feature Inventory** | Inspect the actual repository before redesigning anything. Enumerate every user-facing feature, route, screen, action, state, role-dependent surface, form, modal, notification, error state, loading state, empty state, offline state, and destructive action. |
| **3** | **UIZZE System** | Use `ui-design` for overall product UI workflow. Use `anti-ui-slop` as the hard visual-quality and generic-UI rejection gate. Use `ui-radar` only when a concrete unresolved question benefits from real-world interface evidence. **Never copy another product blindly.** Extract principles, patterns, and interaction solutions, then adapt them directly to ArmSphere. |
| **4** | **Taste System** | Use `redesign-existing-projects` for refactoring existing ArmSphere screens. Use `high-end-visual-design` for aesthetic quality. Use `imagegen-frontend-mobile` only when visual assets are genuinely needed. |
| **5** | **Anthropic Frontend Design System** | Use as a secondary aesthetic and interaction critique layer. It must **not** override ArmSphere's primary product requirements or established design tokens. |
| **6** | **Context7** | Retrieve current documentation whenever implementation depends on a library, package, Flutter API, React API, or animation API. Never invent or assume an API when authoritative documentation is accessible. |
| **7** | **Design Canvas** | Select exactly **ONE** design-system canvas (Figma + Figwright OR Penpot MCP). Do not simultaneously use both unless there is an explicitly documented technical reason. |
| **8** | **Web Animation** | For React / Vite / admin-web surfaces only: use official GSAP skills (`gsap-core`, `gsap-timeline`, `gsap-scrolltrigger`, `gsap-react`). Use Lenis only when smooth scrolling materially improves UX. Use cinematic-scroll storytelling only for narrative marketing sections. |
| **9** | **Flutter Mobile Animation** | **NEVER import GSAP, Lenis, or web-only animation architectures into Flutter.** Research Flutter-native animation approaches (CurvedAnimation, AnimatedBuilder, RProvider, Hero, TweenAnimationBuilder) and select only what is performant and justified. |
| **10** | **Shadcn / DesignRevision** | Use only for React / admin-web surfaces where `shadcn/ui` is actually present or intentionally selected. It must never dictate Flutter UI. |
| **11** | **Baserow** | Do not install or use unless a concrete project requirement is discovered and verified. |
| **12** | **Unverified Skills & Packages** | Before installing any additional skill or package: verify repository identity, inspect README / SKILL.md, verify license, verify Antigravity compatibility, check for duplication, and determine whether it applies to Flutter, React, or both. Reject redundant or weakly supported skills. |
| **13** | **Conflict Resolution Rule** | When two directives disagree: **Product requirements > Actual ArmSphere source > Established design tokens > Primary design workflow > Evidence/reference skill > Secondary aesthetic skill > Generic recommendations.** |

---

## 3. Core Design & Architectural Rules

### Rule 14: No Skill-Stacking for its Own Sake
Do not add a skill, dependency, or MCP server simply because it is impressive. Every installed skill and dependency must have a defined responsibility, documented trigger condition, and measurable benefit.

### Rule 15: Final Canonical Design System
Before implementation begins, the design architecture must resolve:
- Color palette & contrast ratios (WCAG 2.1 AA/AAA compliance)
- Typography scale, weights, and letter-spacing (SpaceGrotesk + Inter)
- Spacing scale and touch-target bounding boxes (minimum 48×48dp)
- Border radii, elevation levels, and surface transparency rules
- Iconography, iconography styling, and visual weight
- Imagery, photography treatments, and gradient overlays
- Restrained glow effects (no excessive neon blur)
- Motion language, easing curves, and duration tiers
- Transitions between screens and modal presentation
- Component state taxonomy (idle, pressed, focused, loading, skeleton, empty, error, success, disabled, destructive)
- Accessibility, screen readers, semantic labels, and reduced-motion modes
- Offline, degraded connectivity, and background sync behaviors
- Role-based UX variations across all 9 federation roles
- Responsive behavior across varying Android handset screen ratios

### Rule 16: Motion Rule
Motion must communicate:
1. **Hierarchy** (what is primary vs secondary)
2. **Continuity** (where the user came from and where they are going)
3. **Feedback** (acknowledgment that an action was registered)
4. **Orientation** (spatial awareness within tabs and drill-downs)
5. **Progress** (clear advancement through multi-step flows)
6. **Emotional Emphasis** (celebrating verified match wins, title changes, PRs)

*Never animate an element merely because animation is technically possible.*

### Rule 17: Media & Asset Rule
Every proposed image, generated graphic, video loop, Lottie/Rive asset, or particle system must have a documented:
- Explicit purpose and UI placement
- Maximum duration and loop point
- Trigger condition and cancellation rule
- Performance and memory budget
- Offline fallback and bandwidth degradation strategy
- Reduced-motion and accessibility alternative

### Rule 18: Performance Rule
**Premium does not mean heavy.**
Reject any visual effect that materially damages:
- Cold app startup time (must reach interactive state in <1.5s)
- Frame rate stability (strict 60fps baseline on mid-tier Android; 120fps on high-refresh OLED)
- Device memory consumption (leak-free, image caching bounded)
- Battery draw during prolonged tournament scorepad sessions
- Touch latency (tap feedback must register in <100ms)
- Low-end Android hardware performance (graceful degradation)

### Rule 19: Evidence Rule
Every major visual decision must be classified into one of four evidence tiers:
1. `SOURCE-GROUNDED`: Directly backed by verified repository source, schema, or API contract.
2. `REFERENCE-GROUNDED`: Derived from the approved North Star visual direction and tailored to mobile.
3. `PRODUCT-DERIVED`: Required by armwrestling federation operational realities.
4. `EXPERIMENTAL`: Novel design concept requiring human review and on-device validation.

*Never present experimental ideas as established best practices.*

### Rule 20: Pre-Coding Integrity Rule
Do not begin UI code modification until the complete screen inventory, feature matrix, navigation architecture, component taxonomy, state map, motion language, and design token system have been fully reviewed and cross-checked twice.

### Rule 21: Post-Planning Contradiction Audit
Prior to handoff, execute an independent contradiction audit addressing:
- Did any feature disappear or become harder to access?
- Did navigation depth increase unnecessarily?
- Did information density become cramped or chaotic?
- Did animations become distracting or delay functional tasks?
- Did any screen receive desktop dashboard UI squeezed down to mobile?
- Did any media asset become purely decorative visual noise?
- Did any proposed visual effect exceed realistic Android performance limits?

### Rule 22: Stop Condition
Planning is complete **only** when:
- Every existing user-facing feature has an intentional home.
- Every screen has a clear visual and content hierarchy.
- Every navigation transition is purposeful and continuous.
- Every interactive element provides immediate tactile feedback.
- All empty, loading, error, success, and offline states are designed.
- All 9 user roles are accounted for with proper permissions.
- All accessibility and performance criteria are satisfied.
- The entire system can be implemented consistently without guesswork.
