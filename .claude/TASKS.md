# CUSTOMIZABLE SHORTCUTS — build loop

Full plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Branch: `customizable-shortcuts` (off main).
Deliver in phase order; SHORTCUTS.md first. Each item: build clean + QA where applicable, then
commit. Mark genuinely-blocked items unchecked with a reason + who owes it, and reprioritize.

## 🔨 NOW — doing right now

➡️ Phase 0 COMPLETE + committed. **Paused at Phase 1 — 2 design decisions + 1 blocker surfaced for Rick** (see below). Grinding the ~150-action input migration (Phase 2) ahead of these would be risky/wasteful. Non-blocked groundwork can proceed once steered.

## ⛔ NEEDS RICK — decisions that gate Phase 1/2 (loop paused, not abandoned)

- [ ] ⛔ **BLOCKED · macOS `Primary`=Cmd is toolchain-blocked** ⟵ QB64-PE does not detect ⌘ on macOS (CHEATSHEET line 2146), so the "logical Primary renders as Cmd on macOS" decision can't be realized at runtime yet — only in the doc (already done). DECISION: (a) ship Primary as a doc-only convention now + reserve the runtime bit for when GLFW/QB64-PE exposes Cmd, or (b) invest in intercepting Cmd via the GLFW layer as part of this work. Owes: Rick.
- [ ] ⛔ **BLOCKED · generator: replace vs augment the curated doc** ⟵ `--dump-shortcuts` from the registry produces accurate but *sparse* tables; the hand-authored `SHORTCUTS.md` is rich (tips, per-tool mouse, workflows). DECISION: should the generated doc (1.5) REPLACE the curated one, or should the generator emit only the binding TABLES that get spliced into a curated shell (keeping the prose)? I recommend augment. Owes: Rick.
- [ ] ⛔ **BLOCKED · Phase 2 migration go-ahead** ⟵ the inventory shows ~150 actions (all Effects/Image/Audio/Align/Symbol/custom-brush + all mouse) are NOT centrally dispatched; making them rebindable means migrating legacy handlers in the hottest code (KEYBOARD.BM 3.8k / MOUSE.BM 6k lines). This is the real cost + regression risk. CONFIRM scope/appetite before I start (all at once vs. keyboard-first). Owes: Rick.

loop:off — Phase 0 (the priority) shipped; Phase 1+ gated on the 3 items above. Flip to `loop:on` after steering.

## Phase 0 — SHORTCUTS.md (first deliverable + registry-gap audit)

- [x] 0.1 Keyboard extraction DONE (agent) — full inventory: tools, chords (G/M/Z/E/F/W held), transforms, text-editing, custom-brush, shape-modifiers, panel modes; with actionIDs + file:lines + UNCERTAIN list.
- [x] 0.2 Mouse extraction DONE (agent) — full inventory: canvas per-tool, panels (layer/palette/toolbar/drawer/preview/charmap/status), wheel-over-region matrix, hold-key chords, special modes; SHORTCUT vs BEHAVIOR tagged.
- [x] 0.3 Registry extraction DONE (agent) — `INPUTS_register_all` = 213 bindings (141 key + 72 mouse); 137 dispatched=TRUE / 76 FALSE; actionId→label/hotkey map; **registry GAPS** enumerated (Effects/Image/Audio/Align/Symbol/etc. have no central binding).
- [x] 0.4 DONE — `PLANS/SHORTCUTS-INVENTORY.md`: coverage (213 registered, 137 TRUE / 76 FALSE), the ~150-action registry GAP (Effects/Image/Audio/Align/Symbol/custom-brush/mouse), parallel-id mismatches, menubar-only accelerators, and UNCERTAIN-confirm list. This scopes Phase 2.
- [x] 0.5 DONE — `SHORTCUTS.md` authored (full taxonomy, kbd+mouse, Primary-modifier convention, macOS note, CHEATSHEET tips merged) + reconciled against agent data (added universal Home/End/PgUp/PgDn transforms, Ctrl+F/Alt+F/Shift+F last-effect, Z+digit zoom, M+/− selection, text formatting, pixel-analyzer overlay; fixed scale keys, D30).
- [x] 0.6 DONE — `CHEATSHEET.md` replaced with a redirect stub → SHORTCUTS.md; CLAUDE.md key-files table updated. (In-app Help→Cheat Sheet opens the Command Palette, not the file — no code change needed.)
- [x] 0.7 DONE — anchors/links sane; committing Phase 0.

## Phase 1 — Registry completion + `--dump-shortcuts` generator

- [ ] 1.1 Add `MOD_PRIMARY` logical modifier (`INPUT.BI`) + a per-OS resolver (Ctrl on Win/Linux, Cmd on macOS) used by dispatch/doc/capture.
- [ ] 1.2 Extend binding metadata: add `category%` + `userOverridden%` to the binding type + `INPUT_register_*` (back-compatible).
- [ ] 1.3 Register every still-unregistered binding from the 0.4 inventory as metadata (`dispatched=FALSE` where legacy still owns it), with category + label.
- [ ] 1.4 Build `--dump-shortcuts [md|html]` generator that emits SHORTCUTS.md from the live registry (console-only, headless-safe).
- [ ] 1.5 Diff generated vs hand-authored SHORTCUTS.md; reconcile until identical; flip SHORTCUTS.md to generated. Build + commit.

## Phase 2 — Finish the migration (dispatched=FALSE → TRUE), batched + QA-gated

- [ ] 2.1 Migrate TOOLS bindings to central dispatch; build + QA (tool-switch matrix) + commit.
- [ ] 2.2 Migrate VIEW / zoom / pan / display-scale; build + QA + commit.
- [ ] 2.3 Migrate SELECTION / marquee; build + QA + commit.
- [ ] 2.4 Migrate LAYERS / groups; build + QA + commit.
- [ ] 2.5 Migrate COLOR / palette / palette-ops; build + QA + commit.
- [ ] 2.6 Migrate GRID / symmetry; build + QA + commit.
- [ ] 2.7 Migrate TEXT / charmap; build + QA + commit.
- [ ] 2.8 Migrate PANELS / docking + remaining mouse; build + QA + commit.
- [ ] 2.9 Developer-mode conflict audit clean (0 conflicts in `inputs.log`); commit.

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
