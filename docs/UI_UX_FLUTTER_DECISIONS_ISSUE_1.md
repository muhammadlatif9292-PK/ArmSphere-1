# ArmSphere Flutter: Owner Decisions, Contrast Check, Currency Investigation (Issue #1)

Status: DRAFT. Documentation only. No application code was changed by this file.
Base: `design/titanium-luxe`. Evidence is from reading source through the GitLab API. Nothing was run, built, rendered or visually inspected.

## 1. Implementation order (supersedes section 6 of the audit)

1. Font-family consistency (slice 1, draft MR !4).
2. Shared loading, empty and error states on the five tabs.
3. Shell and navigation consistency (active state across Arena, Discover, Events, Community, Passport).
4. One high-impact user journey, chosen after reading its screens and dependencies.

Admin web is paused. MR !3 stays an unmerged draft.

## 2. Font alias (slice 1)

- Verified on `design/titanium-luxe`: `apps/mobile/assets/fonts/` contains `SpaceGrotesk.ttf`, `SpaceGrotesk-Medium.ttf`, `SpaceGrotesk-SemiBold.ttf`, `SpaceGrotesk-Bold.ttf`.
- Existing `SpaceGrotesk` declaration maps them to weights 400, 500, 600, 700. The alias repeats exactly that mapping under the family name `Space Grotesk`.
- File names and the declared weights agree by name only. I could not open the binaries, so I did not verify the weight metadata inside the font files.
- Not verified: that Flutter falls back to the default font for the spaced name today (inferred from how Flutter matches family names), and `flutter pub get` or `flutter analyze` acceptance of the file (no toolchain here).
- Weights 800 and 900 are requested in code, but only 400 to 700 are declared. This slice does not change that.

## 3. Contrast (WCAG 2.x relative luminance, calculated by hand, not by a tool)

Colours are the Titanium Luxe values in `apps/mobile/lib/core/theme/app_theme.dart` on `design/titanium-luxe`. Formula: ratio = (L1 + 0.05) / (L2 + 0.05), with L from sRGB linearisation. I did the arithmetic by hand with no calculator tool, so re-verify with a tool or in review before relying on a borderline value.

Relative luminance used: crimson `#E23B3B` 0.1962; card `#151B24` 0.0107; background `#0B0F19` 0.0048; void `#070A11` 0.0030; white 1.0; darker crimson candidate `#D43232` 0.1652.

| Pair | Ratio | Needs | Result |
| --- | --- | --- | --- |
| White text on solid crimson `#E23B3B` | 4.27:1 | 4.5:1 normal text | FAIL |
| `#070A11` text on `#E23B3B` | 4.64:1 | 4.5:1 | pass (unconventional on a red button) |
| Crimson `#E23B3B` text on card `#151B24` | 4.06:1 | 4.5:1 normal text | FAIL for normal text; passes 3:1 for large text and UI components |
| Crimson `#E23B3B` on background `#0B0F19` | 4.49:1 | 4.5:1 normal text | marginal fail (0.01 short); passes 3:1 for UI components |
| White text on `#D43232` (candidate fill) | 4.88:1 | 4.5:1 | pass |
| `textMuted` `#7E8996` on card `#151B24` | 4.87:1 | 4.5:1 | pass |

Conclusions and plan:
- A solid crimson button with white label fails as written. Use a local, darker fill such as `#D43232` (4.88:1) for filled primary buttons. Do not change the global crimson token. Confirm the pressed and hover states keep at least 4.5:1 (a darker fill raises the ratio against white).
- Crimson as small text on dark surfaces fails. Use it for icons, borders and large or bold headings (3:1 applies to UI components and large text), or use a lighter tint for small text.
- Outlined crimson buttons: a crimson border passes the 3:1 UI-component test on both surfaces. The label should be white or titanium-light, not crimson at small sizes.
- Not yet checked: focus rings (cyan `#38BDF8` against surfaces), disabled states (exempt, but should stay distinguishable), and text over images and scrims.

## 4. LEFT ARM pill

