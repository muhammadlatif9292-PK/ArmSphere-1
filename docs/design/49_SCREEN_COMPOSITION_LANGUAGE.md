# ArmSphere Stage 4 — Screen Composition Language & 66-Screen Mapping Architecture
**Document Version**: 1.0.0 (Authoritative Stage 4 Architecture)
**Date**: September 26, 2026
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `UI_UX_DESIGN_STATE.md`, & Stage 4 Master Directive
**Scope**: Handheld Combat Ergonomics, Visual Hierarchy Law, One Primary Story Mandate, 8 Experience Modes, Visual Rhythm Curves, Before/After Gap Analysis, and Exhaustive 66-Screen Mapping.

---

## 1. Handheld Combat Ergonomics & Mobile Spatial Law

ArmSphere is first and foremost a **handheld mobile athletic companion**. Unlike desktop dashboards that enjoy widescreen mouse precision, mobile armwrestling interfaces must survive sweat, stadium lighting, physical adrenaline, and single-handed thumb operation.

```
+-----------------------------------------------------------------------------------+
|                        MOBILE HANDHELD THUMB-ZONE MAP                             |
|                                                                                   |
|  [TOP 20% OF VIEWPORT]      HARD REACH ZONE                                       |
|                             * Screen Title / Persistent Orientation Header        |
|                             * Ambient Arena Atmosphere / Status Scrim             |
|                             * Strictly read-only; ZERO critical action CTAs       |
|                                                                                   |
|  [MIDDLE 45% OF VIEWPORT]   NATURAL SCAN ZONE                                     |
|                             * "One Primary Visual Story" Focal Anchor             |
|                             * Match Face-Off / Live Fight Clock / Elo Readout     |
|                             * Secondary Telemetry Rails & Interactive Chips       |
|                                                                                   |
|  [BOTTOM 35% OF VIEWPORT]   HIGH-COMFORT THUMB ZONE                               |
|                             * Primary Operational Action Bar (Sticky 56dp)        |
|                             * Referee Pin Confirm / Weigh-In Submit Triggers      |
|                             * Category Filters & Bottom Sheet Action Triggers     |
|                                                                                   |
|  [PERSISTENT BOTTOM 56dp]   GLOBAL NAVIGATION SHELL                               |
|                             * Home | Discover | Compete/Ref | Community | Profile |
+-----------------------------------------------------------------------------------+
```

### Mobile Composition Laws:
1. **The First Viewport Guarantee**: The single most urgent question on any screen must be answered within the initial 640dp viewport height without scrolling.
2. **Sticky Action Bar Discipline**: Forms with more than 3 fields and critical live actions must anchor their submit CTA to a `StickyBottomActionBar` with keyboard avoidance. Never force an athlete or referee to hunt for a submit button at the bottom of a 2000dp scroll list.
3. **Modal Sheets Over Full-Screen Push**: Contextual actions (division selection, bout rules, referee warnings, comment threads) must open as **Interactive Bottom Sheets** (expanded to 60–85% viewport), preserving background spatial context.

---

## 2. The Visual Hierarchy Law: What, Why, Action

Every screen layout must answer four fundamental cognitive questions within 500 milliseconds:

```
[1. WHAT IS THE FIRST THING I SEE?]  -> Primary Story Focal Anchor (Weight: 50%)
[2. WHAT IS THE SECOND THING I SEE?] -> Immediate Context / Supporting Data (Weight: 30%)
[3. WHAT ACTION SHOULD I TAKE?]     -> High-Contrast Tactile CTA (Weight: 15%)
[4. WHAT CAN I IGNORE UNTIL NEEDED?]-> Tertiary Metadata / Archived Records (Weight: 5%)
```

*RULE: If all elements on a screen have equal visual weight, the screen has zero design hierarchy and is rejected.*

---

## 3. "One Primary Visual Story" Mandate

Major screens must possess exactly **one dominant visual hero**. Secondary content must yield visual authority to this story:

