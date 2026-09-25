# ArmSphere Open Decisions & Human Review Register
**Unresolved Questions, Hardware Validation Gaps & Operator Choices**
**Document Version**: 1.0.0
**Status**: ACTIVE TRACKING

---

## 1. Questions Requiring Human Visual & Operator Approval

| # | Question / Topic | Impact Area | Operator / Human Decision Required | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Q1** | **Physical Table Scorepad Feel** | Mobile UX / Officiating | Manual physical testing of the 64dp score buttons on a physical Android handset with chalked/sweaty hands at a real table. | **AWAITING HANDSET TEST** |
| **Q2** | **FCM Push Notification Activation** | Live Match Callouts | Operator must download `google-services.json` from their free Firebase project into `apps/mobile/android/app/` to enable background push alerts. | **GATED ON OPERATOR** |
| **Q3** | **Google Play Console Registration** | App Distribution | Operator must complete the one-time $25 Google Play Console registration with verified `com.armsphere.app` Application ID. | **GATED ON OPERATOR** |
| **Q4** | **Audio Effects in Vibrate Mode** | Game Polish | Confirm whether sound effects (`challenge_accepted.wav`, `match_won.mp3`) should be strictly muted when Android hardware ringer is set to Vibrate. | **PROVISIONAL (Mute in vibrate)** |
| **Q5** | **Cloudflare Alert Delivery Rule** | Observability | Operator must configure the 1-click email notification rule in Cloudflare Zero Trust Dashboard for automated tunnel down alerts. | **GATED ON OPERATOR** |
| **Q6** | **Preferred Dual-Role Default View** | Navigation / Home | Should dual-role users (Athlete + Referee) automatically launch into Referee mode if they have a match assigned within 30 minutes? | **PROVISIONAL (Yes, auto-prompt)** |

---

## 2. Low-Confidence / Provisional Items

1. **Ambient Hero Video Loop in National Championships**:
   - *Classification*: `EXPERIMENTAL`.
   - *Risk*: Memory and battery consumption on entry-level Android devices (2GB/3GB RAM).
   - *Mitigation*: Disabled by default unless device reports >4GB RAM and active WiFi connection.
2. **Double-Elimination Bracket LOD Rendering**:
   - *Classification*: `PROVISIONAL — HUMAN REVIEW RECOMMENDED`.
   - *Risk*: Text readability on 64-player brackets when zoomed out to 30% scale.
   - *Mitigation*: Pinned list view alternative provided via AppBar icon.
