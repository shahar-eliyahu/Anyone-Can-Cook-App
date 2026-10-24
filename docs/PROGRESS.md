# Progress

Frequently changing status. Permanent rules are in `CLAUDE.md`; the approved design is `docs/PLAN.md`.
Update this file at the end of every work step.

_Last updated: 2026-10-24 (Phase 2 security hardening)_

## Phase status

| Phase | Status |
|---|---|
| 0 — Local foundations | ✅ Complete, committed and pushed (`1196478`). Render verified: `/health` 200, `/internal/ai-check` 404. |
| 1 — Deterministic cooking core (no AI) | ✅ Implemented, verified (automated + emulator), approved by the user, committed and pushed to `main` (see `git log`). |
| 2 — AI recipe analysis & planning | 🔄 Implemented with mock/fake providers and verified on the emulator against a local mock backend. Not committed. Live Gemini evaluation not run (needs approval). |
| 3 — Cooking AI Agent | ⏸ Not started. |
| 4 — Polish & release | ⏸ Not started. |

## Phase 1 — what exists

- **Contract:** Pydantic `Recipe`/`CookingPlan` (`backend/app/schemas/`), exported JSON Schema (`shared/schema/`),
  Hebrew sample recipe + plan (`shared/fixtures/sample_recipe.json`, bundled as an app asset), Dart freezed
  models, contract tests on both sides.
- **Engine** (`app/lib/features/cooking/engine/`): plan validator, events, `CookingEngine` (reduce, replay,
  step status, focus step, available actions, "meanwhile" parallel steps, prep-task surfacing, active timers,
  agent snapshot), `ActionDispatcher` (single entry point, `source: ui|agent`, serialized, idempotent,
  proposal-id dedup, undo, pause/resume/+1 min/dismiss).
- **Storage** (`app/lib/data/`): recipes + approved plans stored separately, sessions with one-active rule,
  append-only events, history, favorites, rename, soft delete with undo, settings, one-time sample seeding.
- **Timers:** `flutter_local_notifications` exact alarms (inexact fallback), stable notification ids,
  restore at startup and on every resume, plugin boot receiver, notification tap opens the session.
- **Screens (Hebrew/RTL):** המטבח שלי (continue-cooking banner), המתכונים שלי + מועדפים + search, recipe
  detail (favorite, rename, original source, delete+undo), plan review (read-only), cooking screen (timers
  tray, prep tasks, current step, confirmation for `always_ask`, בינתיים אפשר, all steps, undo), finish
  (notes), cooking history + detail, settings (notifications, exact alarms, battery, test notification).
- Notification permission and exact-alarm permission are requested when cooking starts.

## Verification so far

Automated at the end of Phase 1: backend **17/17**, Flutter **57/57**, `flutter analyze` clean (Phase 2 numbers below).

Emulator `emulator-5554` (Android 15), app built in debug, **network disabled** for the cooking flow:

| Check | Result |
|---|---|
| Hebrew name, RTL, sample recipe seeded and shown offline | ✅ |
| Plan review with estimate badges | ✅ |
| Prep task starts plan timer; alarm registered | ✅ |
| Exact alarms off by default (Android 14+) → found ~11 min window; fixed (prompt + reschedule on resume) | ✅ `window=0` after grant |
| Test notification while app in background | ✅ Hebrew title/body, channel `cooking_timers`, importance max |
| Double tap "הכנסתי לתנור" → one timer, one alarm | ✅ |
| Three timers at once (preheat, rice, bake) | ✅ |
| Force stop clears alarms → relaunch restores same alarms, progress and remaining times | ✅ |
| Device reboot → boot receiver restores alarms without opening the app | ✅ |
| App swiped from recents → alarms kept | ✅ |
| Real timer notification fired on time with the app closed | ✅ "⏰ חימום תנור: הזמן נגמר" |
| Tap timer notification → opens that cooking session | ✅ |
| Early completion cancels running timers; `always_ask` dialog; rest timer; finish → history | ✅ |
| Leave with Back, reopen (same process) → database writes | ✅ Found a hang (second Flutter engine in the same process); fixed with drift `shareAcrossIsolates`; re-verified twice in the same process (pid unchanged): actions, abandon and history all saved |
| Offline proof | ✅ Home showed "אין חיבור לשרת" during the cooking flow; reconnected to Render afterwards |

