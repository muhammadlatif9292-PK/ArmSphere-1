# ArmSphere UI/UX Refinement: Inspection Report and Plan (Issue #1)

Status: DRAFT. Documentation only. No application code was modified.
Base inspected: branch `design/titanium-luxe` at `47d57bc7` (2026-10-13), read through the GitLab API.

## 0. Method and limits (read first)

- Everything below was read from the repository through GitLab API tools (file reads, tree listings, code search).
- NOT done: no code was run, no tests were run, no Flutter or Node toolchain was used, no screenshots were seen or compared.
- NOT verifiable through the API: uncommitted working-tree changes on any developer machine.
- Code search indexes `main` only. Any finding sourced from search is marked "(main only)" and must be re-checked on the working branch before use.
- Whether Claude Sonnet 5.5 was actually used for this session cannot be confirmed from here.

## 1. Repository identity

| Item | Verified value |
| --- | --- |
| Project | `me-and-ai-group/ArmSphere-1` (id 87578846), private |
| Default branch | `main` (protected), tip `255b1080` (2026-10-03) "default fresh logins to athlete role..." |
| Newest branch | `design/titanium-luxe`, tip `47d57bc7` (2026-10-13) "qualify release candidate, reconcile mobile repository test contracts, and align admin web types" |
| Other branches | `verification/flutter-rc-a46b93c` (`a8a91591`), `copilot/fix/ts-null-province` (`2cf3603c`, open MR !1 into `main`) |
| Open MRs | !1 only |

Key finding: `main` is far behind `design/titanium-luxe` (P0 to P3 API, lifecycle and UX commits from 2026-10-12 and 2026-10-13 exist only on the design branch). The design branch is treated here as the current release-candidate line (inferred from its latest commit message; please confirm). It is the authoritative base for this work. `main` still carries the older token set (see 2).

Applications (monorepo): `apps/mobile` (Flutter, Dart), `apps/admin-web` (React 19, TypeScript, Vite, Tailwind 4, react-router 7, TanStack Query), `apps/api` (backend, out of scope), plus `packages/{core,cryptography,db-schema,types}`, `supabase`, `infra`, `netlify`.

Repo hygiene note: the root holds many scratch files (`_*.txt`, `_p8_logs`, `_probe`) and `apps/mobile/lib/core/theme/` holds `app_theme.dart.new` and `app_theme_final.dart`. These are out of scope but are a confusion risk for token lookups. `app_theme_final.dart` carries older values (e.g. `radiusCircular` listed with legacy tokens).

## 2. Actual design system present

### Mobile (Flutter)
- Single token class: `apps/mobile/lib/core/theme/app_theme.dart` (`AppTheme`, aliased `ArmSphereTheme`), re-exported by `theme.dart`.
- On `design/titanium-luxe` this is a "Titanium Glass" token set: canvas `#070A11`, background `#0B0F19`, titanium card `#151B24`, elevated `#1E2836`, hairline borders as translucent silver (`0x1FD6DCE3`), crimson `#E23B3B`, champagne gold `#D4AF37`, cyan `#38BDF8`, emerald `#10B981`, text `#F4F7FA / #AAB3BE / #7E8996`, fonts SpaceGrotesk (display) and Inter (body), spacing scale, radii 8/12/16/24, motion tiers, gradients and shadow helpers, Material 3 `darkTheme`.
- On `main` the same file uses older values (card `#121826`, border `#334155`, elevated `#1E293B`).
- Shared widgets in `apps/mobile/lib/core/widgets/`: `elevated_action_card.dart`, `glass_card.dart`, `status_chip.dart` (also `ArmIndicatorPill`), `app_empty_state.dart`, `app_error_view.dart`, `skeleton_placeholder.dart`, `sticky_bottom_action_bar.dart`, `sticky_form_scaffold.dart`, `step_header.dart`, `tactile_press_wrapper.dart`, `premium_floating_nav_bar.dart`, `main_shell_screen.dart`, `signature_ceremonies.dart`, `count_up_text.dart`, `pulse_indicator.dart`, `celebration_overlay.dart`, `achievements_section.dart`, `armsphere_image.dart`.
- Routing: `core/routing/app_router.dart`, `page_transitions.dart`.

