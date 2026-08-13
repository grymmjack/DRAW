# DRAW input QA — exhaustive seam tests + z-order refactor

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
- [ ] H1 · Add generic `hover x y` (move, no click) and split `mouse_down`/`mouse_up` verbs to `core/input.sh` (+ driver verbs if needed). Unit-verify in isolation. Commit qa-harness branch.
- [ ] H2 · Add `middle_click x y` (MMB = X button 2). Unit-verify. Commit.
- [ ] H3 · Add modifier-held-DURING-mouse: `with_mods "ctrl+shift" <click|drag|hover|wheel …>` (hold mods via keydown, run gesture, release) + convenience `ctrl_click`/`shift_click`/`alt_click`/`shift_drag`. Unit-verify a modifier is actually held across the gesture. Commit.
- [ ] H4 · Add modifier+wheel (`shift`+scroll etc.) via H3's wrapper or a `scroll_mod`. Unit-verify. Commit.
- [ ] H5 · Add generic z-order/hit-target assertion helpers + document the z-order/hit-target TESTING PATTERN in `ARCHITECTURE.md` (how to assert "front-most window wins the click" and "cursor renders above an overlay"). Commit.

## Group 2 — Unified z-order design (DRAW)
- [ ] Z0 · Write `.claude/instructions/draw-zorder.md`: the ONE declarative z-stack that drives BOTH render order and input hit-test order; a `ZORDER_FLOATING` tier above `ZORDER_PANEL`; where the cursor screen-0 reblit fits. Design only — the refactor plan the Z-items follow. (Root problem: 3 parallel sources of truth — render sequence, dormant region table, legacy geometry — see inventory.)

## Group 3 — Z-order fixes/refactor (DRAW) — each GREEN
- [ ] Z1 · Fix cursor-under-floating-window (Preview/Color Mixer/Browser). Add a cursor screen-0 reblit AFTER the floating-window blits in all 3 render paths of `SCREEN_render` (mirror `TOOLTIP_reblit_to_screen0`); fix the false comment at `GUI/POINTER.BM:1601`. Verify offscreen the cursor renders on top over the preview. Full build green.
- [ ] Z2 · Add `ZORDER_FLOATING` (> `ZORDER_PANEL`); register REGION_PREVIEW/COLOR_MIXER/IMAGE_BROWSER at it so `REGION_hit_test%` agrees with render (front-most wins). Verify a click on preview-over-layer-panel resolves to preview. Green.
- [ ] Z3 · Reconcile legacy floating-window hit-test order to front-to-back matching render; remove the inconsistent per-site browser hand-patches (`MOUSE.BM:4599/5135/5155/5176`). Verify overlap clicks hit the front window with NO double-fire (S2/S4). Green.
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