## Known issues / limitations

- Prep-task "due" timing is rule-based (`surface`, `needed_by_step` unlocked); no time estimate before a step.
- Backdated confirmations ("I put it in 5 minutes ago") not supported (as planned).
- iOS not built or tested (needs macOS / Codemagic, Phase 4).
- Typing into the notes field via `adb input text` was unreliable on the emulator (test-tool limitation;
  the widget test covers notes).
- System Hebrew font (no bundled Heebo) — styling deferred to Phase 4.
- Timer matrix items not covered on the emulator: battery saver / "restricted" app state and vendor-specific
  restrictions (Samsung, Xiaomi). Needs a real device.
- The "הערכה" badge explanation is on long-press only (not discoverable); revisit in Phase 4.
- Screen-on during cooking (wakelock) not implemented; avoided an extra package. Revisit if users need it.
- Cold start: the home screen's "המשך בישול" card briefly shows "אין בישול פעיל כרגע" before the active
  session loads (the card treats "still loading" as "no session"). Fix later with the UI/UX improvements
  (Phase 4): show a neutral loading state instead. Seen on the emulator 2026-10-24.

## Phase 2 progress

- **2.0 contract + engine — done.** Additive optional fields (`ingredient_uses`, wait guidance, range timers,
  `estimated_active_minutes`, `advance_notice_he`, `remind_before_needed`, provenance `reference`,
  `confidence`, `source_ids`), `RecipeAnalysis` contract, bread fixture. Engine: `waitGuidance`,
  `desiredNotifications`, `TimerShortened`, `TimerRechecked`, time-based prep urgency; the coordinator
  synchronizes notifications after every event. Cooking screen shows wait info, check time, range end,
  tips, next-step preview, the step's own action at check time and "עוד לא — לבדוק שוב".
  Tests: backend 22/22, Flutter 77/77 (57 Phase 1 + 20 new).
  **Only Phase 1 test change:** the flow test now expects "זמן לבדוק!" instead of "הזמן נגמר!" (user
  requirement: never imply food is ready); UI test helpers moved to `test/support/ui_helpers.dart`.

- **2.1–2.3 backend — done.** Error shape, `X-App-Token` deterrent, per-IP and daily limits (in memory),
  size caps, Gemini timeout/one retry/no retry on 429, repair call, number and provenance checks, gap
  resolution ladder, curated food-safety table (FSIS + Israeli guidance), home-preserving refusal, URL fetcher
  with SSRF guard (JSON-LD, then trafilatura), `/v1/recipes/analyze`, `/analyze-image`, `/plan`. Backend 99/99.
- **2.4–2.6 app — done.** Drafts (DB v2 migration), duplicate detection, import service, API client.
  Screens: ייבוא מתכון (text / photo / link, one-time privacy notice, duplicate prompt, progress stages,
  Hebrew errors per error code), clarify questions with "לא יודע/ת", editable review ("מה הוערך" with
  provenance badges, ingredient / instruction / timer / temperature corrections, source excerpts, photo
  preview, warnings and limitations, required check box, approve / cancel), drafts on the home screen,
  "עריכת המתכון והתוכנית" for saved recipes, out-of-date plan blocks cooking (regenerate with one /plan
  call, or "בדקתי — התוכנית נכונה"). Startup cleanup of old drafts and orphan photos. iOS camera/photo strings.
