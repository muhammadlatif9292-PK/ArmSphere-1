# ArmSphere Stage 3 — Premium Layer Audit: Visual, Media, Motion & Experience Gaps
**Document Version**: 1.0.0 (Authoritative Stage 3 Architecture)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, & Stage 3 Master Directive
**Scope**: Comprehensive 66-Screen Audit of Visual Density, Media Absence, Interaction Ergonomics, Motion Readiness, Brand Distinction, and Perceived Quality Across All 11 Functional Domains.

---

## 1. Executive Summary & Audit Context

ArmSphere has achieved functional robustness across its 26 real user features, 66 production screens, 9 federation roles, and offline-first state synchronization. However, an empirical visual and sensory audit of the current compiled release (`app-release.apk`) reveals a stark operational paradox:

1. **The "Wireframe in Production" Phenomenon**: While the underlying architecture (`packages/types`, `packages/contracts`, Riverpod, Isar/SQLite, GoRouter) is institutional-grade, the visual layer relies almost exclusively on flat CSS-like containers (`#121826`, `#1E293B`), default Material vector icons (`Icons.*`), and plain textual cards.
2. **Total Media Void**: The physical asset directory (`apps/mobile/assets/`) contains zero raster or photographic assets. Every athlete avatar, tournament banner, division badge, trophy asset, and empty state is rendered either as a colored circle with initial letters, a generic Material icon, or an unadorned blank surface.
3. **Athletic Emotional Disconnect**: Armwrestling is one of the world's most visceral, high-tension, tactile, and physically intense strength combat sports. The current UI feels like a generic enterprise SaaS dashboard (e.g., Jira or ERP) rather than an electric, arena-grade federation sports platform.
4. **Motion Timidity**: The motion system is predominantly instant cuts or default framework sliding transitions. Key athletic triumphs (winning a match, advancing a bracket, hitting a personal record, locking a tournament registration) lack cinematic weight, haptic grounding, and celebration choreography.

This audit establishes the rigorous baseline gap analysis across all 66 screens to guide Stage 3 elevation without breaking a single line of business logic, route parameter, or security constraint.

---

## 2. Global Aesthetic & Systemic Deficiency Analysis

### 2.1 The Visual Palette: From Flat Dark to "Raw Iron & Precision Steel"
- **Current State**: Surfaces are predominantly a uniform matte `#121826` with 1px border `#1E293B`. There is minimal depth hierarchy, zero specular highlights, no micro-textures (knurled steel, chalk grain, carbon fiber weave), and no atmospheric depth.
- **Elevation Requirement**: Introduce the full multi-layered "Raw Iron & Precision Steel" hierarchy:
  - Deepest Obsidian Core: `#070A11`
  - High-Density Steel Plate: `#0B0F19`
  - Elevated Precision Surface: `#121826`
  - Inactive Border / Chamfer: `#1E293B`
  - Active Accent / Telemetry: `#38BDF8` (Luminous Cyan)
  - Championship Glory / Institutional Gold: `#D4AF37` (Champagne Gold)
  - Combat Tension / Ref Alert: `#EF4444` (Adrenaline Crimson)

### 2.2 Typography & Hierarchy Weighting
- **Current State**: While `SpaceGrotesk` and `Inter` are bundled, header-to-body scale differentiation is timid. Subheads frequently blend into body text, and numeric telemetry (Elo ratings, grip dyno kg, bracket seeds, match timers) lacks the high-impact tabular monospace athletic presence of a professional fight clock.
- **Elevation Requirement**: Standardize athletic typographic rhythm:
  - Fight Display / Hero Numbers: `SpaceGrotesk-Bold`, letter-spacing `-0.03em`, high-contrast white `#F8FAFC`.
  - Telemetry & Seeds: Monospace numbers, uppercase micro-labels (`tracking: 0.12em`), 10-12sp.
  - Body & Form: `Inter-Regular` / `Inter-Medium`, 14-16sp with optimized 1.5 line height for high-stress referee/athlete scanning.

