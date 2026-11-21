# ArmSphere Remaining Visual Evidence Gaps & Inaccessibility Report

**Task Reference**: ARMSPHERE TASK 31 — Comprehensive Contextual UI/UX Audit  
**Target Repository**: `E:\ArmSphere\`  
**Target Platform**: Android (Physical Device: TECNO_BG6 / Android 13, 720×1612)  
**Evidence Baseline**: Tasks 28–30 (62 Screenshot Captures across 49 Unique Screens)  
**Output Directory**: `E:\ArmSphere\docs\qa\armsphere-visual-ux-review\`  

---

## 1. Executive Summary

Across the 58 candidate route endpoints and conditional surfaces declared in `app_router.dart`, Tasks 28 through 30 successfully reached, rendered, interaction-tested, and captured **49 unique screen classes** across **62 distinct visual states**.

Exactly **eight (8)** candidate surfaces remain unobserved in the physical device screenshot inventory. This document provides the rigorous technical rationale for why these surfaces were deliberately preserved unobserved during live device testing, and establishes the exact protocol required to capture them safely in future iterations without jeopardizing test accounts or release integrity.

---

## 2. Complete Catalog of Remaining Unobserved Surfaces

| # | Route / Surface | Destination Widget Class | Category | Blocker Classification | Technical Root Cause |
|:---:|:---|:---|:---|:---|:---|
| **1** | `/welcome` | `WelcomeScreen` | Authentication | `BLOCKED_BY_AUTHENTICATION_ACCESS` | App router auth-guard automatically redirects authenticated sessions to `/home`. Reaching `/welcome` requires clearing application storage or logging out. |
| **2** | `/login` | `LoginScreen` | Authentication | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Route guarded by auth status. Activating requires session revocation. |
| **3** | `/register` | `RegisterScreen` | Authentication | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Route guarded by unauthenticated status requirement. |
| **4** | `/forgot-password` | `ForgotPasswordScreen` | Authentication | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Child route of unauthenticated login flow. |
| **5** | `/mfa/verify` | `MfaVerifyScreen` | Authentication | `BLOCKED_BY_AUTHENTICATION_ACCESS` | Requires active intermediate `AuthStatus.mfaRequired` state during a login challenge sequence. |
| **6** | `/onboarding` | `OnboardingScreen` | Onboarding | `BLOCKED_BY_AUTHENTICATION_ACCESS` | First-time athlete bio & arm profile onboarding wizard; permanently completed for the active account. |
| **7** | `/role-intent` | `RoleIntentScreen` | Onboarding | `BLOCKED_BY_AUTHENTICATION_ACCESS` | First-time role intent intake sheet; permanently fulfilled for the active account. |
| **8** | `/tournament/:id/operations` | `TournamentOperationsScreen` | Operator Live | `BLOCKED_NO_LIVE_DATA` | Deep-linking renders an unpopulated container because Riverpod data providers require a live tournament ID assigned to the operator in the backend database. |

---

## 3. Session Preservation Rationale & Safety Safeguards

### Authentication Surfaces (`BLOCKED_BY_AUTHENTICATION_ACCESS`)
The 7 authentication and onboarding surfaces were intentionally preserved without capture in accordance with the strict directives of Tasks 28, 29, and 30:
1. **Mandate to Protect Session**: Task instructions explicitly ordered: *"Do not clear application data, remove the existing account, reset the phone or risk losing the current authorized session... If reaching a state requires an unavailable account or a session reset, document that prerequisite and stop rather than risking account access."*
2. **Device State Verification**:
   - The test environment relies on a single connected physical device: `TECNO_BG6` (`109973341V002618`), running Android 13.
   - The workstation has no parallel Android Virtual Devices (AVD) or running emulator instances (`emulator.exe`).
   - The active physical device holds an authorized test session for `Muhammad Hamad Latif`, equipped with four verified federation grants (`PAFF COMPETITOR`, `REFEREE`, `OPERATOR`, `SYSTEM_ADMIN`).
3. **Catastrophic Risk**: Evicting this session via logout or clearing app data would permanently destroy the cached JWT tokens and biometric verification state. Because automated account re-provisioning credentials are not in scope, evicting the session would have permanently locked the audit out of all authenticated screens.

### Live Tournament Operations Console (`BLOCKED_NO_LIVE_DATA`)
The `TournamentOperationsScreen` represents the digital command desk used by tournament directors at table-side:
1. **Provider Architecture**: The widget is bound to multiple Riverpod providers:
   - `eventDetailProvider(tournamentId)`
   - `eventStatsProvider(tournamentId)`
   - `eventRegistrationsProvider(tournamentId)`
   - `eventBracketsProvider(tournamentId)`
   - `eventMatchTablesProvider(tournamentId)`
   - `eventMatchesProvider(tournamentId)`
2. **Data Dependency**: When deep-linked with a synthetic tournament ID (`/tournament/demo-event-id/operations`), all six providers fail with missing data errors, and the widget gracefully collapses into an unpopulated fallback container.
3. **Safety Protection**: Creating a live sanctioned tournament and assigning it to the operator in the backend database would have required mutating backend staging/production databases, violating Task §1 instructions (*"Do not trigger real challenges, matches, payments, registrations, scoring submissions, destructive operations or other production mutations"*).

---

## 4. Protocol for Capturing Gaps in Future Verification Cycles

To capture visual evidence for these final 8 surfaces without compromising release integrity or physical test sessions:

### Protocol A: Authentication Surfaces Capture (Secondary Sandbox Environment)
1. **Prerequisite**: Launch a headless Android Virtual Device (AVD) or secondary test phone.
2. **Isolation**: Build and install the test APK on the secondary device:
   ```powershell
   flutter build apk --debug
   adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
   ```
3. **Traverse Auth Funnel**:
   - Launch app on clean storage to capture `/welcome` (`WelcomeScreen`).
   - Tap `[Sign In]` to capture `/login` (`LoginScreen`).
   - Tap `[Create Account]` to capture `/register` (`RegisterScreen`).
   - Tap `[Forgot Password]` to capture `/forgot-password` (`ForgotPasswordScreen`).
   - Inject test credentials with MFA flag to capture `/mfa/verify` (`MfaVerifyScreen`).
   - Create a fresh sandbox account to capture `/onboarding` and `/role-intent`.
4. **Preservation**: The primary physical phone (`TECNO_BG6`) remains untouched and fully authorized throughout.

### Protocol B: Tournament Operations Console Capture (Mock Fixture Injection)
1. **Prerequisite**: Utilize a Flutter Driver integration test or debug flavor with mocked Riverpod overrides:
   ```dart
   ProviderScope(
     overrides: [
       eventDetailProvider.overrideWith((ref, id) => MockTournamentDetail()),
       eventMatchTablesProvider.overrideWith((ref, id) => MockMatchTables()),
       eventRegistrationsProvider.overrideWith((ref, id) => MockRegistrations()),
     ],
     child: TournamentOperationsScreen(tournamentId: 'mock-tourney-01'),
   )
   ```
2. **Capture**: Capture `TournamentOperationsScreen` under fully populated table operations conditions, displaying active tables, referee callouts, and weigh-in queues.

---

## 5. Audit Completeness Assessment

With 49 of 57 unique widget classes captured and reviewed (an **86.0% physical visual coverage rate**), and 100% of reachable multi-role production surfaces visually inspected, the evidence baseline is fully sufficient to support the master UI/UX redesign and structural improvements planned in Task 31.
