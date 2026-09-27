# ArmSphere Implementation Governor
**Document Version**: 1.0.0 (Authoritative Implementation Protocol)
**Date**: September 27, 2026
**Status**: PERMANENTLY LOCKED & ENFORCED
**Authority**: ArmSphere Founder Directive, `docs/design/71_ARMSPHERE_DREAM_GOAL_AND_ANTI_DRIFT_CONSTITUTION.md`, `UI_UX_DESIGN_STATE.md`
**Scope**: Mandatory pre-coding, coding, and post-coding verification protocol governing every code change, visual refinement, and canary screen implementation.

---

## 1. The Pre-Coding Governor Protocol

Before writing or modifying ANY code in the repository:
1. **Read `UI_UX_DESIGN_STATE.md`**: Verify canonical tokens, current implementation phase, and approved architecture.
2. **Read `71_ARMSPHERE_DREAM_GOAL_AND_ANTI_DRIFT_CONSTITUTION.md`**: Enforce the 12-question evaluation rubric.
3. **Read Relevant Canonical Design Documents**: Check the specific doc in `docs/design/` governing the target screen or component.
4. **Inspect the Actual Current Implementation**: Check existing AST, Riverpod providers, database hooks, and routing contracts.
5. **Identify the Smallest Correct Implementation Boundary**: Restrict edits to the exact slice under test; zero blast radius.

---

## 2. The Universal "NEVER" Invariants

When implementing or refactoring code, you must **NEVER**:
- ❌ Redesign unrelated screens.
- ❌ Invent new product features or hypothetical flows.
- ❌ Create one-off visual systems or ad-hoc button styles.
- ❌ Introduce unnecessary external packages or dependencies.
- ❌ Override canonical tokens (`voidBackground`, `cardSurface`, `goldPrimary`, etc.).
- ❌ Use animation without documented purpose (no elastic bounces, no persistent particle loops).
- ❌ Add media without documented purpose (no un-encapsulated video, no uncompressed raster images).
- ❌ Change business logic, database queries, or offline synchronization queues.
- ❌ Change API/security behavior or bypass authentication rules.
- ❌ Silently alter navigation routes or GoRouter contracts.

---

## 3. Mandatory Pre-Coding Declaration

Before modifying code, the developer or AI agent MUST explicitly state in prose:
1. **Target Files to Change**: The exact, minimal list of file paths.
2. **Reusable Primitives to Use**: Canonical widgets (`ElevatedActionCard`, `TactilePressWrapper`, `StatusChip`, `AppTheme` tokens).
3. **Existing Behavior to Preserve**: Core state providers, async loading/error states, routing targets, role checks.
4. **Acceptance Criteria**: Concrete, testable visual and functional milestones.
5. **Identified Risks & Mitigations**: Potential layout shifts, frame drops, or state regressions and how they are prevented.
6. **The 12-Question Dream Goal Filter Verification**: Proof that the proposed work passes all 12 criteria and is NOT merely "looking cool".

---

## 4. Mandatory Post-Coding Verification

After modifying code, the developer or AI agent MUST:
1. **Inspect Diff**: Review exact git diff against base branch for unintended edits.
2. **Run Static Analysis**: Execute `flutter analyze` or relevant lint checks; zero new warnings permitted.
3. **Run Relevant Unit / Widget Tests**: Verify that existing test suites pass.
4. **Verify Behavior Preservation**: Ensure all existing navigation, buttons, and data loads function identically.
5. **Report Exact Proof**: Provide a structured verification report detailing what was executed, tested, and confirmed.

---

## 5. Ambiguity Resolution & Dream Goal Veto

*   **Zero Guesswork**: If a visual or functional requirement is ambiguous, **STOP**. Resolve it from the repository design documents (`docs/design/00` through `71`) or ask the user. Never guess.
*   **The Dream Goal Gate**: If any proposed visual effect, animation, or container design fails the 12-question Dream Goal Gate, **REJECT IT IMMEDIATELY**.
*   **Final Objective**: The objective is not maximum visual complexity. The objective is the **best possible ArmSphere experience for its actual purpose**.
