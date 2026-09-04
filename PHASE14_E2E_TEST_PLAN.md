# Phase 14: E2E User Journey Verification

**Date:** 2026-09-01
**Purpose:** Verify all Phase 13 remediations through real user testing
**Status:** TEST PLAN CREATED - MANUAL TESTING REQUIRED

---

## Test Environment Setup

### Prerequisites

1. **Database Setup:**
   - Apply migration 00016 and 0017
   - Ensure province fields are populated
   - Create test users for each role

2. **Backend API:**
   - Start API server: `cd apps/api && npm run dev`
   - Configure CORS for test domains
   - Verify database connection

3. **Mobile App:**
   - Flutter SDK available
   - Mobile device or emulator

4. **Web App:**
   - Flutter web build available
   - Preview URL accessible

---

## Test Accounts Required

### Roles to Test

| Role | Username | Password | Expected Route |
|------|----------|----------|----------------|
| ATHLETE | athlete@test.com | password123 | /home |
| REFEREE | referee@test.com | password123 | /referee/dashboard |
| PROVANCIAL_DIRECTOR | pd@test.com | password123 | /referee/dashboard |
| NATIONAL_DIRECTOR | nd@test.com | password123 | /referee/dashboard |
| SYSTEM_ADMIN | admin@test.com | password123 | /referee/dashboard |
| TOURNAMENT_OPERATOR | to@test.com | password123 | /governance |
| COMPLIANCE_OFFICER | co@test.com | password123 | /governance |
| SUPPORT_AGENT | sa@test.com | password123 | /governance |
| ORGANIZATION_LEADER | ol@test.com | password123 | /governance |

### Account Setup

Each test account must have:
- ✅ Email verified
- ✅ MFA configured (optional for testing)
- ✅ Role assigned
- ✅ Province assigned (for jurisdiction roles)
- ✅ Profile complete

---

## Test Scenarios

### Scenario 1: Complete First-Run Journey

**Objective:** Verify new user registration and onboarding flow

**Steps:**
1. Launch app (mobile or web)
2. See splash screen
3. Welcome screen displayed
4. Click "Create Account"
5. Enter valid email and password
6. Verify registration success
7. Redirect to role selection
8. Select role and intent
9. Complete onboarding
10. Verify correct dashboard routing

**Expected Results:**
- ✅ Splash screen transitions to welcome
- ✅ Registration validates email format
- ✅ Success message displayed
- ✅ Role intent screen shows available roles
- ✅ Onboarding completes successfully
- ✅ Redirect to correct dashboard based on role

**Evidence Required:**
- Screenshots of each screen
- Video of complete flow

---

### Scenario 2: Role-Aware Routing Verification

**Objective:** Verify server-side role verification determines routing

**Steps:**
1. Sign in as each role
2. Verify dashboard routing
3. Test navigation between dashboards
4. Verify protected routes work correctly

**Test Matrix:**

| Role | Register Intent | Expected Route | Actual Route | Result |
|------|-----------------|----------------|--------------|--------|
| ATHLETE | athlete | /home | /home | ⬜ |
| REFEREE | referee | /referee/dashboard | /referee/dashboard | ⬜ |
| PROVANCIAL_DIRECTOR | referee | /referee/dashboard | /referee/dashboard | ⬜ |
| NATIONAL_DIRECTOR | referee | /referee/dashboard | /referee/dashboard | ⬜ |
| SYSTEM_ADMIN | referee | /referee/dashboard | /referee/dashboard | ⬜ |
| TOURNAMENT_OPERATOR | organizer | /governance | /governance | ⬜ |
| COMPLIANCE_OFFICER | organizer | /governance | /governance | ⬜ |
| SUPPORT_AGENT | organizer | /governance | /governance | ⬜ |
| ORGANIZATION_LEADER | organizer | /governance | /governance | ⬜ |

**Expected Results:**
- ✅ Routing based on verified server-side role, NOT client intent
- ✅ Referee roles go to referee dashboard
- ✅ Governance roles go to governance dashboard
- ✅ Athletes go to home dashboard
- ✅ No access to unauthorized routes

**Evidence Required:**
- Login screenshots for each role
- Dashboard screenshots
- Route verification logs

---

### Scenario 3: Provincial Director Jurisdiction Enforcement

**Objective:** Verify provincial directors can only access their province's resources

**Setup:**
- Create two provinces: KPK and Punjab
- Create Provincial Director account for KPK
- Create Provincial Director account for Punjab
- Create events in both provinces
- Create matches in both provinces