| Screen Archetype | Dominant Visual Story | Primary Focal Anchor | Subordinated Elements |
| :--- | :--- | :--- | :--- |
| **Home Screen** | The Athlete's Immediate Horizon | Active Match Briefing or Upcoming Weigh-In Call | Historical statistics, news feed, general tutorials |
| **Tournament Detail**| Event Identity & Clock | Arena Hero Image + Live Countdown Clock | Fineprint rules, venue address, past results |
| **Match Screen** | Combatant Face-Off & Tension | Head-to-Head Athlete Profiles + Live Fight Clock | Division seed history, previous tournament records |
| **Athlete Profile** | Hard-Won Identity & Mastery | Full-Bleed Athlete Crest + Official Elo Rating | Raw transaction logs, historical weight slips |
| **Rankings Screen** | Competitive Standing & Velocity | Top 3 Podium Cards + User's Current Position | Category filters (subordinated to horizontal rail) |
| **Bracket Viewer** | Path to the Championship | Active Table Match Nodes with Table Glow | Archived loser-bracket past matches |
| **Referee Scorepad** | Unimpeachable Official Authority | Split-Screen Competitor Pin Pads + Foul Counter | System settings, tournament schedule lists |
| **Ceremony Screen** | Championship Triumph | 45° Sweeping Gold Sheen + Medallion Drop | Social share links, technical bout metadata |

---

## 4. 8 Experience Modes (Purpose-Driven Aesthetic Differentiation)

To avoid visual monotony across 66 screens while maintaining a single cohesive DNA, screens are classified into **8 Purpose-Driven Experience Modes**:

```
+-----------------------------------------------------------------------------------+
|                           8 EXPERIENCE MODES MATRIX                               |
|                                                                                   |
|  [MODE A: DISCOVERY]    -> Editorial, atmospheric, inviting. High media hero.    |
|  [MODE B: COMPETITION]  -> Focused, electric, authoritative. Cyan/Crimson tension.|
|  [MODE C: ATHLETE]      -> Identity, pride, progress. Elo telemetry & dyno kg.    |
|  [MODE D: OPERATIONAL]  -> High-speed, high-tactile, ergonomic. 64dp hit targets.|
|  [MODE E: SOCIAL]       -> Human, community, warm. Video thumbnails, feed rails.  |
|  [MODE F: CEREMONIAL]   -> Prestige, emotional, restrained Champagne Gold sheen.  |
|  [MODE G: DATA]         -> Dense, tabular, structured. Double-elimination trees.  |
|  [MODE H: GOVERNANCE]   -> Quiet, institutional, trustworthy. Audit logs & rules. |
+-----------------------------------------------------------------------------------+
```

---

## 5. Visual Rhythm: The 7-Step Emotional Curve

A screen is not a static poster; it is a **scrolling temporal sequence**. High-quality screens orchestrate visual rhythm:

```
[1. OPEN]      -> Monumental Hero (Arena Media, High-Contrast Typography)
     |
[2. FOCUS]     -> Urgent Decision Card (Call to Table, Match Countdown)
     |
[3. PROGRESS]  -> Interactive Segmented Rail (Divisions, Weight Classes)
     |
[4. DENSITY]   -> Tabular Data / Bracket Nodes (High-density telemetry)
     |
[5. RELIEF]    -> Generous Negative Space (Hairline rules, unbordered stats)
     |
[6. ACTION]    -> High-Tactile Interactive Trigger (Sticky Bottom Bar)
     |
[7. RESOLUTION]-> Institutional Federation Seal & Sanctioning Footer
```

---

## 6. Before / After Gap Analysis across Core Archetypes

