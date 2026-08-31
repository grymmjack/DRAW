---
name: bug-field-kit
description: "Turn a batch of deferred/found bugs into an interactive HTML Field Kit artifact the user works through at their own pace — per-bug repro steps, an honest 'why this needs you' tag (Reproduce/Judge/Decide), Confirmed/Couldn't-reproduce/Decision/Skip buttons, and a copy-paste report Claude parses to act on findings. Use when you have several bugs that need human verification Claude can't do alone (live GUI, platform-specific, visual judgment, or a behavior decision), or when the user says 'make a field kit', 'bug field kit', or '/bug-field-kit'."
---

# Bug Field Kit — hand the user a verification worklist

Some bugs Claude finds by reading code but **cannot verify alone**: they need a live GUI, a specific OS, a malformed input file, a multi-instance race, a visual "does this look wrong?" judgment, or a "what's the intended behavior?" decision. Dumping them in chat as a wall of text gets skimmed and lost.

This skill packages them as an **interactive artifact**: one card per bug with step-by-step repro, an honest note on *why* it needs the user, four result buttons, and a **Build report** button that emits `BUG-## [STATUS] note` lines the user copies and pastes back — which this skill then parses to drive fixes. The user works at their pace and can send several partial reports.

## When to use

- You deferred a set of bugs during a hunt/review and want the user to confirm them.
- A batch needs **human hands/eyes/judgment**: reproduce on the real app, judge visual output, or decide intended behavior.
- The user asks for a "field kit", "verification kit", or `/bug-field-kit`.

Not for a single bug (just describe it), or bugs you can verify yourself (do that instead).

## The three "why you" categories — be honest per bug

Tag each bug with one or more, and write a specific `why` explaining the ask:

- **`reproduce`** 👆 — Claude can't drive the live GUI, craft malformed PSD/ASE/TDX files, or run Windows / read-only-dir / multi-instance scenarios. The user's fingers + machine confirm it's real.
- **`judge`** 👁 — the automated harness diffs pixels but can't say "this looks wrong." Visual/output bugs (transform, effects, export, apron) need eyes.
- **`decide`** 🧠 — it may be a behavior choice, not a defect. Get the user's call on intended behavior *before* "fixing" it.

## Input: the bug list

Gather bugs from the source of truth (e.g. `BUGS-*.md`, a review, a hunt). For each, produce one JS object:

```js
{id:20, sev:'M', need:['reproduce'],
 t:'Undo reattaches a layer to the wrong group',
 steps:['Delete a grouped child (frees its slot).','Do ops that make another layer occupy that freed slot.','Undo the child-delete.'],
 why:'Reproduce IF you can engineer the slot collision. Otherwise mark ⊘ Skip — I’ll fix it by storing historyId, not the raw slot.'}
```

Fields:
- `id` — the bug number (renders as `BUG-##`, used in the report).
- `sev` — `'H'` | `'M'` | `'L'` (High/Med/Low; drives the color stripe + badge).
- `need` — array of `'reproduce'` | `'judge'` | `'decide'` (at least one). **Never omit `need`** — the render does `b.need.join(...)` and an empty array must be `need:[]` (only for a completeness-only entry with nothing to do).
- `t` — short title.
- `steps` — array of concrete repro steps (rendered as a numbered list). Keep each a single action.
- `why` — one honest sentence on what the user is confirming and why Claude can't. This is the heart of the kit — write it per bug, never boilerplate.
- **Fixed entries** (when re-issuing a kit after fixes): add `fixed:true` and `fixNote:'…what changed + where…'`. **Keep `need` and the other fields** — a fixed card still renders its repro so the user can confirm the fix. The default filter hides fixed cards ("🐞 Unfixed only"), and the count shrinks as you mark them.

## Build it

1. Read `template.html` (next to this SKILL.md). It is the exact, battle-tested shell — palette, dark/light theming, sticky filters, result buttons, notes, the report builder, and a fixed-card badge/fixnote. Do not re-derive the CSS/JS.
2. Fill the placeholders:
   - `__BUGS_ARRAY__` → your JS bug objects, comma-separated (this is the only required fill).
   - `__EYEBROW__` → a short kicker, e.g. `PROJECT · vX.Y.Z · Deferred-Bug Worklist`.
   - `__SUBTITLE__` → one sentence framing the batch (how many, what you need).
   - `__REPORT_HEADER__` → the first line of the pasted report, e.g. `=== PROJECT vX.Y.Z — BUG VERIFICATION REPORT ===`.
3. Write the filled HTML to a scratchpad file.
4. **Sanity-check before publishing** (a missing `need` breaks the render):
   ```bash
   grep -nE "^\s*\{id:[0-9]+" <file> | grep -v "need:"   # must print nothing
   ```
5. Publish with the **Artifact** tool (favicon `🐛`, title e.g. `PROJECT Bug Field Kit`). Give the user the URL and one line on how to use it (mark results → Build report → copy → paste back).

## Reading results back

The user pastes a block of lines shaped `BUG-## [STATUS] optional note`, where STATUS ∈ `CONFIRMED` | `NOT-REPRODUCED` | `DECISION` | `SKIP`. Parse each line and act:
- **CONFIRMED** → the bug is real; fix it (or schedule it), citing their note.
- **NOT-REPRODUCED** → don't fix blindly; re-examine whether it's real, or ask for detail.
- **DECISION** → the note carries the user's intended-behavior call; implement to match.
- **SKIP / can't test** → leave open; note why it couldn't be tested (needs a fixture/OS you don't have).

Partial reports are expected — act on whatever lines arrive, and the user can send more later.

## Re-issuing after fixes

To refresh a live kit (mark fixes), **build your update on the current published version, not a stale local copy** — read the artifact's URL first (the Artifact tool refuses a publish until you've read the live version, precisely to stop a stale local file from clobbering marks made since). Add `fixed:true` + `fixNote` to the fixed entries and republish to the same URL.

## Gotchas learned the hard way

- **`need` is mandatory on every entry** — `b.need.join(' ')` throws on `undefined`. Use `need:[]` for a pure completeness entry.
- **The local file drifts from the published artifact.** Marks made across sessions live in the published version; always re-read the live artifact before republishing, and merge onto *that*.
- **Escape apostrophes** inside `fixNote`/`why`/`t` string literals (`\'`) — these are single-quoted JS strings.
- **Keep `id` stable** — it's the report key the parse-back relies on.