### Admin Web (React)
- Tokens live in `apps/admin-web/src/index.css` (`@theme` block: `--color-brand-canvas/bg/panel/titanium/raised/silver/recessed/card/border/accent/gold/crimson/cyan/emerald`) plus utility classes `.titanium-panel`, `.titanium-card`, `.brushed-steel`, `.recessed-graphite`, `.smoked-glass`, and glow helpers.
- Shared primitives: `src/components/ui.tsx` (`LoadingCard`, `ErrorPanel`, `EmptyState`, `ErrorBanner`, `FormError`).
- Shell and routing: `src/layout/AdminShell.tsx`, `src/App.tsx` (`RoleGuardedRoute`, central RBAC via `lib/authorizationPolicy.ts`).
- Fonts: Inter, Space Grotesk, JetBrains Mono via Google Fonts `@import`.

### Approved design specification
- `UI_UX_DESIGN_STATE.md` (root, v3.1.0) lists `docs/design/00` to `72` as canonical authority and carries a 12-question rubric, anti-slop rules (no 999dp action buttons, no nested glass, no purposeless particles, no imitation of TikTok/UFC/F1) and motion rules.
- Caveat: that file states the tokens are "mathematically locked" at `#121826 / #334155`, and that the work is "100% complete". The code on `design/titanium-luxe` has since moved to the titanium token set. The doc and the branch disagree. The `docs/design/` files were not opened in this session, so which token set is currently approved needs owner confirmation before implementation.

## 3. Screen families (inventory)

### Mobile: `apps/mobile/lib/features/*` (19 feature folders)
athlete, auth, championship, community, governance, home, informal_event, match, messaging, nomination, notifications, referee, search, session, settings, support, team, tournament, venue. `UI_UX_DESIGN_STATE.md` claims 66 screens plus 3 modals. That count was not independently verified. Individual screen files were not read in this session.

### Admin Web: `apps/admin-web/src/pages/` (12 pages, routes in `App.tsx`)
`/login` (LoginPage, public), `/` Dashboard, `/analytics`, `/championships`, `/governance`, `/athletes`, `/referees`, `/moderation`, `/venues`, `/nominations`, `/audit`, `/support`, plus `ForbiddenPage` rendered inside the shell when RBAC denies access. Catch-all redirects to `/`.

## 4. Verified visual inconsistencies (read on `design/titanium-luxe`)

Admin Web mixes two visual vocabularies. The shell and `index.css` use the titanium tokens. Several surfaces still use generic Tailwind slate/amber values:

1. `pages/LoginPage.tsx`: panels use `bg-[#0F172A]/90`, `border-slate-800`, `border-slate-700/80`; primary CTA and accents use `bg-amber-500` / `amber-400`, not the gold `#D4AF37` token used by the shell. The first screen every admin sees is off-palette.
2. `pages/LoginPage.tsx`: a pill reads "F1 RACE-CONTROL INFORMATION DENSITY". This contradicts the design-state rule against imitating F1 and reads as internal design jargon, not product copy. Copy-only change, no logic.
3. `pages/ForbiddenPage.tsx`: `bg-brand-panel border-slate-800`, `amber-*` for role and switch-role CTA, `red-*` instead of the crimson token.
4. `App.tsx`: error boundary card (`bg-[#0F172A] border-slate-800`, `amber-500` CTA, an emoji shield) and the auth-loading spinner (`border-amber-500`) are off-palette.
5. `layout/AdminShell.tsx`: the desktop sidebar uses titanium tokens, but the mobile drawer uses `border-slate-800`, `text-amber-400`, `bg-amber-500` active role chip and `bg-slate-800` chips. Desktop and mobile navigation do not match each other.
6. `components/ui.tsx`: already on crimson/gold tokens and is the correct reference for shared primitives. It is a good base, not a defect.

Already correct (do not touch): `AdminShell` desktop sidebar, `index.css` token and material classes, `ui.tsx` states, `authorizationPolicy.ts` driven navigation.

Mobile: the token layer and shared widgets (`ElevatedActionCard`, `StatusChip`, `GlassCard`) are coherent and consistent with the titanium set. No concrete screen-level defects were verified because screen files were not read. `glass_card.dart` still exists with a `BackdropFilter`; per the design state it is reserved for floating bars and modals, so its callers should be audited before any change.

Found by code search on `main` only and NOT verified on the branch: `pages/AuditPage.tsx` and `pages/VenuesPage.tsx` use `border-slate-800`, `bg-slate-900`, `amber-*` accents and `focus:border-amber-500/60`. Likely the same drift. Confirm on the branch.

## 5. Recommended first refinement target

Admin Web "entry and shell" family: `LoginPage`, `ForbiddenPage`, `App.tsx` boundary and loader, and `AdminShell` mobile drawer.