- **2.7 security hardening before deployment — done (2026-10-24).**
  - URL fetching: DNS rebinding fixed. The connection layer (`_PinnedBackend` in
    `backend/app/services/url_fetcher.py`) resolves each host once, refuses the host if any answer is
    non-public, connects to that checked IP itself (TLS still verifies the hostname), and then checks the
    socket's real peer address. Every redirect hop is a new origin and goes through the same check.
    Environment proxies are ignored. Also blocked now: IPv4-mapped IPv6, NAT64 (`64:ff9b::/96`), carrier-grade
    NAT, `0.0.0.0`/`::`. A total deadline (2 × `URL_FETCH_TIMEOUT_SECONDS`) stops slow-drip pages.
  - Request bodies: the size cap now also applies to bodies without `Content-Length` (chunked); at most the
    cap is held in memory (pure ASGI middleware `BodySizeLimit`).
  - Rate limiter: idle client entries are swept, so memory stays bounded.
  - Logs and errors: unexpected exceptions return `server_error` and are logged by type only (their messages
    can quote recipe content); AI error and plan-validation details sent to the app are generic.
  - Test guard: `backend/tests/conftest.py` makes creating a real Gemini client, or any network connection
    other than loopback, fail every test (with a self-test).
  - New tests (real sockets on 127.0.0.1 only): rebinding (public answer, then internal) never connects;
    the connection goes to the checked IP with the original `Host` header; redirects to internal and metadata
    addresses blocked on the real stack; a peer that differs from the checked IP is refused; mixed public/
    private answers refused; mapped/NAT64/CGNAT forms; slow drip; proxy variables ignored; chunked body over
    the cap; limiter sweep; content-free 500. A mutation check (connecting to the hostname instead of the
    checked IP) makes 4 of these tests fail.
- **Tests (zero real Gemini calls):** backend **122/122** on Python 3.14 and 3.12 (Render runs 3.12.9);
  Flutter **105/105**, `flutter analyze` clean. Earlier in Phase 2: backend 99/99; Flutter 105/105 (includes the Phase 1 tests), `flutter
  analyze` clean. New Flutter tests: edit rules, import service, import flows (text, questions, photo, offline,
  stale-plan block, reopen and cook with the fake API set to fail on any call).
- **Emulator (2026-10-24, local backend `AI_PROVIDER=mock` on 127.0.0.1, no token):** existing v1 database
  migrated to v2 with the active session kept; privacy notice shown once; text import → review with
  estimates; timer corrected to 50 min ("ערך שלך"); approval gated by the check box; backend log: the app made
  exactly 1 analyze + 1 plan call; with the backend stopped the saved plan reopened and cooking ran; the oven
  step used the corrected 50:00 timer with the 74°C food-safety check; one exact alarm (window 0).
  Found and fixed: an edited timer kept the AI's "estimated" note.

## AI quota and rate-limit handling (2026-10-24, not committed)

Checked what existed, changed only what was missing.
- Already in place: 429 never retried (backend or app); typed text and links stay in the field; drafts and
  clarification answers saved before the plan call; saved recipes, cooking, timers and notifications work
  with no backend (tests: offline cooking flow, reopen-and-cook with the fake API failing on any call).
