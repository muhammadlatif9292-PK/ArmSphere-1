# ArmSphere Task 29 — New Navigation Transitions

This document details all new screen transitions discovered, exercised, and verified during Task 29. These transitions expand the visual coverage of the ArmSphere Mobile & Combat OS application beyond the initial Task 28 inventory.

---

## Transition Inventory

| Transition ID | Source Screen | Action / Trigger | Destination Screen | Destination Route | Screenshot Artifact |
|:---|:---|:---|:---|:---|:---|
| **TR-NEW-01** | `S-012` Referee Panel | Tap "Search Athletes" tile | `S-028` Referee Athlete Search | `/referee/search-athletes` | `035-S-028-referee-search-athletes.png` |
| **TR-NEW-02** | `S-013` Settings Hub | Tap "Support Requests" tile | `S-029` Helpdesk Modal Sheet | `/settings (Modal Sheet)` | `036-S-029-settings-support-modal.png` |
| **TR-NEW-03** | `S-013` Settings Hub | Tap "Terms of Service" tile | `S-030` Terms of Service | `/settings/terms` | `037-S-030-settings-terms-of-service.png` |
| **TR-NEW-04** | `S-013` Settings Hub | Tap "Privacy Policy" tile | `S-031` Privacy Policy | `/settings/privacy` | `038-S-031-settings-privacy-policy.png` |
| **TR-NEW-05** | `S-013` Settings Hub | Tap "Delete Account" tile | `S-032` Account Deletion | `/settings/deletion` | `039-S-032-settings-account-deletion.png` |
| **TR-NEW-06** | `S-017` Account Roles | Tap "Apply for Federation Role" | `S-033` Apply Federation Role | `/settings/roles/apply` | `040-S-033-apply-federation-role.png` |
| **TR-NEW-07** | `S-017` Account Roles | Switch persona to "Tournament Operator" + Navigate Home | `S-034` Operator Command Dashboard | `/home (Role: TOURNAMENT_OPERATOR)` | `041-S-034-tournament-operator-dashboard-top.png` |
| **TR-NEW-08** | `S-017` Account Roles | Switch persona to "System Administrator" + Navigate Home | `S-035` Governance Dashboard | `/home (Role: SYSTEM_ADMIN)` | `042-S-035-governance-arbitration-dashboard-top.png` |
| **TR-NEW-09** | `S-035` Governance Dashboard | Tap "File a complaint" CTA | `S-036` Submit Complaint | `/governance/submit-complaint` | `043-S-036-governance-submit-complaint.png` |

---

## Detailed Transition Provenance

### TR-NEW-01: Referee Panel to Athlete Search Directory
- **Source**: `S-012` (`RefereeDashboardScreen` / `/referee/dashboard`)
- **Trigger**: Clickable tile labelled "Search Athletes" located in the "Official Actions" 2x2 grid.
- **Destination**: `S-028` (`AthleteSearchScreen` / `/referee/search-athletes`).
- **Observed Behavior**: Opens a specialized athlete search directory allowing table-side referees to query armwrestling competitors by ring name or legal name to verify license validity and roster eligibility before matches.
- **Capture**: `035-S-028-referee-search-athletes.png`

### TR-NEW-02: Settings Hub to ArmSphere Helpdesk Modal
- **Source**: `S-013` (`SettingsHubScreen` / `/settings`)
- **Trigger**: Tapping the "Support Requests" tile under the "SUPPORT & LEGAL" section.
- **Destination**: `S-029` (`SettingsHubScreen._showSupportModal` bottom sheet).
- **Observed Behavior**: Opens a styled modal bottom sheet displaying the official federation helpdesk contact details, direct email `support@armsphere.pk`, and explanation of support services.
- **Capture**: `036-S-029-settings-support-modal.png`