### 2.3 Media & Texture Infrastructure
- **Current State**: 0 bundled images. 0 tournament hero backdrops. 0 weight class division emblems. 0 empty state narrative scenes.
- **Elevation Requirement**: Define and integrate a multi-tiered media system (M0–M7) with multi-density WebP assets, strict caching, fallback gradients, and progressive loading.

---

## 3. Screen-by-Screen Exhaustive Audit (66 Screens + 3 Modals)

### Domain 1: Auth & Identity (Screens 01–06)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **01. LoginScreen** (`/login`) | Clean dark form, text inputs, gold CTA. | Lacks brand hero presence; feels like standard admin login rather than entry to the Global Armwrestling Federation. | Cinematic arena background texture (subtle knurled steel + chalk atmospheric lighting), debossed gold ArmSphere insignia, gold-trimmed input fields with active focus glow. |
| **02. RegisterScreen** (`/register`) | Multi-field form, standard checkboxes. | Visually dense without rhythmic pacing; lacks excitement of joining a worldwide athletic league. | Step indicators with metallic edge-lit active state; micro-badge preview of initial Elo (1200); clear terms agreement card. |
| **03. ForgotPasswordScreen** (`/forgot-password`) | Isolated email field, send button. | Utilitarian and cold; no reassurance cues. | Security shield lock icon with subtle cyan glow; reassuring institutional support typography. |
| **04. ResetPasswordScreen** (`/reset-password`) | Two password fields, submit button. | Generic form inputs. | Real-time strength meter with animated segmented steel bars (Red -> Amber -> Gold -> Cyan). |
| **05. VerifyEmailScreen** (`/verify-email`) | 6-digit OTP input boxes. | Sterile; boxes feel like detached wireframe outlines. | High-tactile keypad feedback, active digit underline pulse, resend cooldown timer with radial stroke progress. |
| **06. RoleIntentScreen** (`/role-intent`) | 9 vertical/grid cards with text labels. Fixed skip CTA. | Cards are flat rects; difficult to distinguish the massive difference between an ATHLETE, REFEREE, and OPERATOR at a glance. | Rich role hero cards with custom metallic insignia (Athlete: Clashed Grips; Referee: Precision Whistle/Scale; Operator: Tournament Bracket Gavel), tactile card press depth. |

---

### Domain 2: Athlete Lifecycle & Training (Screens 07–15)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **07. AthleteHomeScreen** (`/athlete/home`) | Action cards, next tournament banner, Elo card. | Banner is flat color; stats are plain numbers; lacks the heartbeat of a combat athlete's war-room. | Dynamic arena hero card with glassmorphism telemetry HUD, live Elo progression sparkline with gold gradient fill, quick-access fight radar. |
| **08. AthleteProfileScreen** (`/athlete/profile`) | Avatar placeholder circle, bio text, weight class, record (W-L). | Avatar is a letter circle; record looks like standard table data; zero federation prestige. | High-res athlete portrait frame with division rank badge overlay, dual-arm radar chart (Left Arm vs. Right Arm), verified federation seal watermark. |
| **09. OnboardingScreen** (`/athlete/onboarding`) | Multi-step wizard (arm stats, weight class, bio). Fixed skip CTA. | Step transitions are abrupt; physical dimension selectors feel like medical survey forms. | Visual arm selector (Left / Right / Both) with anatomic silhouette highlight; interactive weight class slider with real-time division tag. |
| **10. TrainingLogScreen** (`/athlete/training-log`) | Chronological list of workout entries. | Text list with minimal visual differentiation between heavy table practice, isometric holds, and endurance. | Workout category micro-chips with metallic color codes; volume intensity heat map; chalk-textured session cards. |
| **11. LogWorkoutScreen** (`/athlete/log-workout`) | Exercise picker, sets, reps, weight inputs. | Dense number inputs; slow to use in a chalky gym environment. | Large, thumb-friendly numeric steppers; quick-tap set completion buttons; instantaneous volume calculator. |
| **12. WorkoutDetailScreen** (`/athlete/workout-detail`) | Static list of exercises performed. | Lacks visual reward for completing heavy volume. | Performance summary ring; comparison to previous session PR with gold highlight stamp. |
| **13. PersonalRecordsScreen** (`/athlete/prs`) | Grid/list of PR lifts (Cupping, Pronation, Rise, Bench). | Pure text table; lacks trophy feel of personal milestones. | Metallic PR shields with embossed lift icons, date stamped with federation verification level, gold badge on new records. |
| **14. AddPRScreen** (`/athlete/add-pr`) | Form with lift type, weight, video URL proof. | Basic inputs; video proof upload feels detached. | Verified proof badge requirement alert; video thumbnail preview container with play trigger; weight conversion toggle (KG/LBS). |
| **15. PRDetailScreen** (`/athlete/pr-detail`) | Historical curve of specific lift. | Basic line chart. | Interactive smooth cubic bezier chart with touch tooltip scrubbing, gold peak marker, video proof embed container. |

