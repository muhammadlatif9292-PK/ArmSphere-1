# ArmSphere — Administrative Cross-Application Integration Matrix

This matrix documents the end-to-end integration and immediate cache/state synchronization between administrative mutations executed in the native Flutter Administration Workspace (`apps/mobile/lib/features/admin`) and downstream athlete, official, and public surfaces across the ArmSphere ecosystem.

---

## 1. Cross-Application State Synchronization Architecture

When an administrative operation is executed in ArmSphere Flutter, the state is propagated through three distinct layers:
1. **Network Layer**: Mutates persistent backend database models via strongly-typed REST endpoints (`/admin/*`) guarded by role-based authorization middleware (`requireRole`, `requireJurisdiction`).
2. **Cryptographic Audit Layer**: Appends an immutable SHA-256 hash-chained event to `audit_events` via `AuditLedgerService.logEvent`.
3. **Client State Synchronizer (`AdminCrossAppSync`)**:
   - Immediately invalidates all affected Riverpod providers (`ref.invalidate(...)`).
   - Evicts affected Hive disk cache keys using prefix wildcards (`fakeHiveStorage.evictByPrefix(...)`).
   - Downstream screens (Athlete Profile, Discover Rankings, Live Matches, Brackets, Community Feed, Partner Gyms, Helpdesk) immediately re-fetch fresh canonical data upon returning to foreground or switching tabs.

---

## 2. Comprehensive Mutation-to-Sync Matrix

