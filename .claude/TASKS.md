# CUSTOMIZABLE SHORTCUTS — build loop

Full plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Branch: `customizable-shortcuts` (off main).
Deliver in phase order; SHORTCUTS.md first. Each item: build clean + QA where applicable, then
commit. Mark genuinely-blocked items unchecked with a reason + who owes it, and reprioritize.

## 🔨 NOW — doing right now

➡️ Phase 0 kickoff — exhaustive shortcut extraction (keyboard + mouse + registry) to author SHORTCUTS.md.

## Phase 0 — SHORTCUTS.md (first deliverable + registry-gap audit)

- [ ] 0.1 Extract EVERY keyboard binding from `KEYBOARD.BM` + `DRAW.BAS` + `MODIFIERS.BM` → structured list (key, mods, context, action, category).
- [ ] 0.2 Extract EVERY mouse / wheel / drag / hover binding from `MOUSE.BM` + per-tool BMs + `STICK.BM` → structured list (event, region, button/dir, mods, context, action).
- [ ] 0.3 Extract the registered set from `INPUTS_register_all` (the 221) + action labels from `CMD_init` / `MENUBAR_init`.
- [ ] 0.4 Reconcile 0.1–0.3 + `CHEATSHEET.md` into a master inventory; flag which bindings are NOT in the registry (= the Phase 2 migration cost number). Write inventory to `PLANS/SHORTCUTS-INVENTORY.md`.
- [ ] 0.5 Author `SHORTCUTS.md` — full taxonomy, keyboard + mouse, logical Primary modifier rendered, CHEATSHEET tips merged in.
- [ ] 0.6 Retire `CHEATSHEET.md` → redirect stub pointing to SHORTCUTS.md; update references (`CLAUDE.md`, `README.MD`, instruction files).
- [ ] 0.7 Verify no broken doc references; commit Phase 0.

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
