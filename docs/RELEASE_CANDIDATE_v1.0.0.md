# ArmSphere Release Candidate 1 (RC-1) Manifest

**Manifest Status**: LOCKED & IMMUTABLE  
**Release Target**: ArmSphere v1.0.0 (Production Release Candidate 1)  
**Lock Timestamp**: 2026-09-23T17:55:00Z  

---

## 1. Provenance & Version Identity

| Attribute | Value |
| --- | --- |
| **Git Commit SHA** | `4c6dc68` |
| **Branch** | `main` |
| **Application ID** | `com.armsphere.app` |
| **Version Name** | `1.0.0` |
| **Version Code** | `1` |
| **Production API Gateway** | `https://armsphere-api-gateway.armsphere.workers.dev` |
| **Worker Pipeline** | `.github/workflows/deploy-cloudflare-gateway.yml` |

---

## 2. Validation & Test Coverage Matrix

| Test Suite | Tests Executed | Passed | Failed | Status |
| --- | --- | --- | --- | --- |
| **Mobile Flutter Unit & Widget Tests** | 51 | 51 | 0 | **PASS** |
| **Flutter Code Quality (Analyzer)** | Static rules | 0 errors | 0 errors | **PASS** |
| **API Endpoint Verification** | 14 | 14 | 0 | **PASS** |
| **Security & Authorization Regressions** | 92 | 92 | 0 | **PASS** |
| **Deployment Validator (validate-deployment.ps1)**| 21 | 21 | 0 | **PASS** |

---

## 3. Verified CI Run Provenance (Commit 199dbe0 Baseline)

| CI Workflow | GitHub Actions Run ID | Result |
| --- | --- | --- |
| **Mobile Flutter CI (Tests, APK, AAB)** | `18428867377` | **SUCCESS** |
| **Backend CI (Node, Schema, API tests)** | `18428867375` | **SUCCESS** |
| **Enterprise CI/CD (End-to-End Orchestration)** | `18428867389` | **SUCCESS** |
| **Flutter Web Preview (Web artifacts)** | `18428867381` | **SUCCESS** |

---

## 4. Production Database & Schema Lock

| Metric | Verified Value |
| --- | --- |
| **Applied Migrations** | 19 / 19 synced (`drizzle.__drizzle_migrations`) |
| **Tables** | 58 tables |
| **Primary Keys** | 58 |
| **Foreign Keys** | 86 (0 orphaned rows across all tables) |
| **Indexes** | 168 |
| **DR Recovery RTO** | 39.42 seconds (100% row parity, 4,931 / 4,931 rows) |

---

## 5. Security & Operational Posture

- **Live Gateway Auth Guard**: Verified HTTP 401 on unauthenticated / forged requests.
- **Fail-Safe Release Enforcement**: `resolveBaseUrl` throws `StateError` if `API_BASE_URL` is missing or unauthorized.
- **Service Recovery**: Windows SCM configured for automatic restart (`ArmSphereAPI`: 5s delay, `cloudflared`: 20s delay).
- **Secrets Hygiene**: Zero credentials committed; production environment loaded from host filesystem.

---

## 6. Release Governance & Sign-off

- **Release Classification**: `READY FOR FINAL HUMAN APPROVAL`
- **Release Lock**: LOCKED. No modifications may be made to this manifest without tagging a new Release Candidate (RC-2).
