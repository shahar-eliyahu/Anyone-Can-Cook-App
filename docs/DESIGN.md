# Phase 4 — UX/UI design ("לבשל כל אחד יכול")

_Status: **implemented (Phase 4B–4E, 2026-10-24, local commits).** Written as the 4A proposal and approved by the
user; section 12 records what was built and where it differs from the proposal. The code is the reference for
exact values: `app/lib/core/theme.dart` (colours, type, shapes), `app/lib/core/motion.dart`,
`app/lib/core/widgets/`._

Source of truth for the visual identity: the final logo, `docs/branding/logo.png` (glossy white and light-blue
chef's hat, blue gradient background, small crossed knife and fork in natural wood above the hat; no steam, no
sparkles). See DECISIONS #64.

---

## 1. What the app looks like today (inspection, 2026-10-24)

| Area | Today | Problem |
|---|---|---|
| Theme | `ColorScheme.fromSeed(0xFFE0663A)` (orange), default Material 3, system font | Unrelated to the logo; no Hebrew font; pure-white surfaces |
| Home | App bar "המטבח שלי", "המשך בישול" card always shown ("אין בישול פעיל כרגע"), drafts card, 4 list tiles (recipes, favorites, history, settings), floating "מתכון חדש" | No brand presence; the main action is a FAB that can cover the list; an empty "continue" card; saved recipes are one tap away instead of visible |
| Navigation | Flat routes; no app menu; history and settings only from home | `context.go()` to `/recipes/:id`, `/cook/:id`, `/cook/:id/finish` and `/history/:id` leaves a **one-page stack**: no back arrow, and Android back closes the app (review → save, finish, history → continue) |
| RTL | Layout padding is symmetric (good) | List rows use `Icons.chevron_left`, which **mirrors in RTL** (`matchTextDirection: true`) and so points right, meaning "back" in Hebrew. 4 places: home ×2, recipes, history |
| Remy | Two unlabeled icons in the cooking app bar (assistant, microphone) beside the menu | Hard to discover; no Remy in preparation (overview, missing items); crowded app bar |
| Loading | Import shows a spinner and a stage line ("reading" / "planning", plus a slow note); Remy shows "רמי חושב…" | Works but feels technical and static; no skeletons; no transitions anywhere |
| Copy | 340 Hebrew strings | 13 `.arb` strings, about 6 Dart strings and about 6 backend strings/prompts use "—" as a separator (for example "סיימתי — לשלב הבא", "רמי — עוזר הבישול") |
| Motion | Platform defaults only | No reduced-motion handling (nothing to reduce yet) |

What already works well and stays: one main action per cooking step, the bottom action bar inside the safe area,
the Remy sheet resizing with the keyboard, no developer-facing text, "הערכה" only where values are reviewed.

---

## 2. Visual design system

### 2.1 Palette (sampled from the logo, contrast checked)

Measured logo colours: background gradient `#4B9ECC` (top) → `#3E7DB3` (middle) → `#3362A0` (bottom); hat light
blues `#79AFE3` / `#61A2D4`; wood utensils average `#DBAC81`.

| Role (Material `ColorScheme`) | Colour | Use | Contrast |
|---|---|---|---|
| `primary` | `#2F5F97` deep logo blue | Main buttons, links, active states | white on it 6.6:1; on background 6.1:1 |
| `onPrimary` | `#FFFFFF` | Text on main buttons | |
| `primaryContainer` | `#DCEAF6` soft hat blue | Active session card, selected chips, Remy bubbles | `#173A5E` on it 9.5:1; `#2F5F97` on it 5.4:1 |
| `onPrimaryContainer` | `#173A5E` | Text on soft blue | |
| `tertiary` (brand blue) | `#3E7DB3` | Icons, progress bars, focus rings, illustrations only | 4.1:1, **not for body text** |
| `secondary` (wood) | `#8A5A2E` | Small warm accents, secondary text links, Remy avatar ring | 5.4:1 on background; white on it 5.9:1 |
| `secondaryContainer` (beige) | `#F3E6D6` | "הערכה" badge, tips, finish screen highlights | `#5A3A1C` on it 8.3:1 |
| `onSecondaryContainer` | `#5A3A1C` | Text on beige | |
| Wood light (decor) | `#DBAC81` | Thin dividers under the brand header, the logo utensils, illustrations | Decor only |
| `surface` / background | `#F8F6F1` warm off-white | Screen background (no pure white) | `#1F2A36` on it 13.5:1 |
| `surfaceContainerLowest` | `#FFFDF9` | Cards and sheets (slightly lighter than the background) | |
| `surfaceContainerLow / / High` | `#F4F1EB` / `#EFEBE4` / `#E9E4DC` | Bottom bar, input fields, pressed states | |
| `onSurface` | `#1F2A36` ink | Main text | |
| `onSurfaceVariant` | `#56616D` | Secondary text | 5.9:1 |
| `outline` | `#7D868F` | Input borders, focus outlines | 3.4:1 (UI component minimum 3:1) |
| `outlineVariant` | `#E3DED5` | Card borders, dividers | Decor |
| `error` / `errorContainer` | `#B3261E` / `#F9DEDC` | Errors, safety warnings | 6.1:1 |
| Success (extension) | `#2E7D4F` | "✓" confirmations | 4.7:1 |
| Timer done (extension) | `#9A5B00` on `#FBEBD3` | A finished timer, "time to check" | 5.0:1; `#6B4A1F` on the container 6.8:1 |