| Administrative Operation | Admin Screen & Control | Backend API Endpoint | Audit Action Type | Downstream Providers Invalidated | Hive Cache Evicted | Affected Downstream Athlete & Public Surfaces |
|---|---|---|---|---|---|---|
| **Approve Athlete Verification** | `AdminRosterScreen` → `VERIFY ATHLETE` | `POST /admin/athletes/:id/verify` | `ATHLETE_VERIFIED` | `athleteProfileProvider`, `rankingsProvider`, `discoverFeedProvider`, `adminAthletesProvider`, `adminDashboardStatsProvider` | `athlete_*`, `rankings_*`, `admin_athletes_*` | Athlete Passport reflects verified badge immediately; public Discover rankings update with verified status. |
| **Reject Athlete Application** | `AdminRosterScreen` → `REJECT` | `POST /admin/athletes/:id/reject` | `ATHLETE_REJECTED` | `athleteProfileProvider`, `adminAthletesProvider`, `adminDashboardStatsProvider` | `athlete_*`, `admin_athletes_*` | Athlete Passport shows unverified state with feedback notes. |
| **Blacklist Athlete** | `AdminRosterScreen` → `BLACKLIST` | `POST /admin/athletes/:id/blacklist` | `ATHLETE_BLACKLISTED` | `athleteProfileProvider`, `rankingsProvider`, `discoverFeedProvider`, `adminAthletesProvider` | `athlete_*`, `rankings_*` | Athlete stripped from public leaderboards and match discovery; banned status reflected. |
| **Correct Athlete Profile** | `AdminRosterScreen` → `CORRECT PROFILE` | `POST /admin/athletes/:id/correct` | `ATHLETE_CORRECTED` | `athleteProfileProvider`, `rankingsProvider`, `discoverFeedProvider`, `adminAthletesProvider` | `athlete_*`, `rankings_*` | Weight class, ELO ratings, and provincial jurisdiction update across athlete profile and leaderboards. |
| **Update Referee License** | `AdminRosterScreen` → `UPDATE LICENSE` | `POST /admin/referees/:id/license` | `REFEREE_LICENSE_UPDATED` | `refereeProvider`, `adminRefereesProvider` | `referee_*`, `admin_referees_*` | Referee Passport credential level (National/Provincial/Junior) and active status updated. |
| **Assign Referee Region** | `AdminRosterScreen` → `ASSIGN REGION` | `POST /admin/referees/:id/region` | `REFEREE_REGION_ASSIGNED` | `refereeProvider`, `adminRefereesProvider` | `referee_*`, `admin_referees_*` | Regional event assignments and referee locator directory update. |
| **Suspend Referee** | `AdminRosterScreen` → `SUSPEND` | `POST /admin/referees/:id/suspend` | `REFEREE_SUSPENDED` | `refereeProvider`, `adminRefereesProvider` | `referee_*`, `admin_referees_*` | Referee locked out of official table scoring console. |
| **Issue Referee Certification** | `AdminRosterScreen` → `ISSUE CERTIFICATION` | `POST /admin/referees/certifications` | `REFEREE_CERTIFICATION_ISSUED` | `refereeProvider`, `adminRefereesProvider` | `referee_*`, `admin_referees_*` | New official credential certificate rendered in referee passport. |
| **Approve / Decline Nomination** | `AdminRosterScreen` → `APPROVE` / `DECLINE` | `POST /admin/nominations/:id/status` | `NOMINATION_UPDATED` | `nominationListProvider`, `adminNominationsProvider` | `nomination_*`, `admin_nominations_*` | Athlete event registration and tournament bracket eligibility updated. |
| **Official Match Score Override** | `AdminArenaOpsScreen` → `Commit Score Correction` | `POST /admin/matches/:id/correct` | `MATCH_SCORE_CORRECTED` | `liveMatchesProvider`, `rankingsProvider`, `athleteProfileProvider`, `tournamentProvider`, `adminMatchesProvider` | `matches_*`, `rankings_*`, `tournament_*` | Bout score, winner determination, and ELO ratings recalculated and displayed on match detail and brackets. |
| **Void Match** | `AdminArenaOpsScreen` → `VOID MATCH & REVERT ELO` | `POST /admin/matches/:id/void` | `MATCH_VOIDED` | `liveMatchesProvider`, `rankingsProvider`, `athleteProfileProvider`, `tournamentProvider`, `adminMatchesProvider` | `matches_*`, `rankings_*`, `tournament_*` | Match marked VOID in tournament history; rating deltas cleanly reverted. |
| **Create Championship Belt** | `AdminArenaOpsScreen` → `Create Championship Title` | `POST /admin/championship/titles` | `TITLE_CREATED` | `championshipProvider`, `adminChampionshipTitlesProvider` | `championship_*` | Title appears in national belt hierarchy and public championship showcase. |
| **Vacate / Strip Championship Title** | `AdminArenaOpsScreen` → `VACATE BELT` / `STRIP TITLE` | `POST /admin/championship/titles/:id/vacate` | `TITLE_VACATED` | `championshipProvider`, `adminChampionshipTitlesProvider`, `adminTitleLineageProvider` | `championship_*` | Belt status changes to VACANT; historical lineage record appended. |
| **Sanction / Decline Title Challenge** | `AdminArenaOpsScreen` → `SANCTION` / `DECLINE` | `POST /admin/championship/challenges/:id/respond` | `CHALLENGE_RESPONDED` | `championshipProvider`, `adminPendingChallengesProvider` | `championship_*` | Scheduled championship super-match confirmed or declined for upcoming event. |
| **Resolve Arbitration Dispute** | `AdminGovernanceScreen` → `UPHOLD` / `OVERTURN` | `POST /admin/disputes/:id/resolve` | `DISPUTE_RESOLVED` | `disputeProvider`, `liveMatchesProvider`, `rankingsProvider`, `adminDisputesProvider`, `adminDashboardStatsProvider` | `disputes_*`, `matches_*`, `rankings_*` | Protest status updated; affected bout score overturned if ruling reversed. |
| **Close Dispute Docket** | `AdminGovernanceScreen` → `CLOSE & ARCHIVE DOCKET` | `POST /admin/disputes/:id/close` | `DISPUTE_CLOSED` | `disputeProvider`, `adminDisputesProvider` | `disputes_*` | Case docket sealed with immutable archival timestamp. |
| **Moderate Community Video** | `AdminGovernanceScreen` → `APPROVE & PUBLISH` / `REJECT` | `POST /admin/community/links/:id/moderate` | `COMMUNITY_MODERATED` | `communityFeedProvider`, `adminPendingCommunityLinksProvider` | `community_*` | Approved training clips appear immediately in public Community Video Feed. |
| **Verify Official Partner Gym** | `AdminGovernanceScreen` → `APPROVE OFFICIAL PARTNER GYM` | `POST /admin/venues/:id/verify` | `VENUE_VERIFIED` | `venueListProvider`, `adminVenuesProvider` | `venues_*` | Gym upgraded to verified status in official club locator map and directory. |
| **Support Ticket Message / Internal Note** | `AdminGovernanceScreen` → `Send Official Reply` / `Internal Staff Note` | `POST /admin/support/tickets/:id/messages` | `SUPPORT_MESSAGE_POSTED` | `supportTicketsProvider`, `adminSupportTicketDetailProvider`, `adminSupportTicketsProvider` | `support_*` | Public responses visible to member in in-app helpdesk; internal notes strictly filtered out from non-staff. |
| **Update Support Ticket Status** | `AdminGovernanceScreen` → `MARK RESOLVED` / `CLOSE TICKET` | `PATCH /admin/support/tickets/:id/status` | `SUPPORT_STATUS_UPDATED` | `supportTicketsProvider`, `adminSupportTicketsProvider` | `support_*` | Ticket state updated in member's help center. |
| **Direct Federation Role Grant** | `AdminCommandScreen` → `Grant Verified Role` | `POST /admin/roles/grant` | `ROLE_GRANTED` | `athleteProfileProvider`, `adminRoleApplicationsProvider`, `adminDashboardStatsProvider` | `athlete_*`, `roles_*`, `admin_*` | User's verified roles updated in backend; multi-role switcher reflects newly granted role. |
| **Review Role Application** | `AdminCommandScreen` → `Approve & Grant` / `Reject` | `POST /admin/roles/applications/:id/review` | `ROLE_APPLICATION_REVIEWED` | `athleteProfileProvider`, `adminRoleApplicationsProvider`, `adminDashboardStatsProvider` | `athlete_*`, `roles_*`, `admin_*` | Applicant notified; granted roles immediately selectable upon next session sync. |
| **Switch Active Role** | `Settings` → `AccountRolesScreen` → `Switch Role` | `POST /users/active-role` | `PERSONA_SWITCHED` | `authProvider`, `adminProvider` | `admin_*`, `support_*` (on leaving admin) | Mobile shell swaps between 5-tab Athlete dock and 5-tab Admin dock. Privileged cache keys purged on exit. |

---

## 3. Cache Eviction & Security Invariants

1. **Privileged Cache Purging**:
   - Whenever an authenticated user leaves the Admin Workspace (by switching active role to `ATHLETE`, logging out, or deleting their account), all cached entries matching `admin_*` and `support_*` are purged from disk storage via `HiveStorage.evictByPrefix(...)`.
2. **Internal Note Security**:
   - Support ticket messages flagged `isInternal: true` are stored with an audit trail, but are strictly hidden on client devices unless the viewing user has an active administrative workspace role (`AdminPermissions.isAdminWorkspaceRole`).
3. **No Synthetic Role Escalation**:
   - Administrators cannot switch into `ATHLETE` mode unless their account holds a genuine verified `ATHLETE` role grant or an onboarded athlete profile.
   - `SYSTEM_ADMIN` accounts cannot switch into `REFEREE` or `TOURNAMENT_OPERATOR` without an official verified credential record in `verifiedRoles`.
