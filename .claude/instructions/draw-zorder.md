# DRAW z-order — one stack for render AND input

Derived from the input inventory (`.claude/input-inventory/03-*`, `04-*`). This is
the design the `Z1–Z4` refactor items follow. **The invariant we are enforcing:**

> Whatever is visually on top must also win the click. Render order == input
> hit-test order == one declarative z-stack. No exceptions, no hand-patches.

## The problem: three parallel sources of truth

Today "on top" is decided independently in three places that can (and do) disagree:

1. **Render order** — a hardcoded draw sequence in `SCREEN_render` (`OUTPUT/SCREEN.BM`).
   Docked panels, then the cursor (baked into `SCRN.CANVAS&`), then the canvas is
   upscaled to screen 0, then the floating windows blit *straight to screen 0* on
   top. Result: the cursor is under the floating windows.
2. **Region table** (`REGION_BOUNDS_TABLE` / `REGION_hit_test%`) — every panel is
   registered at the same `ZORDER_PANEL=100`, so overlap ties break on region
   *constant number*, not stacking; 4 of 7 z-tiers are unused; and the whole
   mouse/wheel/hover layer is `dispatched=FALSE`, so this table is **dormant** for
   pointer input.
3. **Legacy geometry** (`*_is_over_area%`, `PREVIEW_hit_window%` in `INPUT/MOUSE.BM`)
   — the map that *actually* owns every click, in handler order, with per-site
   hand-patched priority for the browser. A third source that drifts from the other
   two.

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

## The refactor, in dependency order

- **Z1 — cursor reblit (render).** The visible bug. `POINTER` has no equivalent of
  `TOOLTIP_reblit_to_screen0`. Add one: after the floating-window blits to screen 0
  (`SCREEN.BM:3600-3602` and the two other render paths), reblit the cursor overlay
  to screen 0 so it lands on top. Fix the false comment at `GUI/POINTER.BM:1601`.
- **Z2 — `ZORDER_FLOATING` tier (input).** Register Preview/Mixer/Browser at the new
  tier so the region table's answer matches render. (Latent today because pointer
  bindings are `dispatched=FALSE`, but correctness now, and it unlocks moving
  pointer dispatch onto the table later.)
- **Z3 — reconcile legacy hit-test order.** Make the `MOUSE.BM` floating-window
  checks test front-to-back (browser, mixer, preview) matching render, and delete
  the inconsistent per-site browser hand-patches. Overlap clicks hit the front
  window; no non-`ELSEIF` double-fire.
- **Z4 — register `REGION_CANVAS`.** Give the canvas real bounds at `ZORDER_CANVAS`
  so `> REGION_CANVAS` and `CTX_OVER_CANVAS` are correct, not idioms leaning on the
  canvas being unregistered.

Each is guarded by the harness `assert_cursor_on_top` + front-most-hit + no-double-fire
patterns (Group 4 tests), and the full suite must stay green.
