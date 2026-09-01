# ArmSphere web preview via GitHub Codespaces

Your repo already has a GitHub remote:
`https://github.com/muhammadlatif9292-PK/ArmSphere-1.git` (branch `main`).
That makes this simpler — no new repo needed.

## 1. Add these three items to your local repo (on Windows)

Copy from this bundle into `E:\Armsphere 1\`:
- `.devcontainer\devcontainer.json` → new folder, tells Codespaces to boot
  with Flutter and Node.js already installed, and to auto-forward ports
  3000 (web preview) and 4000 (API) as **public** URLs.
- `apps\mobile\web\` → same web scaffold as before (skip if you already
  copied this in from the earlier bundle).
- `apps\mobile\lib\core\notifications\push_notification_manager.dart` →
  same fix as before (skip if already applied).

## 2. Commit and push

In `E:\Armsphere 1`:
```
git add .devcontainer apps/mobile/web apps/mobile/lib/core/notifications/push_notification_manager.dart
git status
```
Check the `git status` output before committing — confirm nothing under
`.env`, `node_modules/`, `build/`, or `.dart_tool/` is staged (your
`.gitignore` already excludes these, this is just a sanity check since
these are real production credentials).
```
git commit -m "Add Flutter Web preview support + Codespaces devcontainer"
git push origin main
```

## 3. Open a Codespace

- Go to `https://github.com/muhammadlatif9292-PK/ArmSphere-1`
- Click the green **Code** button → **Codespaces** tab → **Create codespace
  on main**
- Wait for it to build (first boot pulls the Flutter image + installs
  Node — a few minutes) and run `postCreateCommand`
  (`flutter pub get` + `npm install`), all inside the cloud container,
  nothing touches your Windows machine.

## 4. Set up the API's .env inside the Codespace

The Codespace is a fresh environment — your local `.env` doesn't come
along (and shouldn't, it's gitignored on purpose). In the Codespaces
terminal:
```bash
cd apps/api
cp ../../.env.example .env
```
Edit `.env` (use the Codespaces file explorer, or `nano .env`) and fill in
the same values you used locally: `DATABASE_URL`,
`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, etc. Set:
```
PORT=4000
CORS_ORIGIN=<leave for step 6, come back and fill this in>
```

## 5. Start the API

```bash
cd apps/api
npm run dev
```
Leave this terminal running. Codespaces will pop up a notification that
port 4000 is available — that's expected (the `scheduled_jobs` log spam
from before is still harmless and unrelated).

## 6. Get the forwarded URLs, then fix CORS

Open the **Ports** tab (bottom panel, next to Terminal). You'll see 3000
and 4000 listed once each service is running. Copy the forwarded URL for
**3000** — this is your actual shareable preview link once step 7 starts
the app, but you need it now to finish the `.env`:
```
CORS_ORIGIN=https://<your-codespace-name>-3000.app.github.dev
```
Paste that into `apps/api/.env`, save, then stop and restart `npm run
dev` (Ctrl+C, rerun) so it picks up the new value.

## 7. Start the Flutter web preview

Open a second terminal (the `+` in the terminal panel) in the Codespace:
```bash
cd apps/mobile
flutter run -d web-server --web-port=3000 --dart-define=API_BASE_URL=http://localhost:4000
```
Note: `API_BASE_URL` stays `http://localhost:4000` even though you're in
the cloud — both processes are in the same container, so `localhost`
between them is correct. It's only the *browser's* address (port 3000)
that's the public forwarded URL from step 6.

## 8. Open it

Click the forwarded **3000** URL in the Ports tab (or the popup that
appears) — that opens in a real browser, on any device, and is the
shareable link. Since you set its visibility to Public in
`devcontainer.json`, anyone with the link can open it without a GitHub
login.

## Notes
- Codespaces' free tier includes a monthly quota of core-hours — fine for
  this kind of session-based testing, just remember to stop the Codespace
  when you're done (Codespaces list → "..." → Stop codespace) so you don't
  burn hours idle.
- If `flutter run -d web-server` errors immediately, check the Codespace
  actually finished `postCreateCommand` (Terminal → "Codespaces" output
  channel) before running commands manually.