| Core Area | Current State | Why It Feels Flat / Generic | Elevated ArmSphere Solution | Validation Method |
| :--- | :--- | :--- | :--- | :--- |
| **Entry & Auth** | Plain dark form with text fields and isolated button. | Feels like an internal Jira or database admin tool; zero athletic excitement. | Cinematic arena backdrop with chalk atmosphere, debossed gold insignia, metallic step indicators. | First-impression trust test; user sign-up completion rate. |
| **Home Dashboard** | Vertical list of 6 identical cards dumping all data at once. | Cognitive overload; no single focal point; cards compete for attention. | **Dynamic Briefing Model**: Surfacing the single most urgent context (T-7d to Post-Event) with contextual action rail. | Glanceability test: user identifies next action in <1.2s. |
| **Tournament Detail**| Text list of dates, fees, and rules inside flat gray cards. | Sterile; lacks arena excitement and prestige of a major sports championship. | Full-bleed arena hero backdrop with 4-stop scrim, live tabular fight countdown, sticky registration CTA. | Event registration conversion; visual hierarchy audit. |
| **Athlete Profile** | Avatar circle + table of numbers in uniform font. | Looks like an employee directory or corporate profile card. | Monumental SpaceGrotesk Elo readout, left vs right grip split bar, dual-role switcher with tactile spring. | Athlete pride test; clarity of dual-arm ratings. |
| **Referee Scorepad** | Standard 40dp Material buttons with generic dialogs. | High mis-tap risk during fast live combat; no physical confirmation. | Full-screen 64dp tactile split-pad grid, 400ms continuous hold pin confirmation, instant heavy haptic shock. | Live bout zero-mis-tap validation under high pressure. |
| **Bracket Viewer** | Text-heavy table with horizontal scroll bars. | Incomprehensible on phone; cannot visualize double elimination path. | Virtualized vector bracket canvas with interactive pinch-zoom, active table glow, and auto-scroll to user's match. | Bracket navigation speed; table coordinator efficiency. |
| **Weigh-In Clearance**| Checkbox toggle with standard toast. | Anti-climactic; clearing weigh-in is an athlete's hardest physical milestone. | Physical rubber stamp clearance (140ms scale drop from 1.8x to 1.0x, -8° tilt, heavy haptic thud). | Athlete satisfaction; official verification clarity. |

---

## 7. Exhaustive 66-Screen Mapping Architecture

Every production screen in the ArmSphere codebase is mapped into the unified visual system:

### Domain 1: Auth & Entry Journey (Screens 01–06)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **01** | `SplashScreen` (`/`) | F: Ceremonial | Global Federation Arrival | Gold-embossed Insignia | SpaceGrotesk Wordmark | None (Auto-route) | Void canvas + Gold Halo | Level 4: 1000ms Gold Sheen |
| **02** | `WelcomeScreen` (`/welcome`) | A: Discovery | The Athletic Calling | Brand Value Pillars | Federation Credentials | Sticky Gold Entry CTA | Arena Chalk Silhouette | Level 2: Machined Steel Plate |
| **03** | `RoleIntentScreen` (`/role-intent`)| C: Athlete | Choose Your Arena Role | 3 Pillar Role Cards | Secondary Role Grid | Sticky Confirmation Bar | Metallic Role Badges | Level 3: Tactile Depress (0.97x)|
| **04** | `OnboardingScreen` (`/onboarding`)| C: Athlete | Profile & Division Setup | 3-Step Wizard Progress | Category / Arm Selection | Sticky Next Step Bar | Grip Macro Scrim | Level 2: 280ms Slide PageView |
| **05** | `LoginScreen` (`/login`) | H: Governance | Federation Access Portal | Credential Form Fields | Biometric Quick Unlock | Sticky Gold Submit Bar | Substrate Void + Top Sheen | Level 3: Active Cyan Border |
| **06** | `RegisterScreen` (`/register`) | H: Governance | Create Official Passport | Step 1/2 Account Form | Sanctioning Terms Card | Sticky Create Passport CTA | Substrate Void + Top Sheen | Level 3: Active Cyan Border |

### Domain 2: Core Discovery & Navigation (Screens 07–12)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **07** | `MainShellScreen` (`/shell`) | H: Governance | Global Spatial Anchor | Active Destination Canvas | Persistent Navigation Rail | Bottom 56dp Shell Bar | None (Structural) | Level 1: 0ms Instant Swap |
| **08** | `HomeScreen` (`/home`) | C: Athlete | Dynamic Athletic Horizon | Urgency Context Card | Quick Training / Feed Rail | Hero Action Trigger | Hero Arena Backdrop Scrim | Level 2: 250ms Cascade Entry |
| **09** | `DiscoverScreen` (`/discover`) | A: Discovery | Worldwide Championships | Featured Event Showcase | Federation Hub Portals | Sticky Search Bar | Full-Bleed Tournament Media | Level 2: Horizontal Carousel |
| **10** | `SearchScreen` (`/search`) | G: Data | Global Directory Search | 300ms Debounced Search Bar | Category Segmented Chips | Live Filter Chips | None (Search Density) | Level 3: High-Contrast Inputs |
| **11** | `NotificationsScreen` (`/notifications`)| B: Competition| Event & Call-to-Table Alerts| Urgent Unread Alerts | Activity Stream Archive | Mark All Read Action | Status Badges (Crimson/Cyan) | Level 2: Alternating List |
| **12** | `SettingsScreen` (`/settings`) | H: Governance | Platform & Sensory Config | Haptic / Audio Toggles | Account & Security Group | Save Preferences CTA | None (Clean Settings) | Level 2: Grouped Rail Sections |