Rules: soft blue does most of the work; wood and beige are accents (at most one warm element per view);
no gradients in the UI except the logo itself; no shadows heavier than elevation 1. Cards are separated by a
1px `outlineVariant` border and tone, not by shadow. Light theme only in Phase 4; the tokens are named so a dark
scheme can be added later without touching screens.

### 2.2 Typography

- **Heebo** (Google Fonts, SIL Open Font License, free), bundled as font files in `assets/fonts/` (no package,
  works offline). Weights 400, 500, 700. Fallback: the system font.
- Scale (kitchen distance, so slightly larger than Material defaults):

| Style | Size / weight / line height | Use |
|---|---|---|
| `displaySmall` | 30 / 700 / 1.2 | "לבשל כל אחד יכול" on home |
| `headlineSmall` | 24 / 700 / 1.3 | Screen headings, recipe title |
| `titleLarge` | 20 / 600 / 1.35 | Current step title, card titles |
| `bodyLarge` | 18 / 400 / 1.55 | **Step instructions**, Remy answers |
| `bodyMedium` | 16 / 400 / 1.5 | Lists, descriptions |
| `labelLarge` | 16 / 500 | Buttons |
| `labelMedium` | 13 / 500 | App name above the screen title, badges |

- Timers and quantities use tabular figures (`FontFeature.tabularFigures()`) so countdowns don't jitter.
- Mixed Hebrew and Latin text (URLs, "°C") is wrapped in bidi isolation so punctuation doesn't jump sides.
- Everything must still lay out at 200% system text size (wrapping, no fixed heights on text containers).

### 2.3 Shape, spacing, touch

- Spacing scale 4 / 8 / 12 / 16 / 24 / 32; screen side padding 16 (24 on wide screens, max content width 640).
- Radius: cards and sheets 20, buttons fully rounded (stadium), inputs 14, chips 12.
- Touch targets at least 48×48 dp; the cooking main button 56 dp tall and full width.
- Icons: Material Symbols Rounded style (already bundled via Material Icons; outlined variants), 24 dp.

### 2.4 Logo usage

- **In the app UI the logo is small:** a 36–40 dp rounded-square mark beside the app name in the home header,
  and on the about section of settings. Never a large central image, never stretched, never recoloured.
- A cropped, transparent-background version of the hat (for the header) and the adaptive icon layers
  (foreground = hat + utensils, background = the blue gradient) are prepared in subphase 4E, when the icon is
  replaced. The Android monochrome icon uses the hat silhouette only.

### 2.5 Components (one reusable widget each, in `lib/core/widgets/`)

`AppScaffold` (back + menu + titles), `BrandHeader`, `PrimaryActionCard`, `ActiveSessionCard`, `RecipeTile`,
`SectionHeader` (with an optional "לכל המתכונים" link), `NoteBanner` (info / tip / warning / safety),
`EstimateBadge` (restyled beige), `StepCard`, `TimerChip` + `TimerTray`, `MainActionBar`, `RemyButton`,
`RemyAvatar`, `StageLoader`, `SkeletonBox`, `EmptyState`, `ConfirmSheet` (replaces ad hoc dialogs).

---

## 3. Navigation and screen hierarchy

### 3.1 Structure

