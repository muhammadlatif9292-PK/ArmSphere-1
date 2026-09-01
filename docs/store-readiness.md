# ArmSphere Store Readiness Status

Tracks the blueprint §46 store-ready checklist for the mobile app (`apps/mobile`).
Status legend: DONE = verified in repo / CI · PENDING = requires an external action
that cannot be completed at zero cost from inside this repository.

## Android

| Item | Status | Notes |
| --- | --- | --- |
| Application ID | DONE | `com.armsphere.app` (`android/app/build.gradle`) |
| minSdk / targetSdk / compileSdk | DONE | 23 / 36 / 36 — meets Play requirement targeting Android 16 (API 36) |
| Version code/name | DONE | `1.0.0+1` from `pubspec.yaml`, injected via Flutter Gradle plugin |
| Release build verification | DONE | CI job "Android Release Build Verification" runs `flutter build apk --release` on GitHub Actions and uploads the APK artifact |
| Signing config | PENDING | CI release APK is debug-signed **for build verification only**. Play submission needs a real upload keystore: generate locally with `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`, add `android/key.properties` (gitignored), and wire `signingConfigs.release`. Keystore must be kept private; never commit it. |
| Launcher icon | DONE | Vector adaptive icon committed (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`); CI generates raster mipmaps mdpi→xxxhdpi via ImageMagick |
| Splash screen | DONE | LaunchTheme + Android 12+ splash attributes (`values-v31/styles.xml`) |
| Permissions | DONE | INTERNET, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS (runtime-requested by FCM), USE_BIOMETRIC (local_auth), READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE(maxSdk 32) (image_picker) |
| MainActivity | DONE | Extends `FlutterFragmentActivity` (required by local_auth) |
| google-services.json | PENDING | Push notifications (FCM) require a Firebase project. Download `google-services.json` into `apps/mobile/android/app/` and add the Firebase Gradle plugin. Code already degrades gracefully without it (try/catch in `push_notification_manager.dart`). |

## iOS

| Item | Status | Notes |
| --- | --- | --- |
| iOS scaffold + build verification | PENDING | Requires macOS/Xcode. Zero-cost path: add a free-fork macOS runner or use Codemagic free tier later. All Dart-side code is already iOS-ready (no platform-specific blockers). |

## Store listing assets & compliance

| Item | Status | Notes |
| --- | --- | --- |
| App metadata | PENDING | Title/short description/full description/screenshots/feature graphic needed at submission time (Play Console / App Store Connect). |
| Privacy policy | PENDING | Host a privacy policy URL (free: GitHub Pages under this repo). Must disclose FCM push, Stripe payments, biometric usage. |
| Account deletion | DONE | In-app account deletion endpoint wired to backend (blueprint Phase 11 deliverable); required for both stores. |
| Data safety form | PENDING | Complete Play Data Safety + Apple privacy nutrition labels at submission time based on the permission list above. |
| Reviewer / test account | PENDING | Provide demo credentials in the Play/App review notes. Backend seed accounts can be used; document them here before submission. |
| Production API base URL | DONE | `https://armsphere2.netlify.app` (HTTPS default baked into `dio_client.dart`; overridable via `--dart-define=API_BASE_URL=...`) |
| Crash behavior | DONE | No crash-reporting SDK yet (zero cost); Flutter default crash handling active. Add Sentry free tier only if desired later. |

## External dependencies summary (per blueprint §56 rule 20)

1. **Upload keystore** — user-generated, local-only; required before any store upload.
2. **Firebase project** — free tier; provides `google-services.json` (Android) and
   `GoogleService-Info.plist` (iOS) enabling FCM push notifications.
3. **Google Play developer account** ($25 one-time) and **Apple Developer Program**
   ($99/yr) — unavoidable store fees, outside the zero-cost software scope.
4. **macOS/Xcode** — required once for the iOS scaffold and archive builds.
