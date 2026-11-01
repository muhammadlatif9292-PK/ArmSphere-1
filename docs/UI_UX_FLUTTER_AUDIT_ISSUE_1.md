# ArmSphere Flutter-First UI/UX Audit (Issue #1)

Status: DRAFT, preliminary. Documentation only. No application code was changed.
Base: `design/titanium-luxe` at `47d57bc7`. Scope: `apps/mobile` (Flutter Android). Admin web is secondary and paused; draft MR !3 stays unmerged.

## 0. Evidence and limits

- Everything was read through GitLab API file reads and code search. The app was NOT run, NO screenshots were seen, and NO tests, `flutter analyze` or builds were run. Nothing below is visually validated.
- Read in full: `lib/main.dart`, `core/routing/app_router.dart`, `core/theme/app_theme.dart`, `core/widgets/{main_shell_screen,premium_floating_nav_bar,elevated_action_card,status_chip,glass_card,app_error_view,app_empty_state}.dart`, `pubspec.yaml`.
- Read partially (first 240 to 300 lines): `features/auth/screens/login_screen.dart` (402 lines), `features/athlete/screens/athlete_screens.dart` (3238), `features/home/screens/discover_screen.dart` (1561), `features/tournament/screens/tournament_screens.dart` (1810), `features/community/screens/community_feed_screen.dart` (1230).
- Not read: `tactile_press_wrapper`, `sticky_bottom_action_bar`, `skeleton_placeholder`, `ambient_particle_background`, the assets folder, the Passport screen body, the referee, operator and governance dashboards, and every detail, registration, settings and secondary screen. An earlier read batch was interrupted by the tool, so I made one targeted retry. It succeeded for the files listed above as read.
- Code search indexes `main` only. Results that came only from search are marked (main index) and are NOT verified on the branch.

## 1. Verified findings (read in source on `design/titanium-luxe`)

### F1. Display font name does not match the bundled family
- `pubspec.yaml` registers families `Inter` and `SpaceGrotesk`, with weights 400, 500, 600 and 700 only. `AppTheme.fontDisplay` is `'SpaceGrotesk'`, and `ThemeData.textTheme` uses it correctly. `core/widgets/count_up_text.dart` also uses `'SpaceGrotesk'` (main index).
- The literal `'Space Grotesk'` (with a space) is used in `login_screen.dart`, `tournament_screens.dart`, `community_feed_screen.dart`, `app_empty_state.dart` and `app_error_view.dart`, all read on the branch. Search (main index) shows many more occurrences in the auth screens, search, role intent, head-to-head, referee, athlete and onboarding screens.
- Flutter resolves `fontFamily` by the exact registered name, so the spaced string should fall back to the platform default font on Android. This effect is an inference from Flutter behaviour and was not observed at runtime.
- `FontWeight.w800` and `w900` are requested in several places (for example `StatusChip`), but only up to 700 is declared, so those render at the nearest declared weight.
- Impact: the shared state widgets carry the mismatch, so it likely reaches every screen that uses them, and the app probably mixes two display typefaces.

### F2. De-facto accent roles differ from the owner hierarchy
Owner hierarchy: crimson = primary interactive emphasis and active navigation; gold = championship, achievement, premium; titanium/silver = structure; cyan only where it has an established semantic role.
- `AppTheme.primaryAccent` (and aliases `primaryRed`, `combatCrimson`, `competitionCrimson`) is crimson `#E23B3B`, but `ThemeData.primaryColor`, `ColorScheme.primary` and the `ElevatedButton` background are gold `#D4AF37`. The theme disagrees with itself.
- Gold is the working primary colour: theme buttons, `AppErrorView` and `AppEmptyState` primary CTAs, Community filter chips and the `POST CLIP` button, login icons, Events fee and location icons.
- Crimson is primary only in the Arena dock tab, the Arena and Discover pull-to-refresh indicators, the Discover active search border and icon tile, and the `live` and `error` status chips.
- `StatusChip.warning` is gold and `ArmIndicatorPill` marks LEFT ARM in gold, which blurs gold's championship meaning.
- Cyan appears in the theme as the input focus border, the `TextButton` foreground (`info`) and the chip `selectedColor`, as well as in the info chip and the right-arm pill.
- `docs/design/07` says never to use gold as the background of generic buttons. The current theme does, so the code matches neither those docs nor the owner hierarchy.

### F3. Each tab has a different header and background treatment

| Tab | Screen (source) | Header | Scaffold background |
| --- | --- | --- | --- |
| Arena | `AthleteDashboardScreen` (`athlete_screens.dart`) | No AppBar. Custom `_buildBrandHeader` (body not read) | `voidBackground` |
| Discover | `DiscoverScreen` (`discover_screen.dart`) | AppBar `elevatedSurface`, crimson icon tile, title plus subtitle | `background` |
| Events | `TournamentsListScreen` (`tournament_screens.dart`) | Plain AppBar, title `Competitions`, refresh action | `background` |
| Community | `CommunityFeedScreen` (`community_feed_screen.dart`) | Uppercase `COMMUNITY ARENA`, gold `LIVE FEED` badge, gold `POST CLIP`, chips in `bottom` | `background` |
| Passport | `AthleteProfileScreen` | Not read | Not read |

