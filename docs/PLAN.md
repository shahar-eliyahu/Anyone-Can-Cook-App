# Anyone Can Cook — Revised Development Plan (v2)

> **Status:** approved by the user on 2026-10-24. This is the design of record; change it only with the
> user's approval and log the change in `docs/DECISIONS.md`. The "Context" section below describes the
> project as it was when the plan was approved. For current status see `docs/PROGRESS.md`.
> Later clarifications that refine this plan (Hebrew branding, functionality-first UI, exact-alarm handling)
> are recorded in `docs/DECISIONS.md` and `CLAUDE.md`.

## Context
At approval time, Phase 0 was partly done:
- The FastAPI backend has a swappable provider design: `LLMProvider` in `backend/app/services/llm/base.py`, with `MockProvider` and `GeminiProvider`, chosen by `factory.get_llm_provider()` from settings.
- It is deployed on **Render Free** with `AI_PROVIDER=gemini`.
- A real Gemini call (`gemini-3.5-flash-lite`) was verified through the temporary token-protected `/internal/ai-check` endpoint. The token has since been removed from Render.
- No Flutter code exists yet.

The product vision is now sharper: an intelligent, Hebrew-first cooking assistant. The AI *plans* the cooking, and the app *runs* it with deterministic logic. The user mostly confirms actions (התחלתי / סיימתי / הכנסתי לתנור), and timers start automatically from the approved plan.

This revision changes five things:
1. Recipe analysis becomes a **two-step AI flow**: analyze → ask clarification questions only when needed → generate a **cooking plan** the user reviews and approves.
2. A **deterministic cooking engine** in Flutter controls step progression, timers and restore after restart.
3. A **domain-restricted Cooking AI Agent** answers only cooking questions and sees the recipe and the live cooking state.
   - It can **confirm actions from natural Hebrew** ("הכנסתי את העוגה לתנור"), using the same engine path as the buttons.
   - It changes things only through proposal "tools" that pass deterministic checks and the user's approval preferences.
4. **Saved recipes, cooking history and a personal area ("המטבח שלי")** run on local SQLite. The data model is designed so accounts and cloud sync can be added later without a rewrite.
5. The **phases are reordered** so the riskiest deterministic parts (engine and timers) are built and tested first, using a sample plan, before any AI work.

### Decisions kept from v1
- Flutter + Riverpod + go_router + drift (SQLite), a thin stateless FastAPI backend, Gemini behind `LLMProvider`, and the model set through environment variables.
- Recipes and progress stay on the device. There are no accounts in the MVP.
- Every value carries a provenance tag (`original` / `inferred` / `user`). This revision adds a fourth value, `answered`, for values that come from a clarification answer.
- Hebrew-only RTL UI with strings in `.arb` files, and a simple feature-folder Flutter structure.
- Mock provider for local development and tests. Real Gemini only on Render.

---

## 1. Architecture overview

```
 Flutter (device)                                     FastAPI on Render (stateless)
 ┌───────────────────────────────────────────┐       ┌──────────────────────────────────┐
 │ Import → Clarify → Review & Approve Plan   │──1──► │ POST /v1/recipes/analyze         │
 │                                            │──2──► │ POST /v1/recipes/plan            │
 │ Cooking screen  ◄── CookingEngine (pure    │       │ POST /v1/agent/turn  (Phase 3)   │
 │                     Dart, deterministic)   │──3──► │  validators: schema, logic,      │
 │ TimerService + local notifications         │       │  provenance, food-safety         │
 │ drift: recipes, plans, session event log   │       │  LLMProvider → Gemini / Mock     │
 └───────────────────────────────────────────┘       └──────────────────────────────────┘
```
- **Gemini's job:** extract the recipe, decide which questions are needed, build the plan (steps, dependencies, parallel work, prep timing, suggested timers), answer questions, and propose changes.
- **Flutter's job:** run the approved plan deterministically (which step is current, what is ready, timers, notifications, persistence). Gemini is **never** in the loop when a step advances or a timer fires.
- **The backend stores no data.** Every AI request carries what it needs: the recipe, the plan, or a snapshot of the cooking state.

---

## 2. Recipe-planning pipeline (AI)

### Call 1: `POST /v1/recipes/analyze`
- **Input:** `{type: text|image|url, content}`.
  - For a URL, the backend fetches the page, uses schema.org JSON-LD when the page has it, and otherwise extracts the main text with `trafilatura`.
  - Image input is a single phone-compressed JPEG.
- **Output:** `RecipeAnalysis`
  - `recipe`: title, servings, ingredients (with quantities), equipment, `source_steps[]` (the original sentences, each with an id), and stated times and temperatures. Every value carries a provenance tag.
  - `questions[]`: `{id, text_he, why_he, kind: choice|number|text, options[], affects: ["ing_3.quantity"], required}`.
  - `is_recipe: false` plus a reason, when the input isn't a recipe.
- **When to ask:** only when the missing information blocks a correct or safe plan. Examples:
  - no oven temperature
  - no baking time
  - a pan size that changes the time a lot
  - a missing quantity for a key ingredient

  There are **at most 3 questions**. Anything less important is filled in as `inferred`, with a note, instead of asked. The app shows the questions on one Clarify screen, and the user can answer or tap "לא יודע/ת", which tells the AI to use its estimate.

### Call 2: `POST /v1/recipes/plan`
- **Input:** the `recipe` from call 1 plus `answers[]`. Answered values get the provenance `answered`.
- **Output:** a `CookingPlan` (see §3). The rules for splitting steps (requirement 5), enforced through the prompt and checked by the validator:
  - Each step covers one logical unit of work ("הכנת הרוטב", not one sentence).
  - A new step starts at a waiting point (a timer), a change of equipment or station, or a change in what the user's hands are doing.
  - Each step has 1–3 actions for the user to confirm.
  - Every plan step links back to the `source_steps` it came from.

### Validation (backend, on every AI response)
1. **Pydantic schema check.**
2. **Logic checks:**
   - all ids resolve
   - `depends_on` contains no cycles
   - every action that starts a timer points to a timer that exists
   - timer durations and temperatures are within sane bounds
   - every source step is covered by the plan
3. **Provenance check:** any number tagged `original` that doesn't appear in the source text is downgraded to `inferred`.
4. **Food-safety check:** a small rule table, for example poultry or minced meat that has an inferred cooking time or temperature. These get a `warning_he` and a highlighted "בדקו מוכנות" cue. Unsafe instructions are rejected.

If validation fails, the backend makes one repair call that sends the errors back to the model. If that also fails, it returns a clear Hebrew error.

### Plan review and approval (Flutter)
- The user sees the steps, prep tasks and timers.
  - AI estimates show a "הערכה" badge.
  - Timers and temperatures can be edited, and an edit changes the provenance to `user`.
  - The user taps **"אישור התוכנית"**.
- The approved plan is saved and stays fixed during cooking. The only way it changes is a patch the user has approved (§5).

**Cost per recipe:** 2 Gemini calls, or 3 if a repair is needed. The settings `PARSE_MODEL` and `PLAN_MODEL` (new) override `AI_MODEL`, which today is `gemini-3.5-flash-lite`.

---

## 3. Data model (shared JSON contract)

Pydantic models in `backend/app/schemas/` are the source of truth. They are exported to `shared/schema/*.json`. A hand-written sample plan in `shared/fixtures/` is loaded by both backend tests and Flutter tests (contract test).

