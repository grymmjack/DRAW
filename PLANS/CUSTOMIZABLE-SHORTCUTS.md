# CUSTOMIZABLE SHORTCUTS — Master Plan

> **Supersedes** `control-customization/PLANS/CUSTOM-CONTROLS.md` (that branch's engine predates
> the `INPUT/INPUT.BM` dispatch table and would add a *third* input path). This plan reuses the old
> plan's good ideas — the rebind dialog UX, the override-only storage file — but re-architects them
> onto DRAW's real central registry: `INPUTS_register_all`.
>
> Branch: `customizable-shortcuts` (off `main`).

## Goal

One central, machine-readable registry of **every** keyboard + mouse + wheel input, that powers:
1. **Runtime dispatch** (already partly true — `INPUT/INPUT.BM`).
2. **`SHORTCUTS.md`** — a complete, always-accurate reference (keyboard + mouse), by use case / tool.
3. **User customization** — rebind keys/mouse/wheel, with **presets** (GIMP, Aseprite, Photoshop,
   Deluxe Paint/GrafX2) and **import/export** of keymaps.

Cross-platform by design: a logical **Primary** modifier renders `Ctrl` on Windows/Linux and `Cmd`
on macOS, in both the doc and the binding engine.

## Locked decisions

| # | Decision | Choice |
|---|----------|--------|
| Doc source | how SHORTCUTS.md stays accurate | **Hybrid** — hand-author now, flip to registry-generated in Phase 1 |
| Engine | what customization is built on | **The existing `INPUTS_register_all` dispatch table** (single source of truth) |
| Scope | how far rebinding goes | **Keyboard + mouse + wheel + presets + import/export** |
| CHEATSHEET.md | fate of the old 2,164-line doc | **Merge its tips into SHORTCUTS.md, then retire it** |
| Cross-platform | macOS Cmd vs Ctrl | **Logical `Primary` modifier**, resolved per-OS |
| Presets | which keymaps to ship | **GIMP, Aseprite, Photoshop, Deluxe Paint/GrafX2** (+ DRAW default) |

## Current state (as of this plan)

- **`INPUT/INPUT.BM` → `INPUTS_register_all`**: 221 registered bindings — **137 `dispatched=TRUE`**
  (fire through the central dispatcher) and **~76 `dispatched=FALSE`** (metadata only; legacy code
  still owns dispatch). Registration fns: `INPUT_register_key% / _mouse% / _wheel% / _hover%`.
- **Context system**: `INPUT/INPUT.BI` defines a 32+-slot `CTX_*` bitmask (`CTX_TEXT_ACTIVE`,
  `CTX_MOVE_ACTIVE`, `CTX_OVER_LAYER_PANEL`, `CTX_OVER_CANVAS`, …) used as `requireCtx`/`forbidCtx`.
  This makes conflict detection **context-aware** — the same key can mean different things in
  different contexts without a false conflict.
- **`CHEATSHEET.md`**: rich hand-maintained taxonomy, drifts from code, no machine link.
- **Legacy dispatch**: much of the mouse pipeline (`MOUSE.BM`, 6k lines), tool-specific keys, and
  drag/hover state machines are NOT in the registry yet — quantified by the Phase 0 audit.

## Architecture

### The binding record (registry entry)
Extend the registered-binding metadata with:
- `category%` — TOOLS / FILE / EDIT / VIEW / SELECTION / LAYERS / COLOR / GRID / TEXT / PANELS / MOUSE.
- `label$` — human name (already present).
- logical **Primary** modifier support in the modifier bitmask (see below).
- `userOverridden%` — set when a user rebind replaces the default (drives persistence).

### Logical Primary modifier
Add `MOD_PRIMARY` alongside `MOD_CTRL/MOD_SHIFT/MOD_ALT`. The registry stores the **logical** intent;
a single resolver maps `MOD_PRIMARY` → `Ctrl` (Win/Linux) or `Cmd` (macOS) at three points: the
dispatcher (match), the doc generator (render), and the capture dialog (display + store).

