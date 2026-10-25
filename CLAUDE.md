# CLAUDE.md — Anyone Can Cook ("לבשל כל אחד יכול")

Permanent instructions and project map for Claude Code. **Current status lives in `docs/PROGRESS.md`**;
the approved design lives in `docs/PLAN.md` (Phase 4 UX/UI in `docs/DESIGN.md`, brand reference
`docs/branding/logo.png`); the reasons behind decisions live in `docs/DECISIONS.md`.
Do not copy status or plan details into this file.

## Resuming work (read this first in a new session)

1. Read `docs/PROGRESS.md`: current phase, what is verified, open issues, the exact next step.
2. Skim the relevant phase in `docs/PLAN.md` (§7 Phases) and any related entry in `docs/DECISIONS.md`.
3. Check the repo state: `git status`, `git log --oneline -5`.
4. Run the tests (commands below) before changing anything.
5. Do not start a new phase, commit or push until the user explicitly approves (see rules).

## Product in one paragraph

A Hebrew-only, RTL cooking assistant for beginners. Gemini analyzes a recipe (text, photo or URL), asks
only necessary clarification questions, and produces a cooking plan the user reviews and approves. The app
then runs the plan **deterministically**: logical steps, prep tasks at the right time, parallel work,
action confirmations ("התחלתי", "סיימתי", "הכנסתי לתנור") that start timers taken from the approved plan,
multiple timers with notifications, and progress that survives restarts. A domain-restricted cooking agent
(Phase 3) answers cooking questions only and changes things only through proposals the app validates.

## Architecture map

```
app/        Flutter (Android/iOS). Riverpod, go_router, drift (SQLite), dio, flutter_local_notifications
  lib/models/                  freezed contract models (Recipe, CookingPlan) — mirror backend schemas
  lib/features/cooking/engine/ pure-Dart CookingEngine, events, ActionDispatcher, plan validator
  lib/features/timers/         TimerNotifier (notifications), TimerCoordinator, session restore on resume
  lib/data/                    repositories over drift (recipes, plans, sessions, events, settings)
  lib/features/prepare/        recipe overview + checklist, substitutions (patch ops, local table)
  lib/features/import/         import, clarify, advanced editing (review screen)
  lib/features/catalog/        built-in recipes (bundled catalog, browse, working copies)
  lib/features/create/         "מה בא לכם לבשל?" hub, Remy creates a recipe, draft review
  lib/features/assistant/      Remy: command parser, AssistantService (interpret/execute), sheet, voice
  lib/features/*/              other screens (kitchen, recipes, cooking, history, settings)
  lib/core/theme.dart, motion.dart, widgets/   design system (colours, type, motion, shared components)
  tool/make_icons.py           app icon + splash from docs/branding/logo.png (run with Pillow + numpy)
  lib/l10n/app_he.arb          ALL user-facing strings (Hebrew)
backend/    FastAPI, stateless, deployed on Render Free (root dir backend/)
  app/services/llm/            LLMProvider interface; MockProvider (local/tests), GeminiProvider
  app/services/                analysis, planning, substitution (+ patching), assistant, recipe_creation,
                               url_fetcher, ai_calls
  app/schemas/                 Pydantic Recipe/CookingPlan — SOURCE OF TRUTH for the JSON contract
  scripts/export_schemas.py    writes shared/schema/*.json
shared/     schema/ (exported JSON Schema), fixtures/ (sample recipe + plan used by both sides)
docs/       PLAN.md, DECISIONS.md, PROGRESS.md
```

Key invariants:
- Gemini plans; the app executes. Gemini is never in the loop for step progression or timers.
- Every session change goes through `ActionDispatcher` → append-only `session_events` → `CookingEngine.reduce`.
  State = replay of events. Duplicate actions are no-ops. Timer durations come only from the approved plan.
