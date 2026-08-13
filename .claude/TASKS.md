# DRAW input QA — exhaustive seam tests + z-order refactor

## 🔨 NOW
- ➡️ Z4 · register REGION_CANVAS + fix `> REGION_CANVAS` idiom / CTX_OVER_CANVAS (DRAW)


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
- [ ] Z4 · Register `REGION_CANVAS` (canvas work-area bounds) so canvas is a real region; make `> REGION_CANVAS` idiom + `CTX_OVER_CANVAS` correct. Verify Alt-eyedrop/loupe over-canvas still behave (must not regress). Green.

## Group 4 — Exhaustive input tests (DRAW `QA/tests/`) — each GREEN
- [ ] T1 · z-order/hit-target suite: cursor-on-top + front-most-hit for Preview/Mixer/Browser; overlap no-double-fire; canvas↔chrome boundary. Uses H5 helpers.
- [ ] T2 · Mouse per-region matrix: LMB/RMB/MMB/wheel±/hover over each docked panel + canvas (toolbar, organizer, drawer, layer panel, palette strip, status bar, edit bar, adv bar).
- [ ] T3 · Modifier+mouse gestures: Ctrl+click (symmetry center), Alt+click eyedrop (canvas AND chrome), Shift+drag, Shift+wheel (pan), Ctrl+Shift+click (dock toggle). Uses H3/H4.
- [ ] T4 · Keyboard singles: every tool key, arrows, space, grave, esc, enter, backspace, delete — correct action + context.
- [ ] T5 · Keyboard chords + ALL modifier combos: Ctrl+/Shift+/Alt+ and the 4 multi-mod tiers; held-key chords (G/M/Z/E/F/W/Space) both key orders.
- [ ] T6 · Seam regressions from the inventory: Ctrl+D mapping (307 vs 518), F11/F12 multi-keycode, backtick quad-purpose, wheel double-consume, legacy-before-modern double-fire, chord-order sensitivity.

## Group 5 — Docs (DRAW)
- [ ] D1 · Update input docs from the inventory + new z-order model: `.claude/instructions/draw-mouse.md`, `input-system.md`, `draw-rendering.md`, and `docs/` as needed; refresh `CHEATSHEET.md` if any binding changed (e.g. Ctrl+D). Commit.

## Group 6 — Green gate
- [ ] G1 · Run the FULL DRAW suite offscreen (existing ~100 + all new). Everything GREEN. Record pass/fail counts in the report artifact. Final commit + push both repos.
