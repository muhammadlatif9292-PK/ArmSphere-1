# ArmSphere Task 30 — Missing Coverage & Inaccessibility Catalog

This document records the exact final inventory of screens and feature areas within the ArmSphere Mobile & Combat OS codebase that remain unobserved following the completion of Task 30.

---

## 1. Resolution Summary of Task 29 Coverage Gaps

During Task 30, each of the previously reported inaccessible surfaces was investigated against `app_router.dart`, client state fallback mechanisms, and live device navigation.

| Feature Area | Route / Surface | Candidate Screen Widget | Task 29 Status | Task 30 Resolution Status | Evidence Artifact |
|:---|:---|:---|:---|:---|:---|
| **Match Analysis** | `/matches/head-to-head` | `HeadToHeadScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `044-S-037-match-head-to-head-tale-of-tape.png` |
| **Tournament Live** | `/tournament/:id` | `TournamentDetailScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `045-S-038-tournament-detail-error-state.png` |
| **Tournament Live** | `/tournaments/bracket` | `TournamentBracketsScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `046-S-039-tournament-brackets-loading.png` |
| **Operator Live** | `/weigh-in` | `TournamentWeighInScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `047-S-040-tournament-weigh-in-error-state.png` |
| **Operator Live** | `/awards` | `TournamentAwardsCeremonyScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `048-S-041-tournament-awards-ceremony-empty.png` |
| **Direct Messaging** | `/messages` | `ConversationsListScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `049-S-042-athlete-inbox-empty-conversations.png` |
| **Championships** | `/championship/titles` | `ChampionshipsListScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `050-S-043-championship-titles-error-state.png` |
| **Tournament Live** | `/events/:id/register` | `EventRegistrationScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `051-S-044-official-event-registration-form.png` |
| **Governance Live** | `/governance/dispute/:id` | `DisputeDetailScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `052-S-045-dispute-dossier-error-state.png` |
| **Direct Messaging** | `/messages/:conversationId` | `ChatScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `053-S-046-match-discussion-chat-screen.png` |
| **Announcements** | `/announcements` | `AnnouncementsListScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `054-S-047-federation-bulletins-empty-state.png` |
| **Venues** | `/venues` | `VenueDirectoryScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `055-S-048-armwrestling-venues-empty-state.png` |
| **Venues** | `/venues/submit` | `SubmitVenueScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `056-S-049-submit-training-venue-form.png` |
| **Grassroots Events** | `/informal-events` | `InformalEventDirectoryScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `057-S-050-practice-meetups-empty-state.png` |
| **Grassroots Events** | `/informal-events/create`| `CreateInformalEventScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `058-S-051-host-practice-meetup-form.png` |
| **Talent Scouts** | `/nominations/my` | `MyNominationsScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `059-S-052-my-nominations-error-state.png` |
| **Talent Scouts** | `/nominate` | `NominateTalentScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `060-S-053-nominate-talent-form.png` |
| **Teams & Clubs** | `/teams` | `TeamsListScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `061-S-054-my-teams-clubs-error-state.png` |
| **Teams & Clubs** | `/teams/create` | `CreateTeamScreen` | `BLOCKED_NO_LIVE_DATA` | **RESOLVED & CAPTURED** | `062-S-055-register-new-team-form.png` |

---

## 2. Exact Remaining Unobserved Surfaces

Following the safe live-navigation campaign of Task 30, exactly **eight (8)** candidate surfaces remain unobserved, categorized into two technical classifications:

| Feature Area | Route / Surface | Candidate Screen Widget | Blocker Classification | Technical Root Cause & Justification |
|:---|:---|:---|:---|:---|
| **Authentication** | `/welcome` | `WelcomeScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Preserved active session. Guard redirects authenticated session to `/home`. No parallel emulator available. |
| **Authentication** | `/login` | `LoginScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Preserved active session. Guard redirects to `/home`. Logging out would destroy physical device session. |
| **Authentication** | `/register` | `RegisterScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Guarded by unauthenticated status requirement. |
| **Authentication** | `/forgot-password` | `ForgotPasswordScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Sub-route of unauthenticated login flow. |
| **Authentication** | `/mfa/verify` | `MfaVerifyScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | AuthStatus.mfaRequired challenge state during unauthenticated login. |
| **Onboarding** | `/onboarding` | `OnboardingScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | First-time athlete bio & arm profile setup; already completed for this account. |
| **Onboarding** | `/role-intent` | `RoleIntentScreen` | `BLOCKED_BY_AUTHENTICATION_ACCESS` | First-time role onboarding intent sheet; already fulfilled. |
| **Operator Live** | `/tournament/:id/operations` | `TournamentOperationsScreen` | `BLOCKED_NO_LIVE_DATA` | Requires sanctioned tournament ID assigned to operator in database; unassigned ID fails provider lookup. |

---

## 3. Preservation Rationale & Safety Safeguards

### Authentication Surface Preservation (`BLOCKED_BY_AUTHENTICATION_ACCESS`)
- **Protocol Mandate**: Task 30 §2 explicitly directs: *"Prefer an existing secondary emulator, secondary device or authorized test account. Do not clear application data, remove the existing account, reset the phone or risk losing the current authorized session... If reaching a state requires an unavailable account or a session reset, document that prerequisite and stop rather than risking account access."*
- **Operational Verification**:
  1. No local Android emulator (`emulator.exe` or Android Virtual Devices) was detected on the host workstation.
  2. The connected physical device (`TECNO_BG6`, serial `109973341V002618`) hosts the active test session for `Muhammad Hamad Latif` with multiple verified federation grants.
  3. Evicting the session or clearing application storage would result in catastrophic loss of test credentials without a known automated recovery path in scope.
  4. Per protocol instructions, the 7 auth/onboarding routes are preserved and documented as the exact remaining gaps.

### Tournament Operations Desk (`BLOCKED_NO_LIVE_DATA`)
- **Technical Mechanism**:
  1. `TournamentOperationsScreen` depends on multiple Riverpod data providers: `eventDetailProvider`, `eventStatsProvider`, `eventRegistrationsProvider`, `eventBracketsProvider`, `eventMatchTablesProvider`, and `eventMatchesProvider`.
  2. When deep-linked with synthetic or unassigned tournament IDs, the provider chain fails to resolve, rendering an unpopulated container.
  3. Displaying the fully populated desk requires assigning a real tournament fixture to the operator's account in backend staging. Mutating production database tables was avoided to uphold Task §1 safety rules.
