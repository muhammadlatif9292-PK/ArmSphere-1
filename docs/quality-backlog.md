# ArmSphere Engineering Quality & Perfection Backlog

Prioritized engineering backlog for platform improvements following Release Candidate 1 (RC-1).
None of these items are launch-blocking. They are prioritized strictly by technical merit and operational value.

---

## Priority Classification Scheme

- **BLOCKER**: 0 items (System has zero launch blockers).
- **HIGH**: Substantial operational value or high-impact developer velocity improvement.
- **MEDIUM**: Meaningful feature enhancement or UX improvement.
- **LOW**: Optimization, minor refactoring, or polishing.
- **NICE-TO-HAVE**: Speculative or cosmetic enhancement.

---

## Backlog Items

### 1. External Monitoring & Outbound Alert Delivery [HIGH]
- **Category**: Observability & SRE
- **Description**: Complete the 1-click notification rule in Cloudflare Zero Trust Free Dashboard to deliver automated email alerts to `Muhammadhamadlatif94747@gmail.com` when the tunnel connection status changes.
- **Rationale**: Eliminates dependency on active manual probing; enables immediate notification during host internet drops.

### 2. Google Play Console Upload Key Ceremony [HIGH]
- **Category**: Mobile Distribution
- **Description**: Generate production `upload-keystore.jks` using Java `keytool`, store outside Git, and register app in Google Play Console with the verified `com.armsphere.app` Application ID.
- **Rationale**: Required for uploading `.aab` bundles to Google Play Store internal testing or production tracks.

### 3. Dedicated GDPR Data Export Endpoint [MEDIUM]
- **Category**: Data Privacy & Compliance
- **Description**: Implement a `GET /api/v1/user/export-data` endpoint that packages user profile, tournament history, and match records into a downloadable JSON/ZIP archive.
- **Rationale**: Complements the existing GDPR anonymized account deletion mechanism with a self-service data portability export.

### 4. Push Notification Provisioning (Firebase FCM) [MEDIUM]
- **Category**: Mobile UX
- **Description**: Download `google-services.json` from a free Firebase project into `apps/mobile/android/app/` to activate FCM background push notifications.
- **Rationale**: App currently degrades gracefully without it; adding the config enables instant round call-out alerts for athletes.

### 5. Automated Physical Device Testing in CI (Firebase Test Lab Free Tier) [LOW]
- **Category**: QA & Mobile Testing
- **Description**: Wire GitHub Actions to submit release APKs to Firebase Test Lab's free Spark tier (5 virtual / 1 physical test per day).
- **Rationale**: Closes the physical hardware testing evidence gap without recurring hardware costs.

### 6. Neon Read-Replica Caching for Public Brackets [LOW]
- **Category**: Performance & Scaling
- **Description**: Cache public tournament brackets in memory or Cloudflare Edge KV cache with a 30-second TTL.
- **Rationale**: Protects PostgreSQL connection pool from spikes during high-concurrency tournament viewings.

### 7. Dark/Light Theme System Polishing [NICE-TO-HAVE]
- **Category**: UI Polish
- **Description**: Add subtle haptic feedback on match score increments in the referee scoring screen.
- **Rationale**: Enhances in-hand referee experience at physical armwrestling tables.