### TR-NEW-03: Settings Hub to Terms of Service
- **Source**: `S-013` (`SettingsHubScreen` / `/settings`)
- **Trigger**: Tapping "Terms of Service" tile under "SUPPORT & LEGAL".
- **Destination**: `S-030` (`TermsScreen` / `/settings/terms`).
- **Observed Behavior**: Pushes full legal terms view outlining platform service scope, account responsibilities, competition data ownership, fee refund policies, and community conduct.
- **Capture**: `037-S-030-settings-terms-of-service.png`

### TR-NEW-04: Settings Hub to Privacy Policy
- **Source**: `S-013` (`SettingsHubScreen` / `/settings`)
- **Trigger**: Tapping "Privacy Policy" tile under "SUPPORT & LEGAL".
- **Destination**: `S-031` (`PrivacyPolicyScreen` / `/settings/privacy`).
- **Observed Behavior**: Renders the complete federation biometric data policy, privacy disclosures, profile visibility controls, data retention timelines, and cryptographic password hashing details.
- **Capture**: `038-S-031-settings-privacy-policy.png`

### TR-NEW-05: Settings Hub to Account Deletion Vault
- **Source**: `S-013` (`SettingsHubScreen` / `/settings`)
- **Trigger**: Tapping "Delete Account" tile in the "DANGER ZONE" section.
- **Destination**: `S-032` (`AccountDeletionScreen` / `/settings/deletion`).
- **Observed Behavior**: Navigates to irreversible account deletion workflow. Highlights warnings regarding permanent credential deactivation, identity anonymization, and preservation of official competition records for sport integrity.
- **Capture**: `039-S-032-settings-account-deletion.png`

### TR-NEW-06: Account Roles to Apply for Federation Role
- **Source**: `S-017` (`AccountRolesScreen` / `/settings/roles`)
- **Trigger**: Tapping the "Apply for Federation Role" button at the bottom of the Account Roles screen.
- **Destination**: `S-033` (`ApplyRoleScreen` / `/settings/roles/apply`).
- **Observed Behavior**: Displays formal federation application form allowing verified athletes to submit licensing credentials, license numbers, and armwrestling background to apply for Certified Referee, Tournament Operator, or Provincial Director credentials.
- **Capture**: `040-S-033-apply-federation-role.png`

### TR-NEW-07: Account Roles to Tournament Operator Command Center
- **Source**: `S-017` (`AccountRolesScreen` / `/settings/roles`)
- **Trigger**: Tapping "Switch" on the Tournament Operator tile in Verified Roles, then navigating to `/home`.
- **Destination**: `S-034` (`TournamentOperatorDashboardScreen` / `/home` when role = `TOURNAMENT_OPERATOR`).
- **Observed Behavior**: Router inspects active client persona and directs Tab 1 (Arena) away from Athlete Dashboard to Arena Operations Command, exposing tournament assignment monitors, table queue tools, and tournament browser.
- **Capture**: `041-S-034-tournament-operator-dashboard-top.png`

### TR-NEW-08: Account Roles to Governance & Arbitration Dashboard
- **Source**: `S-017` (`AccountRolesScreen` / `/settings/roles`)
- **Trigger**: Tapping "Switch" on System Administrator tile in Verified Roles, then navigating to `/home` (or `/governance`).
- **Destination**: `S-035` (`GovernanceDashboardScreen` / `/home` when role = `SYSTEM_ADMIN` or `/governance`).
- **Observed Behavior**: Switches client persona to federation governance. Tab 1 renders Arbitration & Disputes command center showing live case dockets, dispute status filters, and dispute filing action.
- **Capture**: `042-S-035-governance-arbitration-dashboard-top.png`

### TR-NEW-09: Governance Dashboard to Submit Arbitration Complaint
- **Source**: `S-035` (`GovernanceDashboardScreen` / `/governance`)
- **Trigger**: Tapping "File a complaint" CTA button (or '+' AppBar icon).
- **Destination**: `S-036` (`SubmitComplaintScreen` / `/governance/submit-complaint`).
- **Observed Behavior**: Renders the formal arbitration dispute intake form with incident subject, detailed narrative explanation, witness/video evidence inputs, and submission button.
- **Capture**: `043-S-036-governance-submit-complaint.png`