### Override model (customization)
- Defaults live in `INPUTS_register_all` (compiled in).
- User overrides are **deltas** in `DRAW.bindings` (OS-native config dir), keyed by `actionId` + slot,
  storing only rows where `userOverridden% = TRUE` — compact, forward-compatible.
- Loaded **over** the defaults right after `CONFIG_load`. Dispatch, doc, and dialog all read the
  merged view.

### Context-aware conflict detection
Two bindings conflict **iff** same trigger (key/mouse/wheel + mods) **AND** their `requireCtx`/
`forbidCtx` masks overlap (could both be active in the same frame). Reuses the `CTX_*` system — a
strict improvement over the old plan's flat check.

### Doc generator
`--dump-shortcuts [md|html]` walks the registry and emits `SHORTCUTS.md` (and optionally an HTML
artifact), grouped by `category%`, Primary rendered per-OS. Console-only, works headless.

## Phase plan

### Phase 0 — SHORTCUTS.md (first; also the audit)
Hand-author the complete doc from an exhaustive source extraction; the extraction doubles as the
**registry-gap audit** (which bindings aren't registered → the Phase 2 migration cost).
Taxonomy: Global/App · File · Edit/History · View (Zoom/Pan/Scale) · Tools (key + mods + mouse per
tool) · Selection · Layers/Groups · Color/Palette · Grid/Symmetry · Text/CharMap · Brush/Custom
Brush · Panels/Docking · Dialogs/Widgets · Mouse reference (per-context) · Appendix (internal
behaviors). Merge CHEATSHEET.md tips, then retire CHEATSHEET.md (redirect stub).

### Phase 1 — Registry completion + generator
Introduce `MOD_PRIMARY`; add `category%` + override fields; register every still-unregistered
binding as metadata (`dispatched=FALSE` where legacy owns it); build `--dump-shortcuts`; reconcile
generated vs hand-authored until identical; flip SHORTCUTS.md to generated.

### Phase 2 — Finish the migration
Move `dispatched=FALSE` → `TRUE` in subsystem batches (tools · view · selection · layers ·
color/palette · grid/symmetry · text · panels · mouse), each **built + QA-regressed**. Goal:
every binding fires through the dispatcher (prerequisite for rebinding). Developer-mode conflict
audit clean.

### Phase 3 — Customization engine
`DRAW.bindings` load/save (deltas); apply overrides over defaults; dispatch honors overrides;
context-aware `BINDINGS_find_conflict%`; reset-to-default.

### Phase 4 — Customization UI
`GUI/CONTROLS.BI/BM` + `ACTION_CUSTOMIZE_CONTROLS` + Edit → "Customize Controls…". Find-filter list,
current assignments, capture sub-modals (key/mouse/wheel, Primary-aware), inline conflict badges,
block-OK-on-conflict. (Reuses the old plan's dialog design.)

### Phase 5 — Presets + import/export
Preset format + loader; ship DRAW default; author GIMP / Aseprite / Photoshop / Deluxe Paint-GrafX2
maps (their actions → DRAW `actionId`s; unmapped actions keep DRAW defaults, noted); import/export
`.bindings` via file dialog + `--export-bindings` / `--import-bindings` CLI; preset picker in dialog.

### Phase 6 — Wrap
Regenerate SHORTCUTS.md; update `CLAUDE.md` / `README` / instruction files; QA tests for rebinding;
full regression; run summary; a rendered **Shortcuts** artifact.

## Testing
- Each phase: clean compile + `QA/draw-qa.sh` regression subset.
- New QA tests: `shortcuts-dump.sh` (generator output stable), `rebind-*.sh` (override applied,
  persisted, reset, conflict blocked), `preset-*.sh` (preset load switches bindings).
- `--dump-shortcuts` diffed in CI to catch drift.

## Risks
- **Phase 2 migration** is the real cost and the main regression risk (legacy input → central). Batched
  + QA-gated per subsystem; any ambiguous handler is flagged, not guessed.
- **Preset fidelity**: not every foreign shortcut has a DRAW equivalent; unmapped → DRAW default,
  documented per preset. No silent wrong mappings.
- **Mouse rebinding** surface (region+button+modifier+event) is larger than keys; keyboard proven
  first within the same model.