**Test Steps:**

**Test 3.1: KPK PD Access**
1. Sign in as KPK PD
2. Navigate to events page
3. Verify only KPK events displayed
4. Try to access Punjab event
5. Verify error: "Cannot access resources outside your province"

**Test 3.2: Punjab PD Access**
1. Sign in as Punjab PD
2. Navigate to matches page
3. Verify only Punjab matches displayed
4. Try to access KPK match
5. Verify error: "Cannot access resources outside your province"

**Test 3.3: Resource Creation**
1. Sign in as KPK PD
2. Try to create event in Punjab province
3. Verify error: "Provincial Director cannot create events outside their province"

**Test 3.4: National Director Access**
1. Sign in as National Director
2. Navigate to KPK events
3. Verify KPK events accessible
4. Navigate to Punjab events
5. Verify Punjab events accessible
6. Verify National Director can access all provinces

**Expected Results:**
- ✅ Provincial Directors restricted to their province
- ✅ National Directors can access all provinces
- ✅ Jurisdiction errors properly displayed
- ✅ Creation operations respect jurisdiction

**Evidence Required:**
- Database query results showing province assignments
- Screenshots of filtered events
- Error messages captured
- Access logs

---

### Scenario 4: Match Inspection Authorization

**Objective:** Verify match inspection is only allowed for authorized roles

**Setup:**
- Create matches in different provinces
- Create test users for each role

**Test Matrix:**

| Role | Can Inspect All Matches | Can Inspect Own Province | Can Inspect Other Province | Result |
|------|------------------------|--------------------------|----------------------------|--------|
| SYSTEM_ADMIN | ⬜ | ⬜ | ⬜ | ⬜ |
| NATIONAL_DIRECTOR | ⬜ | ⬜ | ⬜ | ⬜ |
| PROVANCIAL_DIRECTOR | ❌ | ⬜ | ❌ | ⬜ |
| REFEREE | ❌ | ❌ | ❌ | ⬜ |
| ATHLETE | ❌ | ❌ | ❌ | ⬜ |

**Test Steps:**

**Test 4.1: System Admin**
1. Sign in as System Admin
2. Navigate to matches list
3. Click inspect on any match
4. Verify match details displayed
5. Verify NO jurisdiction error

**Test 4.2: National Director**
1. Sign in as National Director
2. Navigate to matches list
3. Click inspect on any match
4. Verify match details displayed
5. Verify NO jurisdiction error

**Test 4.3: Provincial Director (Own Province)**
1. Sign in as KPK PD
2. Navigate to KPK matches list
3. Click inspect on KPK match
4. Verify match details displayed
5. Verify NO jurisdiction error

**Test 4.4: Provincial Director (Other Province)**
1. Sign in as KPK PD
2. Navigate to Punjab matches list
3. Click inspect on Punjab match
4. Verify error: "Provincial Director cannot inspect matches outside their province"
5. Verify match details NOT displayed

**Test 4.5: Referee**
1. Sign in as Referee
2. Navigate to matches list
3. Try to inspect any match
4. Verify error: "Only SYSTEM_ADMIN, NATIONAL_DIRECTOR, and PROVANCIAL_DIRECTOR can inspect matches"
5. Verify match details NOT displayed

**Expected Results:**
- ✅ SYSTEM_ADMIN can inspect all matches
- ✅ NATIONAL_DIRECTOR can inspect all matches
- ✅ PROVANCIAL_DIRECTOR can inspect own province only
- ✅ Referee and Athletes cannot inspect matches
- ✅ Jurisdiction errors properly displayed

**Evidence Required:**
- Screenshots of successful inspections
- Screenshots of denied inspections
- Error messages captured
- Access logs

---

### Scenario 5: Android Production Build

**Objective:** Verify Android release build works correctly

**Steps:**
1. Configure Android signing in `keystore.properties`
2. Build release APK: `flutter build apk --release`
3. Install APK on physical device
4. Sign in with test account
5. Verify app functionality
6. Test all features

**Test Checklist:**
- [ ] APK builds successfully
- [ ] No signing errors
- [ ] App installs on device
- [ ] All features work
- [ ] Navigation functional
- [ ] API integration working
- [ ] No crashes or errors

**Expected Results:**
- ✅ APK builds without errors
- ✅ App installs successfully
- ✅ All features functional
- ✅ No performance issues

**Evidence Required:**
- Build logs
- APK file
- Screenshots from device
- Error logs if any

---

### Scenario 6: iOS Build