Title casing, header colour, and the accent colour used for tab emphasis all differ.

### F4. Shared state widgets exist but the list screens bypass them
- `AppErrorView` is well built: it categorises auth, permission and network errors, formats messages through `AppErrorFormatter`, and offers a primary plus a safe secondary action. `AppEmptyState` has presets such as `noCompetitions` and `noSearchResults`.
- `TournamentsListScreen` (Events tab) builds its own error layout. It prints the raw `'$error'` string with a default `ElevatedButton`. Its empty state is a bespoke icon plus two lines with no action.
- `CommunityFeedScreen` renders errors as `AppEmptyState(subtitle: error.toString())`, which leaks raw exception text.
- Commit `bdce232c` fixed dead-end fallbacks for `TournamentDetailScreen` and others, but not these two list screens. Discover's `_buildErrorState` and the Arena error handling were not read.
- Both widgets hardcode `'Space Grotesk'` (see F1).

### F5. Bottom dock (`main_shell_screen.dart`)
- Active colour is `index == 0 ? crimson : goldPrimary`, so only Arena is crimson.
- Labels are 9.5sp. Icons are 20dp. Each item is an `Expanded` `GestureDetector` across the 64dp dock.
- The items have no `Semantics` wrapper, so the selected state is not exposed to screen readers.
- `BackdropFilter` on the dock is within the documented rule (floating bars only).
- `PremiumFloatingNavBar` has different labels (`Log`, `Matches`) and a gold border. Search finds no reference outside its own file (main index), so it appears to be dead code. Not verified on the branch.
- `AmbientParticleBackground` is still in the shell stack, although `UI_UX_DESIGN_STATE.md` lists its removal under Slice 10. The widget was not read, so its behaviour is unknown.

### F6. Theme file hygiene
`lib/core/theme/` also contains `app_theme.dart.new` and `app_theme_final.dart` (older values). Whether anything imports them was not checked.

### F7. Structure facts
- Router: `go_router`, redirect state machine (splash, welcome, login, MFA, role intent, onboarding, then role landing). Roughly 100+ `GoRoute` entries (not exactly counted) with many legacy aliases for brackets, weigh-in, awards and head-to-head.
- Shell: 5 branches. Arena (`/home`, role-dispatched to athlete, referee, operator or governance dashboards), Discover (`/discover`, `/rankings`), Events (`/tournaments`), Community (`/community/feed`), Passport (`/athlete/profile`).
- `formatEventFee` hardcodes the prefix `CAD $`. Whether that is intended is an owner question.

## 2. Needs further source inspection (hypotheses, not defects)
- Route shadowing: `/tournament/details`, `/tournament/operations`, `/tournament/brackets` and `/athlete/achievements` are declared after the parameterised `/tournament/:tournamentId` and `/athlete/:athleteId`. They may never match. This is a navigation issue, out of UI scope. Report only, do not touch.
- `AmbientParticleBackground` may be fully covered by the opaque child Scaffolds, or still animating.
- Remaining ~2,900 lines of `athlete_screens.dart` (dashboard sections plus the Passport profile and persona switcher), `discover_screen.dart`, `community_feed_screen.dart`, `tournament_screens.dart` (detail, brackets), and `event_registration_screen.dart` (payment flow).
- The role dashboards that share the Arena tab: referee, operator and governance.
- Discover filter chips versus Community chips (radius and selected colour not compared).
- Existing tests that assert on shell labels or error titles. Commit `c18f785e` is titled "align error title with integration test contract". Tests named in other commits were not located in `apps/mobile/test`.

## 3. Needs rendered screenshots or runtime testing
- Actual typeface rendering (Space Grotesk versus platform default) on a device.
- Layout after any font change, especially dense rows and the 9.5sp dock labels at 360dp width and large text scale.
- Contrast of white or dark text on a crimson fill. Hand estimate for white on `#E23B3B` is about 4.3:1, below the 4.5:1 AA threshold for normal text. This was not tool-verified.
- Header and background consistency, and whether the ambient layer is visible.
- Real loading, empty and error states (need forced states).
- Back-navigation and route behaviour, including the shadowing hypothesis.
- Scroll performance and keyboard behaviour in forms.

## 4. Accent direction (recorded, not applied)
- Start from the titanium tokens already in `app_theme.dart`. Do not revert to the older documented set.
- Crimson is the primary interactive emphasis. Risk: crimson already means live, foul, loss and error (`StatusChip.live`, `StatusChip.error`). Mitigation: reserve a filled crimson for primary actions and use the `error` token (`#FF4D4D`), an icon and wording for destructive or failed states. Check contrast before any filled crimson button (see section 3).
- Gold: championship, achievement, premium (podiums, titles, ELO milestones). It should leave generic CTAs and the warning chip in later slices.
- Titanium and silver: surfaces, borders, secondary controls.
- Cyan: keep only for focus rings, blue-corner identity, live telemetry and info status. The default `TextButton` and chip `selectedColor` are cyan today and should be reviewed.
- Do not change `ThemeData` globally yet. A global primary swap (gold to crimson) is deferred until the contrast check and owner approval.

