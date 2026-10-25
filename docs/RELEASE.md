# Private beta on Android: build, share, update

A small private beta for family and friends: one signed APK, sent directly, installed by hand. No store,
no accounts. Decisions: `docs/DECISIONS.md` #88.

## What lives where (nothing secret is in the repository)

| What | Where | In git? |
|---|---|---|
| Beta signing key | `%USERPROFILE%\.anyone-can-cook\signing\anyone-can-cook-beta.jks` | No |
| Key passwords and alias | `%USERPROFILE%\.anyone-can-cook\signing\key.properties` | No |
| Backend URL + app token for builds | `%USERPROFILE%\.anyone-can-cook\dart_defines.json` | No |
| `GEMINI_API_KEY` | Render environment only | No, and never in the app |
| Signing setup | `app/android/app/build.gradle.kts` reads `key.properties` from the folder above (or from the file named by `ANYONE_CAN_COOK_SIGNING`) | Yes (no values) |

The `.anyone-can-cook` folder is readable only by your Windows user. **Back up the `signing` folder** (both
files) somewhere private, such as an encrypted USB stick or a password manager. Without this exact key, no
update can ever be installed over the testers' app: they would have to uninstall it, which deletes their
recipes and history.

Without `key.properties`, release builds fall back to the debug key (a Gradle warning says so). Such an
APK is for local testing only: never send it to testers.

## Build a beta APK

From `app/`:

```bash
flutter analyze
flutter test --timeout 90s
flutter build apk --release --dart-define-from-file="%USERPROFILE%/.anyone-can-cook/dart_defines.json"
```

The output is `app/build/app/outputs/flutter-apk/app-release.apk`; copy it with a clear name, e.g.
`AnyoneCanCook-beta-0.9.0-build2.apk`. Check the signature before sharing:

```bash
"%LOCALAPPDATA%/Android/Sdk/build-tools/36.1.0/apksigner.bat" verify --print-certs app-release.apk
```

The signer must be `CN=Anyone Can Cook Beta, O=Anyone Can Cook, C=IL` (certificate SHA-256
`17333e89af915cdf37b08a51feafd4458d5ece22be7e9a55ea88bcc833052b08`).

## Send it to testers

- Send the APK file directly to each tester (WhatsApp as a *document*, email attachment, or a private
  Google Drive/OneDrive link shared only with them). Don't post it in public groups or open links.
- Tell them:
  1. Open the file on the phone and tap "Install".
  2. If Android asks, allow "Install unknown apps" for the app they opened it from (WhatsApp, Files,
     Chrome...). They can turn it off again afterwards.
  3. If Play Protect warns about an unknown app, choose "More details", then "Install anyway". The app isn't
     from the Play Store, so this is expected.
  4. Open "לבשל כל אחד יכול". Allow notifications (for timers) and, when Remy asks, the microphone.
  5. For timers that ring exactly on time, allow "Alarms & reminders" when the app asks.
- Requirements: Android 7.0 or newer, internet for importing recipes and for Remy's questions (cooking,
  timers and the built-in recipes work offline).

## Updates (keeping recipes and data)

1. Raise the build number in `app/pubspec.yaml` (`version: 0.9.0+2` → `0.9.0+3`; change `0.9.0` when you
   like). Android installs an update only when the build number is higher than the installed one.
2. Build with the same command (the same key is used automatically) and check the signature as above.
3. Send the new APK. Testers open it and tap "Update" (or "Install"): **no uninstall**. Recipes, preparation,
   cooking history, a cooking in progress and Remy's conversations stay.

Uninstalling the app deletes its data. That's only needed if someone has a copy signed with another key (for
example a development build installed from VS Code). Android then refuses the update ("App not installed" or
"conflicts with an existing package"). On your own phone, if it has a development build, export nothing,
uninstall, and install the beta: its data starts fresh.

## Limits for this beta (accepted)

- The app token (`X-App-Token`) ships inside the APK and can be extracted; it only deters casual use of the
  backend. The Gemini key stays on Render, so the worst case is using up the free daily Gemini quota.
- Per-device (per IP) rate limits and the app-wide daily AI cap are kept in memory on Render; they reset when
  the service restarts. Testers on the same Wi-Fi share one per-IP limit.
- On Render Free, the first request after a quiet period can take up to about a minute (the app says so).