- Decision: a passive `LEFT ARM` label uses a restrained titanium/silver chip by default. An interactive arm selector keeps the established active treatment only for the selected option. No global pill or badge restyle.
- Source: `ArmIndicatorPill` in `apps/mobile/lib/core/widgets/status_chip.dart` is a `StatelessWidget` with no `onTap`, so it is purely descriptive. Currently RIGHT ARM is cyan and LEFT ARM is gold.
- Call sites (code search, main index, unverified on the branch): `features/home/screens/discover_screen.dart` (around line 1345) and `features/referee/widgets/live_scorepad_controller.dart` (around line 295). Both render it as a label.
- Open question: if LEFT becomes silver while RIGHT stays cyan, the two arms are no longer a matched pair. Options: (a) both neutral titanium and rely on the label text; (b) LEFT silver only, RIGHT unchanged. Awaiting owner choice. Not implemented yet. It belongs to the shell and chrome slice.

## 5. Event currency investigation (not implemented)

Evidence is from code search, which indexes `main` only. The backend files were NOT read on `design/titanium-luxe`, so this must be re-checked there. `formatEventFee` itself was read on the branch.

### What the code does
- Event model: `packages/db-schema/index.ts` event table has `registrationFeeCents` (integer, nullable). The only `currency` column the search found in the schema is on the payments table (`varchar(10)`, default `'CAD'`). No currency field on events was found.
- Charging: `apps/api/src/services/tournament.ts` creates a Stripe PaymentIntent with `currency: "cad"` and stores the payment row with `currency: "CAD"`. Ticket purchases (`apps/api/src/controllers/ticket.ts`) also hardcode `"cad"`. The API tests assert `"CAD"`.
- Event create and edit schemas (`apps/api/src/controllers/tournament.ts`) accept `registrationFeeCents` and `paymentMethod` (`STRIPE` or `MANUAL_QR`). They accept no currency.
- Mobile display: `formatEventFee(registrationFeeCents)` in `tournament_screens.dart` (read on the branch) returns `Free entry` for 0 or null, otherwise `CAD $` plus the amount. It is used by the Events list, event detail, registration screen and dialog, and the operations screen.
- Inconsistent formats elsewhere (main index): `discover_screen.dart` formats a fee as a bare `$` plus two decimals and `Free Entry`; `tournament_statistics_widget.dart` formats a prize pool through `_formatCurrency` and reads `prizePoolPkr`.
- Hardcoded fallback values (main index, needs branch check): `tournament_details_hero_widget.dart` falls back to `'PKR 500,000 PRIZE'`, a registered count of `84`, and sample weight categories when the data lacks them. These are invented values and conflict with the no-mock-data rule.
- Data context: the seed and test data mix Pakistani locations (Islamabad, Lahore, Federal Capital) and Canadian ones (Ontario, Toronto, Ottawa). `ARMSPHERE_GOAL_COMPLETION_LEDGER.md` lists "Validate currency PKR/CAD logic" as an open item for registration.
- Tests: `phase1c_batch3_media_integration_test.dart` asserts on `formatEventFee(...)` output itself, so it follows the function. Other mobile tests found use `registrationFeeCents` as input only.

### Conclusion
The backend contract has no per-event currency. Every card payment is created in CAD, so today the `CAD $` label is consistent with what the backend charges, although the Pakistani seed data suggests the product intent may differ. The app does not read a currency from the API, so the correct behaviour (show the event's own currency) is not possible without a contract change.

### Safe, backward-compatible proposal (needs owner approval, separate from UI polish)
1. Backend (separate change, schema migration): add a nullable `currency` column to events, default `'CAD'` so existing events and behaviour are unchanged. Return it in event responses. Have the payment flow use the event's currency. This touches payment logic and needs its own review and tests.
2. Mobile (after 1): `formatEventFee(cents, {String? currency})` uses `event['currency']` when present and falls back to the current `CAD` output when absent, so old responses render exactly as now. Pass the event currency from the five call sites.
3. Until then: do not hardcode `PKR`, do not change `CAD $`, and do not change payment code. Optional, display-only and safe: make the Discover card use the same helper as the other screens so one event never shows two formats. That is a UI change and can wait for the shared-component slice.
4. Separately review the hero widget's invented fallbacks (`PKR 500,000 PRIZE`, `84`).

### Owner questions
1. Which currency does the federation actually charge in production? The backend currently charges CAD.
2. May the backend change in step 1 be scheduled as its own task?
3. Should the hero widget's placeholder defaults be removed in the Events journey slice?

## 6. Preserve in every slice
Route behaviour, authentication, RBAC, match and ELO logic, event registration, payment flows, API contracts. No broad theme rewrite, no new dependencies.

## 7. Checks completed
None. No `flutter pub get`, `flutter analyze`, `flutter test`, build, device or screenshot run. All of this is from reading source.