## 5. Screen inventory (from the router; depth of reading varies)

| Family | Main screens | Read? | Provisional action |
| --- | --- | --- | --- |
| Entry and auth | splash, welcome, login, register, forgot and reset password, MFA setup and verify, recovery codes, role intent, onboarding | Login partly | POLISH (font only, pending) |
| Arena (role dispatched) | `AthleteDashboardScreen`, referee, operator and governance dashboards | Athlete top only | Undecided |
| Discover | `DiscoverScreen`, `RankingsScreen`, `GlobalSearchScreen` | Discover top only | POLISH |
| Events | `TournamentsListScreen`, detail, registration, brackets, operations, weigh-in, awards | List screen only | POLISH |
| Community | `CommunityFeedScreen`, comments, create post | Feed top only | POLISH |
| Passport | `AthleteProfileScreen`, public profile, followers, training log, achievements | No | Undecided |
| Social and club | teams, venues, informal events, nominations, messages, announcements, notifications | No | Undecided |
| Governance and referee tools | disputes, complaint, certifications, scorepad, evidence upload | No | Undecided |
| Account | settings hub, payment methods, tickets, blocked users, roles, deletion, terms, privacy, support tickets, sessions | No | Undecided |

No RESTRUCTURE or REDESIGN is recommended anywhere on the evidence so far. Where a screen was not read, the action is "Undecided", not "no problem".

## 6. Top three Flutter improvements, in order

### 1. Fix the display-font name (foundation, no colour change)
- Option A (smallest): add a second font family named `Space Grotesk` in `apps/mobile/pubspec.yaml`, pointing at the same four asset files already declared. This repairs every literal usage without touching Dart code.
- Option B (cleaner, larger diff): replace the literals with `AppTheme.fontDisplay`, starting with `core/widgets/app_empty_state.dart`, `core/widgets/app_error_view.dart`, `features/auth/screens/login_screen.dart`, `tournament_screens.dart` and `community_feed_screen.dart`, then the rest.
- Recommendation: A first, B as a later cleanup.
- Why first: one shared root cause that touches every tab, and it changes text metrics, so all later layout work should be judged after it.
- Checks: confirm on a device or emulator screenshot that the fallback really occurs; confirm the four `assets/fonts/SpaceGrotesk*.ttf` files exist (assets listing was not read); `flutter analyze`; `flutter test`; before and after screenshots of all five tabs at 360dp for overflow.

### 2. Shell and tab chrome
- Files: `core/widgets/main_shell_screen.dart` (active colour rule, `Semantics` with `selected`), then the AppBars in `discover_screen.dart`, `TournamentsListScreen` and `community_feed_screen.dart`, with the Arena header in `athlete_screens.dart` read in full first.
- Change: crimson as the active state on all five dock tabs; one consistent title casing and background across tabs; gold only for achievement cues. Keep the label strings `Arena`, `Discover`, `Events`, `Community`, `Passport`.
- Why second: visible on every screen, small diffs, and it settles the accent rule before the state widgets are touched.
- Checks: read `discovery_and_home_routing_test.dart`, `multi_role_switching_test.dart` and `widget_test.dart` for shell assertions first; run them; screenshot the dock at small widths and large text scale.

### 3. Loading, empty and error surfaces on the five tabs
- Files: `TournamentsListScreen` error and empty branches (`tournament_screens.dart`), the `CommunityFeedScreen` error branch, then Discover and Arena after they are read.
- Change: use `AppErrorView` and the `AppEmptyState` presets, remove raw `'$error'` and `error.toString()` text, keep provider invalidation and pull-to-refresh. The empty branch must stay inside a scrollable (`AlwaysScrollableScrollPhysics`) so refresh still works.
- Why third: it depends on the accent and font decisions above, and tests may assert on error titles (see section 2).
- Checks: read the related tests first; run them; force each state and screenshot it.

After these: Events journey (detail, registration with payment), the Arena dashboard in full, Passport. A global primary button colour change is a separate, later decision.

## 7. Must be preserved
API contracts and providers, auth, redirects and role gating, route paths and parameters, back navigation, ELO and match rules, jurisdiction, payment flows, and real loading, empty, error and permission states. No new dependencies, no invented features, no mock data.

## 8. Documentation follow-ups (not done here)
- `docs/design/07`, `56` and `UI_UX_DESIGN_STATE.md` still describe the older `#121826` set, cyan for active navigation, and gold for master CTAs. They predate the titanium theme (`77687af9`) and conflict with the owner hierarchy. Update them after implementation, not before.
- Re-verify the documented contrast ledger against titanium values and any crimson fill.

## 9. Questions for the owner
1. May a pubspec font alias (Option A) be used as the first fix?
2. Is `CAD $` the intended currency prefix for events?
3. Should `ArmIndicatorPill` keep gold for LEFT ARM, given gold's championship meaning?
4. Approve a darker crimson fill or an outlined crimson button style if the contrast check fails?

## 10. Checks actually completed
None. No test, analysis, build, screenshot or device run was performed. All findings above are from reading source.
