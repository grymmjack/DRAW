# CUSTOMIZABLE SHORTCUTS — build loop

Full plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Branch: `customizable-shortcuts` (off main).
Deliver in phase order; SHORTCUTS.md first. Each item: build clean + QA where applicable, then
commit. Mark genuinely-blocked items unchecked with a reason + who owes it, and reprioritize.

## 🔨 NOW — doing right now

➡️ Phase 0 done + committed. Rick steered (2026): **macOS ⌘ via GLFW interception**, **augment generator (tables spliced into curated prose)**, **keyboard-first migration**. Executing Phase 1. Starting 1.1a (GLFW ⌘ probe).

Decisions locked (were BLOCKED, now resolved): macOS Primary = real ⌘ intercepted through the GLFW layer · generator emits binding TABLES that splice into the curated SHORTCUTS.md shell (prose stays) · Phase 2 migrates KEYBOARD first, then mouse as a 2nd pass.

## Phase 0 — SHORTCUTS.md (first deliverable + registry-gap audit)

- [x] 0.1 Keyboard extraction DONE (agent) — full inventory: tools, chords (G/M/Z/E/F/W held), transforms, text-editing, custom-brush, shape-modifiers, panel modes; with actionIDs + file:lines + UNCERTAIN list.
- [x] 0.2 Mouse extraction DONE (agent) — full inventory: canvas per-tool, panels (layer/palette/toolbar/drawer/preview/charmap/status), wheel-over-region matrix, hold-key chords, special modes; SHORTCUT vs BEHAVIOR tagged.
- [x] 0.3 Registry extraction DONE (agent) — `INPUTS_register_all` = 213 bindings (141 key + 72 mouse); 137 dispatched=TRUE / 76 FALSE; actionId→label/hotkey map; **registry GAPS** enumerated (Effects/Image/Audio/Align/Symbol/etc. have no central binding).
- [x] 0.4 DONE — `PLANS/SHORTCUTS-INVENTORY.md`: coverage (213 registered, 137 TRUE / 76 FALSE), the ~150-action registry GAP (Effects/Image/Audio/Align/Symbol/custom-brush/mouse), parallel-id mismatches, menubar-only accelerators, and UNCERTAIN-confirm list. This scopes Phase 2.
- [x] 0.5 DONE — `SHORTCUTS.md` authored (full taxonomy, kbd+mouse, Primary-modifier convention, macOS note, CHEATSHEET tips merged) + reconciled against agent data (added universal Home/End/PgUp/PgDn transforms, Ctrl+F/Alt+F/Shift+F last-effect, Z+digit zoom, M+/− selection, text formatting, pixel-analyzer overlay; fixed scale keys, D30).
- [x] 0.6 DONE — `CHEATSHEET.md` replaced with a redirect stub → SHORTCUTS.md; CLAUDE.md key-files table updated. (In-app Help→Cheat Sheet opens the Command Palette, not the file — no code change needed.)
- [x] 0.7 DONE — anchors/links sane; committing Phase 0.

## Phase 1 — Registry completion + augment-generator + Primary/⌘

- [ ] 1.1a Investigate + prototype **GLFW ⌘ interception on macOS**: can QB64-PE reach `GLFW_MOD_SUPER` / `glfwGetKey(GLFW_KEY_LEFT/RIGHT_SUPER)` via `DECLARE LIBRARY` against the GLFW backend (the same layer that gave us `_MOUSECURSOR`)? Probe standalone; macOS-only, Linux/Win unaffected.
- [ ] 1.1b Add `MOD_PRIMARY` (`CORE/HELPERS.BI`). Feed it in `MODS_NOW%` from Ctrl (Win/Linux) or ⌘ (macOS via 1.1a). **AUDIT `MODS_only%` exact-match sites** so the extra bit can't break them (keep MOD_PRIMARY out of the exact-match snapshot, or update MODS_only%).
- [ ] 1.2 Add `category%` + `userOverridden%` to `INPUT_BIND`; derive category (by actionId range or explicit). Back-compatible.
- [ ] 1.3 Register the ~150 unregistered actions (0.4 inventory) as metadata (`dispatched=FALSE`) with category + label.
- [ ] 1.4 Build `--dump-shortcuts` → emits binding TABLES (markdown) grouped by category, Primary rendered per-OS. Add splice markers to SHORTCUTS.md's table regions (**augment**: prose stays hand-authored).
- [ ] 1.5 Splice generated tables into SHORTCUTS.md; verify tables ↔ registry; build + commit.