---

### Domain 3: Tournaments & Brackets (Screens 16–24 + Modals)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **16. TournamentListScreen** (`/tournaments`) | Vertical scroll list of event cards, filter tabs. | Cards have no venue imagery; status badges (Upcoming, Live, Completed) look identical except for text. | Cinematic tournament poster cards with gradient scrim, glowing live pulse for active events, tier badges (World, National, Regional, Local). |
| **17. TournamentDetailScreen** (`/tournament-detail`) | Tabbed view (Overview, Brackets, Rules, Roster). | Header is flat; countdown timer is small; registration CTA lacks urgency. | Wide hero arena header with date/venue lockup, animated countdown timer HUD, persistent Champagne Gold registration action dock. |
| **18. BracketViewerScreen** (`/brackets`) | Pan/zoom canvas with match nodes. | Nodes are rectangular boxes; winner progression lines are plain; complex brackets feel intimidating. | Steel-beveled match nodes, arm-specific indicator (Left Arm / Right Arm tab bar), active table assignment tag, smooth vector connector paths. |
| **19. MatchDetailScreen** (`/match-detail`) | Competitor A vs Competitor B, score, referee names. | Lacks the adrenaline of a championship fight card; head-to-head feels static. | Split-screen fighter faceoff layout with angled dynamic slash divider, head-to-head historical Elo comparison bar, live round-by-round score tiles. |
| **20. TournamentRegistrationScreen** (`/tournament-register`) | Division checklist, waiver agreement, entry fee pay CTA. | Legal waiver is a raw text block; division selection feels ambiguous. | Interactive division selector with weight-in tolerance warnings, styled legal waiver scrollbox with digital signature confirmation, fee summary breakdown. |
| **21. WeighInScreen** (`/weigh-in`) | Scale weight input, pass/fail toggle. | Utilitarian form; misses official federation weigh-in ceremonial weight. | Large digital scale LED readout display, official weight limit difference indicator (+/- 0.2kg in green/red), official stamp confirmation. |
| **22. TableAssignmentScreen** (`/table-assignments`) | List of tables (Table 1, Table 2...) and queued matches. | Table status is ambiguous; queue visibility is cluttered. | High-contrast arena table layout map with live table occupancy indicators (In Match, On Deck, In Warmup, Paused). |
| **23. BracketManagementScreen** (`/operator/bracket-management`) | Operator tool to seed, advance, and resolve disputes. | High risk of operator mis-clicks under tournament noise and stress. | Error-prevention dialogs with two-stage confirmation for bracket advancements, high-contrast seed re-ordering handles, dispute alert banners. |
| **24. TournamentLiveStreamScreen** (`/tournaments/live-stream`) | Video player container with chat/match feed below. | Video container is a raw black box; live match overlay is basic. | Integrated broadcast HUD showing live table, competitors, referee calls, and synchronized live bracket drawer. |
| **Modal 1. FullInteractiveBracketModal** | Full-screen interactive bracket. | Navigation can get lost in deep double-elimination trees. | Mini-map viewport radar, branch focus zooming, quick search by athlete name. |
| **Modal 2. TournamentEmptyStatesShowcaseWidget** | Developer/debug screen for 8 empty states. | Plain containers. | Production-grade atmospheric illustrations with context-aware CTAs. |
| **Modal 3. CelebrationOverlay** | Full-screen overlay upon tournament win. | Basic confetti or text banner. | Cinematic gold particle fountain, trophy render, haptic burst sequence, audio triumph chord. |

