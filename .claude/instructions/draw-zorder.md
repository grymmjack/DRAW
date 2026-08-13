# DRAW z-order — one stack for render AND input

Derived from the input inventory (`.claude/input-inventory/03-*`, `04-*`).
**Status: IMPLEMENTED (Z1–Z4 landed on `qa-harness-input-improvements-1`).** This
is the model the code now follows. **The invariant we enforce:**

> Whatever is visually on top must also win the click. Render order == input
> hit-test order == one declarative z-stack. No exceptions, no hand-patches.

Guarded by `QA/tests/zorder-hit-targets.sh` (cursor-on-top of the floating
Preview, no click leak-through to the panel beneath, canvas floor doesn't shadow
tools) and `QA/tests/input-seam-regressions.sh`.

## The problem this fixed: three parallel sources of truth

"On top" used to be decided independently in three places that could (and did)
disagree. All three are now reconciled:

1. **Render order** — the draw sequence in `SCREEN_render` (`OUTPUT/SCREEN.BM`).
   The cursor was baked into `SCRN.CANVAS&` and the floating windows blit *over it*
   straight to screen 0 → the cursor rendered UNDER the floating windows.
   **Fixed (Z1):** the cursor overlay is drawn into its own `SCRN.CURSOR&` layer and
   composited to screen 0 by `POINTER_composite_cursor_to_screen0` *after* the
   floating windows, in all three render paths.
2. **Region table** (`REGION_BOUNDS_TABLE` / `REGION_hit_test%`) — every panel was
   registered at the same `ZORDER_PANEL=100`, so overlap ties broke on region
   *constant number*, not stacking. **Fixed (Z2/Z4):** floating windows now register
   at `ZORDER_FLOATING=200`, and the canvas is registered at `ZORDER_CANVAS=0`
   (`REGION_CANVAS`, the z-stack floor) every frame. (The pointer layer of this table
   is still `dispatched=FALSE`; correctness is in place for when it is switched on.)
3. **Legacy geometry** (`*_is_over_area%`, `PREVIEW_hit_window%` in `INPUT/MOUSE.BM`)
   — the map that actually owns every click, which had per-site hand-patched browser
   priority that had drifted apart. **Fixed (Z3):** unified into two predicates in
   `GUI/BROWSER.BM` — `BROWSER_owns_mouse%(x,y)` (front-most gate: visible AND
   drag/resize/file-drag/hit) and `BROWSER_active_hit%(x,y)` (purely spatial). All
   floating-window precedence now defers to `BROWSER_owns_mouse%`; the spatial
   canvas-pan/GUI-route sites use `BROWSER_active_hit%`.

## The z-stack (single source of truth)

One ordered set of tiers, low draws/tests first, high wins:

| Tier | value | members |
|------|-------|---------|
| `ZORDER_CANVAS`   | 0   | the canvas work area (register it — Z4) |
| `ZORDER_PANEL`    | 100 | docked chrome: toolbar, organizer, drawer, layer panel, palette strip, status bar, edit bar, adv bar |
| `ZORDER_FLOATING` | 200 | **floating windows: Preview, Color Mixer, Image Browser** (new tier — Z2) |
| `ZORDER_POPUP`    | 300 | popup menus, context menus, palette menu, command palette |
| `ZORDER_FLYOUT`   | 400 | subtool flyout (already highest) |
| `ZORDER_TOOLTIP`  | 500 | tooltip (render-only, never consumes input) |
| — cursor —        | top | the pointer overlay reblits ABOVE everything each frame |

Both consumers read this stack:
- **Render:** draw tiers low→high; the cursor reblits to screen 0 *after* the
  highest interactive tier (so it is never buried) — Z1.
- **Input:** `REGION_hit_test%` already picks highest zOrder; giving floating
  windows `ZORDER_FLOATING` makes it agree with render — Z2. The legacy geometry
  order is then reconciled front-to-back to match, and the hand-patches deleted — Z3.

## The refactor, as built (in dependency order)

- **Z1 — cursor overlay (render).** `SCRN.CURSOR&` is allocated alongside
  `SCRN.CANVAS&`/`SCRN.GUI&` and cleared each frame; `POINTER_render_cursor_overlay`
  draws the pointer into it; `POINTER_composite_cursor_to_screen0` blits it to
  screen 0 *after* `BROWSER_render` in all three render paths. Freed in
  `MAIN_shutdown`. The cursor now lands on top of the floating windows.
- **Z2 — `ZORDER_FLOATING=200` tier (input).** `CONST ZORDER_FLOATING` in
  `INPUT/INPUT.BI`; `PREVIEW.BM` / `COLOR-MIXER.BM` / `BROWSER.BM` register their
  `REGION_set_bounds` at it instead of `ZORDER_PANEL`. `REGION_hit_test%` (strictly
  greater zOrder wins, ties → lowest region index) now agrees with render.
- **Z3 — unified legacy hit-test.** `BROWSER_owns_mouse%` / `BROWSER_active_hit%` in
  `GUI/BROWSER.BM` replaced 4 drifted inline "browser owns" copies + 5 spatial
  copies in `MOUSE.BM`. Preview/Mixer both defer to the SAME `BROWSER_owns_mouse%`
  rule (incl. drag/resize/file-drag — a latent Preview fix). No double-grab.
- **Z4 — `REGION_CANVAS` floor.** `REGION_set_bounds REGION_CANVAS, 0, 0, SCRN.w&,
  SCRN.h&, ZORDER_CANVAS` right after `REGION_clear_all` in `SCREEN_render`. Chrome
  (higher zOrder) wins where it overlaps, so hit-test returns `REGION_CANVAS` over
  the drawing area and `>= 2` over chrome — making `> REGION_CANVAS` and
  `CTX_OVER_CANVAS` correct by construction (the latter was dead before).

All guarded by the harness `assert_cursor_on_top` + front-most-hit + no-leak-through
patterns; the full suite stays green.

### Offscreen QA notes (learned building the tests)

- DRAW draws a **software** brush-square cursor into `SCRN.CURSOR&` over the canvas
  AND floating windows — the offscreen capture backend (scrot) grabs it, so
  `assert_cursor_on_top` works there. Over **docked** chrome DRAW shows the OS arrow
  cursor, which scrot does NOT capture (and docked panels never occluded the software
  cursor — that was a floating-window bug). So cursor-on-top is asserted over the
  floating Preview only.
- The brush cursor sprite extends down-right from its hotspot; a too-tight sample box
  centred on the hotspot reads a false "identical". `assert_cursor_on_top` defaults to
  a 32px box + a settle so a throttled idle app renders the cursor frame first.
- Tooltips are disabled in the QA config (qa-harness DRAW adapter override) so a
  tooltip popping up near the pointer doesn't pollute hover-based region diffs.
