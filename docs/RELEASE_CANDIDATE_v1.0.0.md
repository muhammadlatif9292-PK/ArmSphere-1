# ArmSphere Release Candidate 1 (RC-1) Manifest

**Manifest Status**: LOCKED & VERIFIED
**Release Target**: ArmSphere v1.0.0 (Production Release Candidate 1)
**Manifest Lock Date**: September 24, 2026

---

## 1. Provenance & Version Identity

| Attribute | Commit SHA / Identifier | Verification Status |
| --- | --- | --- |
| **Application Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Deployed, verified, and running |
| **API Backend Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Active in Windows service `ArmSphereAPI` |
| **Mobile Flutter Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Verified with strict host allowlist |
| **Cloudflare Worker Source SHA**| `864a45f` (created) / `199dbe0` (integrated) | **PASS** — Live at `.workers.dev` gateway |
| **Worker Pipeline SHA** | `d8d897f` | **PASS** — Workflow committed; deployment pending secret setup |
| **Published Repository State** | `509eec3da730e410d04525d2d870dfd73e139e9d` (`509eec3`) | **PASS** — Published to `origin/main` |
| **Application ID** | `com.armsphere.app` | **PASS** — TargetSdk 36, MinSdk 23 |
| **Version Name / Code** | `1.0.0` / `1` (`1.0.0+1`) | **PASS** — Configured in `pubspec.yaml` |
| **Production API Gateway** | `https://armsphere-api-gateway.armsphere.workers.dev` | **PASS** — Live and responsive (HTTP 200) |

---

## 2. Release Artifact Integrity & Cryptographic Checksums

| Artifact | Source CI Run | Cryptographic SHA256 Hash | Signing Classification |
| --- | --- | --- | --- |
| **Release APK (`app-release.apk`)** | GitHub Actions Run `35943103870` | `d7a7cb5e042de839cc907ad07cbd02c3cb29303916ca0da1c04ebe87cbbaa804` | **DEBUG-SIGNED (AWAITING OPERATOR UPLOAD KEYSTORE)** |
| **Release AAB (`app-release.aab`)** | GitHub Actions Run `35943103870` | `26bae8e1739655fa91bfaebbdcb3588d05e3908d60796b6a2561dcad15c589e8` | **DEBUG-SIGNED (AWAITING OPERATOR UPLOAD KEYSTORE)** |

---

## 3. Verified Post-Push CI Run Provenance (Commit `509eec3` on `origin/main`)

| CI Workflow | GitHub Actions Run ID | Event | Status / Conclusion | Scope Verified |
| --- | --- | --- | --- | --- |
| **Enterprise CI/CD Pipeline** | `35943103882` | `push` | `completed` / **`success`** | Workspace lint, application module validation |
| **Backend Production Testing CI** | `35943103796` | `push` | `completed` / **`success`** | Node 20.x build, migrations, all 39 unit/API test suites |
| **Mobile Flutter Analysis** | `35943103870` | `push` | `completed` / **`success`** | Flutter analyze (0 errors), 51 tests, release APK & AAB builds |
| **Flutter Web Preview** | `35943103798` | `push` | `completed` / **`success`** | Web build and GitHub Pages deployment |
| **Deploy Cloudflare Gateway** | `35943103774` | `push` | `completed` / **`failure`** | Dry-run passed; deploy blocked by missing `CLOUDFLARE_API_TOKEN` secret in GitHub repo |

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

## 5. Security & Operational Hardening Status

- **Live Gateway Auth Guard**: Verified HTTP 401 on unauthenticated requests (`/api/v1/observability/metrics`).
- **Fail-Safe Release Enforcement**: `resolveBaseUrl` throws `StateError` if `API_BASE_URL` is missing or unauthorized.
- **Service Recovery Configuration**: Windows SCM configured for automatic restart (`ArmSphereAPI`: 5s delay, `cloudflared`: 20s delay). Process termination protected under `LocalSystem`.
- **Secrets Hygiene**: Zero credentials committed; production environment loaded from host filesystem.

---

## 6. Release Gate & Authorization Boundary

- **Release Classification**: `READY FOR FINAL HUMAN APPROVAL`
- **Release Lock**: LOCKED. No modifications may be made to application source code without tagging a new Release Candidate (RC-2).
- **Public Publication Gate**: Strictly gated on human operator confirmation.