- Added, backend: Gemini 429 bodies are classified from `QuotaFailure.quotaId` (`…PerDay…` → daily quota,
  `…PerMinute…` → short limit) and `RetryInfo.retryDelay`. Daily quota → `ai_quota_exhausted`, no
  `Retry-After` (reset time not promised; Gemini's `retryDelay` is ignored for daily quotas). Short limit →
  `ai_rate_limited` with `Retry-After` only when Gemini stated a delay (the old fixed "60" was removed).
  After a quota error the server stops calling Gemini for 1 hour (30 s, or the stated delay, for short
  limits) and answers the same error without a provider call; then it tries again.
- Added, app: separate Hebrew messages for daily quota, temporary limit (a wait time only if the server
  stated one) and service outage, each saying saved recipes and cooking keep working (the old "נסו שוב בעוד
  דקה" promise is gone). The unsent input (text, link or photo) is saved and restored when the import
  screen reopens; a failed photo import no longer deletes the photo. A plan-step failure right after
  analysis opens the saved draft with "נסו שוב", which retries only the plan (no second analysis call).
  Retry is always a user tap ("נסו שוב"), never automatic.
- Tests (all mocked, zero real Gemini calls): backend 135/135 (Python 3.14 and 3.12): 429 body parsing
  (daily, per-minute, unclear and malformed bodies), SDK `ClientError` mapping, daily quota pause with no
  further provider calls, stated vs unstated delays, quota during planning not repaired or retried. Flutter
  110/110: quota message and retry, input restored after leaving, wait time only when stated, plan-only retry,
  pending photo kept by cleanup.
- Needs the live run: confirm the real Gemini 429 body uses these `quotaId` names. If it doesn't, the
  app shows the general "temporary limit" message (safe fallback, no time promised).

## App icon (2026-10-24, not committed)

- Official logo (user-supplied, 2048×2048) as the app icon: source `app/assets/icon/app_icon.png` (lossless copy;
  not bundled into the app), monochrome silhouette `app_icon_monochrome.png` for Android 13+ themed icons.
  Generated with `flutter_launcher_icons` 0.14.4 run as a global tool (config `app/flutter_launcher_icons.yaml`)
  so the app's dependencies didn't change. The tool's edit to `ios/Runner.xcodeproj/project.pbxproj` (a known
  bug that breaks an unrelated build setting) was reverted; `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
  was already set.
- Android: legacy `mipmap-*/ic_launcher.png`, adaptive icon (`mipmap-anydpi-v26`) with the full logo as the
  foreground at inset 0 (logo within 0.301 of the size from the center: inside the 0.306 safe zone), background
  color, monochrome layer. Verified: APK declares the adaptive icon and label "לבשל כל אחד יכול"; installed on
  the emulator with data kept; launcher lists the app and it opens normally; circle/squircle/rounded masks
  simulated with nothing clipped. iOS: 25 icon sizes, no alpha, `Contents.json` valid (not built: needs macOS).
- Observed (pre-existing, not icon related): on a cold start the "המשך בישול" card briefly shows
  "אין בישול פעיל כרגע" while the database stream loads.

## Phase 2 — needs live testing (after deploy, with approval)

- Gemini accepts our structured-output schemas, `PLAN_MODEL`/`AI_MODEL` and the optional thinking level
  (unverified until a live call). First evaluation: ≤ 5 recipes, ≤ 15 calls, stop on quota or rate-limit errors.
- Plan quality on real Hebrew and English recipes: step grouping, labeled estimates, questions only when needed,
  food-safety warnings.
- URL import against real sites, over HTTPS through the pinned connection (TLS SNI/certificate with an IP
  connection is covered by httpcore's design, not by an automated test), and how often sites block it.
- Photo import with a real camera and a real recipe photo (the emulator run used text only).
- Render specifics: the client IP for per-device limits comes from the rightmost `X-Forwarded-For` hop
  (`TRUSTED_PROXY_HOPS=1`); confirm that two devices get separate limits. If Render's proxy chain differs,
  all users may share one limit (stricter, not a bypass).
- Cold start: the app's "server waking up" message during a real Render wake-up.

## Phase 2 — remaining limitations (accepted for private testing; revisit before a public launch)

- `X-App-Token` ships inside the app and can be extracted; it only deters casual use. Real per-user
  protection needs accounts or App Check (Phase 4).
- Rate limits and the daily AI cap live in memory: they reset when Render restarts or wakes the service.
  The worst case is spending the free Gemini quota (requests then fail with "busy"); no money is at risk
  while the Google project has no billing.
- Clients behind one IP (shared Wi-Fi, mobile carrier NAT) share the per-IP limit.
- Free Gemini tier: Google may use prompts to improve its products (the app's privacy notice says so).
- Prompt injection inside a recipe can only produce a wrong plan, which the user reviews; it can't reach
  secrets or server tools. Output is schema-checked, numbers are checked against the source.
- `/docs` and `/openapi.json` are public (they list endpoints, no data). Optional to disable later.
- Page text extraction runs on the request thread (CPU for up to 2 MB of HTML); fine at the current limits.
- iOS not built or tested.

## Next step

1. User review of the hardening; approval to commit locally (no push, no deploy yet).
2. Before any Render deploy, the user (not Claude): set `APP_CLIENT_TOKEN` and check the variables listed in
   the hand-over; the app is then built with the same `--dart-define=APP_CLIENT_TOKEN=…`.
3. With approval: first live evaluation (≤ 5 recipes, ≤ 15 Gemini calls, stop on quota errors), after
   checking the model's limits and remaining usage with the user.