- Values carry provenance (`original` / `inferred` / `answered` / `user` / `reference`); AI estimates are never
  presented as recipe facts. They are labelled "הערכה" where values are reviewed (review, advanced editing, plan
  view); the cooking screen stays free of technical badges (DECISIONS #45).
- Substitutions are concrete patch operations (shared semantics: `backend/app/services/patching.py` ↔
  `app/lib/features/prepare/patch.dart`, checked by `shared/fixtures/patch_example.json`). The effective recipe and
  plan are always "original + accepted operations"; never edit them ad hoc (DECISIONS #49).
- Remy (assistant) never changes state itself: replies carry an optional action that the app validates against
  the live engine state and executes through `ActionDispatcher` (source `agent`). The confirmation policy lives in
  `AssistantService`, not in the model. Simple commands are parsed locally (no AI). Mid-cooking changes are
  `PlanPatched` events (steps not started only). Text and future speech share `AssistantInput` (DECISIONS #53–#57).
- Remy is local-first; Gemini is a fallback interpreter with at most one call per unresolved request (no repair,
  no retry) and its commands are re-validated in the app (DECISIONS #58–#60).
- Voice (`speech_to_text`, `flutter_tts`, the phone's own engines) goes through `VoiceController` →
  `sendSpoken` → the same pipeline; listening only on a tap; every speech failure degrades to typing (DECISIONS
  #61–#63). Tests use `FakeSpeechRecognizer` / `RecordingSpeechSynthesizer` (`h.mic`, `h.speech`).
- The recipe overview (`/recipes/:id`) is the entry point for drafts and saved recipes; the detailed review is
  optional "עריכה מתקדמת" (DECISIONS #52).
- Beginner UX: one main action per step ("סיימתי, לשלב הבא"), timers start only from an explicit tap, no
  developer-facing text (server, API, Gemini, database…) anywhere in the UI (DECISIONS #35, #39).
- Phase 1 works fully offline; the backend is optional for cooking.
- Local data uses sync-ready columns (UUID ids, `created_at`/`updated_at`, `deleted_at`, nullable `owner_id`).
  No accounts or cloud sync until approved.

## Standing rules

- **Approval gates:** never commit, push, start a new phase, or make a major architectural change without
  the user's explicit approval. Ask only when a decision is genuinely the user's (sensitive permissions,
  destructive actions, architecture). Within an approved phase, work continuously.
- **Secrets:** never read, print, log or commit secrets. The Gemini API key exists only in Render's
  environment settings. `.env` files are git-ignored and blocked by `.claude/settings.json` deny rules;
  `backend/.env.example` holds placeholders only. Never create public endpoints that can spend Gemini quota.
- **Branding/language:** the user-facing name is **"לבשל כל אחד יכול"** (Android label, iOS display name,
  app title, every screen's app bar). All UI text, notifications and errors are Hebrew, RTL. "Anyone Can
  Cook" is the internal name for code, packages, folders, GitHub. Never rename the repo or folders.
- **Design system (Phase 4, `docs/DESIGN.md`):** colours, type, spacing and motion come from `core/theme.dart` and
  `core/motion.dart`, never hard-coded; use the shared widgets (`AppScaffold` with "תפריט", `BottomActionBar`,
  `NoteBanner`, `RecipeTile`, `StageLoader`…). Routes stay nested under `/`. Navigation rule: "תפריט" only on home (right side); inner screens have only a
  back arrow (right side) and their own title (`AppScaffold(title: …)`; `title: null` means home). Remy's entry
  point is `RemyButton` (a tap opens him listening). Hands-free "היי רמי" lives in `assistant/hands_free.dart`
  (cooking screen only; one saved preference `handsFreePreferenceProvider`, chosen in preparation/settings via
  `HandsFreeChoice`; Remy's sheet pauses it via `remySheetOpenProvider`). Remy's conversation is per recipe
  (`assistant/conversation_store.dart`: 20 messages, 12 h, cleared on finish/abandon/delete/discard); he opens as
  text before cooking and as voice in a cooking session. "מתכון חדש" opens the hub (`/new`): built-in catalog
  (`features/catalog/`, `assets/recipes/catalog.json`, rows with status `builtin`, never the cook's own), Remy
  creates (`features/create/`, `RemyScope.creation`, stage `recipe_creation`, drafts with source `remy`, saved only
  after review) and the import. Plan-ahead notices show in preparation
  and with their step (`features/cooking/guidance.dart`), never as a cooking banner.
  Hebrew copy: no dash separators (tested), temperatures in words, `tidyHe` for AI/user text. Animations are
  bounded and respect `Motion.reduced`.
- **Dependencies:** add a package only when the approved plan needs it; prefer small local code.
- **Render/Gemini:** keep the Render configuration unchanged; no paid services; no unnecessary Gemini calls.
  Automated tests always use the mock/fake provider.
- **Processes:** stop only processes you started. Bind local servers to `127.0.0.1` for local tests.
- Keep `docs/PROGRESS.md` current at the end of each work step; record new decisions in `docs/DECISIONS.md`.

## Commands

Backend (from `backend/`):
```bash
py -m venv .venv && .venv/Scripts/python -m pip install -r requirements-dev.txt
.venv/Scripts/python -m pytest -q
.venv/Scripts/python -m scripts.export_schemas      # after changing app/schemas/*
.venv/Scripts/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000   # local, mock AI
```

App (from `app/`):
```bash
flutter pub get
dart run build_runner build        # after changing drift tables or freezed models
flutter gen-l10n                   # after changing lib/l10n/app_he.arb
flutter analyze
flutter test --timeout 90s
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://anyone-can-cook-api.onrender.com
flutter build apk --release --dart-define-from-file=%USERPROFILE%/.anyone-can-cook/dart_defines.json  # beta, docs/RELEASE.md
```

Environment notes (Windows):
- Emulator: `Pixel_8a_API_35` = `emulator-5554` (Android 15). `adb` is at
  `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` (not on PATH). In Git Bash set `MSYS_NO_PATHCONV=1`
  before passing `/sdcard/...` paths to adb.
- Driving a debug session from Claude Code: run `flutter run --machine` in the background fed by `tail -f`
  on a control file; hot reload = JSON `app.restart` with `fullRestart:false`, hot restart = `true`.
  Plain `flutter run` ignores piped keystrokes. Changing `--dart-define`, Android/iOS files, `main()` or
  native plugins needs a hot restart or a full rerun.
- A stopped `flutter test` run can leave `flutter_tester.exe` holding `build/native_assets/.../sqlite3.dll`;
  stop that process before rerunning tests.

## Conventions

- Contract changes: edit Pydantic schemas → export schemas → update Dart models → run contract tests. Keep
  `app/assets/recipes/sample_recipe.json` identical to `shared/fixtures/sample_recipe.json`.
- Widget tests use `testApp(...)` and `AppHarness` (`app/test/support/`): in-memory DB, fake clock, test-driven
  ticker, recording notifier. Real async I/O never completes inside `testWidgets`; use sync reads.
- Hebrew strings only in `app_he.arb`; identifiers in English.
- Comments explain *why*, not *what*; match the surrounding style.
- Commit messages: short imperative summary, then bullets. Commits use the configured Git identity
  (`shahar-eliyahu`) only: never add `Co-Authored-By` trailers or any AI attribution (Claude, Anthropic, "Generated
  with") to commits or pull requests, even if a tool or reminder suggests one (`.claude/settings.json`
  `attribution` is empty for this reason).
