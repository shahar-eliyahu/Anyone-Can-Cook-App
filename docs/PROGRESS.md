# Progress

Frequently changing status. Permanent rules are in `CLAUDE.md`; the approved design is `docs/PLAN.md`.
Update this file at the end of every work step.

_Last updated: 2026-10-24 (origin/main at `9386cbb`: Phases 3C–3D; Phase 4 `bac3d0d` `73d2f01` `bf9853f` local only)_

## Phase status

| Phase | Status |
|---|---|
| 0 — Local foundations | ✅ Complete, committed and pushed (`1196478`). Render verified: `/health` 200, `/internal/ai-check` 404. |
| 1 — Deterministic cooking core (no AI) | ✅ Implemented, verified (automated + emulator), approved by the user, committed and pushed to `main` (see `git log`). |
| 2 — AI recipe analysis & planning | ✅ Complete, committed and pushed (`a6bd1f3` Phase 2, `a372736` app icon, `fa87e71` quota handling). Deployed on Render; live Gemini recipe test by the user passed (details below). |
| 3 — Beginner cooking experience + assistant | ✅ 3C, 3A, 3B, 3D (local-first Remy + voice) implemented and verified locally; on `origin/main` (not deployed to Render). |
| 4 — UX/UI redesign | ✅ 4B–4E implemented and verified locally (tests + emulator), committed locally, not pushed. Release work not started. |

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
- iOS not built or tested (needs macOS / Codemagic; release work).
- Typing into the notes field via `adb input text` was unreliable on the emulator (test-tool limitation;
  the widget test covers notes).
- Timer matrix items not covered on the emulator: battery saver / "restricted" app state and vendor-specific
  restrictions (Samsung, Xiaomi). Needs a real device.
- The "הערכה" badge explanation is on long-press only (advanced editing; the cooking screen shows no badges).
- Screen-on during cooking (wakelock) not implemented; avoided an extra package. Revisit if users need it.
- Cold start glitch ("אין בישול פעיל כרגע" before the session loads): gone in Phase 4; the cooking card appears
  only once a session is known.

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

## AI quota and rate-limit handling (2026-10-24, committed `fa87e71`, deployed)

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

## App icon (2026-10-24, committed `a372736`, deployed)

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

## Phase 2 — deployment and live test (2026-10-24)

- Deployed: `main` = `origin/main` = `fa87e71`; Render redeployed from it. `APP_CLIENT_TOKEN` set on Render by
  the user; the app is built with `--dart-define-from-file` pointing at a file outside the repository.
- Verified by Claude (read-only, no Gemini calls): `/health` → `ok`, `ai_provider: gemini`; the deployed API
  lists `/v1/recipes/analyze`, `/analyze-image`, `/plan`; `POST /v1/recipes/analyze` without a token → 401.
- Live test by the user (Android app → Render → Gemini, `gemini-3.5-flash-lite`, free tier: 15 RPM,
  250,000 TPM, 500 RPD): a real recipe (omelette) was analyzed, cooking steps ran, timers worked.
- Findings that shaped Phase 3: too many confirmations while cooking ("התחלתי"/"סיימתי" for nearly every
  action); the omelette got a 71°C thermometer check — caused by the backend's food-safety layer (step tagged
  `egg_dish`, a value meant for baked egg dishes), not by Gemini.

## Phase 2 — still to check live (as it comes up; each live run needs approval)

- Structured output and the model setting work (confirmed by the live recipe test). A broader evaluation
  (≤ 5 recipes, ≤ 15 calls) is still open.
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

## Phase 3 — status

