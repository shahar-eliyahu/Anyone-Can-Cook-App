# Decisions log

Short records of decisions and why they were made. Newest last. Add an entry when a decision changes the
plan, the architecture, or a standing rule. The approved design itself is `docs/PLAN.md`.

| # | Date | Decision | Why |
|---|------|----------|-----|
| 1 | 2026-10-23 | Flutter app + thin stateless FastAPI backend; recipes and progress stored on the device (SQLite). | Low cost, offline cooking, no accounts needed for the MVP. |
| 2 | 2026-10-23 | Gemini (free tier) behind a swappable `LLMProvider`; model chosen by env vars (`AI_MODEL`, `PARSE_MODEL`, `PLAN_MODEL`, `CHAT_MODEL`). Mock provider for local dev and all automated tests. | Free MVP; easy to switch providers; tests never spend quota. |
| 3 | 2026-10-23 | Develop locally first; deploy later. Backend later deployed on Render Free (`https://anyone-can-cook-api.onrender.com`, Python 3.12.9, root dir `backend`). | User request; free hosting. |
| 4 | 2026-10-23 | Gemini connectivity verified once through a token-protected, rate-limited, temporary endpoint; then removed (404 on Render). | Prove the integration without a public quota-spending endpoint. |
| 5 | 2026-10-24 | Plan v2: two-step AI (analyze → only necessary questions → plan the user approves); deterministic Flutter engine; phases reordered so engine and timers come first. | Reliability and testability; AI output targets a contract the engine already runs. |
| 6 | 2026-10-24 | AI estimates carry provenance and are labeled "הערכה"; never shown as recipe facts. Backend downgrades unverifiable "original" numbers to "inferred". | User requirement: no silent invention of times, temperatures or quantities. |
| 7 | 2026-10-24 | Cooking agent is domain-restricted (positive scope + intent classification, fixed Hebrew redirect, mixed-message handling). Tool calls are structured-output *proposals*, validated by the backend and again by the app; no agent framework. | Safety, provider neutrality, testability with a fake provider. |
| 8 | 2026-10-24 | Natural-language confirmations ("הכנסתי את העוגה לתנור") go through the same `ActionDispatcher` as buttons; auto-applied only when clear, safe (`confirm_policy: auto_ok`) and allowed by the user setting, with undo. | One deterministic path; no duplicate timers. |
| 9 | 2026-10-24 | Saved recipes, history and "המטבח שלי" use local SQLite with sync-ready columns; accounts and cloud sync deferred. | MVP simplicity without a future rewrite. |
| 10 | 2026-10-24 | User-facing name "לבשל כל אחד יכול"; all UI Hebrew/RTL; "Anyone Can Cook" internal only. | User requirement. |
| 11 | 2026-10-24 | Functionality before visual polish until Phase 4. System Hebrew font for now (bundled Heebo deferred). | User priority. |
| 12 | 2026-10-24 | Timer notifications via `flutter_local_notifications` + `timezone`; battery-optimization status via a small platform channel instead of another package. `USE_EXACT_ALARM` not used (store policy). | Minimal dependencies; Play policy. |
| 13 | 2026-10-24 | Android 14+ denies exact alarms by default (observed: inexact window ≈ 11 min). The app asks when cooking starts and in Settings, and restores/reschedules notifications on every resume so running timers become exact once allowed. | Timers must ring on time. |
| 14 | 2026-10-24 | Notification permission is requested when the user starts cooking (Android 13+). | Otherwise first-time timers would never alert. |
| 15 | 2026-10-24 | "הערכה" badge tooltip uses long-press, not tap. | A tap-tooltip swallowed taps on the prep-task checkbox (found on the emulator). |
| 16 | 2026-10-24 | drift database opened with `shareAcrossIsolates: true`. | Leaving with Back and reopening starts a second Flutter engine in the same process; its writes hung on the first engine's connection (found on the emulator). |
| 17 | 2026-10-24 | Project knowledge lives in the repo: `CLAUDE.md` (permanent rules), `docs/PLAN.md` (approved design), `docs/DECISIONS.md` (why), `docs/PROGRESS.md` (status). Personal Claude memory keeps only user preferences and points here. | Survives context compaction, new sessions and machines; no duplication. |
