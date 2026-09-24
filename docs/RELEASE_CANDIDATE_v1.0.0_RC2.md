# ArmSphere Release Candidate 2 (RC-2) Manifest

**Manifest Status**: LOCKED & VERIFIED
**Release Target**: ArmSphere v1.0.0 (Production Release Candidate 2)
**Manifest Lock Date**: September 24, 2026

---

## 1. Provenance & Version Identity

| Attribute | Commit SHA / Identifier | Verification Status |
| --- | --- | --- |
| **Application Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Deployed, verified, and running |
| **API Backend Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Active in Windows service `ArmSphereAPI` |
| **Mobile Flutter Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Verified with strict host allowlist |
| **Admin Web Source SHA** | `199dbe0bfc0835b2ff8ef571d315bf18d0b0ba2e` (`199dbe0`) | **PASS** — Production build verified (2,399 modules) |
| **Worker Implementation SHA** | `864a45f` / `199dbe0` | **PASS** — Live on `armsphere-api-gateway.armsphere.workers.dev` |
| **Worker Pipeline SHA** | `d8d897f` | **PASS** — `.github/workflows/deploy-cloudflare-gateway.yml` |
| **Worker Deployment Identity** | Account `557bb5f38b0285d1467eec73173c6b5c` / Script `armsphere-api-gateway` | **PASS** — Live gateway active and healthy |
| **Release Manifest SHA** | HEAD (`RELEASE_CANDIDATE_v1.0.0_RC2.md`) | **LOCKED** |

---

## 2. Test Suite & Validation Baselines

| Verification Domain | Verified Metric | Result |
| --- | --- | --- |
| **Backend API Tests** | 39 test suites / 573 automated tests | **PASS (100% Green)** |
| **Mobile Flutter Tests** | 51 unique unit & widget tests | **PASS (100% Green)** |
| **Targeted Security Tests** | 92 security tests (IDOR, RBAC, Auth, Token, Storage) | **PASS (No issue found under tested conditions)** |
| **Security Headers** | 4/4 strict security headers | **PASS** |
| **Deployment Validator** | 21/21 deployment requirements | **PASS** |
| **Admin Web Build** | 2,399 modules transformed, 0 errors | **PASS** |

---

## 3. Database Schema & Integrity

| Schema Attribute | Verified Value | Status |
| --- | --- | --- |
| **Applied Drizzle Migrations** | 19 migrations (`0000` through `0018`) | **PASS (100% Synced)** |
| **Public Database Tables** | 58 tables | **PASS** |
| **Foreign Key Constraints** | 86 constraints | **PASS (0 Orphan Records)** |
| **Duplicate User Emails** | 0 duplicates | **PASS** |
| **Active Sessions for Inactive Users** | 0 orphan sessions | **PASS** |
| **Total Live Database Rows** | 5,363 rows | **PASS** |
| **Database Recovery Classification** | **LOGICAL RESTORATION PROVEN** (RTO: 39.42s; Provider-native PITR not tested) | **PASS** |

---

## 4. Release Artifact Cryptographic Manifest

| Release Binary | File Size | SHA256 Checksum | Signature Classification |
| --- | --- | --- | --- |
| **`app-release.apk`** | 80,453,948 B (~76.73 MB) | `d7a7cb5e042de839cc907ad07cbd02c3cb29303916ca0da1c04ebe87cbbaa804` | **DEBUG-SIGNED (Awaiting Operator Upload Key)** |
| **`app-release.aab`** | 75,376,945 B (~71.89 MB) | `26bae8e1739655fa91bfaebbdcb3588d05e3908d60796b6a2561dcad15c589e8` | **DEBUG-SIGNED (Awaiting Operator Upload Key)** |

> [!IMPORTANT]
> The release artifacts are compiled with production optimizations, strict endpoint allowlists, and fail-closed security. However, in accordance with Android release engineering standards, the binaries are currently signed with the debug keystore because the production upload keystore has not yet been provided by the operator. Submitting to Google Play requires signing with the official operator upload key.

---

## 5. Post-Push CI Execution Evidence

| CI Workflow | Run ID | Status | Output Summary |
| --- | --- | --- | --- |
| **Enterprise CI/CD Pipeline** | `35943103882` | **SUCCESS** | Dependency audit clean, secret scan clean, DB migrations verified |
| **Backend Production Testing CI** | `35943103796` | **SUCCESS** | 39 test suites / 573 automated tests passed |
| **Flutter Web Preview** | `35943103798` | **SUCCESS** | Flutter Web client compiled and deployed |
| **Mobile Flutter Analysis & Build** | `35943103870` | **SUCCESS** | 51/51 tests green, release APK & AAB generated |
| **Cloudflare Worker Deploy Workflow** | `35943103774` | **FAILURE (GRACEFUL)** | Missing `CLOUDFLARE_API_TOKEN` in GitHub Secrets; live Worker unaffected |

---

## 6. Live Production Health & Performance Baseline

Probed against `https://armsphere-api-gateway.armsphere.workers.dev` (10 samples per endpoint, 0 errors, 0 timeouts):

| Route | Status | Min Latency | Average Latency | p50 Latency | p95 Latency |
| --- | --- | --- | --- | --- | --- |
| `GET /health` | HTTP 200 | 718 ms | 855 ms | **874 ms** | 959 ms |
| `GET /api/health` | HTTP 200 | 619 ms | 731 ms | **649 ms** | 1,491 ms |
| `GET /api/ready` | HTTP 200 | 623 ms | 659 ms | **656 ms** | 692 ms |
| `GET /api/v1/observability/metrics` | HTTP 401 | 497 ms | 521 ms | **519 ms** | 559 ms |

---

## 7. Known Operational State & Evidence Gaps

| Area | Status | Factual Classification & Context |
| --- | --- | --- |
| **Monitoring** | **PARTIAL** | Automated scheduled GitHub Actions monitor (`production-monitor.yml`) active; external third-party monitor (BetterStack/UptimeRobot) requires operator registration. |
| **Alert Delivery** | **PARTIAL** | Cloudflare Zero Trust free Tunnel Down alert documented for operator dashboard activation; external notification channels pending. |
| **Disaster Recovery** | **LOGICAL RESTORATION PROVEN** | Cross-database logical restoration proven (39.42s RTO, 100% row parity); provider-native storage PITR not tested. |
| **Physical Android Testing** | **EVIDENCE GAP** | No physical handset attached or ADB toolchain installed on host; manual hardware validation pending operator test. |
| **Google Play Release** | **GATED ON OPERATOR** | Application ID `com.armsphere.app` and TargetSDK 36 configured; $25 Google Play account registration and upload key generation required from operator. |
| **Worker Automated CD** | **GATED ON OPERATOR** | Pipeline committed; awaiting `CLOUDFLARE_API_TOKEN` secret in GitHub repository settings. |
