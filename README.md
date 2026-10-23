# Anyone Can Cook

A Hebrew-first (RTL) cooking assistant: Flutter app for Android/iOS + a small FastAPI backend that calls Gemini.

```
app/       Flutter app
backend/   FastAPI backend (stateless)
shared/    JSON contract: schema/ (exported from Pydantic) and fixtures/ (sample recipe + plan)
```

## Project docs

- `docs/PLAN.md` — approved development plan · `docs/PROGRESS.md` — current status and next step
- `docs/DECISIONS.md` — decision log · `CLAUDE.md` — standing rules and how to resume work (for Claude Code)

## Recipe/plan contract

The Pydantic models in `backend/app/schemas/` are the source of truth for the `Recipe` and `CookingPlan` JSON.
After changing them, re-export the JSON Schemas (a backend test fails if they are stale):

```bash
cd backend
.venv/Scripts/python -m scripts.export_schemas
```

The Dart models (`app/lib/models/`) mirror them; `app/test/contract_test.dart` checks the shared fixture
parses in Dart and that every emitted key exists in the schema. `app/assets/recipes/sample_recipe.json`
must stay identical to `shared/fixtures/sample_recipe.json` (also tested).

## Backend

### Run locally (mock AI, no API key needed)

```bash
cd backend
py -m venv .venv
.venv/Scripts/python -m pip install -r requirements-dev.txt
.venv/Scripts/python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

- `http://127.0.0.1:8000/health` → `{"status":"ok","version":"…","ai_provider":"mock"}`
- The Android emulator reaches it at `http://10.0.2.2:8000` (an alias for the PC's `127.0.0.1`).
- Only for a real phone on the same Wi-Fi, use `--host 0.0.0.0` (it exposes the server to your local network; Windows Firewall may ask).
- Settings come from environment variables or an optional `backend/.env` file — see `backend/.env.example`. Without any, the backend uses the mock provider.

### Tests

```bash
cd backend
.venv/Scripts/python -m pytest -q
```

Tests never call a real AI provider.

### Deploy (Render)

- Build command: `pip install -r requirements.txt` (runtime dependencies only)
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Root directory: `backend`
- Environment variables (set in Render, never in the repo): `AI_PROVIDER=gemini`, `GEMINI_API_KEY`, `AI_MODEL`, optionally `PARSE_MODEL` / `PLAN_MODEL` / `CHAT_MODEL`.

## Flutter app

User-facing name: **לבשל כל אחד יכול** (Hebrew-only UI, RTL). "Anyone Can Cook" is the internal project name.

```bash
cd app
flutter pub get
# after changing drift tables or .arb strings:
dart run build_runner build
flutter gen-l10n

flutter analyze
flutter test

# against the local backend (emulator alias for the PC's localhost)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
# against the deployed backend
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

Plain HTTP is allowed only in debug builds and only to `10.0.2.2`, `127.0.0.1` and `localhost`.

### How cooking works (offline)

- `lib/features/cooking/engine/` is a pure-Dart, deterministic engine. Every change goes through
  `ActionDispatcher` (UI buttons now, the AI agent in Phase 3) and is stored as an append-only event in
  SQLite (`session_events`). A session's state is rebuilt by replaying its events; duplicates are no-ops.
- Timer durations always come from the approved plan. Timers store their end time, so they survive restarts.
- Timer notifications are scheduled with `flutter_local_notifications`. They are restored at startup and on
  every resume (covers force stop and permission changes) and after reboot by the plugin's boot receiver.
- Android 14+ denies exact alarms by default; the app asks when cooking starts and in Settings, and falls
  back to inexact delivery (possibly minutes late) if refused.
- Cooking never needs the backend; the server status on the home screen is informational only.

## Secrets

- Never commit `.env` files or keys; `.gitignore` excludes `.env` and `.env.*` (except `.env.example`).
- The Gemini API key lives only in Render's environment settings.
