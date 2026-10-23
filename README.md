# Anyone Can Cook

A Hebrew-first (RTL) cooking assistant: Flutter app for Android/iOS + a small FastAPI backend that calls Gemini.

```
app/       Flutter app
backend/   FastAPI backend (stateless)
```

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

## Secrets

- Never commit `.env` files or keys; `.gitignore` excludes `.env` and `.env.*` (except `.env.example`).
- The Gemini API key lives only in Render's environment settings.