### Domain 3: Tournament & Competition (Screens 13–20)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **13** | `TournamentDetailScreen` (`/tournaments/:id`) | B: Competition | Championship Event Identity | Arena Hero + Fight Countdown | Division Matrix & Timeline | Sticky Register CTA | Full-Bleed Scrim 4-Stop | Level 2: Hero to Sticky Bar |
| **14** | `EventRegistrationScreen` (`/tournaments/:id/register`) | H: Governance | Division & Weight Lock | Weight Class Selector | Liability & Waiver Cards | Sticky Payment / Submit Bar | Sanctioning Badge | Level 3: Stepper Wizard |
| **15** | `BracketViewerScreen` (`/tournaments/:id/bracket`) | G: Data | The Road to the Crown | Interactive Table Nodes | Competitor Seeds & Bye Tags| Floating Zoom & Table Filter| High-Contrast Vector Lines | Level 4: Active Table Pulse |
| **16** | `LiveBoutScreen` (`/bouts/:id`) | B: Competition | Combat Tension at Table | Split Competitors + Clock | Foul Count & Strap State | Referee Control Floating Pad| Arena Spotlight Vignette | Level 4: 1Hz Live Table Pulse |
| **17** | `WeighInScreen` (`/tournaments/:id/weigh-in`) | D: Operational| Official Weight Verification | Digital Scale Telemetry | Weight Allowance Variance | Sticky Approve / Reject Bar| Scale Hardware Status | Level 5: Rubber Stamp Drop |
| **18** | `TournamentScheduleScreen` (`/tournaments/:id/schedule`) | G: Data | Table Time & Bouts Agenda | Active Table Running Clock | Queued Bout Order Rails | Table Selector Strip | Chronometer Telemetry | Level 2: Timeline Track Rail |
| **19** | `TournamentLeaderboardScreen` (`/tournaments/:id/leaderboard`) | F: Ceremonial | Event Champions & Medals | Top 3 Podium Cards | Team & Division Points | Category Filter Rail | Gold / Silver / Bronze Medals| Level 4: 45° Gold Sheen |
| **20** | `TournamentRulesScreen` (`/tournaments/:id/rules`) | H: Governance | Official WAF/IFA Rulebook | Weight Limits & Fouls | Grip & Strap Protocols | Download Rulebook PDF | Federation Watermark | Level 1: Editorial Typography |