```
המטבח שלי (home)                          ← root of every stack
├── מתכון חדש (import: text / photo / link)
│     └── שאלה או שתיים (clarify, only when needed)  → replaced by the overview
├── מתכון (overview: ingredients, missing items, Remy)   /recipes/:id
│     ├── עריכה מתקדמת (review/edit)                     /recipes/:id/edit
│     ├── תוכנית הבישול (plan view)                       /recipes/:id/plan
│     └── מבשלים (cooking)                                /cook/:id
│           └── סיימנו! (finish)                          /cook/:id/finish
├── המתכונים שלי (+ favourites filter)                   /recipes
├── היסטוריית בישול                                       /history → /history/:id
└── הגדרות                                                /settings
```

- **Nested go_router routes** (children of `/`), so every deep location has a real back stack. `go()` to any page
  then always shows a back arrow, and Android back (including predictive back) never exits from inside a flow.
- Flow steps that should not be revisited are replaced, not stacked: import → clarify → overview. Back from the
  overview returns home (or to "המתכונים שלי" when opened from there).
- Leaving the cooking screen is always allowed: the session continues, timers keep notifying, and home shows the
  active session card. No confirmation dialog for leaving; "הפסקת הבישול" stays a deliberate menu action.

### 3.2 The menu (always visible, no hidden gestures)

- A **"תפריט" button in every app bar**, always at the same place: the end side (top left in Hebrew). The back
  arrow stays at the start side (top right, pointing right). Home has no back arrow, only the menu.
- The menu is a side sheet sliding in from that same side (`endDrawer`), labelled items with icons:
  "המשך בישול" (only when a session is active, highlighted at the top) · "המטבח שלי" · "מתכון חדש" ·
  "המתכונים שלי" · "מועדפים" · "היסטוריית בישול" · "הגדרות".
- It closes on selection, on back and on a tap outside; it is fully reachable with TalkBack/VoiceOver.
- The app bar keeps the branding rule: the small app name above every screen title.

### 3.3 Layout safety rules (checked in widget tests)

- Bottom action bars and sheets sit inside `SafeArea`; content scrolls above them with matching bottom padding.
- No floating buttons over lists (the home FAB is removed). Snackbars appear above the bottom bar.
- The timer tray is part of the cooking layout (above the main action bar), never a floating overlay.
- The Remy sheet resizes with the keyboard; the text field and send/mic buttons stay visible.
- Tested at 360×640 with 200% text, and with the keyboard open, for: home, import, overview, cooking, Remy.

---

## 4. Home screen (final structure)

```
┌──────────────────────────────────────────┐
│ [≡ תפריט]                                │  app bar: only the menu
│                                          │
│              [logo 40dp]  לבשל כל אחד יכול │  BrandHeader (display text, wood hairline)
│                         מה מבשלים היום?   │  one friendly line
│                                          │
│ ┌──────────────────────────────────────┐ │  ActiveSessionCard (ONLY when cooking)
│ │ מבשלים עכשיו: עוף בתנור              │ │  soft blue container
│ │ שלב 3 מתוך 5 · ⏱ 12:30 לעוף בתנור     │ │
│ │                        [ המשך לבשל ] │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌──────────────────────────────────────┐ │  PrimaryActionCard (the one main action)
│ │ ＋  מתכון חדש                         │ │  filled primary, full width, 64dp
│ │    מטקסט, מתמונה או מקישור           │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ מתכונים שהתחלתם                          │  drafts, only when there are any (max 2)
│                                          │
│ המתכונים שלי              לכל המתכונים ‹ │  SectionHeader + link
│  ⭐ עוף בתנור עם תפוחי אדמה        ‹     │  compact RecipeTiles: favourites first,
│     שקשוקה                         ‹     │  then recently cooked/added, up to 5
│     עוגת שוקולד                     ‹     │
│                                          │
│ (empty state: "עוד אין מתכונים שמורים.    │
│  אפשר להתחיל עם המתכון לדוגמה." + link)  │
└──────────────────────────────────────────┘
```

- History and settings move to the menu (they are not daily actions).
- No server status, no versions, no technical text. The quiet server wake-up on open stays invisible.
- The "‹" row chevrons point left in Hebrew (`Icons.chevron_right`, mirrored).

---

## 5. The beginner cooking journey

1. **Home → "מתכון חדש".**
2. **Import**: three clear tabs (טקסט · תמונה · קישור) with one button "המשך". The text field keeps its draft;
   photo shows a preview before sending.
3. **Reading the recipe** (Gemini): the `StageLoader` (section 7.3). Cancel is always available; a failure keeps
   the draft and offers "לנסות שוב".
4. **A question or two** (only when needed, at most 3): one card per question with big choices and
   "לא בטוח/ה, תחליטו בשבילי".