```jsonc
// CookingPlan (simplified)
{
  "plan_version": 1,
  "steps": [{
    "id": "s3", "title": "צליית העוף", "instruction_he": "…", "source_refs": ["src4","src5"],
    "ingredient_ids": ["i1"], "equipment_ids": ["e1"],
    "depends_on": ["s2"], "kind": "active|passive", "parallel_ok": false,
    "actions": [
      {"id": "a1", "type": "in_oven", "label_he": "הכנסתי לתנור", "starts_timer": "t1",
       "confirm_policy": "auto_ok"},
      {"id": "a2", "type": "done",    "label_he": "הוצאתי מהתנור", "completes_step": true,
       "confirm_policy": "always_ask"}       // set by the backend validator (see §5.3)
    ],
    "timers": [{"id": "t1", "label_he": "עוף בתנור", "seconds": 2700,
                "provenance": "original|inferred|answered|user", "note_he": null}],
    "temperature": {"value": 200, "unit": "C", "provenance": "original"},
    "doneness_cue_he": "…", "warnings_he": []
  }],
  "prep_tasks": [{
    "id": "p1", "kind": "preheat_oven|boil_water|mise_en_place|thaw|other",
    "text_he": "הדליקו תנור ל-200°", "needed_by_step": "s3",
    "lead_minutes": {"value": 15, "provenance": "inferred"},
    "surface": {"with_step": "s1"},           // or {"at_start": true}
    "timer": {"id": "tp1", "label_he": "חימום תנור", "seconds": 900, "provenance": "inferred"},
    "confirm_policy": "auto_ok"
  }]
}
```
- `actions[].type` is a fixed set: `start | done | in_oven | out_of_oven | custom`. Flutter shows only these buttons.
- The recipe (ingredients and equipment) and the plan are stored separately, so the plan can be regenerated without importing the recipe again.

---

## 4. Cooking engine & state (Flutter, deterministic)

**A pure Dart `CookingEngine` with no Flutter imports.** It takes an injected clock, so it can be unit-tested exhaustively.