### Domain 4: Athlete Performance & Profile (Screens 21–28)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **21** | `AthleteProfileScreen` (`/athletes/:id`) | C: Athlete | Competitor Legacy & Rating | Full-Bleed Crest + Elo | Grip Dyno & Bout History | Challenge / Follow CTA | High-Contrast Silhouette | Level 2: Hero Parallax |
| **22** | `AthleteEditProfileScreen` (`/profile/edit`) | H: Governance | Official Passport Details | Photo Upload + Club Field | Weight Class Preferences | Sticky Save Changes Bar | Avatar Cropper Interface | Level 3: Form Inset Plates |
| **23** | `EloHistoryScreen` (`/athletes/:id/elo`) | G: Data | Rating Trajectory & Peaks | Monoline Elo Vector Graph | Milestone Upsets List | Time Range Filter (1Y/All)| Minimalist Grid Axis | Level 2: Sparkline Smooth Path|
| **24** | `GripAnalyticsScreen` (`/athletes/:id/grip`) | G: Data | Left vs Right Arm Dominance | Comparative Dual-Bar Dyno | Endurance Curve Telemetry | Connect Hardware Dyno | Dyno Split Visualization | Level 3: Real-Time Force Gauge|
| **25** | `MatchHistoryScreen` (`/athletes/:id/matches`) | G: Data | Career Bout Log | Chronological Match Feed | Round Splits & Win Methods | Arm Filter (Left/Right) | Victory Emerald / Loss Red | Level 2: Hairline Bout List |
| **26** | `PersonalRecordsScreen` (`/athletes/:id/records`) | F: Ceremonial | Peak Strength Hall of Fame | PR Trophy Cards | Table Pins & Heavy Holds | Add New Certified PR | Gold Sheen Borders | Level 4: Medallion Glow |
| **27** | `AthleteBadgeVaultScreen` (`/athletes/:id/badges`) | F: Ceremonial | Earned Federation Honors | 3D Metallic Badge Grid | Certification Credentials | Share Badge Portfolio | Debossed Metal Emblems | Level 3: Tactile Badge Tilt |
| **28** | `RoleSwitchScreen` (`/profile/switch-role`) | H: Governance | Federation Persona Portal | Dual-Role Segmented Cards | Active Credential Badges | Instant Switch Tap | Metallic Role Crests | Level 4: 200ms Spring Flip |

### Domain 5: Referee & Table Operations (Screens 29–36)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **29** | `RefereeHubScreen` (`/referee`) | D: Operational| Active Table Assignments | Current Table Status Card | Queued Bout Roster | Check In Table CTA | Table Number Hero Badge | Level 2: Operational Steel |
| **30** | `RefereeScorepadScreen` (`/referee/scorepad`) | D: Operational| Live Table Split Officiating | 64dp Left/Right Pin Pads | Foul Counters & Warning Ticks| 400ms Pin Hold Trigger | Combat Red / Emerald Pads | Level 3: Heavy Tactile Thud |
| **31** | `FoulDisputeScreen` (`/referee/dispute`) | D: Operational| Table Review & Sanctions | Foul Classification Grid | Video Replay Marker | Submit Final Ruling CTA | Warning Amber Indicator | Level 4: High-Contrast Alert |
| **32** | `TableRosterScreen` (`/referee/roster`) | D: Operational| Next Competitors at Table | On-Deck Athlete Pair | Weight Class Check Status | Call to Table Audio Broadcast| Competitor Avatars | Level 2: High-Density List |
| **33** | `RefereeCertificationsScreen` (`/referee/certs`) | H: Governance | Master Official Credentials | WAF Official Grade Badge | Completed Seminar Logs | Renew Federation License | Official Federation Seal | Level 2: Document Credential |
| **34** | `RefereeIncidentLogScreen` (`/referee/incidents`) | H: Governance | Official Sanction Reports | Incident Categorization | Referee Signature Field | Submit Official Incident | Adrenaline Red Accents | Level 3: Form Inset Plates |
| **35** | `StrapApplicationScreen` (`/referee/straps`) | D: Operational| Table Strap Timer & Lock | 60s Strap Setup Timer | Slip Assessment Checklist | Straps Applied Lock Bar | Canvas Strap Graphic | Level 4: Chrono Countdown |
| **36** | `RefereeScorecardAuditScreen` (`/referee/audit`) | G: Data | Post-Bout Official Ledger | Complete Bout Score Breakdown| Time Stamps & Referee Sign | Sign & Transmit to Cloud | Digital Signature Surface | Level 2: High-Density Table |