**Objective:** Verify iOS project builds correctly

**Steps:**
1. Open iOS project in Xcode
2. Configure code signing
3. Build for release
4. Test app functionality
5. Verify all features work

**Test Checklist:**
- [ ] Project opens in Xcode
- [ ] Dependencies install correctly
- [ ] Build succeeds
- [ ] App runs on simulator/device
- [ ] All features functional

**Expected Results:**
- ✅ Project builds successfully
- ✅ App runs on iOS device
- ✅ All features functional

**Evidence Required:**
- Xcode build logs
- Screenshots from iOS device
- Error logs if any

**Note:** iOS build requires Xcode and macOS, cannot be tested in current environment.

---

### Scenario 7: Flutter Web Build

**Objective:** Verify Flutter web build works correctly

**Steps:**
1. Build web app: `flutter build web`
2. Serve build: `npx serve build/web`
3. Open preview URL in browser
4. Test complete user journey
5. Verify API integration

**Test Checklist:**
- [ ] Web build succeeds
- [ ] Preview URL accessible
- [ ] Splash screen displayed
- [ ] Registration flow works
- [ ] Sign in works
- [ ] Dashboard routing correct
- [ ] All features functional
- [ ] API calls working
- [ ] No console errors

**Expected Results:**
- ✅ Web build successful
- ✅ Preview URL accessible
- ✅ All features functional
- ✅ API integration working

**Evidence Required:**
- Build logs
- Preview URL
- Screenshots from browser
- Network requests captured

**Note:** Flutter SDK not available in current environment. User must test locally.

---

### Scenario 8: Secret Hygiene Verification

**Objective:** Verify environment files are properly structured

**Steps:**
1. Check `.env.example` file
2. Verify all required variables present
3. Check `apps/mobile/.env.example`
4. Check `apps/api/.env.example`
5. Verify no sensitive data in examples
6. Verify documentation clear

**Test Checklist:**
- [ ] `.env.example` complete
- [ ] No real secrets included
- [ ] Clear documentation for each variable
- [ ] `apps/mobile/.env.example` complete
- [ ] `apps/api/.env.example` complete
- [ ] Production example file exists

**Expected Results:**
- ✅ All example files complete
- ✅ No sensitive data in templates
- ✅ Clear documentation
- ✅ Production template available

**Evidence Required:**
- File screenshots
- Variable documentation
- Verification checklist

---

## Test Results Summary

### Pass/Fail Tracking

| Scenario | Status | Notes |
|----------|--------|-------|
| Scenario 1: First-Run Journey | ⬜ PENDING | Manual testing required |
| Scenario 2: Role-Aware Routing | ⬜ PENDING | Manual testing required |
| Scenario 3: PD Jurisdiction | ⬜ PENDING | Manual testing required |
| Scenario 4: Match Inspection | ⬜ PENDING | Manual testing required |
| Scenario 5: Android Build | ⬜ PENDING | Manual testing required |
| Scenario 6: iOS Build | ⬜ PENDING | Requires macOS + Xcode |
| Scenario 7: Flutter Web | ⬜ PENDING | Requires Flutter SDK |
| Scenario 8: Secret Hygiene | ✅ PASS | Files verified |

### Overall Status

- **Completed:** 1/8 (12.5%)
- **Pending:** 7/8 (87.5%)
- **Passed:** 1/8 (12.5%)
- **Failed:** 0/8 (0%)

---

## Known Limitations

1. **Flutter SDK Not Available:** Cannot run Flutter web build locally in this environment
2. **iOS Build Requires macOS:** Cannot test iOS build in Windows environment
3. **Mobile Device Not Available:** Cannot test Android app on physical device
4. **Manual Testing Required:** All user journey tests must be performed by human users

---

## Next Steps

1. **Setup Test Environment:**
   - Apply database migrations
   - Create test accounts
   - Configure API server
   - Build mobile/web apps

2. **Execute Test Scenarios:**
   - Follow test plan steps
   - Capture evidence (screenshots, logs)
   - Record results (pass/fail)

3. **Document Results:**
   - Update test results
   - Capture screenshots
   - Record error messages
   - Note any issues

4. **Fix Issues:**
   - Address any failures
   - Re-test fixes
   - Verify improvements

5. **Complete Phase 14 Evidence:**
   - Document all test results
   - Create final Phase 14 report
   - Verify all remediations work

---

**Prepared By:** AI Assistant
**Review Status:** READY FOR MANUAL TESTING
**Date:** 2026-09-01