- **Events** (append-only, stored in SQLite as the session's event log):
  - `SessionStarted`
  - `ActionConfirmed(stepId, actionId, source: ui|agent, proposalId?)`
  - `PrepTaskDone(id, source: ui|agent, proposalId?)`
  - `TimerPaused/Resumed/Extended(+60s)/Dismissed(id)`
  - `StepUndone(id)`
  - `PlanPatchApplied(patch)`
- **State** = `replay(plan, events)`. It holds:
  - the status of each step: `locked | ready | in_progress | waiting_timer | done`
  - the prep task statuses
  - timers stored as `{startedAt, durationS, pausedRemaining, state}`
- **`reduce(state, event)` returns a new state plus effects.** The effects are `ScheduleNotification`, `CancelNotification` and `PlaySound`. Examples:
  - Confirming `in_oven` produces `timer t1 started` and `ScheduleNotification(t1, endsAt)`.
  - When `t1` finishes, the step waits for its `out_of_oven` / `done` confirmation.
- **Derived views** the UI reads:
  - `currentStep`
  - `readyNow`
  - `meanwhile`: steps marked `parallel_ok` whose dependencies are done, shown while a passive timer runs
  - `prepTasksToShow`: tasks whose `surface` condition is met, plus "הדליקו תנור עכשיו" when `needed_by_step` is within `lead_minutes`, estimated from the active steps left before it
  - `activeTimers`
- **Restore after restart:**
  1. Load the plan and its events.
  2. Replay them.
  3. Cancel the session's scheduled notifications and reschedule the active ones.
  4. Any timer whose `endsAt` has passed shows as finished.

  Because timers are stored as start times, not countdowns, nothing drifts.
- **TimerService / NotificationService** (as in v1): `flutter_local_notifications` `zonedSchedule` with `exactAllowWhileIdle`, exact-alarm permission with a fallback, rescheduling on boot, battery-optimization guidance in Settings, and a dedicated high-importance channel.
- **Single dispatch path.** UI buttons and the agent both call **`ActionDispatcher`**:
  - `confirmAction(stepId, actionId, source)`
  - `completePrepTask(id, source)`

  These produce the same engine events, so the reducer, timers and notifications behave the same whichever source the action came from. **Timer durations always come from the approved plan,** through the action's `starts_timer` or the prep task's `timer`. No caller, UI or agent, ever passes a duration.
- **Idempotency:**
  - Confirming an action that is already confirmed, or completing a prep task that's already done, is a **no-op** that returns `already_done`.
  - A timer id that's already running is never started twice. Its notification is scheduled once.
  - A repeated `proposalId` is ignored.
- **`engine.availableActions()`** lists the actions that can be confirmed right now: the step is ready or in progress, the action isn't confirmed yet, and earlier actions in the step are done. `engine.pendingPrepTasks()` does the same for prep tasks. Both buttons and the agent use these lists.
- **Assistant snapshot:** `engine.snapshot()` returns compact JSON for the agent (requirement 10):
  - the current step, completed and pending steps
  - `available_actions[]`, each `{step_id, action_id, label_he, starts_timer: {id, label_he, seconds} | null}`
  - `pending_prep_tasks[]`
  - active timers with remaining seconds
  - `next_guidance`: the next step, what can be done meanwhile, and prep tasks that are due, all computed deterministically

---

## 5. Cooking AI Agent (domain-restricted, approval-gated)

The agent is a **cooking-only assistant**, not a general chatbot. It needs no agent framework: it's one FastAPI endpoint, one Gemini call per turn, a small tool registry, and deterministic guardrails around the model.

### 5.1 Endpoint & context
`POST /v1/agent/turn`
- **Input:**
  - `{message_he, recipe, plan, snapshot?, history(last 6 turns), action_results[]}`
  - `snapshot` comes from `engine.snapshot()` (§4): the current step, completed and pending steps, and active timers with remaining seconds. It's present only during cooking. The agent also works on the Plan Review screen, using the recipe and plan only.
  - `action_results[]` reports what happened to earlier proposals: `{proposal_id, status: applied|rejected|invalid}`. This lets the agent describe what really happened.
- **Uses the existing `LLMProvider.generate_structured()`**, so the interface doesn't change and the call works the same with `GeminiProvider` and `MockProvider`. History and context are serialized into the prompt.
  - Untrusted text (recipe content, page text from a URL, user messages) is wrapped in clearly labeled data blocks.
  - `CHAT_MODEL` sets the model, falling back to `AI_MODEL`.
- **Output (structured):**
  ```jsonc
  { "intent": "cooking_question|session_question|action_confirmation|action_request|out_of_scope|unclear",
    "has_off_topic_part": false,
    "answer_he": "…",
    "tool_calls": [{ "name": "propose_confirm_action",
                     "args": { "step_id": "s3", "action_id": "a1", "evidence_he": "הכנסתי את העוגה לתנור" },
                     "confidence": "high|low" }],
    "safety_note_he": null }
  ```
  **Tool calling uses structured output**, not provider-native function calling. The model picks from a declared list of tools and argument schemas, which are included in the prompt and the response schema, and the backend validates every call. This keeps the provider layer neutral and easy to test with the mock. Gemini's native function calling can replace it later inside `GeminiProvider` without changing the contract.

### 5.2 Intent handling
**Scope is defined by what's allowed, not a blacklist.** The model classifies the intent of each message from the message itself and its context: the current recipe, the plan and the session.
- **In scope:** cooking, recipes, ingredients, kitchen equipment, food preparation, substitutions, food storage and food safety, menu planning for a meal, and the current cooking session.
- **Out of scope: everything else**, regardless of topic. That includes cars and mechanics, politics, sports, programming (even about this app), general trivia, and unrelated personal questions.
- **Borderline cases:**
  - Greetings and thanks get one short friendly line.
  - "מי אתה?" gets a one-line introduction plus the redirect.
  - Medical or diet-therapy questions get general food information plus a safety note to consult a professional.

| Intent | Behavior |
|---|---|
| `cooking_question` | Recipes, techniques, ingredients, substitutions, food prep, equipment. A short, natural Hebrew answer. |
| `session_question` | "כמה זמן נשאר לעוף?", "מה עכשיו?". Answered from `snapshot`. For "מה עכשיו?" the model rephrases `next_guidance` naturally. Never invents state it wasn't given. |
| `action_confirmation` | The user reports something they **already did**: "הכנסתי את העוגה לתנור", "סיימתי לחתוך את הירקות", "הדלקתי את התנור". Returns `propose_confirm_action` or `propose_complete_prep_task`, matched to `available_actions` or `pending_prep_tasks`. Statements about the future or intentions ("אני עומד להכניס…") are **not** confirmations; those get a short answer and no tool call. |
| `action_request` | "תוסיף 5 דקות לטיימר", "אין לי חמאה". Returns proposal tool calls plus a short explanation phrased as a **suggestion**. |
| `unclear` | One short clarifying question, with no tool calls. |
| `out_of_scope` | The backend replaces the answer with the fixed redirect message: **"אני עוזר הבישול של Anyone Can Cook. אני כאן כדי לעזור במתכונים, מרכיבים ותהליך הבישול. במה אוכל לעזור לך במטבח?"**, and drops any tool calls. |

**Mixed messages,** for example "כמה זמן לבשל אורז ומי ניצח אתמול במשחק?":
- The model answers only the cooking part and sets `has_off_topic_part: true`.
- The backend then adds one fixed line: **"לגבי שאר השאלה — אני כאן רק לעזרה במטבח."**
- The redirect wording is a constant in code, so it's always the same.

### 5.3 Tool registry
The tool names are shared by backend and Flutter. **Every tool is a proposal, and nothing runs on the server.**

| Tool | Args (validated) | Applied by Flutter as |
|---|---|---|
| `propose_confirm_action` | `step_id`, `action_id`, `evidence_he` (**no duration field**; the schema forbids extra fields) | `ActionDispatcher.confirmAction(…, source: agent)`. Any timer starts from the plan. |
| `propose_complete_prep_task` | `prep_task_id`, `evidence_he` | `ActionDispatcher.completePrepTask(…, source: agent)`. A prep timer, such as preheating, starts from the plan. |
| `propose_timer_change` | `timer_id`, `new_seconds`, `reason_he` | `TimerExtended`, or a timer edit on a step that hasn't started |
| `propose_add_timer` | `step_id`, `label_he`, `seconds`, `reason_he` | `PlanPatchApplied` (adds a timer) |
| `propose_substitution` | `ingredient_id`, `replacement_he`, `quantity`, `effects_he` (taste, texture, time) | `PlanPatchApplied` (`replace_ingredient`) |
| `propose_plan_update` | `summary_he`, `ops[]` from the fixed set: `set_timer_seconds`, `add_step_note`, `scale_quantity`, `insert_step_after`, `remove_pending_step` | `PlanPatchApplied` |

**When a confirmation from the chat is applied automatically.** Flutter decides this with fixed rules, never the model. A confirmation proposal is **applied immediately**, with a 5-second **"בטל"** undo toast, only when **all** of these hold:
1. The setting `agent_action_mode` (stored in `app_settings`) is **"לבצע אוטומטית כשברור"**. This is the default. The other option is **"תמיד לשאול"**.
2. The tool is `propose_confirm_action` or `propose_complete_prep_task`. **Plan changes always need an approval card.**
3. The turn has **exactly one** confirmation proposal, with `confidence: "high"`.
4. The target is in `availableActions()` or `pendingPrepTasks()` right now, so it isn't locked, already done or a duplicate.
5. The target's `confirm_policy` is `auto_ok`. The backend plan validator sets `always_ask` on actions in steps with food-safety flags or warnings, such as taking poultry out.

**Otherwise:**
- If one of rules 1, 3 or 5 fails but the target is valid, Flutter shows a one-tap confirmation card, for example "להתחיל טיימר 'עוגה' (35:00)?".
- If several actions could match, Flutter shows candidate chips taken from `availableActions()`.
- If the target is invalid or already done, nothing changes and the result is `invalid` or `already_done`. Flutter's reply says what happened, for example "זה כבר סומן כבוצע — הטיימר כבר רץ (12:30 נותרו)".

**Feedback text comes from the engine's result,** using fixed templates such as "✓ סומן: הכנסתי לתנור · טיימר 'עוגה' הופעל (35:00)", never from the model. An undo emits `StepUndone`, which cancels the timer and its notification.

**Not supported in the MVP:** "הכנסתי לפני 5 דקות". The timer starts now, and the user can adjust it with the timer controls.

**Execution flow (requirement 6):**
1. The backend validates each tool call. It must be a known tool name, the arguments must match the schema, the ids must exist in the plan, and the values must be within bounds. Invalid calls are dropped and logged by name only.
2. Flutter validates each call again against the **live engine state**. Proposals can't change steps that are done, can't cut short a running timer without showing it, and can't refer to a missing id.
3. Flutter shows an approval card with the before and after values and **"אשר" / "בטל"**.
4. Only an approval turns into an engine event. The result (`applied`, `rejected` or `invalid`) goes back in the next turn's `action_results`. Only the app's UI says "בוצע", and only after the engine has applied the change.

### 5.4 Guardrails (deterministic layers around the model)
1. **System prompt:**
   - It defines the scope and the fixed redirect message.
   - Answers are Hebrew-only, concise and natural.
   - It never claims an action happened, and uses suggestion language instead ("אפשר להאריך את הטיימר ב-5 דקות — אשרו בכרטיס").
   - It never invents times, temperatures or quantities without labeling them as estimates.
   - It follows the food-safety rules.
   - It treats all data blocks as data, not instructions.
2. **Backend post-checks, applied to every model response:**
   - The `out_of_scope` replacement from §5.2.
   - The tool allowlist and argument validation.
   - A **false-success check**: if `answer_he` contains completion claims ("שיניתי", "עדכנתי", "הפעלתי", "הטיימר הוגדר" …), the backend replaces them with fixed proposal wording.
   - The reply is capped at about 600 characters.
   - The food-safety rule table from §2 also applies to proposed timers and temperatures.
3. **Input limits:** messages of at most 500 characters, history of 6 turns, the per-IP rate limit and app token from Phase 2, and history items that are plain text only.
4. **Prompt-injection stance:** the model never sees secrets, and the server holds no privileged tools. So the worst result of an injection is a wrong *proposal*. The deterministic checks and the user's approval still stop it.

---

## 6. Saved recipes, cooking history & "המטבח שלי"

### 6.1 Local data model (drift / SQLite, ready for future sync)
All tables use the same sync-ready conventions:
- **Ids** are client-generated **UUIDs**.
- **`created_at` / `updated_at`** on every row.
- **`deleted_at`** for soft delete. It works as a tombstone for future sync and makes undo possible.
- **`owner_id`**, which can be null and is always null in the MVP (null means a local user).
- **`schema_version`** on every JSON field.

Nothing depends on a server. A sync service could be added later on top of these repositories without changing the tables.

| Table | Key fields | Notes |
|---|---|---|
| `recipes` | `title`, `custom_title?`, `is_favorite`, `source_type`, `source_url?`, `source_text?`, `source_image_path?`, `analysis_json` (the `RecipeAnalysis`, including clarification answers), `plan_stale` | **This is the original recipe.** An imported image is kept as a local, compressed file. |
| `plans` | `recipe_id`, `plan_json`, `status: approved \| superseded`, `approved_at`, `based_on_plan_id?` | **This is the approved plan, stored separately and versioned.** Approving a new plan marks the old one `superseded`. |
| `cooking_sessions` | `recipe_id`, `plan_id` (the plan in use when cooking started), `status: in_progress \| completed \| abandoned`, `started_at`, `ended_at?`, `notes?` | **One active session at a time in the MVP.** Starting another asks whether to finish or abandon the current one. This keeps timers simple. |
| `session_events` | `session_id`, `seq`, `type`, `payload_json`, `at` | Append-only (§4). Approved modifications are the `PlanPatchApplied` events. |
| `app_settings` | `key`, `value` | Simple key-value storage. |

### 6.2 Behaviors
- **Reopen without Gemini:**
  - A saved recipe opens straight from `analysis_json` and its latest approved plan, with **zero AI calls**.
  - "התחל בישול" creates a new session from the approved plan.
- **Edit a recipe:**
  - The user can edit the title, servings, ingredients and quantities. Edits change the provenance to `user` and set `plan_stale=true`.
  - The user then picks one of two options:
    - **"עדכן ערכים בתוכנית"** edits timers and temperatures by hand, with no AI.
    - **"צור תוכנית מחדש"** makes **one** `/plan` call, without repeating analysis.
- **Rename** sets `custom_title`. **Favorite** toggles `is_favorite`.
- **Delete** is a soft delete with a 5-second undo. Deleting a recipe also removes its plans and history, after a confirmation that says so. Rows are purged for good later.
- **Changes made during a session stay in that session.** The session's effective plan is its plan plus its approved patches.
  - On the Finish screen, the user can choose **"שמור את השינויים במתכון"**. That creates a new approved plan version.
- **Cooking history** lists each session with:
  - the date, duration and status (הושלם / הופסק / בתהליך)
  - the list of approved changes, read from the `PlanPatchApplied` events
- **Continue Cooking:** opening an `in_progress` session replays its events (§4). This restores the step status and timers, and reschedules notifications.

### 6.3 "המטבח שלי" (Hebrew RTL personal area)
"המטבח שלי" is the home screen. A floating **"+ מתכון חדש"** button opens Import.
- **המשך בישול**: a banner at the top, shown only while a session is in progress.
- **המתכונים שלי**: a list with filter chips (הכל / ⭐ מועדפים) and title search.
- **מועדפים**: the favorites filter, also reachable from its own tile.
- **היסטוריית בישול**: a list of sessions with a detail view.
- **הגדרות**: notifications, battery optimization, timer sound, the backend server address (debug builds only), and "אודות".

Recipe detail has these actions: התחל בישול, ערוך, שנה שם, ⭐, מחק, הצג מקור.

### 6.4 Local now vs. requires accounts and cloud later
| Works locally (MVP, no account) | Needs authentication + cloud storage (future) |
|---|---|
| Saving recipes, original and plan; reopening with no AI calls | Syncing across devices and restoring after reinstall or a new phone |
| Favorites, rename, edit, delete | Sharing recipes with others or a family kitchen |
| Cooking history and approved changes | Cloud storage for recipe images |
| Continue cooking and restoring timers | Per-user AI quotas and abuse control (replacing the per-IP limit) |
| Settings | A web version |

**Before accounts exist**, a simple local export and import of a JSON backup file (Phase 4, optional) covers moving to a new phone without any server.

---

## 7. Phases

### Phase 0 — finish setup *(next)*
1. **Remove the temporary ai-check endpoint:**
   - Delete `backend/app/routers/ai_check.py` and `backend/tests/test_ai_check.py`.
   - Remove the import and `include_router` from `backend/app/main.py`, and the `ai_check_*` fields from `backend/app/config.py`.
   - Run `pytest`, commit, and push. Render redeploys.
   - Verify that `POST /internal/ai-check` returns **404** and that `/health` still returns `ok`.
   - `extra="ignore"` in the settings means a leftover environment variable on Render can't cause an error.
2. **Backend housekeeping:**
   - Split `requirements.txt` (runtime) from `requirements-dev.txt` (pytest, httpx).
   - Pin the Python version with `.python-version`, matching Render.
   - Add `PLAN_MODEL` to the settings.
   - Add a README with the run and deploy commands.
3. **`.env.example` permissions:** narrow the Claude Code deny rules from `.env.*` to the known secret files (`.env`, `.env.local`, `.env.*.local`, `.env.development`, `.env.production`, `.env.test`). Then I can create and maintain `backend/.env.example`. The `.gitignore` stays as it is.
4. **Flutter skeleton** (`app/`):
   - `flutter create` for Android and iOS
   - `he` locale with RTL, `.arb` strings, the theme, and a bundled Hebrew font (Heebo)
   - go_router, Riverpod, and drift with **schema v1 from §6.1** (`recipes`, `plans`, `cooking_sessions`, `session_events`, `app_settings`) plus its migration setup
   - a dio client with `API_BASE_URL` set through `--dart-define`
   - cleartext HTTP in debug builds only
   - an empty **"המטבח שלי"** home screen with its sections as placeholders, plus a backend status line: "מתעורר…" while the Render cold start lasts, then mock or Gemini
5. **Verify on `emulator-5554`:**
   - Against the local backend (`http://10.0.2.2:8000`, mock provider) **and** against the Render URL.
   - Run the widget test.

### Phase 1 — Deterministic cooking core (no AI)
1. Pydantic `CookingPlan` schema, JSON Schema export, a hand-written Hebrew sample plan in `shared/fixtures/`, and matching Dart `freezed` models with a contract test.
2. `CookingEngine` (reducer, derived views, replay) with full unit tests: dependencies, parallel suggestions, prep surfacing, undo, timers with a fake clock.
   - This includes the **`ActionDispatcher`** with `source: ui|agent`, the **idempotency rules**, `availableActions()`, `pendingPrepTasks()` and `snapshot()`. The buttons use them now, and the Phase 3 agent reuses the same path unchanged.
3. TimerService + notifications + restore and reschedule. Run the **real-device timer test matrix from v1** (Doze, app swiped away, restart, battery saver, exact-alarm permission denied, 3 timers at once).
4. **Local persistence:** repositories for recipes, plans and sessions over drift. On first run, the sample plan is saved as a recipe, "מתכון לדוגמה", so everything runs on the real storage path. Sessions and events are stored, with the one-active-session rule.
5. Screens using the sample plan:
   - Plan Review (read-only for now)
   - Cooking screen: current step, action buttons, timer tray, "בינתיים אפשר…", prep cards
   - Finish screen
   - "המטבח שלי" with **המשך בישול** and **המתכונים שלי** working
   - **היסטוריית בישול**: list and detail
   - Settings: notification and battery checks

   **Outcome:** you can cook the sample recipe end to end with reliable timers and no AI, kill the app, resume from **המשך בישול**, and see the session in history.

### Phase 2 — AI recipe analysis & planning
1. Backend `analyze` (text input first), with validators and Gemini prompts. Mock fixtures for tests.
2. Backend `plan`, including the step-splitting rules, the provenance and food-safety checks, and the repair retry.
3. **Abuse protection before these endpoints go live on Render:**
   - an app client token header (not truly secret, but it filters casual traffic)
   - a per-IP limit in memory
   - limits on body and image size
   - protection on URL fetching: http/https only, private and internal IPs blocked, size and time limits
4. Flutter Import (text) → Clarify → Review & Approve (with editable timers) → **save the recipe and the approved plan** → Cooking. This connects the real plan to the Phase 1 engine.
   - Reopening a saved recipe makes **no AI calls**.
   - Recipe management: rename, favorite (with the מועדפים filter), edit with `plan_stale` and its two options (edit values by hand, or regenerate the plan with one `/plan` call), and soft delete with undo.
5. Add image import, then URL import.
6. An evaluation set: about 15 real Hebrew and English recipes, run on demand against Gemini to check plan quality. The check is manual and kept small to save quota. Automated tests always use the mock.

#### Phase 2 — approved detailed design (2026-10-24)

This refines the list above; where they differ, this section wins. Decisions are logged in `docs/DECISIONS.md` #19–#30.

**Imports and storage**
- Three inputs: typed/pasted text, a camera/gallery photo, a user-provided URL. URL fetching is safe (http/https only,
  private/loopback/link-local addresses blocked, re-checked redirects, size and time limits) and extracts only the
  recipe (schema.org JSON-LD first, then main-text extraction).
- Photos: compressed on the device with metadata removed, the extracted text and structure are kept; the photo
  itself is kept **only temporarily** for review and deleted after approval or when the draft is cleaned up.
- Stored locally: extracted source text, source URL/site/title, the structured recipe, questions/answers/gaps, and
  the approved plan. Reopening never calls Gemini. Drafts (`recipes.status = draft`) expire after 7 days.
- `url_fetcher.fetch_recipe_page()` and `analysis.analyze_source()` are plain functions usable without their
  endpoints, so future recipe discovery can reuse them (see "Later").

**Accuracy and corrections**
- Original amounts, units and instructions are preserved; plan steps may carry per-step amounts
  (`ingredient_uses`) and link to source excerpts (`source_refs`).
- Before approval the user may correct ingredient names, amounts, units, original instructions, temperatures and
  timers. Corrections become provenance `user`. After a recipe correction the plan is marked out of date and
  **cannot be cooked** until the user edits plan values by hand or regenerates it (one `/plan` call).

**Missing information (resolution ladder)**
1. Recipe context → 2. curated food-safety reference (USDA FSIS, and Israeli guidance where available; cited) →
3. model estimate (`inferred` with confidence; range timers with check cues) → 4. a question only when genuinely
needed (equipment that changes the plan, preferences that change steps, unresolved safety, high-impact
low-confidence gaps). No fixed question limit. "לא יודע/ת" never repeats the question. Unresolvable
safety-critical values are never invented: that part is not scheduled and the limitation is explained.
Review shows every estimate and assumption ("מה הוערך"); a confirmation checkbox appears only when a
safety-related value is an estimate.

**Waiting-period guidance (in the approved plan; no Gemini calls while cooking)**
- Timer fields: `wait_kind` (bake, proof, chill, freeze, rest, soak, marinate, cook, other), `wait_info_he`,
  `max_seconds` (range end), `check_cue_he`, `suggest_during` (ids of real steps/prep tasks), up to 3
  `meanwhile_tips_he`, `recheck_seconds`. Limit raised to 72 h. Plan-level `advance_notice_he`; step-level
  `estimated_active_minutes`; `PrepTask.remind_before_needed`.
- Notifications are computed from state by one function and synchronized after every event: one "check time"
  notification per timer, one optional end-of-range notification, one optional prep reminder per prep task
  (quiet channel). Extending, shortening, pausing, resuming, re-checking or completing recalculates all of them.
  "עוד לא — לבדוק שוב" leaves exactly one pending notification for that timer.
- Wording never implies food is ready: "⏰ {label}: זמן לבדוק" / "זמן לבדוק!".

**Gemini usage**
- `gemini-3.5-flash-lite`, minimal thinking, separate LLM-facing schemas, backend validation + one repair call.
  Typical cost 2 calls per recipe (3 with repair). Automated tests use fakes only (zero real calls).
- Live evaluation only with the user's approval: first batch ≤ 5 recipes and ≤ 15 real calls including retries;
  stop on any quota/rate-limit error; report calls, failures and results.

**Backend security**
- `GEMINI_API_KEY` only on Render. `X-App-Token` (`APP_CLIENT_TOKEN`, set by the user) is an abuse deterrent, not
  authentication. Per-IP limits and an app-wide daily cap (in memory: reset on restart, shared IPs share limits),
  request-size caps, SSRF protection, no recipe content in logs. A Hebrew privacy notice before the first import.

### Phase 3 — final product direction (approved 2026-10-24)

Supersedes the older Phase 3 text below and §5 where they differ. Decisions: `docs/DECISIONS.md` #33–#43.

**Goal.** A complete beginner imports a recipe, prepares everything needed, and cooks successfully with minimal
confusion and minimal interaction. The app handles complexity behind the scenes; the user never has to
understand, validate or edit a complicated plan.

**Flow.** Import → Recipe overview → Check ingredients and equipment → Resolve missing items → "מתחילים לבשל"
→ Simple steps → Finish. Advanced editing (the Phase 2 review/edit screen) stays available but secondary.

**Principles (all of Phase 3)**
- One clear primary action per screen; few buttons; no unnecessary dialogs or confirmations.
- Short, beginner-friendly Hebrew; explanations only on request.
- Practical cues first; no thermometers, special equipment, professional techniques or extra measurements unless
  the recipe needs them or food safety genuinely requires it. High-risk safety guidance stays, said briefly;
  appearance is never presented as reliable where it isn't.
- No developer-facing text (server, backend, API, Gemini, Render, HTTP, JSON, database, versions); no technical
  success messages; errors only when the user needs to know or act.
- Deterministic local execution stays: CookingEngine, event replay, undo, session restore, parallel steps,
  timers and notifications, offline cooking and saved recipes. No automatic Gemini calls; no new dependencies or
  paid services without approval.

#### Phase 3C — simple cooking, practical guidance, timer end (first)

Status: implemented locally 2026-10-24 (not committed); see `docs/PROGRESS.md`.

Checklist:
1. **Food-safety reference (backend).** Split eggs: stovetop eggs (omelette, scrambled, fried) → observable cue
   ("until the eggs are set, no runny egg"), no temperature, no forced confirmation; baked egg dishes (quiche,
   frittata, casserole) keep 71°C as an optional precise check with an observable cue. Shorten every cue to one
   sentence; poultry/ground meat: brief thermometer recommendation plus signs, without claiming colour alone is
   reliable (open decision 4). Add the `egg_*` cases to tests.
2. **Planning (backend).** Stop appending the full safety cue to `warnings_he` for every safety-tagged step: one
   short line only for high-risk foods; `always_ask` only for high-risk foods (poultry, ground meat, …), not
   stovetop eggs.
3. **Plan prompt.** Ordinary step = one action that completes it ("סיימתי"); timed step = the start action
   ("הכנסתי לתנור", `starts_timer`) + completion. Short beginner instructions; observable cues; no unneeded
   equipment; equipment only if the recipe needs it; one optional `help_he` per step (how to know it's ready,
   one common problem, plain words).
4. **Contract.** `PlanStep.help_he` (optional; schema_version stays 1) → export schemas → Dart model; fixtures.
5. **Engine.** `ActionDispatcher.completeStep(stepId)`: confirms the step's remaining actions in order as
   `ActionConfirmed` events; stops at an action that starts a timer (that action becomes the primary button);
   idempotent and serialized; completion with a running timer keeps today's behaviour (timers end). Derived
   `primaryAction(step)` for the UI: start-timer action / waiting / "סיימתי — לשלב הבא".
6. **Timer end (app).** Doneness cue + "מוכן — לשלב הבא" + "צריך עוד זמן (+N דק')" with N from
   `recheck_seconds` (default 5 min) and ± 1 minute adjust; uses existing `TimerRechecked`/`TimerExtended`.
7. **Cooking screen (app).** Current step big: title, one instruction, amounts used, primary button, small
   "חזרה" (undo last). "איך יודעים?/עזרה" expands `help_he` and the doneness cue. Timers tray and "בינתיים
   אפשר" stay, compact. Hidden from the main view: estimate badges, step status chips, technical timer labels;
   "כל השלבים" behind a link. Remove per-action success snackbars (undo is on the screen). Safety check inline
   ("בדקתי ש…" before the primary button) instead of a popup.
8. **Developer-facing messages (app).** Remove the home status card text (server connected/offline/waking, AI
   mode, database version); keep a silent warm-up health request. Friendly loading/error text (see the audit
   below). Fix the cold-start "אין בישול פעיל" flash (neutral loading state).
9. **Tests and checks.** Backend (fake provider): egg categories, high-risk only `always_ask`, prompt rules
   reflected in validation. Flutter: `completeStep` (multi-action steps, stops at timer actions, undo, idempotent,
   old event logs replay identically), timer-end extension, single-button cooking flow, inline safety check, no
   developer text on home/import. Emulator: one full cook offline. Live check with approval (≤ 2 recipes,
   ≤ 6 calls).

Acceptance: an ordinary step takes one tap; a timed step two (start, done); no popups except destructive
actions; omelette without a thermometer, chicken with a short doneness check; old saved recipes and active
sessions keep working; timers and notifications unchanged offline; no developer terminology on screen.

#### Phase 3A — recipe overview, checklist, missing items, substitutions

Status: implemented locally 2026-10-24 (see `docs/PROGRESS.md`; decisions #48–#52). Deviation: no automatic
`/plan` regeneration when an AI substitution stays invalid — a clear message and advanced editing instead (#51).

- After import the app analyzes and plans automatically, then shows the **overview**: name, servings,
  estimated duration (computed locally from steps and timers), short useful notes; a short "שימו לב" card only
  for safety-relevant estimates or limitations. Questions only when needed for a reliable plan.
- **Checklist** of all ingredients (with amounts) and equipment: have / missing, one tap each; free text such as
  "אין לי שמנת, יש לי חלב", "אין לי מיקסר", "אין לי משקל", "אין לי מדחום".
- **Resolution:** curated context-aware local table first (offline); otherwise one Gemini call
  (`POST /v1/recipes/substitute`) with the whole recipe as context. Verdicts: works / changes the result (how) /
  not recommended / essential, no reliable substitute. Adjusted quantity and instructions; never an invented
  workaround.
- **Applying:** a backend-validated patch (ingredient + affected step text; plan checks, number checks, safety
  re-classification); if invalid, fallback to one `/plan` regeneration. Saved as a new plan version
  (`based_on_plan_id`), original kept; undo before cooking. Resolved equipment isn't asked again while cooking.
- Primary action "מתחילים לבשל"; the Phase 2 review/edit screen becomes "עריכה מתקדמת".
- Acceptance: everything needed is visible before cooking; common swaps offline; essential items never faked;
  recipe and plan consistent after a swap; active sessions untouched; reopening makes zero calls.
- Tests: fake-provider verdicts, patch validation, safety re-classification (e.g. chicken → fish), fallback,
  limits/quota; app checklist, local table, apply/undo, plan versions, no stale text. Live check with approval
  (≈ 5 substitutions, ≤ 10 calls).

#### Phase 3B — Remy: assistant intelligence and action execution (text now, voice in 3D)

Status: implemented locally 2026-10-24 (see `docs/PROGRESS.md`; decisions #53–#57). Phase 3D (microphone, speech
recognition, text-to-speech, wake word) not started.

Requirements (user, 2026-10-24): Remy answers context-aware questions AND performs real actions; the same pipeline
must serve typed text now and speech in Phase 3D (microphone, speech recognition, text-to-speech, wake word are 3D,
not 3B).

Design:
- **One modality-independent pipeline** (`app/lib/features/assistant/`): `AssistantInput(text, modality)` →
  `AssistantService.interpret` → `AssistantReply {answer_he, speech_he (plain text for future TTS), action?,
  requires_confirmation, source local|ai}` → execution only through `CookingController` → `ActionDispatcher`.
  Speech recognition in 3D will produce the same `AssistantInput`.
- **Local first, no Gemini:** a deterministic Hebrew command parser for next / mark done, back / undo, how much
  time is left, what now, help with this step, pause / resume a timer, extend a timer by a spoken duration (Hebrew
  number words), and starting a timer when the cook reports the real-world action ("הכנסתי את העוגה לתנור"),
  matched against the labels of the actions available right now. Intentions ("אני עומד להכניס") never confirm.
- **Remy (one AI call, only when asked):** `POST /v1/assistant/turn` with the effective recipe, plan, engine
  snapshot (current/completed steps, available actions, active timers), the last turns and the message. Returns a
  Hebrew answer, speech text and at most one proposal: extend a timer, a substitution, or a change to pending
  steps (patch operations from 3A, validated on the server, food safety recomputed). Guardrails from §5.4: cooking
  scope with a fixed redirect, off-topic line, no success claims, length caps, data blocks are data. Own per-device
  limit inside the shared daily cap.
- **Execution and validation (app, deterministic):** every action is checked against the live engine state; a step
  is completed or a timer started only when the command clearly says the real-world action happened. Auto-run:
  clear next/undo/start/pause/resume and extensions up to 15 minutes. Confirmation card: steps that need the
  high-risk doneness check, finishing while a timer still runs, partial matches, extensions over 15 minutes, and
  every AI proposal. Replies after execution come from engine results (templates), never from the model.
- **Mid-cooking changes:** new replayable event `PlanPatched(ops, summary)`; allowed only on steps not started and
  timers not running; the effective plan is plan + patches (old sessions replay unchanged); the cooking view shows
  the patched recipe; history lists the changes.
- **UI:** "רמי" in the cooking screen's app bar opens a sheet: conversation, quick chips (מה עכשיו? / כמה זמן
  נשאר? / עזרה בשלב), approval cards. Offline: local commands keep working; questions say Remy is unavailable.
- Acceptance: simple commands work offline with zero calls; nothing executes without validation; no silent
  completion or timer start; proposals need approval; old sessions replay identically; voice can plug in without
  changing the pipeline.
- Tests: parser (Hebrew phrasings, numbers, intentions), confirmation policy, execution through the dispatcher,
  `PlanPatched` validation and replay, assistant sheet flows with a fake API; backend guardrails and proposals with a
  fake provider. Live evaluation only with approval.

#### Phase 3D — voice, with local-first understanding and Gemini as a fallback interpreter

Requirements (user, 2026-10-24): Remy feels natural, fast and inexpensive. Local understanding first (natural Hebrew
variations, synonyms, verb forms, durations, references to steps and timers; simple questions answered from the
plan); Gemini only as a fallback interpreter returning a strict command from the supported set, validated against
the live engine; at most one Gemini call per unresolved request, no automatic retry; ambiguity resolved by asking
locally; voice and text through the same pipeline; offline keeps every local command working.

Status (2026-10-24): **implemented locally** (see `docs/PROGRESS.md`, decisions #58–#63). Local-first refinements
(`fee2df1`), then voice with the approved free packages `speech_to_text` and `flutter_tts` (the phone's own
engines): Hebrew recognition, spoken replies, a microphone in the Remy sheet and in the cooking screen, listening /
processing / speaking states, permission handling, an optional "שיחה רציפה" (continuous conversation) mode. The
wake phrase ("Hey Remy") stays later (always-on listening: battery and privacy).

- Implemented: word-family parser with prefix-aware and one-letter-tolerant matching, uncertainty markers,
  question detection, local Q&A (amounts, temperature, next step, this step's ingredients, steps left), local
  clarification ("עוד קצת" → the plan's re-check time, asked first), noise filtering for transcripts; server
  `command` interpretation (complete_step, undo, get_timer_status, extend_timer, pause/resume_timer,
  start_timer_action, whats_next, help) validated on the server and again in the app; one call, no repair, no
  retry; minimal context (no source text, completed steps by title); `SpeechRecognizer` / `SpeechSynthesizer`
  interfaces with silent defaults; spoken requests get `speechHe` read aloud once an engine is added.
- Voice: `VoiceController` (per session) runs listen → `sendSpoken` (the same pipeline as typed text) → speak
  `speechHe`; "כן" / "לא" answers a pending confirmation by voice; every speech problem becomes a Hebrew note and
  typing keeps working.

#### Phase 4 and Future

- Phase 4: visual identity from the final logo (`docs/branding/logo.png`, DECISIONS #64), navigation, the
  beginner journey, an original "Remy" (רמי) look, motion and accessibility. **Implemented 2026-10-24 (4B–4E,
  local commits); design and as-built notes in `docs/DESIGN.md`, decisions #65–#71.** Release work (store,
  privacy policy, App Check, paid tier, iOS builds) remains separate and needs approval.
- Future: an optional "Hey Remy" wake phrase (always-on listening). Original character only.

#### Gemini usage in Phase 3

| Moment | Gemini calls |
|---|---|
| Import (analyze + plan) | 2 (3 with a repair) |
| Reopening or cooking a saved recipe; timer end; doneness check; extension | 0 |
| Step help, glossary, common substitutions | 0 (prepared in the plan or local) |
| Recipe-specific substitution | 1 |
| Free-text assistant question | 1, only when asked |

Protections: app-wide daily cap (300, under Gemini's 500 RPD), per-device limits, quota pause, short context.

#### Developer-facing message audit (2026-10-24)

Remove or reword in 3C:
- Home status card: "מתחבר לשרת…", "השרת מתעורר…", "השרת מחובר ✓", "מצב הדגמה / בינה מלאכותית מחוברת / לא
  ידוע", "אין חיבור לשרת", "מסד הנתונים מוכן (גרסה N)" → removed (silent warm-up request kept).
- Import loading: "קוראים את המתכון…" → "בודקים את המצרכים וההוראות…"; "בונים תוכנית בישול…" → "מסדרים לך את
  שלבי הבישול…"; "זה לוקח קצת זמן — ייתכן שהשרת מתעורר." → "זה לוקח קצת יותר זמן מהרגיל…".
- Errors: "השרת לא הגיב בזמן" → "זה לקח יותר מדי זמן. נסו שוב בעוד רגע."; "השרת עדיין לא מוגדר לייבוא
  מתכונים." → "ייבוא מתכונים לא זמין כרגע. נסו שוב מאוחר יותר."; quota/busy/unavailable texts drop "שירות
  הבינה המלאכותית" for "הכנת מתכונים חדשים לא זמינה כרגע…".
- Cooking: per-action success snackbars ("✓ סומן…") removed; technical timer/estimate labels hidden.
Keep: the debug-only server address in Settings (not in release builds); the Settings notification test,
reworded as "בדיקת התראות".
Later: 3A — review terms ("מה הוערך", provenance badges, "תוכנית", "מקורות") move into advanced editing;
Phase 4 — Settings wording (exact alarms, battery).

#### Phase 3 — open decisions (resolved 2026-10-24: 1–4 adopted as recommended, `docs/DECISIONS.md` #44–#47; 5 still needs approval)

1. The one-time privacy notice: keep naming Google as the recipient of recipe text/photos (without "Gemini")?
2. Estimate badges ("הערכה") leave the cooking screen; transparency moves to the overview's "שימו לב" card and
   advanced editing. This changes the CLAUDE.md invariant "AI estimates show הערכה".
3. Existing saved recipes (e.g. the test omelette) keep their old plan text (including the thermometer line);
   offer an optional "rebuild the plan" (one call) rather than editing saved text automatically?
4. Poultry and ground meat: a one-line thermometer recommendation plus observable signs, honestly worded, never a
   mandatory checkbox; if the user marks "no thermometer" in 3A, signs only with the caveat.
5. Live check at the end of 3C (≤ 2 recipes, ≤ 6 calls).

### Phase 3 — Cooking AI Agent (original plan; superseded where it differs from the section above)
1. **Backend:**
   - `POST /v1/agent/turn`, the `AgentTurn` schema, the agent system prompt in `backend/app/prompts/agent.md`
   - the tool registry and validators in `backend/app/services/agent/`
   - all post-check guardrails
2. **Automated tests with a fake provider (no tokens).** The fake returns canned model outputs, and the tests check that the pipeline handles each one correctly:
   - **In scope:** a cooking question, a session question, an action request that produces valid proposals.
   - **Out of scope** (parametrized over cars, politics, sports, programming, trivia, personal): the reply becomes the exact redirect message and tool calls are dropped.
   - **Mixed:** the cooking answer is kept and the fixed off-topic line is added once.
   - **Borderline in scope:** food storage, food safety and menu planning are answered normally.
   - **Ambiguous:** a clarifying question and no tools.
   - **Prompt injection:**
     - "ignore previous instructions" in the user message
     - instructions hidden in recipe or URL text
     - a model output that calls an unknown tool or refers to a fake id, which must be dropped
     - a model output that claims success, which must be rewritten
   - **Contract:** results in `action_results` appear in the next prompt.
   - **Confirmation tools:**
     - A valid `propose_confirm_action` and a valid `propose_complete_prep_task` pass through.
     - Unknown step, action or prep ids are dropped.
     - A tool call that includes `seconds` or any other extra argument is rejected.
     - Several candidates are passed through without changes.
     - `confidence` is passed through.
   - **Plan validator:** sets `confirm_policy: always_ask` on actions in steps with safety flags.
3. **Flutter:**
   - an agent bottom sheet in Cooking and Plan Review
   - approval cards for each tool
   - live-state checks of proposals before applying them, then engine events, then `action_results`
   - approved changes listed in the session's history detail, and **"שמור את השינויים במתכון"** on the Finish screen, which creates a new approved plan version
   - **Natural-language confirmations:**
     - the auto-apply rules from §5.3
     - the undo toast, the one-tap confirmation card and the candidate chips
     - result messages built from templates
     - the `agent_action_mode` setting
   - **Unit tests on the dispatcher and engine with a fake clock, covering:**
     - **success:** confirming `in_oven` from the agent starts the plan's timer with the plan's duration and schedules one notification
     - **UI and agent paths match:** the same action from either source produces identical state
     - **prep task:** "הדלקתי את התנור" completes the prep task and starts its preheat timer from the plan
     - **duplicates:** the same proposal twice, or a UI tap followed by the agent, produces one event, one timer and one notification, and the result `already_done`
     - **invalid:** a locked step, an action already done or a wrong id rejects with no state change
     - **ambiguous:** two proposals or `confidence: low` shows the card or chips and applies nothing
     - **safety:** `always_ask` shows a card even with high confidence
     - **preference:** "תמיד לשאול" always shows a card
     - **undo:** undo within 5 seconds cancels the timer and its notification
   - widget tests for the approve, reject and invalid-proposal paths
4. **On-demand agent eval against Gemini on Render** (manual, about 30 cases, small quota):
   - The cases live in `backend/evals/agent_cases.jsonl`. Each has a `category`: in-scope, session ("מה עכשיו?"), action_confirmation ("הכנסתי את העוגה לתנור", "סיימתי לחתוך את הירקות", "הדלקתי את התנור"), future intent (no confirmation expected), ambiguous confirmation, action request, out-of-scope (cars, politics, sports, programming, trivia, personal, with several phrasings each), mixed, borderline, injection.
   - The grader checks the expected `step_id`, `action_id` or `prep_task_id`, and that no tool call contains a duration.
   - A pytest check confirms every category has at least 3 cases.
   - `backend/evals/run_agent_eval.py --base-url …` grades the results deterministically: the expected intent, the expected tool names, the exact redirect text for off-topic, no success claims, and a Hebrew reply.

### Phase 4 — Polish & release
(Superseded in detail by `docs/DESIGN.md` (Phase 4A proposal). Voice was delivered in Phase 3D.) Servings scaling, Hebrew text-to-speech and voice confirmations ("סיימתי"), local JSON backup export and import, App Check, a paid Gemini tier and privacy policy, iOS builds (Codemagic), store release.

### Later (not planned yet): accounts and cloud sync
Optional sign-in, then a sync service built on the existing UUIDs, `updated_at` and `deleted_at` tombstones, and `owner_id`, plus cloud image storage and sharing (§6.4). Nothing in Phases 0–4 depends on it.

### Later (product requirement, not scheduled): recipe discovery and online research
Requested by the user on 2026-10-24; deliberately postponed (see `docs/DECISIONS.md` #18).
- **"Find me a recipe for X"** using online search.
- Show recipe **options with their original sources** (site name, title, link).
- The user **selects** a recipe, which then goes through the **existing URL import → analysis → plan** flow.
- **Research missing recipe information** when appropriate, with researched values clearly labeled and kept
  separate from original recipe facts and AI estimates.

Constraints found when this was evaluated (2026-10-24): Google Search grounding is free only on Gemini 2.5
Flash / Flash-Lite (shared daily limit), not on `gemini-3.5-flash-lite`; JSON output together with search works
only on Gemini 3 models (preview); the Gemini API terms require grounded results to be shown with Google's
Search Suggestions and not modified or cached. Re-check pricing, limits and terms before designing this.
Phase 2 keeps URL fetching and recipe analysis callable on their own so a future search step can reuse them.

### Build order: what to develop when
| Area | When | Why |
|---|---|---|
| Timer system + engine | Phase 1 (first) | Deterministic, the riskiest part on Android, and testable without AI. |
| Flutter screens | Skeleton in Phase 0; cooking screens in Phase 1; import, clarify and review in Phase 2; agent sheet and approval cards in Phase 3 | Each screen is built when its data source exists. |
| AI components | Phase 2 (analyze and plan), Phase 3 (Cooking AI Agent) | They target a plan schema the engine already runs, so AI output has a concrete, tested contract. |

---

## 8. Render Free & Gemini free-tier constraints
- **Cold start.** The service sleeps after about 15 minutes idle, and waking takes about 30–60 seconds. The app pings `/health` when it opens, client timeouts are 90 seconds, and the loading message is friendly.
- **Memory.** The backend is stateless and has no disk, so nothing is lost on a restart. The in-memory rate limits reset when it restarts, which is acceptable.
- **Quota.** Each recipe costs 2–3 calls, and each question costs 1. Rate-limit errors become a 429 with "נסו שוב בעוד דקה".
- **Privacy.** On the free tier Google may use prompts to improve its products. This is acceptable for testing, but a paid tier and a privacy-policy note are needed before a public launch.
- **Logs.** Recipe text and secrets are never logged, only ids, latency and error types.

---

## 9. Verification
- **Phase 0:**
  - `pytest` passes.
  - `curl -X POST <render>/internal/ai-check` returns 404.
  - `GET <render>/health` returns `{"status":"ok",…,"ai_provider":"gemini"}`.
  - The app on `emulator-5554` shows the backend status for both the local backend and the Render URL.
- **Phase 1:**
  - Engine unit tests pass.
  - A Flutter contract test parses the shared fixture.
  - The real-device timer matrix passes.
  - The sample recipe can be cooked end to end after the app is killed and reopened.
  - Repository tests on an in-memory drift database cover save and reopen, soft delete and undo, the one-active-session rule, and the history list.
- **Phase 2:**
  - Backend tests with mock fixtures pass, covering schema, the logic, provenance and food-safety validators, and the repair path.
  - A manual evaluation of the recipe set on Render shows good step grouping, no unflagged invented values, and at most 3 questions.
  - A test checks that reopening a saved recipe makes zero API calls, using a fake API client that fails if it's called.
- **Phase 3:**
  - The fake-provider guardrail tests pass for all categories.
  - Proposals are never applied without approval, and the widget tests cover approve, reject and invalid.
  - The on-demand agent eval on Render reaches 100% on off-topic redirects in every category and on injection cases, with no false success claims. Mixed messages keep the cooking answer.
  - Natural-language confirmations match the correct action, and future-intent messages never produce a confirmation.
  - Manual check on `emulator-5554`: type "הכנסתי את העוגה לתנור" and see the timer start once with the plan's duration. Type it again and see "כבר סומן". Kill the app and see the timer restored.