### Domain 6: Federation & Organizer Console (Screens 37–44)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **37** | `OrganizerDashboardScreen` (`/organizer`) | H: Governance | Tournament War Room | Live Tables Active Status | Registered Athletes Counter | Create New Tournament CTA | Venue Blueprint Overview | Level 2: Multi-Table Ticker |
| **38** | `CreateTournamentScreen` (`/organizer/new`) | H: Governance | Event Sanctioning Setup | Stepper Event Metadata | Venue & Weigh-In Schedule | Sticky Publish Event Bar | Arena Blueprint Upload | Level 3: Stepper Plates |
| **39** | `ManageDivisionsScreen` (`/organizer/divisions`) | G: Data | Weight Class Matrix | Division Configuration Grid | Competitor Count per Class | Add Custom Class CTA | Weight Scale Iconography | Level 2: Compact Rows |
| **40** | `TableAssignmentScreen` (`/organizer/tables`) | D: Operational| Venue Table Distribution | Table 1–8 Hardware Matrix | Assigned Officials List | Drag-Drop Match Assignment | Table Status Badges | Level 3: Grid Reorder |
| **41** | `AthleteCheckInScreen` (`/organizer/check-in`) | D: Operational| Gate & Weigh-In Scan | QR Scanner Viewport | Verification Badge Popover | Manual ID Check Override | Live Camera Scrim | Level 4: Scanner Laser Bar |
| **42** | `SanctioningComplianceScreen` (`/organizer/sanctions`)| H: Governance| International Compliance | Federation Sanction Seal | Medical & Anti-Doping Checks | Request Sanction Review | Official WAF Ribbon | Level 2: Compliance Checklist |
| **43** | `VenueManagementScreen` (`/organizer/venue`) | H: Governance | Venue Logistics & Tables | Arena Map & Table Layout | Power & Network Telemetry | Save Venue Configuration | Arena Floorplan Vector | Level 2: Interactive Map |
| **44** | `FinancialLedgerScreen` (`/organizer/finances`) | G: Data | Entry Fees & Payouts | Total Revenue & Prize Pool | Payout Status per Division | Export Financial Audit CSV | Monospace Numbers | Level 2: Tabular Ledger |

### Domain 7: Training & Athletic Progression (Screens 45–50)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **45** | `TrainingHubScreen` (`/training`) | C: Athlete | Daily Combat Preparation | Current Cycle / Workouts | Grip Work & Recovery Status | Log Today's Session CTA | Gym Heavy Iron Backdrop | Level 2: Progress Ring |
| **46** | `TrainingLogScreen` (`/training/log`) | C: Athlete | Exercise & Load Input | Dynamic Exercise Picker | Sets, Reps, RPE Sliders | Sticky Save Workout Bar | Chalk Dust Vignette | Level 3: Haptic Slider Ticks |
| **47** | `ArmwrestlingTechniqueScreen` (`/training/technique`)| A: Discovery| Biomechanical Mastery | Toproll vs Hook Analysis | Vector Leverage Diagrams | Video Breakdown Modal | High-Contrast Anatomical Vector| Level 2: Video Card Thumbnail |
| **48** | `WorkoutDetailScreen` (`/training/workouts/:id`)| C: Athlete | Session Breakdown & Volume | Total Tonnage & Arm Load | Exercise Sequence Rail | Start Guided Workout CTA | Table Grip Photography | Level 2: Sequential Step Cards|
| **49** | `RecoveryTrackerScreen` (`/training/recovery`) | C: Athlete | Tendon & Joint Readiness | Forearm Inflammation Meter | Sleep & Nutrition Readiness | Log Rest Day CTA | Tendon Tension Gauge | Level 3: Segmented Health Bar|
| **50** | `StrengthBenchmarkScreen` (`/training/benchmarks`)| G: Data | Global Strength Standards | User vs World Record Split | Pronation & Riser Kilograms | Test Benchmark Mode | Tabular Standard Bars | Level 2: Comparative Metric |