---

### Domain 4: Refereeing & Scorepad (Screens 25–29)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **25. RefereeDashboardScreen** (`/referee/dashboard`) | List of assigned tables, active tournament session. | Lacks clear duty status; table assignment alert is small. | High-visibility duty toggle (On Duty / Break), prominent active table callout card, quick rules reference shortcut. |
| **26. LiveMatchScorepadScreen** (`/referee/scorepad`) | Left/Right tap zones for fouls, pins, warnings. 0ms requirement. | Needs absolute ergonomic perfection; buttons must never miss-tap under sweaty referee thumbs. | Ultra-high contrast split interface (Blue Corner vs. Red Corner), 64dp+ tap targets, zero latency immediate visual/haptic response, warning indicators (Warning 1, Foul 1, Foul 2 / DQ). |
| **27. MatchDisputeScreen** (`/referee/dispute`) | Dispute reason dropdown, referee statement field, video link. | High-stress screen; form inputs feel slow to complete during a live match halt. | Quick-tag dispute categories (Elbow Foul in Winning Position, Slip in Grip, Intentional Foul, Officiating Call Appeal), camera video evidence review container. |
| **28. RefereeCertificationScreen** (`/referee/certifications`) | List of badges (Master Ref, National Ref, Regional Ref). | Simple badge list; lacks official prestige. | Embossed metallic federation referee badges with serial number, issue date, and authorized division scope. |
| **29. RulebookViewerScreen** (`/referee/rules`) | Searchable document viewer with federation bylaws. | Raw text; hard to find specific rule under rapid dispute inquiry. | Instant search with highlighted keyword hits, quick-jump accordion index (Starting Position, Fouls, Straps, Referee's Grip, Pin Definition). |

---

### Domain 5: Community & Social (Screens 30–36)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **30. CommunityFeedScreen** (`/community/feed`) | Card feed of posts, likes, comments. | Looks like generic social media; lacks combat armwrestling identity. | Athletic feed cards featuring video embeds, match breakdown tags, equipment reviews, challenge announcements, gold-trimmed like reactions. |
| **31. CreatePostScreen** (`/community/create-post`) | Text box, image attach button, post CTA. | Bare-bones creation sheet. | Category selector (Match Footage, Training Tip, Gear Talk, Callout), rich media preview container, character counter. |
| **32. PostDetailScreen** (`/community/post-detail`) | Full post with nested comment thread. | Comments are flat text blocks; athlete badges are missing. | Verified athlete/referee badges in comment headers, upvote counters, smooth keyboard elevation. |
| **33. ChallengeScreen** (`/community/challenges`) | List of pending, sent, and active athlete-to-athlete challenges. | Table looks like generic invoice list; lacks personal rivalry tension. | "Versus" card design with dual athlete portraits, stake indicators (Rank, Honor, Event Match), countdown to challenge expiration. |
| **34. CreateChallengeScreen** (`/community/create-challenge`) | Athlete search, date/location picker, arm selection. | Form is clinical; does not feel like throwing down the gauntlet. | Athlete battle preview card updating live as opponent is chosen; Arm selection toggle; official terms toggle. |
| **35. TrainingClubsScreen** (`/community/clubs`) | Club cards with member counts and locations. | Generic group directory. | Club banner art with location pin, sparring schedule pills, "Join Club" action with club seal watermark. |
| **36. ClubDetailScreen** (`/community/club-detail`) | Club leader, member list, club table practice schedule. | Static lists; lacks club community camaraderie. | Team roster grid with role badges, table practice countdown timer, interactive map preview. |

---

### Domain 6: Rankings & Analytics (Screens 37–41)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **37. GlobalRankingsScreen** (`/rankings/global`) | Tabular list of athletes, ranks 1..N, Elo scores. | Standard data table; rank 1 looks almost identical to rank 50. | Podium top-3 presentation with Gold, Silver, Bronze metallic laurels, country flag integration, delta rank change indicators (+2, -1, NEW). |
| **38. CategoryRankingsScreen** (`/rankings/category`) | Filtered by weight, arm, and division. | Filters are buried in multi-dropdowns. | Horizontal scrolling pill filters with instant reactive table transition; clear division title lockup. |
| **39. AthleteAnalyticsScreen** (`/analytics/athlete`) | Win rate charts, method of victory breakdown. | Plain pie/bar charts; lacks fight analyst polish. | Victory method distribution ring (Pin, Foul, Strap, Technical), Arm comparison radar, win-streak flame indicator. |
| **40. HeadToHeadScreen** (`/analytics/h2h`) | Two athlete columns with historical match records. | Data is plain text; missed opportunity for epic rivalry breakdown. | Tale of the Tape comparison layout (Height, Weight, Reach, Bicep, Forearm, Elo, Historic Record), win probability gauge. |
| **41. LeaderboardsScreen** (`/rankings/leaderboards`) | Streak leaders, most active athletes, top refs. | Plain list. | Category trophy cards with dynamic crown icons and monthly/all-time toggle. |

---

### Domain 7: Governance & Federation Operations (Screens 42–47)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **42. FederationDashboardScreen** (`/federation/dashboard`) | Key metrics (Total Athletes, Events, Revenue, Sanctions). | Standard business KPI tiles. | Executive Command Center layout with steel-cut KPI metrics, live regional event map indicator, gold federation crest header. |
| **43. MemberDirectoryScreen** (`/federation/members`) | Paginated member table with search and filter. | Sterile directory. | High-performance virtualized list with instant search, verified license status pills, quick action slide menu. |
| **44. SanctionApplicationScreen** (`/federation/sanctions`) | Form for club/operator requesting official event sanctioning. | Intimidating multi-page form. | Progressively disclosed sanction request stages, insurance upload preview, official sanction seal watermarking. |
| **45. DisciplinaryScreen** (`/federation/disciplinary`) | List of active sanctions, bans, and rule violations. | Looks like an email inbox. | Official legal decree card styling, suspension severity tags (Warning, Suspended, Expelled), case evidence attachments. |
| **46. FinancialOverviewScreen** (`/federation/financials`) | Revenue charts, event sanction fee breakdowns. | Basic accounting view. | Institutional revenue cards, transaction ledger with status indicators, export statement action dock. |
| **47. PolicyDocumentsScreen** (`/federation/policies`) | PDF/document list with download buttons. | Plain link list. | Formal document cards with version numbers, adoption dates, and official signature seals. |

---

### Domain 8: Provincial & Regional Federation (Screens 48–51)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **48. ProvincialDashboardScreen** (`/provincial/dashboard`) | Regional event list, athlete counts by district. | Similar to generic admin dashboard. | Regional jurisdiction map header, district performance metrics, urgent sanction requests banner. |
| **49. DistrictRosterScreen** (`/provincial/districts`) | District athlete listings. | Flat list. | District club breakdown cards with active sparring venues and verified coaches. |
| **50. RegionalEventApprovalsScreen** (`/provincial/event-approvals`) | Pending event queue with approve/reject actions. | Basic review form. | Side-by-side venue safety checklist, sanction fee clearance indicator, one-tap approval with signature confirmation. |
| **51. RegionalRankingsScreen** (`/provincial/rankings`) | Regional Elo rankings. | Duplicate of global view without regional pride. | Regional championship banner, local qualification cutoff lines, regional trophy badges. |

---

### Domain 9: Tournament Operator Console (Screens 52–56)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **52. OperatorDashboardScreen** (`/operator/dashboard`) | Tournament status overview, live tables, staff check-in. | Information density lacks hierarchy during chaotic event management. | High-visibility command bridge with active table status grid, emergency announcement broadcast bar, next-up athlete queue counter. |
| **53. CreateTournamentScreen** (`/operator/create-tournament`) | Multi-section tournament setup wizard. | Cluttered input fields; risk of misconfigured double-elimination parameters. | Visual tournament format selector (Double Elimination, Round Robin, Super Match) with interactive rule toggles, prize pool configuration card. |
| **54. ManageDivisionsScreen** (`/operator/divisions`) | Weight and arm class configurator. | Text list with checkboxes. | Drag-and-drop division reordering, weight class preset templates (WAF, IFA, WAL, Custom), registered athlete count chips. |
| **55. RefereeAssignmentScreen** (`/operator/referees`) | Table-to-referee assignment matrix. | Table grid is hard to scan rapidly. | Visual table allocation slots with referee availability status, shift rotation timer, certification match validation. |
| **56. TournamentResultsPublishScreen** (`/operator/publish-results`) | Final standings list and "Publish to Global Elo" CTA. | Lacks gravity of locking permanent world rankings. | Irreversible action confirmation dialog with two-key security challenge, official audit checklist, public results preview modal. |

---

### Domain 10: Compliance & Integrity (Screens 57–60)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **57. ComplianceDashboardScreen** (`/compliance/dashboard`) | Anti-doping queue, age verification requests, incident reports. | Standard task manager look. | High-security integrity monitor layout with urgency sorting, encrypted case badges, chain-of-custody tracking indicators. |
| **58. AntiDopingTestingScreen** (`/compliance/anti-doping`) | Drug testing sample ID registry and lab result statuses. | Generic form. | Official WADA/Federation testing chain-of-custody cards, blind sample ID masking, certified lab confirmation attachments. |
| **59. AgeVerificationScreen** (`/compliance/age-verification`) | Document review queue (ID / Passport / Birth Certificate). | Split view is cramped. | Secure document inspection viewer with pan/zoom, zoom magnifier, official approval/rejection reason macro-buttons. |
| **60. IncidentReportingScreen** (`/compliance/incidents`) | Safety violations, unsportsmanlike conduct log. | Form lacks context attachments. | Incident timeline scrubber with video evidence link, involved party tags, disciplinary recommendation selector. |

---

### Domain 11: Settings, Support & System (Screens 61–66)
| Screen ID & Route | Current Visual State | Identified Gaps | Elevation Requirements |
| :--- | :--- | :--- | :--- |
| **61. SettingsScreen** (`/settings`) | List of preference tiles (Theme, Notifications, Language). | Standard iOS/Android settings list. | Premium metallic category groupings (Account Security, Athletic Profile, Display & Motion, Audio & Haptics, Legal), version footer. |
| **62. NotificationPreferencesScreen** (`/settings/notifications`) | Switch toggles for match alerts, challenges, news. | Flat switches. | Precision custom toggle switches with micro-haptic clicks, notification preview mockups demonstrating alert appearance. |
| **63. SecuritySettingsScreen** (`/settings/security`) | 2FA setup, active sessions, change password. | Plain buttons. | Biometric authentication status shield, active device session cards with remote logout CTA, 2FA recovery key backup card. |
| **64. HelpCenterScreen** (`/support/help`) | FAQ accordion, search bar, contact button. | Utilitarian FAQ. | Search bar with instant suggestion pills, category cards with clean iconography, federated escalation ticket status tracker. |
| **65. SubmitTicketScreen** (`/support/submit-ticket`) | Form for bug report or inquiry. | Generic feedback form. | Auto-diagnostics attachment preview (App version, OS, Device model, Network state), priority urgency selector. |
| **66. SystemAdminScreen** (`/admin/system`) | Cache controls, database sync stats, log viewer. | Raw technical metrics. | Industrial server telemetry gauges, real-time sync heartbeat indicator, granular cache purge triggers with confirmation locks. |

---

## 4. Priority Elevation Tiers for Implementation

To ensure non-destructive execution, all 66 screens are grouped into 4 distinct implementation tiers:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 1: HIGH-IMPACT FLAGSHIP SCREENS (18 Screens)                           │
│ Critical touchpoints that define user perception, athletic excitement, and  │
│ core competition. First to receive Flow imagery, custom motion & haptics.  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 01. LoginScreen                   07. AthleteHomeScreen                     │
│ 06. RoleIntentScreen              08. AthleteProfileScreen                  │
│ 09. OnboardingScreen              16. TournamentListScreen                  │
│ 17. TournamentDetailScreen        18. BracketViewerScreen                   │
│ 19. MatchDetailScreen             24. TournamentLiveStreamScreen            │
│ 26. LiveMatchScorepadScreen       30. CommunityFeedScreen                   │
│ 33. ChallengeScreen               37. GlobalRankingsScreen                  │
│ 40. HeadToHeadScreen              42. FederationDashboardScreen             │
│ 52. OperatorDashboardScreen       Modal 3. CelebrationOverlay               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 2: COMPETITION & ATHLETE WORKFLOW SCREENS (20 Screens)                 │
│ Deep athletic management, training telemetry, and referee operations.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 10. TrainingLogScreen             11. LogWorkoutScreen                      │
│ 12. WorkoutDetailScreen           13. PersonalRecordsScreen                 │
│ 14. AddPRScreen                   15. PRDetailScreen                        │
│ 20. TournamentRegistrationScreen  21. WeighInScreen                         │
│ 22. TableAssignmentScreen         23. BracketManagementScreen               │
│ 25. RefereeDashboardScreen        27. MatchDisputeScreen                    │
│ 28. RefereeCertificationScreen    34. CreateChallengeScreen                 │
│ 38. CategoryRankingsScreen        39. AthleteAnalyticsScreen                │
│ 53. CreateTournamentScreen        54. ManageDivisionsScreen                 │
│ 55. RefereeAssignmentScreen       56. TournamentResultsPublishScreen        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 3: FEDERATION, COMMUNITY & INTEGRITY SCREENS (18 Screens)              │
│ Institutional governance, social connection, and compliance oversight.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 31. CreatePostScreen              32. PostDetailScreen                      │
│ 35. TrainingClubsScreen           36. ClubDetailScreen                      │
│ 41. LeaderboardsScreen            43. MemberDirectoryScreen                 │
│ 44. SanctionApplicationScreen     45. DisciplinaryScreen                    │
│ 46. FinancialOverviewScreen       47. PolicyDocumentsScreen                 │
│ 48. ProvincialDashboardScreen     49. DistrictRosterScreen                  │
│ 50. RegionalEventApprovalsScreen  51. RegionalRankingsScreen                │
│ 57. ComplianceDashboardScreen     58. AntiDopingTestingScreen               │
│ 59. AgeVerificationScreen         60. IncidentReportingScreen               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 4: SYSTEM, SUPPORT & UTILITY SCREENS (10 Screens)                      │
│ Rock-solid foundational settings, security, and developer utilities.        │
├─────────────────────────────────────────────────────────────────────────────┤
│ 02. RegisterScreen                03. ForgotPasswordScreen                  │
│ 04. ResetPasswordScreen           05. VerifyEmailScreen                     │
│ 29. RulebookViewerScreen          61. SettingsScreen                        │
│ 62. NotificationPreferencesScreen 63. SecuritySettingsScreen                │
│ 64. HelpCenterScreen              65. SubmitTicketScreen                    │
│ 66. SystemAdminScreen             Modals 1 & 2                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Audit Verification Sign-Off

- **Total Screens Audited**: 66 Screen Components + 3 Master Modals.
- **Contract Integrity**: 0 breaking changes proposed to routes, models, or state providers.
- **Brand Consistency**: Full alignment with "Raw Iron & Precision Steel" specification.
- **Next Phase Gate**: Approval of `46_MASTER_MEDIA_ASSET_MAP.md` establishing the exact asset inventory and performance budgets.
