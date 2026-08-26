# CUSTOMIZABLE SHORTCUTS — build loop

Full plan: `PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Branch: `customizable-shortcuts` (off main).
Deliver in phase order; SHORTCUTS.md first. Each item: build clean + QA where applicable, then
commit. Mark genuinely-blocked items unchecked with a reason + who owes it, and reprioritize.

## 🔨 NOW — doing right now

➡️ Phase 0 done + committed. Rick steered (2026): **macOS ⌘ via GLFW interception**, **augment generator (tables spliced into curated prose)**, **keyboard-first migration**. Executing Phase 1. Starting 1.1a (GLFW ⌘ probe).

Decisions locked (were BLOCKED, now resolved): macOS Primary = real ⌘ intercepted through the (permanent) GLFW layer · generator emits binding TABLES that splice into the curated SHORTCUTS.md shell (prose stays) · Phase 2 migrates KEYBOARD first, then mouse as a 2nd pass.

➡️ **Phases 0 + 1 COMPLETE** (8 commits): SHORTCUTS.md (curated + self-generating), CHEATSHEET retired, inventory/gap audit, MOD_PRIMARY + macOS ⌘, binding metadata, augment-generator + splice pipeline.

➡️ Phase 2A keyboard: **5 subsystems migrated to central dispatch + tested** — tools, Flip H/V, transforms (layer-vs-brush), effects, Quit. 17 commits; conflict audit 0/227; **5 new QA tests** GREEN. The cleanly-migratable-AND-Linux-verifiable keyboard work is COMPREHENSIVELY DONE.

➡️ **CORE FEATURE WORKS (25 commits): keyboard rebinding engine + preset system, both tested.** Users can remap the 5 migrated keyboard subsystems via `DRAW.bindings` and switch keymaps via `--load-preset`. Delivered: doc + foundation, 5 keyboard migrations, Phase 2B reframe, Phase 3 engine, Phase 5 preset system.

⏸️ Genuine boundary — everything AUTONOMOUSLY-verifiable is done. The remainder each needs RICK-in-the-loop:
  - **Phase 4 — rebind UI dialog**: a big *visual* GUI (find-filter list, capture modals, conflict badges) — needs your eyes on screenshots.
  - **Preset keymap content** (aseprite/photoshop/gimp/dpaint): slots+format shipped; accurate maps need conflict-tradeoff decisions (foreign keys vs DRAW chords) — your call.
  - **2B.2 mouse override wiring**: hot-path `MOUSE.BM` changes; testable now but risky — best with visual confirmation.
  - **Flagged keyboard** (Settings/Music/F12): needs a **Windows** machine to verify.
The engine + presets + doc are all shippable. loop:off — these last pieces genuinely want you. loop:on to push any of them anyway.

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
  - [x] **Quit (212, Ctrl+Q)** DONE (2A.2b) — was a DEAD binding (no legacy handler); revived via central dispatch. `seam-quit-central.sh` 6/6 (unsaved-dialog observable). Alt+X stays separate.
  - [ ] ⚑ STILL GATED — **Settings (2100, Ctrl+,)** genuinely needs the keyhit-alias: legacy comment confirms `_KEYDOWN(44)` works on Linux/macOS while Ctrl held, but **Windows suppresses it** and delivers comma only via `_KEYHIT ±188`. Migrating with plain keycode-44 would regress Windows. Needs a keyhit-alias (iii) + Windows verification. Works via legacy today.
- [x] 2A.2a-iv DONE — `CTX_CUSTOM_BRUSH_ACTIVE` context bit (set in `INPUT_update_context`); unblocked the transform-key batch. Remaining infra as-needed: (i) modified-key legacy-removal (the unconditional-GOTO-skip pattern proved clean — reusable), (ii) CMD ids for menu-only Audio `{`/`}`/`*` (427/428/433 not in `CMD_execute_action`), (iii) key/keyhit-alias for Ctrl+`,` (comma 188 fallback) + multi-trigger Quit.
- [x] 2A.2b-transforms DONE (build + 3 tests GREEN) — **Home/End/PgUp/PgDn** migrated: two central bindings each (layer vs brush via `CTX_CUSTOM_BRUSH_ACTIVE`); legacy block disabled with a one-line `GOTO SkipTransformKeys`. New `seam-transform-brush-context.sh` (5/5) proves the brush-branch routing; `seam-flip-central` 8/8 + `transform-scale-2x` 7/7 cover the layer branch.
- [x] 2A.2b-effects DONE (build + FIRE-log + test GREEN) — **Ctrl+F/Ctrl+Alt+F/Ctrl+Shift+F** (Redo/Recall/Blend last effect) migrated; legacy `_KEYDOWN` block removed. New `seam-effects-central.sh` (5/5) applies Glow then Ctrl+F re-applies it; `--developer` FIRE log confirms `action=2350`. (Learned: Image adjustments like Invert aren't tracked as "last effect" — only Effects-menu effects are.)
- [ ] ⚑ 2A.2b-rest — the cleanly-migratable keyboard subsystems are DONE (tools, flip, transforms, effects — 4 batches, all tested, audit 0/227). Each REMAINING batch is genuinely gated (flag-don't-guess), so they need the infra sub-project below, not more of the same:
      - **custom-brush F12** (export): the legacy handler uses keycode **34304** while the registry dev-dump uses **28416** (the F12 keycode-variant landmine from the inventory's UNCERTAIN list) AND the `9999`-vs-`1110` id conflict. Needs the keycode-variant resolved first — do NOT guess.
      - **music `{`/`}`/`*`**: infra-gated on (ii) — 427/428/433 aren't in `CMD_execute_action`.
      - **Quit / Settings**: infra-gated on (iii) — Alt+X multi-trigger + comma `_KEYHIT 188` fallback need a key/keyhit-alias.
      - **grid/symmetry extras** (908/910/911): no keyboard trigger — "assignable but unassigned"; the rebind UI lists them; nothing to migrate.
      → NEXT real step is the infra sub-project (2A.2a-ii CMD-ids + 2A.2a-iii key/keyhit-alias + F12 keycode-variant helper), each a dedicated unit with a test. Substantial; not "more flips."
- [x] 2A.3 (running audit) — dev-mode conflict audit **0 conflicts across 227 bindings** after the flip + transform-key migrations. Re-run after each future batch. Keyboard tools/flip/transform now rebindable-ready.

### 2B — Mouse (second pass, after keyboard ships)
- [x] 2B.0 Kickoff DONE — scouted the mouse pipeline; **reframed the phase** (design in `PLANS/CUSTOMIZABLE-SHORTCUTS.md`): mouse ops are positional and mostly NOT discrete CMD actions, so do NOT route all 72 rows / the 6k-line pipeline through central dispatch. Migrate only the ~15-20 rebindable "input-preference" behaviors by having MOUSE.BM honor registry overrides; tool strokes + panel affordances stay put. Fixed the BACKWARDS canvas-wheel metadata (plain=zoom, Ctrl=brush-size) + an inherited CHEATSHEET doc error. Build clean; doc regenerated.
- [x] 2B.1 DONE (enumerated) — the rebindable-mouse set is: button FG/BG paint, wheel zoom-vs-brush-size, Alt+click pick FG/BG, Ctrl+click symmetry center, pan trigger (MMB/Space+drag), wheel-over-region. **Key finding:** most DON'T map to a dispatchable CMD action (symmetry-center 1003 and reset-pan 802 have NO CASE in `CMD_execute_action`; Alt+click-pick is a tool-mode, not an action). So mouse rebinding CANNOT reuse the keyboard "fire a CMD action" model — MOUSE.BM must become **registry-driven** (ask the registry "which button/modifier triggers FG-paint / pan / pick?" instead of hardcoding LMB/MMB).
- [ ] ⚑ 2B.2 — ORDERING CONSTRAINT discovered: wiring MOUSE.BM to honor overrides is only *testable* once a user can actually rebind, i.e. after the **Phase 3 override engine**. A rebound mouse button can't be exercised without persistence + apply-over-defaults. So Phase 3 (engine) should come BEFORE 2B.2's per-behavior wiring. Re-sequence: Phase 3 engine (on the already-migrated keyboard bindings) → then 2B.2 mouse behaviors → then 4/5 UI+presets.
- [ ] 2B.2 Mouse/wheel conflict audit clean; commit.

## Phase 3 — Customization engine

- [x] 3.1 DONE — `CFG/BINDINGS.BI/BM`: `DRAW.bindings` override-only persistence in the config dir; `BINDINGS_load` parses `actionId keycode requireMods forbidMods` rows.
- [x] 3.2 DONE (validated) — `BINDINGS_apply` re-points the first dispatched keyboard binding of each action + rebuilds the skip-list; wired into `INPUTS_init` before the perf-table build. `tools/test-rebind-engine.sh`: rebind Flip H `h`→`j` → registry shows J (default H); both PASS.
- [x] 3.3 DONE — `BINDINGS_find_conflict%` (same keycode + same mods + overlapping requireCtx/forbidCtx → conflicting actionId). Ready for the Phase 4 UI.
- [x] 3.4 DONE — `BINDINGS_set_override` (add/replace + save + live re-apply) + `BINDINGS_reset_all` (clears + deletes file). NOTE: reset fully takes effect on next launch (live registry keeps applied keycodes until re-register) — fine for v1; the UI can force a re-register later.

## Phase 4 — Customization UI

- [ ] 4.1 `GUI/CONTROLS.BI/BM` scaffold + `ACTION_CUSTOMIZE_CONTROLS` + Edit → "Customize Controls…" + `CMD` wiring + `_ALL` includes.
- [ ] 4.2 Binding list: find-filter, category dividers, current assignments (HOLD/PRESS/CLICK/WHEEL), scroll.
- [ ] 4.3 Capture sub-modals (key / mouse / wheel), Primary-aware, CLEAR/CANCEL.
- [ ] 4.4 Inline conflict badges + block-OK-on-conflict; SAVE/LOAD/RESET/PRINT toolbar. Build + QA + commit.

## Phase 5 — Presets + import/export

- [x] 5.1 DONE (tested) — `BINDINGS_load_preset` + `--load-preset <name>` CLI; `ASSETS/PRESETS/draw-default` (reset) shipped. `test-rebind-engine.sh` covers preset load (Flip H → J via preset). Format = same as DRAW.bindings.
- [ ] 5.2–5.5 ⚑ preset CONTENT (aseprite/photoshop/gimp/deluxepaint) — **slots + format shipped as documented starters**; the accurate keymaps need conflict-judgment (foreign keys collide with DRAW chords, e.g. G) best decided WITH Rick. Not a blocker; the system works, slots are ready to fill.
- [ ] 5.6 Import/export `.bindings` via file dialog + CLI — the CLI half is effectively `--load-preset`; a Save/Load-file path + dialog remains (small, pairs with Phase 4 UI).
- [ ] 5.7 Preset picker — part of the Phase 4 Controls dialog (GUI).

## Phase 6 — Wrap

- [ ] 6.1 Regenerate SHORTCUTS.md from the final registry; reconcile.
- [ ] 6.2 Update `CLAUDE.md` / `README.MD` / instruction files for the new input system + customization.
- [ ] 6.3 Full QA regression; run summary in `PLANS/CUSTOMIZABLE-SHORTCUTS.md`; rendered Shortcuts artifact; final commit.

loop:on