- Product direction approved 2026-10-24 (`docs/PLAN.md` "Phase 3 — final product direction"; decisions #33–#47).
- Order: **3C** → **3A** (overview, checklist, substitutions) → **3B** (assistant) → Phase 4 → Future (voice).

### Phase 3C — implemented 2026-10-24 (local commit `536436c`)

- **Food safety (backend):** stovetop eggs (`eggs_stovetop`: omelette, scrambled, fried) → "cook until set, no runny
  egg", no temperature, no forced confirmation; baked egg dishes keep 71°C as reference value with an observable cue
  (knife comes out clean); all cues one practical sentence. Only poultry and ground meat are high-risk: one short
  warning line, the doneness cue and `always_ask`. Thermometer lines the model adds to non-high-risk steps are
  dropped unless the recipe itself mentions a thermometer. Fixes the omelette 71°C bug.
- **Prompts:** plan — ordinary step = one action "סיימתי"; timed step = explicit start action (starts the timer) +
  completion; short beginner instructions; observable cues; no unneeded equipment; optional `help_he`. Analyze —
  equipment only what the recipe needs.
- **Contract:** `PlanStep.help_he` (optional; schema_version stays 1); schemas re-exported; Dart model; sample fixture
  has help texts (asset copy identical); mock AI data regenerated.
- **Engine:** `ActionDispatcher.completeStep` (remaining actions as ordinary `ActionConfirmed` events from one tap;
  stops before a timer-start action) and `undoLast` ("חזרה": undoes the whole last tap or a prep task);
  `CookingState.primaryFor` (start timer / waiting / check due / next, with the safety-check flag) and a tap log
  rebuilt by replay. No new event types: old sessions replay identically.
- **Cooking screen:** current step big; one main button in a fixed bottom bar above the system navigation bar
  ("סיימתי — לשלב הבא", the start action with "כשתלחצו, יתחיל טיימר של …", "מוכן — לשלב הבא" + "צריך עוד זמן (+N דק')"
  from the plan's re-check time, "כבר מוכן? לשלב הבא" while waiting) and "חזרה"; inline safety check instead of a
  popup; help only on request; timer controls in a small menu; no estimate badges, status chips or per-action
  snackbars; "כל השלבים" collapsed with per-step undo.
- **History:** the detail is a friendly summary (date, status, duration or "פחות מדקה", steps with ✓, notes); the raw
  action log and the empty "approved changes" placeholder are gone. The finish screen uses the same duration label.
- **No developer-facing text:** home status card removed (server/AI mode/database version); a silent health request
  still wakes the server; import loading and error texts reworded (no server/AI-service wording); privacy notice
  names Google without "Gemini"; Settings test notification renamed "בדיקת התראות". Unused strings removed.
- **Cold start:** the continue-cooking card shows "…" while loading instead of "אין בישול פעיל כרגע".
- **Tests (all with fakes, zero Gemini calls):** backend 141/141 (new: stovetop/baked eggs, thermometer stripping,
  recipe that uses a thermometer, high-risk confirmation, help text); Flutter 123/123, analyzer clean (new:
  `complete_step_test.dart` 14 tests incl. replay of old sessions; developer-terminology test for import texts).
  **Intentionally changed tests:** `cooking_flow_test` (one tap per step, explicit timer start, inline safety
  check, "צריך עוד זמן", history summary), `wait_guidance_ui_test` (new button labels), `widget_test` (home has no
  server/database/AI text, still pings health once), helpers moved to `test/support/ui_helpers.dart`.
- **Emulator (Android 15), 2026-10-24:** new build installed over the existing app with data kept; home has no
  technical text; the Phase 2 session (old per-action events) resumed in the new layout at its oven check, with the
  inline safety check gating "מוכן — לשלב הבא"; airplane mode on: finished the oven step, started rice (one exact
  alarm added), "חזרה" cancelled it (alarm removed), finished rest and serving offline; history showed the new
  summary. Airplane mode turned off again afterwards.

### Phase 3C — limitations and follow-ups

- No live Gemini check of the new prompt rules yet (needs approval, ≤ 2 recipes / ≤ 6 calls). Until then, new plans
  from Gemini may still contain 2–3 actions per step; the one-button flow handles that.
- Saved recipes keep their old plan text (e.g. the earlier omelette's thermometer line); "rebuild the plan" is 3A.
- The review/advanced editing screen still uses technical terms ("מה הוערך", provenance badges): planned for 3A.
- The cold-start loading state is reviewed in code; no automated test (drift streams can't be held "loading"
  inside widget tests).
- The "cooking history changes" and "Android layout fixes" in the 3C approval had no written spec in this project;
  implemented as: beginner-friendly history summary, and a fixed bottom action bar inside the safe area (Android
  15 edge-to-edge) with wrapping rows. Adjust if something else was meant.

### Phase 3A — implemented 2026-10-24 (local commit `9e888f7`)

- **Flow:** import → (questions if needed) → **overview** (`/recipes/:id`, also for saved recipes): name, servings,
  estimated total and hands-on time (computed on the device), a short "שימו לב" card (warnings, limitations,
  safety-relevant estimates, photo note; "קראתי" only for drafts that need it), advance notice, the checklist of
  every ingredient (with amounts) and piece of equipment, and one main button "מתחילים לבשל" (drafts are approved
  then; "שמירה במתכונים שלי" saves without cooking). Favorite, rename, source, delete / cancel import in the menu;
  "עריכה מתקדמת" opens the Phase 2 review screen; "כל שלבי הבישול" the full plan.
- **Checklist:** "יש לי" per item, "יש לי הכול", "חסר לי" → a sheet: a local answer at once when the table has one,
  otherwise (or "לחפש פתרון אחר") the cook's note ("יש לי חלב") and one server call. Verdicts: works / changes the
  result (how) / not recommended / no reliable substitute (explained, item stays missing, cooking still allowed).
  Accepted substitutions show "במקום …", the effect, and "ביטול ההחלפה". Missing items are listed above the button.
- **Local table** (`app/lib/features/prepare/local_substitutions.dart`): sour cream ↔ yogurt, cream → milk + butter
  (not for whipping), buttermilk, butter → margarine / oil (not in pastry), self-rising flour, brown sugar, honey,
  milk → plant milk, garlic → powder, stock → water + powder; no scale (grams → cups/spoons with a density table,
  unknown ones named), no thermometer (honest signs-only wording, confirmation kept), no mixer (by hand).
- **Server:** `POST /v1/recipes/substitute` (token + rate limits; one AI call + at most one repair), `LlmSubstitution`
  schema, `substitute_recipe.md` prompt, `services/substitution.py` (answer → operations → apply → validate →
  safety recompute), `services/patching.py`; contract additions `Ingredient/Equipment.substituted_for/omitted`,
  `PlanStep.notes_he`; `substitution_response.schema.json`; mock answer for local development.
- **App internals:** `patch.dart` (same semantics as the server; shared fixture), `preparation.dart`
  (marks, substitutions, base snapshot, effective recipe/plan), `preparation_service.dart`, repository
  `savePreparation` / `applyPreparation` and extra-key preservation, API `substitute`, cooking and plan views show
  step notes ("🔄 …"), advanced edits lock substitutions, the old recipe detail screen was replaced.
- **Tests (fakes only, zero Gemini calls):** backend **158/158** (16 new: patch fixture, verdicts, notes, equipment,
  omit, safety recompute both ways, repair, endpoint token/422/rate limit); Flutter **152/152**, analyzer clean
  (new: patch fixture + local table + estimate 12, preparation service 10, overview/sheet widget flows 7).
  **Intentionally changed tests:** import flows land on the overview ("שימו לב" + "קראתי" instead of the review
  screen's check box); cooking flow starts with "מתחילים לבשל"; the stale-plan test reaches advanced editing from
  the overview menu.
- **Emulator (local backend, `AI_PROVIDER=mock`, 127.0.0.1), 2026-10-24:** new build installed over existing data;
  the Phase 2 recipe opened in the overview (time chips, "שימו לב", checklist); olive oil → sheet → one
  `/v1/recipes/substitute` call → accepted ("במקום שמן זית", effect, undo) → undo restored it → re-applied → cooking
  showed "🔄 במקום שמן זית: …" on the step; a new text import opened the overview directly ("קראתי" gates
  "מתחילים לבשל"). Test session abandoned, test draft discarded and the substitution undone afterwards.

### Phase 3A — limitations

- No automatic plan regeneration when an AI substitution stays invalid (#51); a user-initiated "rebuild the plan"
  for old saved recipes (#46) is still only possible through advanced editing after a change.
- Local rules don't rewrite instruction text (notes instead); quantities in local rules use simple ratios.
- The no-scale conversion covers common ingredients only; others are named in the effect line.
- The substitution prompt is untested against real Gemini (needs approval; suggested ≤ 5 substitutions,
  ≤ 10 calls).
- Mid-cooking substitutions are Phase 3B.

### Phase 3B — Remy, implemented 2026-10-24 (local commit `cd82fa6`)

- **Pipeline** (`app/lib/features/assistant/`): `AssistantInput(text, modality)` → `AssistantService.interpret`
  (local parser first, Remy for questions) → `AssistantReply` (answer, plain `speechHe` for future TTS, optional
  action, `requiresConfirmation`, source) → `AssistantService.execute` through `CookingActions` (the cooking
  controller → `ActionDispatcher`, source `agent`); result texts come from engine results. `AssistantController`
  keeps the conversation per session; `send()` is the single entry point for text now and speech in 3D.
- **Local commands (no AI, offline):** next/done ("הבא", "סיימתי…", "next"), back/undo ("חזרה", "תבטל"), time left
  ("כמה זמן נשאר?"), what now, help (the step's help text and cue), pause/resume, extend by a spoken duration
  ("תוסיף שתי דקות לאורז", "רבע שעה", "דקה וחצי"), reported real-world actions ("הכנסתי את התבנית לתנור",
  "הדלקתי את התנור") matched to available actions and prep tasks; intentions never confirm.
- **Confirmation policy:** see decision #56 (high-risk checks, early finish, "next" before a real-world start,
  partial matches, long extensions and all AI proposals ask first).
- **Engine:** `PlanPatched` event (decision #53) with dispatcher validation (`patchProblem`): steps without
  progress and timers not started only; plan + patches on replay; `displayRecipe` in the cooking view; history
  lists "שינויים בזמן הבישול". Patch helpers split into plan-only and recipe-only variants.
- **Server:** `POST /v1/assistant/turn` (`schemas/assistant.py`, `services/assistant.py`, `prompts/assistant.md`,
  `LlmAssistantTurn`), guardrails and validated proposals (extend a running timer / substitution via the 3A
  pipeline / step change on non-completed steps), one repair call, own rate limit, mock answer, exported
  `assistant_turn_response.schema.json`.
- **UI:** "רמי" button in the cooking screen's app bar → sheet with conversation, quick chips (מה עכשיו? / כמה זמן
  נשאר? / עזרה בשלב), text input and approval cards ("אישור" / "לא, תודה"). No microphone (Phase 3D).
- **Tests (fakes only, zero Gemini calls):** backend **173/173** on Python 3.14 and 3.12 (15 new: scope redirect,
  off-topic line, claim rewriting, proposal validation incl. substitution safety and completed steps, repair,
  limits, endpoint token and own rate limit); Flutter **181/181**, analyzer clean (29 new: parser 7, service 15,
  `PlanPatched` 5, Remy sheet 2).
- **Emulator (local backend `AI_PROVIDER=mock`), 2026-10-24:** cooking the sample: Remy sheet opened from the app
  bar; "מה עכשיו?" and "עזרה בשלב" answered from the plan; "next" finished the step through the engine; "back"
  undid it; an English test question made exactly one `/v1/assistant/turn` call (commands made none). Test session
  abandoned afterwards. Hebrew can't be typed through adb, so Hebrew commands were covered by automated tests.

### Phase 3B — limitations

- Local recognition covers common phrasings; anything else goes to Remy (online). Speech-specific phrasing will be
  tuned in 3D with real recognizer output.
- The conversation is kept in memory per open session (not stored).
- Remy's prompt and proposals are untested against real Gemini (needs approval; suggested ≈ 15 questions,
  ≤ 20 calls).
- The emulator's old sample recipe has no help texts (seeded before 3C); help falls back to the instruction.

### Phase 3D — local-first Remy and voice seams, implemented 2026-10-24 (local commit)

- **Local understanding:** word families instead of exact phrases (next, back, time, pause/resume, extend, help,
  what now, next step), one Hebrew prefix handled ("שסיימתי"), one-letter tolerance for longer words
  (transcription slips → confirmed first), uncertainty markers ("אולי", "נראה לי") → confirmed first, "מוכן?" is a
  question (answered with the cue), Hebrew number words with prefixes ("בחמש דקות"), "עוד קצת" → the plan's re-check
  time (asked), local answers: "כמה מלח?", "כמה מעלות?", "מה השלב הבא?", "מה צריך לשלב הזה?", "כמה שלבים נשארו?".
  Transcript noise ("…", one letter) → "לא הבנתי" with no call.
- **Gemini fallback interpreter:** `command` in `/v1/assistant/turn` (supported set only), validated on the server
  (ids, running timers, completed steps, bounds) and again in the app (live state); info commands answered from
  local data; real-world facts and undo always confirmed; unsure / low-confidence → confirmed. One call per
  request: no repair, `max_attempts=1` (no retry on unavailable, quota or rate limits). Minimal context.
- **Voice seams:** `voice.dart` (`SpeechRecognizer`, `SpeechSynthesizer`, silent default),
  `AssistantController.sendSpoken()`; spoken requests get `speechHe` spoken (recorded in tests).
- **Tests (fakes only, zero Gemini calls):** backend **186/186** (13 new: command interpretation, invalid commands,
  unsupported command, command vs proposal, no retry for unavailable / rate limit / quota, minimal context, schema
  failure after one call; 3 repair-based tests changed to the one-call behaviour); Flutter **227/227**, analyzer clean
  (46 new in `local_first_test.dart` + 1 spoken-input widget test: phrasings with zero calls, local Q&A, local
  clarification, noise, fallback interpretation, unsure interpretation, real-world facts confirmed, 5 invalid
  interpretations rejected, offline/timeout/quota/rate-limit/unavailable with one attempt, spoken = typed).
- **Emulator (offline, no backend), 2026-10-24:** Remy sheet: "done" finished the step, "back" undid it; test
  session abandoned afterwards.

### Phase 3D — voice, implemented 2026-10-24 (local commit)

- **Packages (approved, free):** `speech_to_text` 7.5.0, `flutter_tts` 4.2.5 (the lock adds only these plus
  `speech_to_text_platform_interface` and `speech_to_text_windows`). Android: `RECORD_AUDIO` + `<queries>` for the
  recognition and TTS services; iOS: Hebrew microphone and speech-recognition usage strings.
- **Code:** `voice.dart` (interfaces, `VoiceIssue`, providers), `voice_platform.dart` (Hebrew locale, error
  mapping, he-IL/iw-IL voice), `voice_controller.dart` (phases, partial transcript, continuous mode, notes);
  `AssistantController` returns replies and accepts "כן"/"לא" for a pending confirmation; mic + status line + stop +
  "שיחה רציפה" in the Remy sheet; a mic in the cooking app bar that opens Remy already listening.
- **Tests (fakes only, zero Gemini calls):** Flutter **244/244**, analyzer clean. 16 widget tests in
  `voice_test.dart`: spoken command acts locally and is spoken; typed = spoken; unsure → asks, "כן"/"לא" by voice;
  permission denied / no service / no Hebrew / offline at start; offline error while listening; silence; no Hebrew
  voice → text + steady note; partial transcript + finish by tap; stop and typing take over; continuous mode stops
  after 2 silences; cooking-screen mic; closing the sheet stops listening. 2 unit tests: error mapping, yes/no.
  The old spoken widget test moved into `voice_test.dart`. Backend **186/186** (unchanged).
- **Emulator (Pixel 8a API 35, offline, no backend), 2026-10-24:** mic visible in the cooking screen and the
  sheet; Android permission prompt; "Don't allow" → the Hebrew permission note, typing still worked; with the
  permission: "מקשיב…" + "עצירה", silence → "לא שמעתי. אפשר לנסות שוב.", "עצירה" → back to idle with nothing sent;
  the Hebrew TTS voice (he-IL) is available; typed "done"/"back" still finished/undid the step. Found and fixed:
  the emulator's recognizer lists 31 languages without Hebrew yet accepts `he_IL` (so Hebrew is tried, not
  refused); the no-Hebrew-voice note was hidden while listening (now a steady line). Test session abandoned and the
  microphone permission revoked again afterwards.

### Phase 3D — pending / limitations

- Real speech was not recognized on the emulator (no microphone input): recognition quality, real Hebrew
  transcripts → commands, and hearing the replies need a check on the user's phone.
- Recognition on most Android phones uses Google's service; offline Hebrew recognition depends on the phone
  (offline language packs). Without it the cook gets the offline note and can type; local commands work offline.
- The wake phrase ("Hey Remy") stays later. Local understanding is rule-based; unusual phrasings go to Gemini
  (online). The server interpretation is untested against real Gemini (needs approval).

### Phase 4A — UX/UI analysis and design proposal, 2026-10-24 (commit `bac3d0d`)

- Inspected every screen, the theme, routes, icons, copy and loading states. Proposal in `docs/DESIGN.md`:
  palette sampled from the final logo with contrast checked, Heebo typography, components, nested navigation with
  an always-visible "תפריט", final home structure, the beginner journey, Remy placement (labelled bottom-bar
  button in cooking, "שאלו את רמי" in preparation), motion patterns with reduced-motion fallbacks, friendly
  Gemini loading, RTL fixes, a Hebrew copy rule (no dashes), subphases 4B–4E.
- Bugs found (to fix in 4B, not yet changed): row chevrons point the wrong way in Hebrew (`chevron_left` mirrors);
  `context.go()` to flat routes leaves a one-page stack (no back arrow; Android back exits) after saving from
  advanced editing, on the finish screen and from history "continue"; 13 `.arb` strings plus some Dart and
  backend strings use dashes as separators.
- The logo is stored at `docs/branding/logo.png`.

### Phase 4B–4E — the redesign, implemented 2026-10-24 (local commits)

- **What:** design system, nested navigation + menu, every screen redesigned, Remy's identity, sheet and
  preparation scope, motion with reduced-motion fallbacks, real loading stages, copy without dashes, RTL fixes,
  new app icon and splash. Details: `docs/DESIGN.md` §12; decisions #65–#71.
- **Bugs found and fixed:** row chevrons pointing "back"; one-page stacks after `go()` (no back arrow, Android back
  exited); the bottom bar's `Align` covering the whole page (found by tests); a ListTile inside a coloured box
  (ink hidden); recipe filter chips and Remy's chips overflowing at 200% text; Remy's sheet overflowing at 200%
  text; the continuous-conversation chip scrolled out of view; the degree sign flipping sides; the "הערכה" badge
  turning green with the new colour roles; the disabled start button not saying why; stray pixels and a channel
  mix-up in the first icon generation (caught in previews).
- **Tests (fakes only, zero Gemini calls):** Flutter **266/266**, analyzer clean (19 new in `phase4_ui_test.dart`:
  back stack from a deep link and after `go()`, Android back, the menu, cooking surviving navigation with timers
  and undo, RTL arrows, keyboard, small phone + 200% text on every main screen, Remy and the main action never
  overlapping, reduced motion, the home cooking card, Remy before cooking (local answers offline, cooking actions
  wait, proposals never applied); 3 in `copy_rules_test.dart`; existing tests updated for the new copy and
  structure). Backend **186/186** on Python 3.14 and 3.12 (copy constants and prompt style rule).
- **Emulator (Pixel 8a, Android 15), 2026-10-24:** home, menu, overview, Remy in preparation (offline answer),
  cooking (step card, prep task, timer controls, amber states), Remy in cooking, abandon dialog, history list and
  detail, settings, advanced editing; new recipe through a local mock backend (127.0.0.1, mock AI): the real
  reading stage, the draft overview with its notes (draft discarded afterwards); Android back through nested pages
  (detail → history → home → leaves only from home); reduced motion via the system animation setting (restored
  afterwards); the new launcher icon and splash. Test session abandoned afterwards.
- **Not verified on a real device:** the soft keyboard (the emulator uses a floating handwriting bar; covered by a
  widget test), haptics, TalkBack/VoiceOver reading order, real speech recognition and spoken replies, iOS (icon
  set and launch screen generated but not built), launcher icon shapes on other vendors' launchers.

### Phase 4 refinement — voice-first Remy, "היי רמי", Hebrew bar layout, 2026-10-24 (local commit)

- **What:** a tap on Remy listens at once; voice-first sheet; Remy listens for the answer to his own yes/no
  questions; hands-free "היי רמי" in the cooking screen (switch, remembered, loop of recognizer sessions, sheet
  hand-off, auto-close, screen kept on); "תפריט" moved to the top-right corner with back beside it on every screen.
  Details: `docs/DESIGN.md` §13; decisions #72–#75.
- **Bugs found and fixed:** the hands-free loop waited on the keep-screen-on platform call (never answers in
  tests; now fire-and-forget); an extra recognizer session around each hand-off (now a hand-off flag and an
  ordered release); reading provider state in a dispose callback (Riverpod assertion); the sheet's list squeezed
  by the header and notes (slim header, flexible notes, the question inside the "כן/לא" card); **on the emulator:**
  opening Remy while hands-free listened failed with "משהו השתבש" because the recognizer was still releasing
  (now a 300 ms start while the sheet slides in, plus one quiet retry on a busy recognizer).
- **Tests (fakes only, zero Gemini calls):** Flutter **279/279**, analyzer clean. New: `hands_free_test.dart` (wake
  phrase matching, off by default and remembered, "היי רמי, סיימתי" with no touch, "היי רמי" then a request,
  ignored kitchen talk, a hands-free yes/no answer, touch keeps the sheet, a tap on Remy pauses and resumes, leaving
  stops listening, permission and offline reasons), voice tests rewritten for tap-to-listen (incl. the busy
  retry), a bar-layout test (menu in the right corner on every screen, back beside it, drawer from the right).
- **Emulator (Pixel 8a, Android 15):** menu/back positions; a tap on Remy asked for the microphone, then listened
  at once; hands-free on: Google's recognizer listening in he-IL (online; no offline Hebrew pack on the emulator),
  the window's KEEP_SCREEN_ON flag, sessions restarting about every 20–60 s with no errors; stopped and flag
  cleared when leaving cooking and in the background, restarted on return and on resume; tapping Remy paused it
  and it resumed after the sheet closed. The test session was abandoned, hands-free turned off and the microphone
  permission revoked afterwards.
- **Not verified:** saying "היי רמי" for real (the emulator has no microphone input), recognition accuracy for the
  phrase in a noisy kitchen, restart sounds on specific phones, battery use over a long cook, iOS.

### Shared-link import (share.google), 2026-10-25 (local commit)

- **Finding:** `https://share.google/8zYO39TZnZUazYh3t` → 302 `www.google.com/share.google?q=…` → 301 chef-lavan.co.il
  (a recipe page, plus a `?shem=` tracking parameter). The redirects were already followed; the site answers servers
  with an Imperva (Incapsula) bot-check page (HTTP 200, a 212-byte script), so the import ended as `no_recipe_found`
  ("לא מצאנו מתכון בדף"), which was misleading. The protection is respected, not bypassed.
- **Backend (`url_fetcher.py`, `errors.py`):** bot checks detected (only when no recipe was found) → `site_blocked`;
  shortener dead ends → `link_unresolved`; redirect limit 3 → 5; link wrappers unwrapped; `<meta refresh>` pages
  followed; errors carry `site` and `resolved_url` (tracking parameters removed). SSRF checks, timeouts and size
  limits unchanged and covered for unwrapped and refreshed targets.
- **App:** the site is named ("האתר chef-lavan.co.il לא מאפשר לאפליקציות לקרוא…", "הקישור מוביל אל …"), with
  "להדביק את טקסט המתכון" (switches to the text tab) and "העתקת הכתובת המלאה" (clipboard); a link is picked out of
  shared text ("כותרת… https://share.google/…"); the link stays in its field and in the saved pending input.
- **Tests:** backend **200/200** on Python 3.14 and 3.12 (13 new: share chain, 5 hops, bot checks of several vendors,
  no false positive on a real page with protection scripts, shortener dead end, wrappers, refresh pages, SSRF on
  unwrapped/refreshed targets, error JSON with `site`/`resolved_url`); Flutter **283/283** (4 new).
- **Live check (no Gemini):** the real fetch pipeline on the reported link returns `site_blocked` (imperva) with
  site chef-lavan.co.il; on the emulator against a local mock backend the app showed the named message, copied the
  address and kept the link. The emulator keeps that link as the saved pending input until the next import.
- **Limits:** sites behind bot protection can't be imported by link (by design); links that resolve only with
  JavaScript in a browser are reported, not resolved; the backend change ships only with an approved deploy.

## Next step

1. User reviews Phase 4 on a real phone (`bac3d0d`, `73d2f01`, `bf9853f` are local only; Phase 3D is on
   `origin/main` at `9386cbb`); tries "היי רמי" in a real kitchen.
2. With approval: push; small live Gemini checks (3C plan rules ≤ 2 recipes / ≤ 6 calls; 3A substitutions ≤ 5 /
   ≤ 10 calls; 3B/3D Remy ≈ 15 questions / ≤ 20 calls), then deploy (the backend copy and prompt style rule ship
   with that deploy).
3. Release work only after approval.
