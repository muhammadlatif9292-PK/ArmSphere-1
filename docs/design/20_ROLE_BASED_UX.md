# ArmSphere Role-Based User Experience Specification
**Permissions, Persona Workspaces & Federation Governance Rules**
**Document Version**: 1.0.0
**Source Authority**: Grounded in `packages/types/index.ts` (9 User Roles) & `app_router.dart`
**Status**: APPROVED & LOCKED

---

## 1. The 9 Federation User Roles

ArmSphere supports 9 formal user roles defined by the Pakistan Armwrestling Federation (PAFF):

```
┌─────────────────────────────────────────────────────────────────┐
│                    THE 9 FEDERATION ROLES                       │
├─────────────────┬──────────────┬────────────────────────────────┤
│ Role Key        │ Classification│ Core Mobile Responsibility     │
├─────────────────┼──────────────┼────────────────────────────────┤
│ ATHLETE         │ Competitor   │ Profile, ELO, Registration, PRs│
│ REFEREE         │ Official     │ Table scorepad, fouls, pins    │
│ TOURNAMENT_OPERATOR│ Logistics │ Weigh-in, tables, bracket draw │
│ PROVINCIAL_DIRECTOR│ Governance│ Provincial events & sanctions  │
│ NATIONAL_DIRECTOR│ Executive   │ National titles, federation seal│
│ COMPLIANCE_OFFICER│ Judicial   │ Dispute arbitration & cases    │
│ SUPPORT_AGENT   │ Operations   │ Ticket & registration disputes │
│ ORGANIZATION_LEADER│ Club Head │ Club rosters & team management │
│ SYSTEM_ADMIN    │ Engineering  │ Audit logs & system integrity  │
└─────────────────┴──────────────┴────────────────────────────────┘
```

---

## 2. Dynamic Surface Adaptation Matrix

Screens adapt automatically according to the active user's permissions:

| Screen / Feature | Athlete View | Referee View | Tournament Operator | Compliance Officer |
| :--- | :--- | :--- | :--- | :--- |
| **Home (Tab 0)** | `AthleteDashboardScreen` | `RefereeDashboardScreen`| `TournamentOperationsScreen`| `GovernanceDashboardScreen`|
| **Tournament Details**| "Register" Button | "Officiate Table" CTA | "Operator Console" CTA | "Audit Regulations" |
| **Match Node** | Public Score & Stats | "Scorepad Console" | "Reassign Table" | "View Video Evidence" |
| **Dispute Filing** | "File Complaint" Form| "Submit Official Report"| "View Disputed Match"| "Issue Ruling / Verdict" |
| **Weigh-in Screen** | View My Weight Record| Read-Only Verification | Record Weight & Pass/Fail | Read-Only Audit |

---

## 3. Dual-Role Persona Switching

Many certified referees and club leaders also actively compete as athletes:
- **Role Switching Pill**: Dual-role users have a switcher toggle in their profile header: `[ Compete (Athlete) | Officiate (Referee) ]`.
- **Mode Switching**: Tapping the switcher animates Tab 0 between the Athlete Dashboard and the Referee Scorepad Board without requiring logout or reauthentication.
- **Security Boundary**: Server-side JWT claims guarantee that role switching only permits access to officially granted credentials.
