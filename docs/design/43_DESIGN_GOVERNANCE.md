# ArmSphere Design Governance & Maintenance Protocol
**System Integrity Rules, Token Change Gates, PR Review Rubric & Anti-Drift Architecture**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md` & `UI_UX_DESIGN_STATE.md`
**Scope**: Long-Term Governance Protocol to Prevent Design Drift, Inconsistent Tokens, and Generic UI Degradation Across Future AI Sessions and Engineering Teams.

---

## 1. Executive Mandate & Problem Statement

Large codebases modified by multiple engineers and autonomous AI agents suffer from inevitable **entropy and design drift**:
- Engineers invent new hex codes rather than finding existing tokens.
- AI models introduce generic pill buttons, unprompted glassmorphism, and cartoonish animations.
- New screens are added without proper empty, error, or loading states.
- Touch targets shrink below physical sports usability standards.

This document establishes the **immutable laws, change protocols, and pull request verification gates** that protect ArmSphere from degradation.

---

## 2. Re-Assertion of Design Authority Hierarchy

Per `docs/design/00_DESIGN_AUTHORITY.md`, all contributors and AI agents must abide by this strict decision hierarchy:

```
[TIER 1: ARMSSPHERE PRODUCT REQUIREMENTS] (Highest Authority)
                   │
                   ▼
[TIER 2: EXISTING CODEBASE TRUTH (66 Screens, 58 DB Tables)]
                   │
                   ▼
[TIER 3: APPROVED DESIGN TOKENS & DESIGN STATE (UI_UX_DESIGN_STATE.md)]
                   │
                   ▼
[TIER 4: ARMSSPHERE DESIGN DOCUMENTATION (docs/design/ 00–43)]
                   │
                   ▼
[TIER 5: EXTERNAL SKILLS, BENCHMARKS & GENERIC GUIDELINES] (Lowest Authority)
```

**Rule**: No external library, UI framework, or AI prompt may override a Tier 1–4 specification.

---

## 3. Design Token Modification Protocol

Design tokens (`ArmSphereTheme`) are mathematically locked. Any modification requires a formal **Token Change Protocol**:

### Token Addition Criteria:
A new token may be added **ONLY** if:
1. It solves a functional semantic need not met by the existing 12 foundational tokens.
2. It has been verified for WCAG AA (>= 4.5:1) or AAA (>= 7.0:1) contrast against both `#070A11` and `#0B0F19`.
3. It has been reviewed across all 8 visual experience modes.

### Token Modification / Deprecation Protocol:
1. **Never mutate in-place**: Changing an existing color value silently alters dozens of screens.
2. **Deprecation Phase**: Mark the old token with `@Deprecated('Use ArmSphereTheme.newSemanticToken instead')`.
3. **Migration PR**: Run an automated refactor across all occurrences in `apps/mobile/lib/`.
4. **Update `UI_UX_DESIGN_STATE.md`**: Persist the token change into the persistent state file before merging the code.

---

## 4. Component Contribution Checklist

Before any new custom widget is added to `apps/mobile/lib/core/presentation/widgets/` or a feature directory, it must pass this 8-point checklist:

- [ ] **1. Single Responsibility**: Does this widget duplicate an existing card, chip, button, or dialog? If yes, extend the existing widget.
- [ ] **2. Token Compliance**: Zero raw `Color(0x...)` or `Colors.*` values. 100% of colors, borders, and radii reference `ArmSphereTheme`.
- [ ] **3. Radius Discipline**: Uses `radiusSmall` (8dp), `radiusMedium` (12dp), or `radiusLarge` (16dp). Zero `BorderRadius.circular(999)` pill shapes on primary action buttons.
- [ ] **4. Touch Target Compliance**: Hit target is >= 48×48dp (>= 64×64dp if table-side referee scorepad).
- [ ] **5. Accessibility**: Contains `Semantics` widget or proper label; text scales cleanly under 1.3x system font size without yellow overflow bars.
- [ ] **6. Complete States**: Implements Idle, Pressed, Focused, Loading, Empty, and Error states where applicable.
- [ ] **7. Tactile Haptics**: Wires `HapticFeedback.lightImpact()`, `mediumImpact()`, `heavyImpact()`, or `selectionClick()` appropriate to action severity.
- [ ] **8. Reduced-Motion Awareness**: Honors `MediaQuery.of(context).disableAnimations` by substituting instant transitions.

