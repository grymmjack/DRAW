---
name: draw-display-scale-system
description: How DRAW's unified UI_SCALE / display-scale / chrome-scale system fits together, and the two small-display bugs fixed in v2.3.2 (estimate-vs-ratio chrome mismatch forcing 1x; explicit scale reverting to 1x).
metadata:
  type: reference
---

DRAW collapsed the old separate display/toolbar/UI scales into **one master knob,
`CFG.UI_SCALE%`** (0 = auto-detect), for debuggability. Everything derives from it.

## The chain (OUTPUT/SCALE.BM + OUTPUT/SCREEN.BM)
- `SCALE_resolve_all`: master = `UI_SCALE` if >0, else legacy `DISPLAY_SCALE` override
  if >0, else `SCREEN_detect_display_scale%` (auto). So **`scaleIsExplicit% =
  (CFG.DISPLAY_SCALE% > 0) OR (CFG.UI_SCALE% > 0)`** exactly distinguishes explicit
  vs auto — reuse that flag, don't re-derive.
- `SCALE_resolve_widgets(master)`: each widget = `SCALE_resolve_one(override, master,
  ratio, 1, 4)`. **Chrome ratio is 0.5** (`SCALE_RATIO_TOOLBAR/ORGANIZER/DRAWER` all
  0.5), so the toolbar/chrome scale is ~half the display scale: **TB=1 at display 2,
  TB=2 at display 3-4.** `SCALE_RATIO_CANVAS = 1.0`, so UI_SCALE maps 1:1 to display
  scale.
- `DISPLAY_SCALE`/`TOOLBAR_SCALE` still exist as cfg keys but are **0=auto overrides**;
  the live values are `SCRN.displayScale%` and `CFG.TOOLBAR_SCALE%` (written by
  `SCALE_resolve_widgets`). Settings clears the overrides to 0 so the one knob wins.
- `SCREEN_preset_toolbar_scale%` is set but **never read** — dead; the preset table's
  TB hint does NOT drive the real chrome scale (the 0.5 ratio does).

## Bug 1 (v2.3.2): short desktops forced to 1x
The chrome-fit safety checks sized their min viewport from
`SCREEN_estimate_toolbar_scale%` (a viewport-size *guess* returning 2 for mid
viewports) instead of the chrome scale that actually renders (~0.5×display). The
guess over-reported chrome **height** by ~2× (`chrome_min_h(TB2)=416` vs real
`(TB1)=235`), so any desktop **shorter than ~900px** (1366×768, 1280×720, 1024×768,
1536×864 — the whole lower preset band) had auto-detected 2× knocked down to 1× =
tiny chrome, buried canvas. Fix: **`SCREEN_effective_chrome_scale%(ds)`** = the same
`SCALE_resolve_one(TOOLBAR_SCALE_OVR, ds, SCALE_RATIO_TOOLBAR, 1, 4)` the renderer
uses; call it at all four fit sites (detect algorithm, init safety loop ×2,
`SCREEN_set_display_scale`). `SCREEN_estimate_toolbar_scale%` was removed.

## Bug 2 (v2.3.2): explicit UI scale reverts to 1x on small screens
`SCREEN_set_display_scale` (called only for **explicit** actions — Settings apply,
scale hotkeys; auto uses a different path) clamped to the protective floor
(`chrome_min_w/h` with a comfortable 320px canvas) AND wrote the clamp back to
`CFG.UI_SCALE%`, so choosing 2× on a small screen silently reverted to 1×. Fix:
explicit requests use a **relaxed floor** — `SCREEN_fit_min_w&/h&(tb, relaxed)` with
`CHROME_MIN_CANVAS_RELAXED = 64` (SCREEN.BI): keeps the docked-chrome + toolbar-column
minimum and `WIN_MIN_*` (320×200) but drops the comfortable-canvas requirement. Auto
keeps the protective floor. The init safety loop passes `scaleIsExplicit%` so a saved
explicit scale **persists across relaunch**. Explicit scale is still bounded by
`DISPLAY_SCALE_MAX` (8) then throttled to the max that fits the desktop — e.g. 13→2 on
768px tall is correct (3× needs ~416px chrome height, only 230 available).

## Rule of thumb
Any fit/scale check must measure against the chrome scale that will **render**
(`SCREEN_effective_chrome_scale%`), never a viewport-size estimate — the estimate and
the 0.5 ratio disagree, and the estimate is wrong. Verified on 1366×768 (Win),
1168×755 (mac), 4K (Linux). See [[qb64pe-logic-operators]] (fit loops use `_ANDALSO`).
