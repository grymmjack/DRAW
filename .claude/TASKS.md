# DRAW input QA — exhaustive seam tests + z-order refactor

## 🔨 NOW
- ➡️ D1 · update input docs from the inventory + z-order model (DRAW)

## Deliverable — zero compiler warnings (Rick, 2026-08-13)
- [x] W0 · Clean build (`make clean && make`) emits **0 warnings**. Fixed the 2 "Unused variable" warnings at root (KIT-ZIP.BM `ZIP_begin` dead param; KIT-IO.BM `KIT_install_textstyles` dead `fh` local). Commit pushed. **ONGOING GUARD: keep every build at 0 warnings — treat any new warning as a defect.**


Branch: `qa-harness-input-improvements-1` (DRAW **and** qa-harness). Derived from the
code inventory in `.claude/input-inventory/` (01-mouse, 02-keyboard,
03-regions-zorder-dispatch, 04-render-zorder-seams). Read those before each item.

**Rules (every item):** verify OFFSCREEN with the Xvfb harness (no WM — openbox grabs
Alt+click; read window geom via `xdotool getwindowgeometry --shell`; capture `_LOGINFO`
via `QB64PE_LOG_*`). Build `make` foreground, 600000ms, `dangerouslyDisableSandbox`.
Remove all temp diagnostics before committing. **Nothing is done until it is GREEN.**
Separation of concerns: generic capabilities/lessons → **qa-harness**; DRAW-specific
inventory/tests/fixes → **DRAW**. Commit + push each item.

## Group 1 — Harness input primitives (qa-harness repo)
- [x] H1 · `hover x y` + `mouse_down`/`mouse_up` added to `core/input.sh`; syntax OK, verbs resolve. Commit 462359e, pushed.
- [x] H2 · `middle_click` added (commit 0afb554).
- [x] H3 · `with_mods` + `driver_input_key_hold` + conveniences (ctrl/shift/alt click & drag). Order unit-tested. Commit fa794b8.
- [x] H4 · modifier+wheel conveniences (shift/ctrl scroll_up/down). Commit da8f991, pushed.
- [x] H5 · `assert_cursor_on_top` helper + z-order/hit-target testing patterns in ARCHITECTURE.md. Commit edc3572, pushed. **Group 1 complete.**

## Group 2 — Unified z-order design (DRAW)
- [x] Z0 · `.claude/instructions/draw-zorder.md` written — the z-stack tiers + Z1–Z4 plan. Commit.

## Group 3 — Z-order fixes/refactor (DRAW) — each GREEN
- [x] Z1 · Restored SCRN.CURSOR& top overlay; composited after floating windows in all 3 paths. Cursor-on-preview verified (212px), batch 35/0. Commit 87f65b5, pushed.
- [x] Z2 · ZORDER_FLOATING=200 tier; Preview/Mixer/Browser moved to it. Hover Preview → REGION_PREVIEW verified. Commit 82fc3e7, pushed.
- [x] Z3 · Unified floating-window precedence into `BROWSER_owns_mouse%` (front-most gate) + `BROWSER_active_hit%` (spatial) in BROWSER.BM; replaced 4 drifted inline copies at MOUSE.BM 4599/5135/5155/5176 + 5 spatial sites (643/1155/1383/1406/3958). Fixes Preview/Mixer double-grab while Browser drags. Build green; regression 33/0. Commit 9010e73.
- [x] Z4 · Registered `REGION_CANVAS` as z-stack FLOOR (full screen @ ZORDER_CANVAS) every frame after REGION_clear_all. Fixes dead CTX_OVER_CANVAS + makes `> REGION_CANVAS` correct by construction, not by the canvas being unregistered. Updated stale comments. Build green; regression 31/0 (picker+loupe over canvas still sample layer). Commit fd092b6. **Group 3 (Z1–Z4) complete.**

## Group 4 — Exhaustive input tests (DRAW `QA/tests/`) — each GREEN
- [x] T1 · `QA/tests/zorder-hit-targets.sh` — 3 invariants, 9 passed/0 failed: A[Z1] cursor renders on top of floating Preview (the reported bug); B[Z2/Z3] click on Preview doesn't leak to toolbar beneath (front-most wins, no double-fire); C[Z4] canvas floor doesn't shadow tools. Also hardened `assert_cursor_on_top` in qa-harness (box size + idle settle). DRAW 6e1ae2e, qa-harness pushed. NOTE: OS arrow over docked chrome isn't capturable offscreen (not a z-order bug); cursor-on-top asserted over the floating Preview only.
- [x] T2 · `QA/tests/mouse-button-matrix.sh` — 11 passed/0 failed: A LMB(FG paint), B RMB(BG paint, distinct color), C wheel↑/↓(brush size), D MMB drag(pan, made deterministic by zooming in first — was flaky at the pan clamp boundary). Documents QB64 button mapping (X11 btn3→DRAW right, btn2→DRAW middle). Also added `TOOLTIPS_DISABLED=TRUE` to the qa-harness DRAW adapter overrides (cleaner hover diffs). Commit pushed.
- [x] T3 · `QA/tests/modifier-mouse.sh` — 9 passed/0 failed (deterministic x3): A Ctrl+click sets symmetry center / no paint (+ plain-drag control); B Alt+click invokes eyedrop loupe not brush (color-pick path unit-verified via PICKER_pick_color diagnostic — fires with correct sampled color; deterministic offscreen color diff fights the opaque-black layer, so assert the no-paint interception signature); C Shift+wheel vertical pan (zoomed-in so unclamped). Uses H3/H4 helpers. Commit pushed.
- [x] T4 · `QA/tests/keyboard-singles.sh` — 20 passed/0 failed: tool-key sweep b→d→l→r→c→m→v→i→f (each moves toolbar highlight ~800-1100px), brush round-trip (0 diff), Esc clean. Keyboard is deterministic — passed first try.
- [x] T5 · `QA/tests/keyboard-chords.sh` — 11 passed/0 failed (deterministic x3): Ctrl+Z undo, Ctrl+Y redo, Ctrl+Shift+Z redo-alt (all 0-diff round-trips of a stroke), Ctrl+A+Esc non-destructive. Covers Ctrl and Ctrl+Shift modifier tiers on the #1 bug area (HISTORY). Held-key chords (G/M/Z/E/W) already covered by existing chord-*.sh. Commit pushed.
- [x] T6 · `QA/tests/input-seam-regressions.sh` — 10 passed/0 failed (deterministic x3): A F11 multi-keycode Toggle-All-UI hides chrome (86k px) + exact round-trip; B Ctrl+D double-mapping resolves to 307 Deselect not 518 Default Colors (marquee raised by Ctrl+A is removed by Ctrl+D at the canvas corner); C backtick 412 toggles brush cursor overlay. **Group 4 complete (T1–T6 all green).**

## Group 5 — Docs (DRAW)
- [ ] D1 · Update input docs from the inventory + new z-order model: `.claude/instructions/draw-mouse.md`, `input-system.md`, `draw-rendering.md`, and `docs/` as needed; refresh `CHEATSHEET.md` if any binding changed (e.g. Ctrl+D). Commit.

## Group 6 — Green gate
- [ ] G1 · Run the FULL DRAW suite offscreen (existing ~100 + all new). Everything GREEN. Record pass/fail counts in the report artifact. Final commit + push both repos.