### Domain 8: Rankings & Global League (Screens 51–56)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **51** | `GlobalRankingsScreen` (`/rankings`) | G: Data | The World's Elite | Top 3 Podium Showcase | Full Leaderboard List | Division & Arm Switcher | Gold, Silver, Bronze Crests | Level 2: Tabular Roster Rows |
| **52** | `DivisionLeaderboardScreen` (`/rankings/:division`) | G: Data | Weight Class Supremacy | #1 Reigning Champion Card | Competitor Ranks #2 to #50 | Rank Delta Filter (Up/Down) | Championship Belt Badge | Level 3: Active User Highlight|
| **53** | `NationalRankingsScreen` (`/rankings/national`) | G: Data | Country Rank & Eligibility | National Champion Profile | State / Provincial Rosters | Select Country Modal | National Federation Flag | Level 2: High-Density Table |
| **54** | `HeadToHeadScreen` (`/compare`) | B: Competition| Face-Off Statistical Rivalry| Side-by-Side Athlete Cards | Historic Bouts & Win Ratios | Share Comparison Poster | Dual Athlete Silhouettes | Level 3: Versus Tension Split |
| **55** | `HallOfFameScreen` (`/hall-of-fame`) | F: Ceremonial | Armwrestling Legends | Iconic Master Champion | Historic Titles & Legacy | Read Hall of Fame Biography | Sepia-Toned Arena Scrim | Level 4: Gold Specular Sheen |
| **56** | `TitleBeltTrackerScreen` (`/title-belts`) | F: Ceremonial | Heavyweight World Titles | Active Championship Belt | Title Defenses & History | View Mandatory Contenders | High-Detail Title Belt Plate | Level 4: 45° Sweeping Gold |

### Domain 9: Community & Social Network (Screens 57–62)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **57** | `CommunityFeedScreen` (`/community`) | E: Social | The Armwrestling Fraternity | Top Video Training Post | Community Sparring Clips | Floating Create Post CTA | 16:9 Video Thumbnails | Level 2: Media Post Containers |
| **58** | `CreatePostScreen` (`/community/new`) | E: Social | Share Table Footage | Media Upload Viewport | Caption & Tag Athlete Form | Sticky Post to Feed Bar | Selected Video Preview | Level 3: Form Inset Surface |
| **59** | `PostDetailScreen` (`/community/posts/:id`)| E: Social | Discussion & Technical Breakdown| Embedded Video Player | Comment Thread Stream | Sticky Comment Input Bar | Video Player with Scrim | Level 2: Threaded Comment List|
| **60** | `ClubFinderScreen` (`/clubs`) | A: Discovery | Find a Sparring Table Near You | Interactive Map Viewport | Local Armwrestling Clubs | Filter by Radius (km) | Map Marker Pins | Level 3: Floating Card Sheet |
| **61** | `ClubDetailScreen` (`/clubs/:id`) | A: Discovery | Local Practice & Coaches | Club Arena Hero + Schedule | Active Members Roster | Join Practice Session CTA | Club Table Photo Scrim | Level 2: Editorial Club Sheet |
| **62** | `SparringRequestScreen` (`/sparring/new`) | C: Athlete | Challenge a Local Heavyweight | Sparring Date & Table Location| Preferred Arm & Weight Match | Send Sparring Challenge CTA | Clashed Grips Iconography | Level 3: Tactical Challenge Pad|

### Domain 10: Governance, Integrity & System (Screens 63–66)
| ID | Screen Name & Route | Mode | Primary Story | Primary Focus | Secondary Content | Action Zone | Media / Scrim | Surface / Motion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **63** | `AntiDopingPolicyScreen` (`/integrity/anti-doping`) | H: Governance| Clean Combat Sports Charter | WADA Compliance Charter | Prohibited Substances List | Acknowledge & Sign Charter | Official Integrity Badge | Level 1: Editorial Document |
| **64** | `SubmitComplaintScreen` (`/integrity/complaint`) | H: Governance| Formal Grievance & Appeal | Incident Description & Evidence| Upload Match Video Clip | Sticky Submit Grievance Bar | Red Warning Accent Banner | Level 3: Form Inset Plates |
| **65** | `FederationCharterScreen` (`/federation/charter`) | H: Governance| Constitution & Bylaws | Official Articles of Governance| Executive Committee Structure | View Official Statutes | Gold Embossed Federation Crest| Level 1: Monumental Headings |
| **66** | `AuditLogScreen` (`/system/audit`) | G: Data | Immutable Database Records | Real-Time Sync & Drizzle Logs| Offline SQLite Sync State | Force Sync & Diagnostics CTA | Tabular Monospace Readout | Level 2: High-Density Ledger |

---

## 8. Architectural Sign-Off
This composition specification provides a complete, unambiguous blueprint for every screen in the ArmSphere mobile product. No AI or human engineer will ever need to invent ad-hoc layouts, arbitrary margins, or unapproved experience modes.
