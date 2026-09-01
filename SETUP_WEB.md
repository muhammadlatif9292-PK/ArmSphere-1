# Running the real ArmSphere app as a Flutter Web preview

This sandbox could inspect and edit the repo, but its outbound network is
locked to package-registry domains (npm, PyPI, crates, GitHub) and does not
include `pub.dev` or `storage.googleapis.com`, which is where the Flutter
SDK and Dart packages are actually served from. That means `flutter`,
`dart`, `flutter pub get`, and `flutter build web` cannot run here, and
this sandbox has no port-forwarding/hosting mechanism to hand you a live
URL even if they could. Run the steps below in a normal dev machine, a
Codespace, or a cloud IDE that has full internet access — everything here
is now genuinely ready for that.

## 1. Apply the two changes in this bundle

- Copy `apps/mobile/web/` from this bundle into your repo's `apps/mobile/web/`
  (new folder — Flutter Web was never configured; only `android/` existed).
- Overwrite your repo's
  `apps/mobile/lib/core/notifications/push_notification_manager.dart` with
  the one in this bundle. It removes the one `dart:io` import in the whole
  `lib/` tree (`Platform.isAndroid` / `Platform.localeName`), which is a
  hard *compile-time* failure on the web target — the rest of the file,
  and its behavior on Android/iOS, is unchanged. On web it now cleanly
  skips FCM registration (see the comment in the file for why) instead of
  crashing; every other feature is unaffected.

## 2. Install Flutter and fetch packages

```bash
cd apps/mobile
flutter pub get
flutter devices          # confirm "Chrome" or "Web Server" is listed
```

Flutter Web has been enabled by default since Flutter 2.5, so no
`flutter config --enable-web` should be needed on Flutter 3.44+.

## 3. Run the real backend locally (or point at production)

The mobile app already talks to the real Express/Postgres(Supabase) API via
`API_BASE_URL` (`--dart-define`, defaults to
`https://armsphere2.netlify.app` in `dio_client.dart`) — there is no
separate Supabase client SDK in the Flutter app, so the only network
dependency to satisfy is that one REST API.

**Local API (recommended for first run):**
```bash
cd apps/api
cp .env.example .env    # fill DATABASE_URL etc.
npm install
npm run dev              # tsx src/server.ts
```
Two things to set correctly in `apps/api/.env`, because both currently
default to the same value:
- `PORT` — defaults to `3000`.
- `CORS_ORIGIN` — also defaults to `http://localhost:3000` (see
  `apps/api/src/app.ts`, `allowedOrigins`). This must equal whatever origin
  the Flutter web preview actually runs on, not the API's own port.

Pick two different ports, e.g. API on `4000`, web preview on `3000`:
```
# apps/api/.env
PORT=4000
CORS_ORIGIN=http://localhost:3000
```

**Or point at the deployed production API instead of running one locally:**
the CORS allowlist in `apps/api/src/app.ts` only contains
`armsphere.com`/`www.armsphere.com`/`api.armsphere.com` in production, plus
whatever `CORS_ORIGIN` is set to in that deployment's environment. A
browser preview hosted anywhere else will otherwise have every API call
silently rejected by the browser's CORS check (not a 401 — the request
never completes). Add the preview's exact origin to `CORS_ORIGIN` on the
Netlify deployment before pointing the web build at production. I don't
have access to that Netlify project from this sandbox, so this step is
yours to do.

## 4. Launch the web preview against the real backend

```bash
cd apps/mobile
flutter run -d web-server --web-port=3000 \
  --dart-define=API_BASE_URL=http://localhost:4000
```
(or `flutter run -d chrome ...` for a browser window instead of a
headless server + URL). If you deploy the `build/web` output somewhere for
a *shareable* link (Netlify, Vercel, Firebase Hosting, GitHub Pages —
anywhere with `flutter build web`'s output), remember step 3's CORS note:
that deployed origin needs to be in the API's `CORS_ORIGIN`.

## Known, real limitations once it's running

- **Push notifications (FCM):** intentionally disabled on web in this
  patch. Firebase isn't configured for *any* platform in this checkout
  (no `google-services.json`, no `firebase_options.dart`, no Gradle plugin
  wiring) — Android/iOS push was already inert. Wiring it up for web
  additionally needs a Firebase Web app config, a VAPID key, and a
  `firebase-messaging-sw.js` service worker.
- **Stripe payment sheet** (`/settings/payment-methods`): `flutter_stripe`'s
  web support is officially experimental — only a subset of the native
  payment-sheet API is implemented, and it needs a Stripe.js `<script>` tag
  added to `web/index.html`. Not touched here since it's outside the
  first-launch/registration/browsing journey.
- **In-feed video playback** (`video_player_modal.dart`, used from the
  community feed): built on `webview_flutter`, whose web implementation
  renders an `<iframe>` and can't load every embed source cross-origin the
  same way the native WebView can. Worth a manual check once running.
