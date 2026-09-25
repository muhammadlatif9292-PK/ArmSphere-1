# ArmSphere Master Screen Inventory
**Exhaustive Ledger of All 66 User-Facing Screen Classes & Modals**
**Document Version**: 1.0.0
**Source Authority**: Verified from `apps/mobile/lib` AST inspection & `app_router.dart`
**Status**: APPROVED & LOCKED

---

## 1. Screen Taxonomy & Distribution

The ArmSphere mobile application consists of **66 distinct user-facing screen classes** partitioned across 11 functional domains:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SCREEN DOMAIN BREAKDOWN                         │
├────┬───────────────────────────────┬──────────────┬───────────────────┤
│ ID │ Domain                        │ Screen Count │ Primary Audience  │
├────┼───────────────────────────────┼──────────────┼───────────────────┤
│ D1 │ Entry, Boot & Authentication  │ 10 Screens   │ All Users / Guests│
│ D2 │ Shell & Personalized Hubs     │ 04 Screens   │ All Roles         │
│ D3 │ Athlete & Competitor Profiles │ 08 Screens   │ Athletes & Fans   │
│ D4 │ Tournaments & Operations      │ 04 Screens   │ Athletes & Ops    │
│ D5 │ Referee & Official Scoring    │ 06 Screens   │ Certified Refs    │
│ D6 │ Governance & Arbitration      │ 03 Screens   │ Compliance & Users│
│ D7 │ Community & Video Social      │ 04 Screens   │ All Athletes      │
│ D8 │ Direct Messaging & Broadcasts │ 04 Screens   │ All Athletes      │
│ D9 │ Venues & Grassroots Meetups   │ 06 Screens   │ Local Pullers     │
│ D10│ Clubs, Teams & Championships  │ 05 Screens   │ Teams & Champions │
│ D11│ Account Settings & Security   │ 12 Screens   │ Signed-In Users   │
├────┼───────────────────────────────┼──────────────┼───────────────────┤
│    │ **TOTAL SCREEN CLASSES**      │ **66 Screens**│                   │
└────┴───────────────────────────────┴──────────────┴───────────────────┘
```

---

## 2. Complete Screen-by-Screen Directory

### Domain 1: Entry, Boot & Authentication (10 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **01** | `SplashScreen` | `features/auth/screens/splash_screen.dart` | `/` | All | App launch animation, branding logo, session restoration check. |
| **02** | `WelcomeScreen` | `features/auth/screens/welcome_screen.dart` | `/welcome` | Unauth | Cold open landing page, federation mission, sign in / sign up CTAs. |
| **03** | `LoginScreen` | `features/auth/screens/login_screen.dart` | `/login` | Unauth | Email/password login form, forgot password link, MFA redirect. |
| **04** | `RegisterScreen` | `features/auth/screens/register_screen.dart` | `/register` | Unauth | Account creation form, email, password strength meter, terms checkbox. |
| **05** | `ForgotPasswordScreen` | `features/auth/screens/forgot_password_screen.dart` | `/forgot-password` | Unauth | Email password recovery initiation, reset link instructions. |
| **06** | `ResetPasswordScreen` | `features/auth/screens/reset_password_screen.dart` | `/reset-password` | Unauth | Password token verification, new password entry & confirmation. |
| **07** | `MfaSetupScreen` | `features/auth/screens/mfa_setup_screen.dart` | `/mfa/setup` | Auth | TOTP QR code display, manual secret key copy, confirmation code. |
| **08** | `MfaVerificationScreen` | `features/auth/screens/mfa_verification_screen.dart` | `/mfa/verify` | Auth (MFA) | 6-digit TOTP challenge input, recovery code fallback toggle. |
| **09** | `RecoveryCodesScreen` | `features/auth/screens/recovery_codes_screen.dart` | `/recovery-codes` | Auth | 10 single-use emergency cryptographic backup codes display & copy. |
| **10** | `RoleIntentScreen` | `features/auth/screens/role_intent_screen.dart` | `/role-intent` | Auth (New) | Post-signup intent picker (Athlete, Referee, Organizer, Club Leader). |

---

### Domain 2: Shell & Personalized Hubs (4 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **11** | `MainShellScreen` | `core/widgets/main_shell_screen.dart` | Shell (All) | All | Persistent 5-branch navigation shell (`Home`, `Discover`, `Competitions`, `Community`, `Profile`). |
| **12** | `RoleAwareHomeScreen` | `core/routing/app_router.dart` | `/home` | All | Role-based dispatcher widget routing to Athlete, Referee, or Governance dashboard. |
| **13** | `AthleteDashboardScreen` | `features/athlete/screens/athlete_screens.dart` | `/athlete/dashboard` | Athlete | Dual ELO ratings (Right/Left), shortcuts, recent matches, training PRs. |
| **14** | `DiscoverScreen` | `features/home/screens/discover_screen.dart` | `/discover` | All | Federation discovery hub: announcements, upcoming tournaments, top rankings. |

---

### Domain 3: Athlete & Competitor Profiles (8 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **15** | `OnboardingScreen` | `features/athlete/screens/onboarding_screen.dart` | `/onboarding` | Auth (New) | 3-step profile builder: 1) Identity, 2) Location/Province, 3) Physical Specs. |
| **16** | `AthleteProfileScreen` | `features/athlete/screens/athlete_screens.dart` | `/athlete/profile` | Auth | Personal profile hub: photo, biometrics (weight, height, reach), settings link. |
| **17** | `PublicAthleteProfileScreen`| `features/athlete/screens/public_profile_screen.dart`| `/athlete/:athleteId`| All | Competitor profile view: verified badge, ELO ratings, follow toggle, chat CTA. |
| **18** | `FollowersListScreen` | `features/athlete/screens/followers_list_screen.dart` | `/athlete/:id/followers`| All | Scrollable list of athletes following the target profile with follow toggles. |
| **19** | `FollowingListScreen` | `features/athlete/screens/followers_list_screen.dart` | `/athlete/:id/following`| All | Scrollable list of athletes followed by the target profile. |
| **20** | `AthleteTrainingLogScreen` | `features/athlete/screens/training_log_screen.dart` | `/athlete/:id/training-log`| All | Historical workout lifts, exercise chips (bicep, wrench, cup), PR stats. |
| **21** | `RankingsScreen` | `features/athlete/screens/rankings_screen.dart` | `/rankings` | All | National ELO ladder: arm toggle (Right/Left), province filters, athlete rows. |
| **22** | `AthleteAchievementsScreen`| `features/athlete/screens/athlete_screens.dart` | `/achievements` | All | Certified medal honors, gold/silver/bronze badges, cryptographic SHA-256 seals. |

---

### Domain 4: Tournaments & Operations (4 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **23** | `TournamentsListScreen` | `features/tournament/screens/tournament_screens.dart` | `/tournaments` | All | Sanctioned events list: date, venue city, registration fee, capacity, status. |
| **24** | `TournamentDetailScreen` | `features/tournament/screens/tournament_screens.dart` | `/tournament/:id` | All | Event briefing: countdown timer, prize pool, weight grid, rules, schedule. |
| **25** | `EventRegistrationScreen` | `features/tournament/screens/event_registration_screen.dart`| `/tournament/:id/register`| Athlete | Division, weight class, arm selection, Stripe checkout or manual QR fee flow. |
| **26** | `TournamentOperationsScreen`| `features/tournament/screens/tournament_operations_screen.dart`| `/tournament/:id/operations`| Operator | Operator desk: registration approvals, weigh-in measurements, bracket draw. |

---

### Domain 5: Referee & Official Scoring (6 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **27** | `RefereeDashboardScreen` | `features/referee/screens/referee_screens.dart` | `/referee/dashboard` | Referee | Official dashboard: assigned tournament events, match board, table calls. |
| **28** | `OfficialScorepadScreen` | `features/referee/screens/official_scorepad_screen.dart`| Custom modal/route | Referee | Table-side scoring: set points, fouls, warnings, pins, timer, submit scorepad. |
| **29** | `MatchSubmissionScreen` | `features/referee/screens/referee_screens.dart` | `/referee/submit-scorepad`| Referee | Formal match result confirmation and ELO recalculation trigger. |
| **30** | `RefereeCertificationsScreen`| `features/referee/screens/referee_screens.dart` | `/referee/certifications` | Referee | Official license display, certification grade, expiration date, match counts. |
| **31** | `AthleteSearchScreen` | `features/referee/screens/referee_screens.dart` | `/referee/search-athletes`| Referee | Official competitor lookup during weigh-ins and table roll-calls. |
| **32** | `EvidenceUploadScreen` | `features/referee/screens/referee_screens.dart` | `/referee/upload-evidence` | Referee | Scorepad photo, incident report, and video proof upload engine. |

---

### Domain 6: Governance & Arbitration (3 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **33** | `GovernanceDashboardScreen` | `features/governance/screens/governance_screens.dart` | `/governance` | Governance | Arbitration hub: active dispute cases list, status badges, resolution tools. |
| **34** | `DisputeDetailScreen` | `features/governance/screens/governance_screens.dart` | `/governance/dispute/:id` | All Involved | Case review: complaint statement, referee evidence, formal committee verdict. |
| **35** | `SubmitComplaintScreen` | `features/governance/screens/submit_complaint_screen.dart`| `/governance/submit-complaint`| All Auth | Formal dispute filing form: event selection, respondent, violation categories. |

---

### Domain 7: Community & Video Social (4 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **36** | `CommunityFeedScreen` | `features/community/screens/community_feed_screen.dart` | `/community/feed` | All | Video feed of training lifts, matches (YouTube, TikTok, FB), likes, comments. |
| **37** | `CreatePostScreen` | `features/community/screens/create_post_screen.dart` | `/community/create` | Athlete | Post creation form: external video URL input, platform detection, caption. |
| **38** | `PostCommentsScreen` | `features/community/screens/post_comments_screen.dart` | `/community/posts/:id/comments`| All | Chronological discussion thread beneath a community post, comment composer. |
| **39** | `VideoPlayerModal` | `features/community/screens/video_player_modal.dart` | Modal | All | Clean in-app WebView player for external video URLs with close button. |

---

### Domain 8: Direct Messaging & Broadcasts (4 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **40** | `ConversationsListScreen` | `features/messaging/screens/messaging_screens.dart` | `/messages` | All Auth | Inbox list: other participant avatar, name, last snippet, unread counter. |
| **41** | `ChatScreen` | `features/messaging/screens/messaging_screens.dart` | `/messages/:id` | All Auth | Real-time chat: message bubbles, delivery state, text composer, attachment. |
| **42** | `AnnouncementsListScreen` | `features/messaging/screens/announcement_screens.dart`| `/announcements` | All | Federation broadcasts, executive circulars, rule changes, schedule updates. |
| **43** | `NotificationsListScreen` | `features/notifications/screens/notification_screens.dart`| `/notifications` | All Auth | Push alert inbox: match callouts, tournament registration notices, comments. |

---

### Domain 9: Venues & Grassroots Meetups (6 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **44** | `VenueDirectoryScreen` | `features/venue/screens/venue_directory_screen.dart` | `/venues` | All | Directory of approved training gyms with official armwrestling tables. |
| **45** | `VenueDetailScreen` | `features/venue/screens/venue_detail_screen.dart` | `/venues/:venueId` | All | Gym profile: address, table inventory, operating hours, phone, map link. |
| **46** | `SubmitVenueScreen` | `features/venue/screens/submit_venue_screen.dart` | `/venues/submit` | All Auth | Submit new training venue for federation verification: name, tables, photos. |
| **47** | `InformalEventDirectoryScreen`| `features/informal_event/screens/informal_event_directory_screen.dart`| `/informal-events` | All | Local practice meetups, pickup pulling sessions, sparring locations. |
| **48** | `InformalEventDetailScreen` | `features/informal_event/screens/informal_event_detail_screen.dart`| `/informal-events/:id` | All | Meetup details: host, time, table address, attending athlete roster, RSVP. |
| **49** | `CreateInformalEventScreen` | `features/informal_event/screens/create_informal_event_screen.dart`| `/informal-events/create`| All Auth | Host meetup form: title, date, start time, location, table details. |

---

### Domain 10: Clubs, Teams & Championships (5 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **50** | `TeamsListScreen` | `features/team/screens/team_screens.dart` | `/teams` | All Auth | User's joined clubs and teams list, team creation button. |
| **51** | `CreateTeamScreen` | `features/team/screens/team_screens.dart` | `/teams/create` | All Auth | New club/team creation form: team name, city, province, logo picker. |
| **52** | `TeamDetailScreen` | `features/team/screens/team_screens.dart` | `/teams/:teamId` | All Auth | Club profile: captain badge, athlete roster with ELO stats, captain controls. |
| **53** | `ChampionshipsListScreen` | `features/championship/screens/championship_screens.dart`| `/championship/titles` | All | National title belts catalog: weight classes, arms, reigning champions. |
| **54** | `ChampionshipDetailScreen`| `features/championship/screens/championship_screens.dart`| `/championship/:id` | All | Title lineage ledger: current reign, defenses count, historic champions list. |

---

### Domain 11: Account Settings, Security & Compliance (12 Screens)

| # | Screen Class | File Path | Route Path | Roles | Purpose & Core Layout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **55** | `SettingsHubScreen` | `features/settings/screens/settings_hub_screens.dart` | `/settings` | All Auth | Main settings menu: Profile, Biometrics, Security, Payments, Tickets, Legal. |
| **56** | `ActiveSessionsListScreen` | `features/session/screens/session_screens.dart` | `/session` | All Auth | Device audit: list of active signed-in devices, IPs, user agents, revocation. |
| **57** | `ActiveSessionControlScreen`| `features/session/screens/session_screens.dart` | `/athlete/session/:id` | All Auth | Specific session deep dive, security anomaly details, remote sign-out CTA. |
| **58** | `PaymentMethodsScreen` | `features/settings/screens/payment_methods_screen.dart`| `/settings/payment-methods`| All Auth | Saved Stripe credit/debit cards, default payment method selection, add card. |
| **59** | `MyTicketsScreen` | `features/settings/screens/settings_screens.dart` | `/settings/tickets` | All Auth | Purchased tournament entry passes, barcode / QR access verification. |
| **60** | `BlockedUsersScreen` | `features/settings/screens/settings_screens.dart` | `/settings/blocked` | All Auth | Blocked athletes list, unblock action button. |
| **61** | `AccountDeletionScreen` | `features/settings/screens/settings_hub_screens.dart` | `/settings/deletion` | All Auth | GDPR account deletion flow: permanent anonymization warnings, confirmation. |
| **62** | `TermsScreen` | `features/settings/screens/settings_hub_screens.dart` | `/settings/terms` | All | ArmSphere Terms of Service and Federation Athlete Code of Conduct. |
| **63** | `PrivacyPolicyScreen` | `features/settings/screens/settings_hub_screens.dart` | `/settings/privacy` | All | Privacy policy, biometric data handling statement, GDPR compliance notice. |
| **64** | `MyNominationsScreen` | `features/nomination/screens/my_nominations_screen.dart`| `/nominations/my` | All Auth | Status of grassroots talent nominations submitted by the signed-in user. |
| **65** | `NominateTalentScreen` | `features/nomination/screens/nominate_talent_screen.dart`| `/nominations/submit` | All Auth | Talent scouting form: nominee name, region, reason for federation support. |
| **66** | `GlobalSearchScreen` | `features/search/screens/search_screen.dart` | `/search` | All | Fullscreen search over all federation athletes with debounced query. |

---

## 3. Key Modals & Canvas Surfaces

In addition to the 66 screen classes, ArmSphere contains 3 specialized modal overlay surfaces that function as complete interactive workspaces:

1. **`FullInteractiveBracketModal`** (`features/tournament/widgets/full_interactive_bracket_modal.dart`):
   - Fullscreen two-finger zoomable double-elimination bracket canvas with winners and losers trees.
2. **`TournamentEmptyStatesShowcaseWidget`** (`features/tournament/widgets/tournament_empty_states_showcase_widget.dart`):
   - Multi-state visual switcher demonstrating unseeded, in-progress, and finalized empty states.
3. **`CelebrationOverlay`** (`core/widgets/celebration_overlay.dart`):
   - Golden particle burst overlay triggered upon tournament victory or PR breakthrough.