---

## 5. UI Pull Request Review Rubric (The Gatekeeper Checklist)

Every pull request modifying files in `apps/mobile/` must be audited against this rubric prior to merge approval:

```markdown
### ArmSphere Visual & Ergonomic PR Gate
- [ ] **Grounded in Codebase**: PR modifies existing routes/providers without inventing unapproved screens.
- [ ] **Anti-Slop Audit**: Zero generic cheerleading copy, zero unprompted particle loops, zero nested BackdropFilters.
- [ ] **Contrast Verification**: All text passes WCAG AA (>= 4.5:1) against card/canvas substrates.
- [ ] **Keyboard Ergonomics**: Form screens implement automatic scroll-to-field and sticky action bar above keyboard.
- [ ] **Offline Resilience**: State updates write to local Hive cache/outbox before or parallel to network requests.
- [ ] **Audio/Haptic Etiquette**: No sound effects for standard UI clicks; approved sounds respect device ringer mode.
- [ ] **Performance Profile**: Verified 60fps frame rate lock (<16.6ms per frame) during scroll in DevTools.
```

---

## 6. Automated CI / Pre-Commit Linting Architecture

To automate enforcement and eliminate human error, the following checks should be incorporated into the CI/CD pipeline:

### 1. Custom Dart Analyzer Rules (`analysis_options.yaml`):
```yaml
analyzer:
  errors:
    avoid_unnecessary_containers: warning
    sized_box_for_whitespace: warning
    use_colored_box: warning
    avoid_print: error
```

### 2. Forbidden Pattern Grep Script (`scripts/verify_design_compliance.sh`):
```bash
#!/usr/bin/env bash
set -e

echo "Verifying ArmSphere Design System Compliance..."

# Check 1: No raw Colors.white or Colors.black
if grep -rn "Colors\.white" apps/mobile/lib/ --exclude-dir=core/theme; then
  echo "ERROR: Hardcoded Colors.white detected. Use ArmSphereTheme.textPrimary or canvas tokens."
  exit 1
fi

# Check 2: No 999dp pill buttons
if grep -rn "BorderRadius\.circular(999" apps/mobile/lib/; then
  echo "ERROR: Banned 999dp pill button radius detected. Use radiusMedium (12dp) or radiusSmall (8dp)."
  exit 1
fi

# Check 3: No nested BackdropFilters
COUNT=$(grep -rn "BackdropFilter" apps/mobile/lib/ | wc -l)
if [ "$COUNT" -gt 6 ]; then
  echo "WARNING: Excessive BackdropFilter count ($COUNT). Ensure glassmorphism is restricted to AppBars and modals."
fi

echo "Design Compliance Verified: 100% Passed."
```

---

## 7. Persistent State Update Protocol (`UI_UX_DESIGN_STATE.md`)

`UI_UX_DESIGN_STATE.md` at the repository root is the **single source of truth for long-term AI memory**. 

Whenever an engineering slice is completed:
1. Update Section 5 ("Screen Inventory & Implementation Status") to mark the completed slice.
2. Record any newly created reusable component in Section 2.
3. Commit both the code and the updated `UI_UX_DESIGN_STATE.md` in the same commit.
4. Future AI sessions will automatically read this state file first and never propose duplicate planning or regress approved architectural decisions.

---

## 8. Verification & Non-Contradiction Proof
This governance protocol enshrines the authority of `docs/design/00_DESIGN_AUTHORITY.md`, establishes strict programmatic gates against design slop and token drift, guarantees long-term codebase health, and ensures seamless collaboration across future human developers and AI coding agents.
