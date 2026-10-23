# Progress

Frequently changing status. Permanent rules are in `CLAUDE.md`; the approved design is `docs/PLAN.md`.
Update this file at the end of every work step.

_Last updated: 2026-10-24_

## Phase status

| Phase | Status |
|---|---|
| 0 — Local foundations | ✅ Complete, committed and pushed (`1196478`). Render verified: `/health` 200, `/internal/ai-check` 404. |
| 1 — Deterministic cooking core (no AI) | ✅ Implemented, verified (automated + emulator), approved by the user, committed and pushed to `main` (see `git log`). |
| 2 — AI recipe analysis & planning | ⏸ Not started. Needs user approval. |
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

Automated (latest run): backend **17/17**, Flutter **57/57**, `flutter analyze` clean.

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

## Next step

The user is reviewing and testing the Phase 1 app themselves. Do **not** start Phase 2 (AI recipe analysis &
planning, `docs/PLAN.md` §7) until the user explicitly approves it. Address any issues the user reports first.
