# CUSTOMIZABLE SHORTCUTS — build loop

Full plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Branch: `customizable-shortcuts` (off main).
Deliver in phase order; SHORTCUTS.md first. Each item: build clean + QA where applicable, then
commit. Mark genuinely-blocked items unchecked with a reason + who owes it, and reprioritize.

## 🔨 NOW — doing right now

➡️ Phase 0 done + committed. Rick steered (2026): **macOS ⌘ via GLFW interception**, **augment generator (tables spliced into curated prose)**, **keyboard-first migration**. Executing Phase 1. Starting 1.1a (GLFW ⌘ probe).

Decisions locked (were BLOCKED, now resolved): macOS Primary = real ⌘ intercepted through the (permanent) GLFW layer · generator emits binding TABLES that splice into the curated SHORTCUTS.md shell (prose stays) · Phase 2 migrates KEYBOARD first, then mouse as a 2nd pass.

➡️ **Phases 0 + 1 COMPLETE** (8 commits): SHORTCUTS.md (curated + self-generating), CHEATSHEET retired, inventory/gap audit, MOD_PRIMARY + macOS ⌘, binding metadata, augment-generator + splice pipeline.

➡️ Phase 2A progress (13 commits): **tools + Flip H/V + Home/End/PgUp/PgDn migrated to central dispatch**, all rebindable-ready; context-bit infra landed; **conflict audit 0/227**; 3 new QA tests GREEN. The cleanly-testable/modelable keyboard migrations are now largely DONE. 2A.2b-rest is flagged: each remaining batch needs either a harder QA fixture (effects — applied-effect flow), an id-conflict fix (F12), or the infra gaps (ii CMD-ids for music / iii key-alias for Quit+Settings). NEXT actionable: build the effects applied-effect QA fixture, then migrate Ctrl+F/Alt+F/Shift+F. Autonomous + QA-gated + expanding coverage, on branch only.

loop:on

## Phase 0 — SHORTCUTS.md (first deliverable + registry-gap audit)

- [x] 0.1 Keyboard extraction DONE (agent) — full inventory: tools, chords (G/M/Z/E/F/W held), transforms, text-editing, custom-brush, shape-modifiers, panel modes; with actionIDs + file:lines + UNCERTAIN list.
- [x] 0.2 Mouse extraction DONE (agent) — full inventory: canvas per-tool, panels (layer/palette/toolbar/drawer/preview/charmap/status), wheel-over-region matrix, hold-key chords, special modes; SHORTCUT vs BEHAVIOR tagged.
- [x] 0.3 Registry extraction DONE (agent) — `INPUTS_register_all` = 213 bindings (141 key + 72 mouse); 137 dispatched=TRUE / 76 FALSE; actionId→label/hotkey map; **registry GAPS** enumerated (Effects/Image/Audio/Align/Symbol/etc. have no central binding).
- [x] 0.4 DONE — `PLANS/SHORTCUTS-INVENTORY.md`: coverage (213 registered, 137 TRUE / 76 FALSE), the ~150-action registry GAP (Effects/Image/Audio/Align/Symbol/custom-brush/mouse), parallel-id mismatches, menubar-only accelerators, and UNCERTAIN-confirm list. This scopes Phase 2.
- [x] 0.5 DONE — `SHORTCUTS.md` authored (full taxonomy, kbd+mouse, Primary-modifier convention, macOS note, CHEATSHEET tips merged) + reconciled against agent data (added universal Home/End/PgUp/PgDn transforms, Ctrl+F/Alt+F/Shift+F last-effect, Z+digit zoom, M+/− selection, text formatting, pixel-analyzer overlay; fixed scale keys, D30).
- [x] 0.6 DONE — `CHEATSHEET.md` replaced with a redirect stub → SHORTCUTS.md; CLAUDE.md key-files table updated. (In-app Help→Cheat Sheet opens the Command Palette, not the file — no code change needed.)
- [x] 0.7 DONE — anchors/links sane; committing Phase 0.

## Phase 1 — Registry completion + augment-generator + Primary/⌘