5. **Recipe overview**: title, servings, total and active time; ingredients checklist ("יש לי הכול" or tick one by
   one); a missing item opens the substitution sheet; equipment; a **"שאלו את רמי"** button; one main button
   "מתחילים לבשל" in the bottom bar.
6. **Cooking**: progress "שלב 2 מתוך 5" with a thin progress bar; one `StepCard` (title, instruction in large text,
   ingredients for this step, the doneness cue, a safety banner when relevant); prep tasks surface as small tip
   banners at the right time; the `TimerTray` above the bottom bar; the bottom bar holds the main action and the
   Remy button. Undo stays a small text button on the step card.
7. **Timer finishes**: notification + sound, the timer chip turns "timer done" amber and gently pulses, and the
   main button becomes "בדקתי, מוכן".
8. **Finish ("סיימנו!")**: a calm celebration (the logo's utensils animate once, see 7.2), the time it took,
   "לשמור את השינויים במתכון?" when changes were made, "חזרה למטבח". Leaving the finish screen goes home.
9. **Later**: the recipe appears first in "המתכונים שלי"; the session appears in history.

---

## 6. Remy: placement and interaction

### 6.1 Identity

- An original character, **not** based on any existing film character: a round `RemyAvatar` showing a small
  chef's hat taken from the logo, on the soft blue container, with a thin wood ring. No animal, no face.
- Voice and tone: short, warm, practical, first person ("אני כאן לעזור"). Remy is a helper, never the boss of the
  session.

### 6.2 Entry points

| Where | Entry point | Remy can |
|---|---|---|
| Cooking | **`RemyButton`** in the bottom bar, at the start side of the main action: avatar + the label "רמי" (labelled, 48 dp). Long press or the small mic inside it opens Remy already listening. The two unlabeled app-bar icons are removed. | Everything from Phases 3B/3D (commands, timers, questions, proposals) |
| Recipe overview | A labelled tonal button **"שאלו את רמי"** under the ingredients, and inside the missing-item sheet ("לשאול את רמי על תחליף") | Recipe questions and substitutions **before** cooking (see 6.4) |
| Finish | none (keep it calm) | |

### 6.3 The sheet

- Opens to about 70% height with a drag handle; the conversation sits on the off-white surface; Remy's bubbles use
  `primaryContainer`, the cook's use `surfaceContainerHigh`.
- The input row keeps "שליחה" and the mic; quick chips stay ("מה עכשיו?", "כמה זמן נשאר?", "עזרה בשלב").
- Approval cards use the same `ConfirmSheet` styling as the rest of the app: what will change, then "אישור" /
  "לא, תודה".
- States: thinking (three soft dots in a bubble), listening (a breathing ring around the mic plus the live
  transcript), speaking (a small sound-wave icon plus "עצירה"). Under reduced motion: static icons and text.

### 6.4 Remy in preparation (needs approval, planned for 4D)

Remy is session-scoped today (it needs a cooking session). Pre-cooking Remy needs a **recipe-scoped context**: the
same `AssistantService` with the recipe and plan but no live session, allowing questions and substitution
proposals only (applied through the existing substitution patches). This is a small architectural extension, so
it is listed as an open decision (section 10).

---

## 7. Motion and feedback (reusable patterns, local code, no new package)

### 7.1 Tokens

`short` 150 ms, `medium` 250 ms, `long` 350 ms; curves `Easing.emphasizedDecelerate` (enter) and
`Easing.emphasizedAccelerate` (exit). One `Motion` helper reads `MediaQuery.disableAnimations` (the system
"remove animations" setting) and returns zero or crossfade-only durations.

### 7.2 Patterns

| Pattern | Where | Normal | Reduced motion |
|---|---|---|---|
| **Forward/back page** (shared axis) | All pushes, via go_router `CustomTransitionPage` | New page fades in while moving 24 dp in the reading direction (from the left edge in Hebrew); back reverses | 150 ms crossfade |
| **Flow replace** | Import → clarify → overview | Fade through (out 90 ms, in 210 ms) | Instant |
| **Step change** | Cooking main action | Current step card slides toward the reading direction and fades, next card follows; the progress bar fills | Crossfade |
| **Check** | Checklist ticks, "✓ סיימנו" | Check mark scales 0.8→1 with a light haptic | Instant + haptic |
| **Timer done** | Timer chip | Turns amber, three gentle pulses, then stays amber | Colour change only |
| **Loading skeleton** | Overview and lists while loading | Soft shimmer on `SkeletonBox` | Static boxes |
| **Thinking dots** | Remy | Three dots fading in sequence | Static "רמי חושב…" |
| **Listening ring** | Mic | Slow breathing ring | Static ring |
| **Celebration** | Finish | The logo's utensils tilt once (600 ms), no confetti | None |

Haptics: light on the main action and on ticks; medium when a timer finishes (with the notification).

### 7.3 Friendly Gemini loading (no artificial waiting)

- The `StageLoader` shows real stages only, each line turning into a ✓ as it completes:
  "קוראים את המתכון" → "מבינים מצרכים וזמנים" → "בונים תוכנית בישול שלב אחר שלב".
  The stages follow the actual calls (analyze, then plan); there is no fake progress bar.
- After about 8 s: "זה לוקח קצת יותר מהרגיל. אפשר להמשיך לחכות או לבטל." (A cold server start is never
  mentioned in technical terms.)
- A skeleton of the overview appears under the loader so the next screen feels close.
- Quota, rate limit and offline errors keep their existing Hebrew messages and preserve the draft.
- Remy's local answers appear immediately; only the fallback interpretation shows the thinking dots.

---

## 8. RTL fixes (concrete list)

1. Row chevrons: `Icons.chevron_left` → `Icons.chevron_right` (auto-mirrored, points left in Hebrew). Home ×2,
   recipes, history. A widget test checks the icon used in `RecipeTile`.
2. Navigation stack: nested routes (3.1) so back arrows exist and point right after any `go()`.
3. Page transitions slide according to `Directionality` (a direction-aware helper, tested in LTR and RTL).
4. Menu: `endDrawer` opening from the menu button's side.
5. Mixed-direction strings (URLs, temperatures with °C, "×2"): bidi isolation helper in `format.dart`.
6. All new padding uses `EdgeInsetsDirectional`; all alignment uses `AlignmentDirectional` (lint check in review).
7. Bottom bar order in cooking: Remy at the start (right), main action filling the rest.

---

## 9. Hebrew copy style

- Natural, short, friendly; addressing the cook in the plural form already used ("בדקו", "לחצו").
- **No dashes as separators** (no "-", "–", "—" between phrases). Use a comma, a period, a colon or two sentences.
  Hyphens inside words that need them ("כ-5 דקות") stay.
  - "סיימתי — לשלב הבא" → **"סיימתי, לשלב הבא"**
  - "רמי — עוזר הבישול" → **"רמי, עוזר הבישול"** (sheet title "רמי")
  - "ערך משוער — המתכון המקורי לא ציין אותו" → **"ערך משוער. המתכון המקורי לא ציין אותו."**
  - "ההתראות חסומות — טיימרים לא יתריעו" → **"ההתראות חסומות, ולכן הטיימרים לא יתריעו."**
- Scope of the cleanup: 13 `.arb` strings, about 6 Hebrew strings in `local_substitutions.dart`, about 6 backend
  strings and prompt examples (`analysis.py`, `planning.py`, `assistant.py`, `food_safety.py`, prompts). The
  prompts get an explicit rule ("no dashes as separators"); AI text shown in the app passes a small display tidy
  step that turns " — " into ", " (unit tested). Backend changes ship only with an approved deploy.
- A test fails if any `.arb` value contains " — ", " – " or " - ".

---

## 10. Decisions (resolved when Phase 4 was approved, 2026-10-24)

1. **Menu position:** first built at the top left; moved to the top-right corner (with back beside it) in the
   refinement of section 13.
2. **Heebo:** bundled (3 static weights, about 130 KB, SIL OFL; license in `app/assets/fonts/OFL.txt`).
3. **Remy in preparation:** implemented with the existing turn endpoint; questions only (section 12).
4. **Icon:** replaced in 4E (section 12).
5. **Dark theme:** later; the app is light-only and so are its splash screens.

---

## 11. Implementation subphases (each needs approval to start)

| Subphase | Scope | Verification |
|---|---|---|
| **4A** (this document) | Analysis and design proposal; logo stored as brand reference | User review |
| **4B — Foundation** | Theme tokens (`theme.dart`), Heebo, `Motion` helper + page transitions, nested routes + back behaviour, `AppScaffold` with menu, RTL fixes (8.1–8.6), copy cleanup in the app (9) with the dash test | All tests + new tests for routes/back, RTL icons, reduced motion, dash rule; emulator walk of every screen |
| **4C — Screens** | Home (section 4), import + `StageLoader` + skeletons, overview, cooking (`StepCard`, `TimerTray`, bottom bar with `RemyButton`), finish, recipes, history, settings wording | Widget tests per screen (structure, no FAB overlap, 200% text, keyboard); emulator journey from import to finish, offline included |
| **4D — Remy and feedback** | `RemyAvatar`, sheet styling, thinking/listening/speaking animations, haptics, recipe-scoped Remy in preparation (if approved), backend copy and prompt rule (deploy needs approval) | Assistant and voice suites, new preparation-Remy tests (fakes, zero Gemini calls) |
| **4E — Icon and accessibility pass** | Replace the app icon from `docs/branding/logo.png` (adaptive + monochrome, iOS), TalkBack/VoiceOver labels, contrast audit, large text, reduced motion review | Icon on the emulator launcher; accessibility scanner; full test run |
| **Release (separate approval)** | Store listing, privacy policy, App Check, paid Gemini tier, iOS builds | Per the release plan |

No new packages are needed for 4B–4E (transitions, skeletons and haptics are local code; Heebo is a font asset).

---

## 12. As built (Phase 4B–4E)

- **Palette:** as in 2.1, unchanged after the contrast check. `tertiaryContainer` carries the success green; the
  "הערכה" badge uses the beige `secondaryContainer`. Wood appears in small doses only (Remy's ring, the header
  rule, the "cooking now" label, favourites, tips).
- **Type:** Heebo 400/500/700; titles use 700 (Heebo has no 600). Symbols such as ✓ and ⏱ fall back to the system
  font. Temperatures are written in words ("200 מעלות") so the degree sign never flips sides in RTL.
- **Frame:** `AppScaffold` (back on the start side, small app name above the title, "תפריט" + side menu from the
  end side), `BottomActionBar` (above the gesture bar and the keyboard, full-width main action), `ContentWidth`
  (max 640). A bug found by tests: an `Align` in the bottom bar filled the whole screen; bars now fit their height.
- **Navigation:** every route is a child of `/`; menu destinations use `go()`, flows use push or replace. Android
  back walks back to home and leaves the app only from home. Leaving cooking never stops it.
- **Home:** header (mark, name, "מה מבשלים היום?"), the cooking card only while cooking (step, nearest timer,
  "המשך לבשל"), "מתכון חדש", unfinished imports, up to 4 recipes (favourites first) and "לכל המתכונים". No FAB.
- **Journey:** new recipe (segmented text/photo/link, sticky "קריאת המתכון"), real stages in a `StageLoader`
  (reading, then planning; after 12 s a note and "יציאה": the request finishes in the background and the recipe
  waits as an unfinished import); questions (at most 3, "לא בטוח/ה, תחליטו בשבילי"); overview (facts as pills,
  notes, round checklist with "יש לי הכול", a ready banner when everything is ticked, a hint when "קראתי" is
  needed, Remy + "מתחילים לבשל"); cooking; finish ("בתאבון!", the logo tilts once, time and steps, notes, sticky
  save) then history.
- **Cooking screen:** "שלב N מתוך M" and a filling progress bar with "חזרה" (undo) beside it; the step card (large
  title, 20px instruction, this step's ingredients, temperature, timer, cue, safety check, help); timers in words
  ("השהיה"/"המשך", "הוספת דקה", "אפשרויות טיימר" for less common actions), amber with three pulses when it is
  time to check; "הפסקת הבישול" as a labelled button at the end of the page. Light haptics on the main actions.
- **Remy:** `RemyAvatar` is a hat drawn in code (no face, no animal) in a wood ring; `RemyButton` ("רמי") sits at
  the start of the bottom bar in cooking and preparation, never covering the main action; long press opens him
  listening. The sheet: header, bubbles (Remy soft blue, the cook warm grey), thinking dots, approval card, a
  voice status line with "עצירה", wrapped quick chips, "שיחה רציפה" on the microphone's side, a rounded input
  with send and a large microphone. On large text the sheet grows and its middle scrolls.
- **Remy before cooking:** `RemyScope.recipe`: local answers (time, first step, amounts, temperature, step count,
  "חסר לי" → the checklist), Remy online for the rest; cooking actions answer "את זה עושים כשמתחילים לבשל";
  proposed changes are never applied from the chat (the checklist's substitutions have their own undo).
- **Motion:** shared-axis page transitions in the reading direction, `Appear` (staggered, capped), step slides,
  `AttentionPulse`, `ThinkingDots`, `BreathingRing`, `SkeletonBox`, check animations. Every repeating animation is
  bounded; with "remove animations" movement becomes a fade or nothing.
- **Copy:** no dash separators (tests on the `.arb` file and Hebrew literals in code; `tidyHe` for text from people
  or the AI; backend constants and a style rule in every prompt).
- **Icon and splash (4E):** generated by `app/tool/make_icons.py` from `docs/branding/logo.png`. Adaptive icon =
  the logo's gradient (background) + the hat and utensils separated from it and scaled to 0.81 so the utensils stay
  inside the safe circle (foreground) + a white silhouette (monochrome); legacy Android and iOS use the logo
  itself. Splash: the mark on the warm off-white (Android 12+ with the adaptive icon; iOS launch screen).

---

## 13. Voice-first Remy, hands-free cooking, Hebrew bar layout (refinement, 2026-10-24)

- **A tap on Remy is "talking to Remy":** the sheet opens already listening (where the phone can listen).
  A long press opens it quietly. There is no choice to make before speaking.
- **The sheet is voice-first:** a centred avatar with a listening ring, one status line ("מקשיב…", "רגע…", "רמי
  מדבר…") with the live transcript under it, the latest exchange only ("כל השיחה (N)" shows the rest), a large
  central microphone (stop while speaking), "הקלדה" as a small side button, "שיחה רציפה" on the other side,
  three quick chips. A question Remy asks shows in its own card with large "כן" / "לא" and "אפשר גם לומר כן או
  לא", and Remy listens for the answer by himself. When typing or reading a note the header becomes a slim row.
- **Hands-free ("היי רמי"), cooking screen only:** a "דיבור בלי ידיים" switch under the progress (off by default,
  remembered). While on, the cooking screen is open and the app is in front: the phone's own speech recognition
  runs in patient sessions (dictation mode, up to 60 s each, restarted in a loop); a session ends 1.4 s after the
  phrase stops changing. "היי רמי, סיימתי" is answered at once; "היי רמי" alone opens Remy listening. Remy's sheet
  pauses the loop (it owns the microphone; Remy never hears himself); a sheet opened by voice closes itself 4 s
  after the answer unless touched, and the loop resumes. Leaving the screen, the app going to the background or
  turning the switch off stops it. The screen stays on while it runs (window flag; iOS idle timer). Problems
  (no permission, no Hebrew, offline recognition, repeated errors) turn it off with a Hebrew reason; the Remy
  button keeps working.
- **Why not always-listening wake-word detection:** a dedicated on-device wake-word engine needs either a paid
  or keyed service or a large offline model plus a new package; the phone's recognizer is free and already
  approved. Limits: recognition restarts about once a minute (some phones play a short sound each time);
  without an offline Hebrew pack it needs the internet; it stops when the screen is off or the app is closed.
- **Bar layout (Hebrew):** the start of the bar is the right edge, so "תפריט" (icon with its word) sits in the
  top-right corner on every screen and opens the menu from the right; the back arrow, pointing right, sits
  right beside it on inner screens; screen actions stay on the left.

---

## 14. Real-device refinement: navigation, cooking hierarchy, hands-free placement (2026-10-25)

Supersedes the bar layout of §3.2 and §13.

- **Navigation rule (final):** home shows the app name and logo in the page and a labelled "תפריט" on the
  right (the menu slides in from the right); no back. Every inner screen shows one back arrow on the right,
  pointing right, and only its own title (one line, ellipsis); no menu, no app name. Back always ends at home
  (routes nested under `/`); a screen opened with nothing under it (a notification, a restored session) goes home.
  Android back matches the visible arrow. Remy's sheet keeps its close control.
- **Cooking screen:** one compact header row (back, recipe name, and the hands-free indicator in the free
  corner); a light progress line ("שלב N מתוך M", the done count, "חזרה" undo, a 4px bar); then the instruction
  card first (title 20, instruction 20px, this step's ingredients, temperature, the timer, cue, safety, help),
  then prep tasks, other timers, "בינתיים אפשר", all steps and "הפסקת הבישול". The bottom bar keeps Remy and the
  main action.
- **Hands-free placement:** the choice "רוצים לדבר עם רמי בלי לגעת במסך?" is a quiet card under the preparation
  checklist and a row in settings ("רמי" section); both are the same saved preference (`hands_free`, so an
  existing choice is kept) and turning it on asks for the microphone first (refused → stays off, says why).
  During cooking there is no setup card: a small "מקשיב" pill only while it really listens (a tap stops it for
  this cooking session; the saved choice stays), a muted microphone to turn it back on when stopped or unable to
  listen (its label says why), nothing while starting or while Remy's sheet is open.
- **Guidance timing:** the plan's plan-ahead notice (`advance_notice_he`, e.g. "מומלץ לתת לעוגה לנוח במקרר לילה
  שלם") is no longer a banner at the start of cooking. It shows in preparation, and during cooking inside the step
  it is about (matched by kind of waiting: chilling, resting, freezing, soaking, rising, marinating; else the
  longest wait of an hour or more; else the last step). Step notes, warnings, help, cues and wait tips were
  already tied to their step or wait and are unchanged. The planning prompt now asks for a short plan-ahead
  sentence and for the wait itself to be a real step with a timer.

---

## 15. Remy: one simple assistant per recipe, with memory (2026-10-25)

- **Default mode by state:** before cooking (overview, preparation) Remy opens as a chat: the input focused,
  a small microphone beside it, nothing listening. In an active cooking session he opens in voice mode and
  listens at once, with "הקלדה" to type instead. Long press opens the other mode. If voice can't work (no
  permission, no recognition, no Hebrew, offline recognition) he switches to text by himself with one note.
  On the overview of a recipe being cooked right now, Remy is the cooking session's.
- **Interface:** a small header (avatar, "רמי", one status line: listening / thinking / speaking / "העוזר שלך
  לבישול"), the conversation as plain chat bubbles (what is being heard shows as a faint bubble), a compact
  "כן / לא" card for anything that needs a yes, and one input area (text field + send + small mic, or a big mic
  + "הקלדה" + "עצירה"). Removed: the long introduction (one short hint line when empty), the suggestion chips,
  the "שיחה רציפה" toggle and the "show the whole conversation" switch.
- **Speech turn-taking:** after Remy answers a spoken request he listens once more for a follow-up (always for
  the answer to a question he asked). The first silence ends the turn quietly; at most 6 follow-ups in a row.
  Nothing listens after that unless the cook taps, or says "היי רמי" with hands-free on (unchanged:
  foreground-only, cooking screen only, paused while the sheet is open).
- **Memory (DECISIONS #81):** one conversation per
  recipe or draft, shared by preparation and cooking, kept on the device (closing the sheet, leaving the screen
  and restarting the app keep it), at most 20 messages, forgotten after 12 hours without activity, and cleared
  when the recipe is finished, abandoned, deleted or its draft discarded. Requests to Gemini carry at most the
  last 6 turns (600 characters each), the stage (preparation / cooking), the saved preparation decisions and the
  live cooking state; never the source text or the whole history.

---

## 16. "מה בא לכם לבשל?": built-in recipes, Remy creates, or your own (2026-10-25)

- **Hub (`/new`):** home's "מתכון חדש" (and the menu) opens three choices as plain recipe tiles: "מתכונים
  מוכנים" (the built-in catalog), "רמי יציע מתכון" (Remy creates one with the cook) and "מתכון משלי" (the
  existing import: text, photo, link, unchanged).
- **Catalog (`/catalog`, DECISIONS #84):** 24 bundled recipes; a search field (title or ingredient) and one
  row of category choices (הכל, מהיר, עוף, פסטה, אפייה, ארוחת בוקר, צמחוני, קינוחים). Each tile shows the
  estimated time (from the plan), servings and categories. Opening one shows the usual overview, marked
  "מתכון מהאוסף", with preparation, Remy and "מתחילים לבשל" as for any recipe. Nothing there changes the
  built-in recipe itself: no rename, favourite, advanced edit or delete; "שמירה במתכונים שלי" saves the cook's
  own copy (with what they prepared), which can then be edited like any recipe.
- **Remy creates (`/create`, DECISIONS #85–#87):** the same chat as Remy's sheet on a screen of its own, text
  first (input focused, small microphone, nothing listening; voice works as in the sheet). An empty chat shows
  one hint line. A broad request gets 2 to 4 dishes as buttons under Remy's reply; a tap answers with that dish.
  A specific request (or a choice) gets a recipe: the review opens by itself, and the chat keeps a
  "לצפייה במתכון" link. The app bar has "שיחה חדשה".
- **Review (`/drafts/:id/preview`):** a note that this is Remy's suggestion, the title, description, servings,
  "הערכת זמן", ingredients, equipment, numbered steps and Remy's tips. "שמירה במתכונים שלי" (plans it and opens
  its overview), "עריכה" (names, amounts, equipment, steps; add and remove rows), "שינוי עם רמי" (back to the
  chat, e.g. "בלי חלב"), "ביטול המתכון" (with a confirmation). An unsaved Remy draft also appears under
  "מתכונים שהתחלתם להוסיף" on home and opens this review.

