# ArmSphere Release Readiness & Candidate Gate

Authoritative reference defining criteria, checks, and release gates for releasing ArmSphere into public production.

---

## 1. Release Candidate Criteria [DEMONSTRATED]

A release candidate is qualified ONLY when all technical gates are green:

1. **Git & Provenance**:
   - Clean Git working tree (`git status` clean).
   - Exact commit SHA pinned.
   - Cloudflare Worker deployment tied to commit SHA via `.github/workflows/deploy-cloudflare-gateway.yml`.
2. **Automated Testing**:
   - 51/51 mobile tests green (`flutter test`).
   - 14/14 endpoint tests green.
   - 92/92 security tests green.
   - 0 Flutter analyzer errors (`flutter analyze`).
3. **Artifact Integrity**:
   - Release APK built and checksummed.
   - Release AAB built and checksummed.
   - Strict production fail-closed base URL verified (`https://armsphere-api-gateway.armsphere.workers.dev`).
4. **Database & Migrations**:
   - 19/19 migrations synced.
   - 58 tables, 86 foreign keys audited with 0 orphans.
5. **Observability & Recovery**:
   - Live public gateway probes responding HTTP 200.
   - SCM recovery actions verified for all host services.
   - Cross-database disaster recovery proven (< 60s RTO).

---

## 2. Android Store Submission Checklist [DOCUMENTED]

| Item | Requirement | Status |
| --- | --- | --- |
| Application ID | `com.armsphere.app` | Verified (`build.gradle`) |
| Version | `1.0.0+1` | Verified (`pubspec.yaml`) |
| Min / Target SDK | 23 / 36 | Verified |
| Signing Key | Upload Keystore JKS | User-managed (Template provided) |
| Target API Gateway | Cloudflare Worker (`.workers.dev`) | Verified (Fail-closed enforced) |
| Privacy Policy | Hosted URL | Required at Play Console submission |
| Data Safety Form | Disclose FCM, Biometrics, Photos | Prepared based on manifest permissions |
| Reviewer Credentials | Test Account for Store Review | Seed script available (`seedReviewer.ts`) |

---

## 3. Human Approval Gate [DEMONSTRATED]

The final release action is strictly **HUMAN-APPROVAL-GATED**:
- No automated pipeline or background worker has authority to publish to the Google Play Store or switch DNS.
- Operator explicitly reviews and signs off on the locked Release Candidate Manifest prior to launch.