## Phase 2 — Migration to central dispatch (KEYBOARD FIRST, then mouse)

### 2A — Keyboard (ship first; makes keys rebindable)
- [ ] 2A.1 Migrate the 4 keyboard `dispatched=FALSE` (Flip H 315, Flip V 316, Quit 212, Settings 2100) → TRUE; build + QA + commit.
- [ ] 2A.2 Register + migrate unregistered keyboard legacy handlers, batched by subsystem: transforms (Home/End/PgUp/PgDn/>/<), custom-brush (F9/F12/`/`/Shift+O/Home/End/PgUp/PgDn), effects (Ctrl+F/Alt+F/Shift+F), music ({/}/*), recent files (Alt+1-0), grid/symmetry extras, display/misc — build + QA per batch.
- [ ] 2A.3 Keyboard conflict audit clean (dev-mode `inputs.log`); commit → keyboard rebindable-ready.

### 2B — Mouse (second pass, after keyboard ships)
- [ ] 2B.1 Give the 72 mouse metadata rows real actionIds; route canvas + per-panel mouse through central dispatch, region by region; build + QA each.
- [ ] 2B.2 Mouse/wheel conflict audit clean; commit.

## Phase 3 — Customization engine

- [ ] 3.1 `DRAW.bindings` override file: load/save deltas only (OS-native config dir).
- [ ] 3.2 Apply overrides over registry defaults at load; dispatcher honors overrides.
- [ ] 3.3 Context-aware `BINDINGS_find_conflict%` (same trigger + overlapping CTX masks).
- [ ] 3.4 Reset-to-default (per-binding + all). Build + QA (`rebind-apply/persist/reset/conflict`) + commit.

## Phase 4 — Customization UI

- [ ] 4.1 `GUI/CONTROLS.BI/BM` scaffold + `ACTION_CUSTOMIZE_CONTROLS` + Edit → "Customize Controls…" + `CMD` wiring + `_ALL` includes.
- [ ] 4.2 Binding list: find-filter, category dividers, current assignments (HOLD/PRESS/CLICK/WHEEL), scroll.
- [ ] 4.3 Capture sub-modals (key / mouse / wheel), Primary-aware, CLEAR/CANCEL.
- [ ] 4.4 Inline conflict badges + block-OK-on-conflict; SAVE/LOAD/RESET/PRINT toolbar. Build + QA + commit.

## Phase 5 — Presets + import/export

- [ ] 5.1 Preset format + loader; ship DRAW default map.
- [ ] 5.2 Author Aseprite preset (map → DRAW actionIds; unmapped keep DRAW default, noted).
- [ ] 5.3 Author Photoshop preset.
- [ ] 5.4 Author GIMP preset.
- [ ] 5.5 Author Deluxe Paint / GrafX2 preset.
- [ ] 5.6 Import/export `.bindings` via file dialog + `--export-bindings` / `--import-bindings` CLI.
- [ ] 5.7 Preset picker in the Controls dialog. Build + QA (`preset-load`) + commit.

## Phase 6 — Wrap

- [ ] 6.1 Regenerate SHORTCUTS.md from the final registry; reconcile.
- [ ] 6.2 Update `CLAUDE.md` / `README.MD` / instruction files for the new input system + customization.
- [ ] 6.3 Full QA regression; run summary in `PLANS/CUSTOMIZABLE-SHORTCUTS.md`; rendered Shortcuts artifact; final commit.

loop:on