Why, based on the code:
- It is the first thing every administrator sees (login, then shell) and the mobile drawer is the only navigation on small screens.
- The drift is verified, concentrated in 4 files, and purely presentational (Tailwind classes and copy).
- The correct tokens and a good shared primitive file already exist, so no new dependency or new system is needed.
- Logic that must not change (login handler, `RoleGuardedRoute`, `switchActiveRole`, `canAccessRoute`) is clearly separable from markup.
- Smaller blast radius than touching 66 mobile screens, and mobile screen defects are not yet evidenced.

Second candidate (after evidence): a mobile screen family chosen after reading the screen files and running them. Do not select it from documentation claims alone.

## 6. Files likely affected (all exist on `design/titanium-luxe`)

- `apps/admin-web/src/pages/LoginPage.tsx`
- `apps/admin-web/src/pages/ForbiddenPage.tsx`
- `apps/admin-web/src/App.tsx` (only the `AppErrorBoundary` markup and `RoleGuardedRoute` loading spinner markup)
- `apps/admin-web/src/layout/AdminShell.tsx` (only the mobile drawer and mobile top bar markup)
- `apps/admin-web/src/index.css` (only if a small shared token or utility is genuinely missing, e.g. a gold primary-button class)
- `apps/admin-web/src/components/ui.tsx` (reuse, optional additive primitive)

Dependencies and constraints: `lucide-react`, `tailwindcss` 4, `react-router-dom` 7, `AuthContext`, `lib/authorizationPolicy.ts`. No new packages. No changes to `apps/api`, `packages/*`, `supabase`, `.env*`, `.vercel`, `netlify`, or CI.

Tests that touch these files: `apps/admin-web/src/test/admin_web_rbac.test.tsx` renders `AdminShell`, `ForbiddenPage`, `RoleGuardedRoute` and several pages. Its assertions (text, roles, test ids such as `locked-jurisdiction-badge`) were only partly read; they must be preserved. Keep all visible text used by tests and all `data-testid` attributes unchanged unless a test is updated for a justified reason.

## 7. Proposed minimal-scope plan

Slice 1 (this target, one MR):
1. Re-map off-palette classes in the 4 files to existing tokens: `#0F172A` and `bg-slate-900` to `brand-panel` / `brand-titanium`; `border-slate-800` / `slate-700` to `border-[rgba(214,220,227,0.12)]` (the value already used in the shell); `amber-*` primary actions to `#D4AF37` gold; error reds to `#E23B3B`.
2. Align the mobile drawer with the desktop sidebar (same active-link style, role chip style, jurisdiction badge).
3. Replace the F1 pill copy on the login screen with neutral product wording after owner approval of the text.
4. Replace the emoji in the error boundary with the existing `Shield` icon style used elsewhere.
5. Keep glass effects limited to where they already exist (login panel, mobile top bar). No new glass.
6. Keep layout, routes, handlers, role logic, jurisdiction display, error messages and all test ids unchanged.

Slice 2 (only after verification): audit `AuditPage` and `VenuesPage` on the branch, then other pages, one MR per small family.

Slice 3: mobile, selected from real screen evidence (see section 5).

## 8. Verification checks needed (none have been run)

Admin Web, from `apps/admin-web`:
- `npm run lint` (this is `tsc`)
- `npm run test` (vitest, including `admin_web_rbac.test.tsx`)
- `npm run build`
- Manual and screenshot comparison before and after at 360, 768 and 1280 px widths for: login (default, error, submitting), forbidden (with and without switch-role), error boundary, loading spinner, desktop sidebar and mobile drawer (single-role and multi-role users).
- Contrast check on gold-on-dark and crimson-on-dark text.
- Confirm no diff in route paths, request code, or `AuthContext`.

Mobile (only when a mobile slice is chosen): `flutter analyze`, `flutter test`, and golden or screenshot comparison on the chosen screens.

## 9. Blockers, gaps and open questions

- No screenshots, running app, or local checkout were available. Visual claims are from source only.
- Uncommitted local changes could not be inspected.
- No test, lint, or build was run.
- Flutter and Node toolchains are not available to this session.
- Which token set is approved (`#121826 / #334155` in `UI_UX_DESIGN_STATE.md` and on `main`, versus titanium `#151B24` with translucent silver borders on `design/titanium-luxe`) needs an owner decision. This plan assumes the branch is authoritative as the issue states.
- Please confirm that `design/titanium-luxe` is the intended release-candidate branch and base for refinement MRs.
- `docs/design/*` (72 files) were not opened; the plan should be checked against `06`, `07`, `22`, `24`, `37`, `72` before coding.
- Model confirmation: cannot verify Claude Sonnet 5.5 usage from this session.

## 10. Guardrails honoured

No deploys, publishes, merges, production config edits, force-pushes, or changes to the existing release-candidate branch. This MR adds one markdown file on a separate branch.