- [x] 1.1a DONE (agent, conclusive + probe-verified) — **the GLFW backend already exposes ⌘/Super through stock `_KEYDOWN`**: `100311`=Left ⌘, `100312`=Right ⌘ (traced through qb64pe `keyboard.cpp`/`cocoa_window.m`; compiled+ran a probe). No `DECLARE LIBRARY`, no upstream patch. Fallback (unneeded): `CGEventSourceKeyState`. The `glfwGetKey` route is a dead end from BASIC (window ptr private, GL context not current on the BASIC thread).
- [x] 1.1b DONE (build + QA verified) — `MOD_PRIMARY=8`, `KEY_LSUPER&/RSUPER&`, `MODIFIERS.cmd%/primary%` (Ctrl on Win/Linux; Ctrl-or-⌘ on macOS via `_KEYDOWN(100311/100312)`), fed into `MODS_NOW%`, `MODS_only%` masks it out. No regression (tool-switch 28/28, undo/redo 11/11). Binding reclassification deferred to 2A.
- [x] 1.2 DONE (build-verified, `DRAW 2.0.0` runs) — added `category%` + `userOverridden%` to `INPUT_BIND` + `CAT_*` constants + `INPUT_category_for%(actionId)` (id-range mapper) wired into `INPUT_register%` (mouse → CAT_MOUSE by device).
- [x] 1.3 DONE (build clean + conflict-audit clean) — registered the legacy-*triggered* CMD-backed keyboard bindings that were missing (Ctrl+F/Alt+F/Shift+F last-effect → 2350/2351/2352, Ctrl+Alt+O CRT → 950, Alt+O open → 206, Alt+X exit → 212) as `dispatched=FALSE` metadata. **Scope clarified vs the raw "~150":** truly-unbound menu actions (Effects/Image/Audio/Align/Symbol) have no trigger → they're "assignable but unassigned," listed by the rebind UI from the CMD table, NOT registered as fake bindings. Chords (Z+digit, G+arrow, M+=, Hold F/E/W) were ALREADY registered via `CTX_*_HELD`. Context-dependent keys (custom-brush/transform Home/End/PgUp/PgDn) + menubar-only non-CMD (Audio {/}/*) → Phase 2A.
- [x] 1.4 DONE (verified under xvfb — 219 bindings/13 categories) — `OUTPUT/SHORTCUTS-DUMP.BM` + `--dump-shortcuts` CLI (after INPUTS_init). Emits per-category markdown tables via binary file I/O (no PRINT / no _DEST; `_LOGINFO` status) → `SHORTCUTS.tables.md`. Per-OS Primary rendering + central/legacy status.
- [x] 1.5 DONE — added `<!-- BINDINGS -->` markers + a "Generated binding index" section to SHORTCUTS.md + `tools/gen-shortcuts.sh` (runs `--dump-shortcuts`, splices tables, leaves prose). Ran it: 219 rows spliced, curated prose intact. **Phase 1 COMPLETE.**

## Phase 2 — Migration to central dispatch (KEYBOARD FIRST, then mouse)

### 2A — Keyboard (ship first; makes keys rebindable)
- [x] 2A.1 DONE (build + QA GREEN, new test) — **Flip H (315)** + **Flip V (316)** migrated to central dispatch. Skip-list handles the no-mod 'h' double-fire; chordHeld preserves legacy suppression; Ctrl+Shift+H was a DEAD binding now revived. New `QA/tests/seam-flip-central.sh` (8/8) doubles as a double-fire guard; tool-switch 28/28, undo/redo 11/11.
  - [ ] ⚑ FLAGGED (not guessed) — **Quit (212, Ctrl+Q)** shares action 212 with a separate Alt+X legacy path; hard to QA (quits). **Settings (2100, Ctrl+,)** needs the cross-platform comma fallback (`_KEYDOWN(44)` OR `_KEYHIT 188`) which the plain central keycode won't replicate. Both need the dispatcher to support a key-alias / keyhit-alias before migrating. They still work via legacy — not blocking. Owes: revisit in a dispatcher-alias sub-task.
- [x] 2A.2a-iv DONE — `CTX_CUSTOM_BRUSH_ACTIVE` context bit (set in `INPUT_update_context`); unblocked the transform-key batch. Remaining infra as-needed: (i) modified-key legacy-removal (the unconditional-GOTO-skip pattern proved clean — reusable), (ii) CMD ids for menu-only Audio `{`/`}`/`*` (427/428/433 not in `CMD_execute_action`), (iii) key/keyhit-alias for Ctrl+`,` (comma 188 fallback) + multi-trigger Quit.
- [x] 2A.2b-transforms DONE (build + 3 tests GREEN) — **Home/End/PgUp/PgDn** migrated: two central bindings each (layer vs brush via `CTX_CUSTOM_BRUSH_ACTIVE`); legacy block disabled with a one-line `GOTO SkipTransformKeys`. New `seam-transform-brush-context.sh` (5/5) proves the brush-branch routing; `seam-flip-central` 8/8 + `transform-scale-2x` 7/7 cover the layer branch.
- [ ] 2A.2b-rest — remaining keyboard batches, each with its specific wrinkle (flag-don't-guess):
      - **effects** (Ctrl+F/Alt+F/Shift+F): modelable (modified keys, legacy removal via the proven GOTO-skip pattern) but a confirming test needs an *applied-effect* QA fixture (open Image menu → apply → Ctrl+F re-applies) — build the fixture, then migrate.
      - **custom-brush F12** (export): has the `9999`(dev-dump)-vs-`1110` parallel-id conflict from the inventory — resolve the id first.
      - **music `{`/`}`/`*`**: ⚑ infra-gated on (ii) — 427/428/433 aren't in `CMD_execute_action`.
      - **Quit / Settings**: ⚑ infra-gated on (iii) — Alt+X multi-trigger + comma-`_KEYHIT 188` fallback need a key/keyhit-alias.
      - **grid/symmetry extras** (908/910/911): no keyboard trigger — "assignable but unassigned", the rebind UI lists them; nothing to migrate.
- [x] 2A.3 (running audit) — dev-mode conflict audit **0 conflicts across 227 bindings** after the flip + transform-key migrations. Re-run after each future batch. Keyboard tools/flip/transform now rebindable-ready.

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
