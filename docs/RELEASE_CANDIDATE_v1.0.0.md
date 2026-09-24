# ArmSphere Release Candidate 1 (RC-1) Manifest

**Manifest Status**: LOCKED & RECONCILED
**Release Target**: ArmSphere v1.0.0 (Production Release Candidate 1)
**Manifest Lock Date**: September 23, 2026 (Reconciled September 24, 2026)

---

## 1. Provenance & Version Identity

| Attribute | Commit SHA / Identifier | Verification Status |
| --- | --- | --- |
| **Application Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Deployed, verified, and running |
| **API Backend Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Active in Windows service `ArmSphereAPI` |
| **Mobile Flutter Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Verified with strict host allowlist |
| **Cloudflare Worker Source SHA**| `864a45f` (created) / `199dbe0` (integrated) | **PASS** — Live at `.workers.dev` gateway |
| **Worker Pipeline SHA** | `d8d897f` | **PASS** — Workflow committed; deployment pending push |
| **Release Manifest Document SHA**| `546a1a2` | **PASS** — Manifest creation commit |
| **Current Repository HEAD** | `a32aa95` | **PASS** — Local branch `main` |
| **Application ID** | `com.armsphere.app` | **PASS** — TargetSdk 36, MinSdk 23 |
| **Version Name / Code** | `1.0.0` / `1` (`1.0.0+1`) | **PASS** — Configured in `pubspec.yaml` |
| **Production API Gateway** | `https://armsphere-api-gateway.armsphere.workers.dev` | **PASS** — Live and responsive |

---

## 2. Release Artifact Integrity & Checksums

| Artifact | Build Environment | Checksum Status | Notes |
| --- | --- | --- | --- |
| **Release APK (`app-release.apk`)** | Remote CI (Ubuntu / GitHub Actions Run `35840642428`) | **EVIDENCE GAP** | Built and uploaded as CI artifact; local SHA256 pending operator download |
| **Release AAB (`app-release.aab`)** | Remote CI (Ubuntu / GitHub Actions Run `35840642428`) | **EVIDENCE GAP** | Built and uploaded as CI artifact; local SHA256 pending operator download |

---

## 3. Verified CI Run Provenance (Commit 199dbe0 on `main`)

| CI Workflow | Real GitHub Actions Run ID | Event | Status / Conclusion | Scope Verified |
| --- | --- | --- | --- | --- |
| **Enterprise CI/CD Pipeline** | `35840642482` | `push` | `completed` / **`success`** | Workspace lint, application module validation |
| **Backend Production Testing CI** | `35840642387` | `push` | `completed` / **`success`** | Node 20.x build, migrations, all unit/API test suites |
| **Mobile Flutter Analysis** | `35840642428` | `push` | `completed` / **`success`** | Flutter analyze (0 errors), 51 tests, release APK & AAB builds |
| **Flutter Web Preview** | `35840642367` | `push` | `completed` / **`success`** | Web build and GitHub Pages deployment |

---

## 4. Production Database & Schema Lock

| Metric | Verified Value | Status |
| --- | --- | --- |
| **Applied Migrations** | 19 / 19 synced (`drizzle.__drizzle_migrations`) | **PASS** |
| **Latest Migration Tag** | `0018_performance_indexes` | **PASS** |
| **Tables** | 58 tables | **PASS** |
| **Primary Keys** | 58 primary keys | **PASS** |
| **Foreign Keys** | 86 foreign keys (0 orphaned rows across all tables) | **PASS** |
| **Indexes** | 168 indexes | **PASS** |
| **Logical Restore Recovery RTO** | 39.42 seconds (100% row parity, 4,931 / 4,931 rows) | **PASS** |
| **Provider-Native PITR / Snapshot**| Documented capability; not tested via provider CLI | **NOT DEMONSTRATED** |

---

## 5. Security & Operational Posture

- **Live Gateway Auth Guard**: Verified HTTP 401 on unauthenticated / forged requests.
- **Fail-Safe Release Enforcement**: `resolveBaseUrl` throws `StateError` if `API_BASE_URL` is missing or unauthorized.
- **Service Recovery Configuration**: Windows SCM configured for automatic restart (`ArmSphereAPI`: 5s delay, `cloudflared`: 20s delay). Process termination protected under `LocalSystem`.
- **Secrets Hygiene**: Zero credentials committed; production environment loaded from host filesystem.

---

## 6. Release Governance & Sign-off

- **Release Classification**: `READY FOR FINAL HUMAN APPROVAL`
- **Release Lock**: LOCKED. No modifications may be made to this manifest without tagging a new Release Candidate (RC-2).
- **Public Publication Gate**: Strictly gated on human operator confirmation.
