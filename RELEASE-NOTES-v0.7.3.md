# DRAW v0.7.3 Release Notes

**Release Date:** February 8, 2026
**Previous Release:** v0.7.2 (February 7, 2026)

---

## Highlights

This release introduces a full suite of **19 Photoshop-style blend modes**, major rendering
performance optimizations, and several usability improvements across the layer system and
drawing tools.

---

## New Features

### 19 Layer Blend Modes

Every layer now supports a blend mode, selectable by **Shift+Right-clicking** the layer row
in the layer panel. Per-pixel compositing is performed using `_MEM` block access with integer
math for maximum performance.

| Mode | Abbr | Description |
|------|------|-------------|
| Normal | Nrm | Standard alpha compositing (default) |
| Multiply | Mul | Darkens by multiplying colors — great for shadows |
| Screen | Scr | Lightens by inverting, multiplying, inverting — great for glows |
| Overlay | Ovr | Combines Multiply and Screen based on base brightness |
| Add (Linear Dodge) | Add | Adds channel values, brightening the result |
| Subtract | Sub | Subtracts source from destination, darkening |
| Difference | Dif | Absolute difference between layers |
| Darken | Drk | Keeps the darker pixel from each layer |
| Lighten | Lgt | Keeps the lighter pixel from each layer |
| Color Dodge | CDg | Brightens base by dividing by inverted source |
| Color Burn | CBn | Darkens base by dividing inverted base by source |
| Hard Light | HdL | Like Overlay but based on source brightness |
| Soft Light | SfL | Gentle contrast adjustment (Pegtop formula) |
| Exclusion | Exc | Similar to Difference but lower contrast |
| Vivid Light | VvL | Combines Color Dodge and Color Burn at midpoint |
| Linear Light | LnL | Linear Dodge + Linear Burn combination |
| Pin Light | PnL | Replaces pixels based on brightness comparison |
| Color | Clr | Applies source hue/saturation with destination luminance |
| Luminosity | Lum | Applies source luminance with destination hue/saturation |

- Color and Luminosity modes use **Rec. 601 luminance** weights: `(R×77 + G×150 + B×29) / 256`
- All blend math uses LONG variables to prevent integer overflow
- Blend mode abbreviation is displayed on each layer row in the panel
- Blend mode is saved and loaded with `.drw` project files (format v2, backward compatible)

### Alt-Click Solo Layer

- **Alt+Left-click** the eye (visibility) icon on any layer to solo it
- All other layers are hidden; only the soloed layer remains visible
- Click again to unsolo and restore all previous visibility states

### Visibility Swipe

- **Click and drag** across multiple eye icons to rapidly show or hide layers
- The action (show or hide) is determined by the first icon clicked
- Efficiently toggle visibility for a range of layers in one gesture

### Spray Tool SHIFT Constraint

- Hold **SHIFT** while spraying to constrain spray center to horizontal or vertical axis
- Works with both left-click (foreground) and right-click (background) spraying
- Mirrors the constraint behavior already available for brush, line, rectangle, and ellipse tools

---

## Performance Optimizations

### Scene Cache System

- Rendered scene is cached and reused when no content has changed
- Only invalidated when layer content, visibility, opacity, or blend mode changes
- Crosshair overlay and cursor updates bypass the cache for responsiveness
- Dramatically reduces CPU usage when idle or panning/zooming without painting

### Partial Composite Cache

- When painting on a layer, all layers *below* the current layer are composited once and cached
- Subsequent frames only re-composite from the current layer upward
- Cache is automatically invalidated when layer order, visibility, opacity, or blend mode changes
- Provides significant speedup for multi-layer projects during active painting

### Render Order Lookup Table

- Pre-computed array maps bottom-to-top render order for visible layers
- Eliminates per-frame visibility checks during render loop
- Recalculated only when visibility or layer order changes

### Per-Layer Opacity Cache

- Each layer's opacity-adjusted image is cached and reused
- Cache key tracks the current opacity value; only regenerated on change
- Avoids redundant `_SETALPHA` operations every frame

### Additional Optimizations

- **Persistent composite buffer** — reused across frames instead of recreated
- **Pixel grid cache** — pre-rendered grid image cached per zoom level
- **Transparency checkerboard cache** — rendered once and reused
- **Frame idle detection** — reduces FPS limit when no input/changes detected (60→15 FPS)
- **GUI conditional redraw** — toolbar and status bar only re-rendered when flagged dirty
- **Blend composite skip** — fast path when all visible layers use Normal blend mode
- **Integer math** throughout blend and opacity calculations (no floating point)

---

## Bug Fixes

### SHIFT Crosshair Not Updating During Mouse Movement
- **Fixed:** Holding SHIFT while moving the mouse did not update the crosshair position
- **Root cause:** Mouse movement without button presses only set `FRAME_IDLE%` but not
  `SCENE_CHANGED%`, so the scene cache fast path served stale content
- **Fix:** SHIFT key held state now forces `SCENE_CHANGED%` and bypasses idle detection

### Mousewheel Zoom Lag
- **Fixed:** Zooming with mousewheel did not immediately update the display
- **Root cause:** Mousewheel zoom changed `SCRN.zoom!` but never set `GUI_NEEDS_REDRAW%`
  (keyboard zoom already did)
- **Fix:** Mousewheel zoom handler now sets `GUI_NEEDS_REDRAW%` and scroll wheel activity
  bypasses idle detection

### Double-Opacity on Non-Normal Blend Modes
- **Fixed:** Layers using non-Normal blend modes appeared overly transparent
- **Root cause:** Opacity was applied to the layer image *and* again during composite blending
- **Fix:** Composite path now uses the already-opacity-adjusted layer image without
  re-applying opacity

### Composite Buffer CLS Artifact
- **Fixed:** Stale pixels could appear in composite buffer between frames
- **Root cause:** `CLS` on the composite buffer was performed with `_BLEND` enabled,
  causing transparent black to alpha-blend over existing content instead of clearing it
- **Fix:** `_DONTBLEND` is set before `CLS` on the composite buffer

### INTEGER Overflow in Blend Math
- **Fixed:** Blend mode calculations could produce incorrect colors at high channel values
- **Root cause:** Multiplying two 255-range values (e.g., `255 × 255 = 65025`) overflows
  QB64PE's `INTEGER` type (max 32767)
- **Fix:** All blend intermediate variables use `LONG` type

---

## DRW Format Changes

- **Format version 2** — adds `blendMode` and `opacityLock` fields per layer
- **Backward compatible** — v1 files load correctly (default to Normal blend, no opacity lock)
- Blend mode, opacity, visibility, and lock state are all preserved in `.drw` project files

---

## Modified Files

| File | Changes |
|------|---------|
| `GUI/LAYERS.BI` | 19 blend mode constants, `BLEND_MODE_COUNT`, solo/swipe state fields, composite cache variables |
| `GUI/LAYERS.BM` | 19 blend formulas in `LAYER_blend_composite`, `BLEND_mode_name$`/`BLEND_mode_short$`, Alt-click solo, visibility swipe, cache invalidation |
| `OUTPUT/SCREEN.BM` | Scene cache fast path, partial composite cache (save/restore), render order loop, composite buffer CLS fix |
| `DRAW.BAS` | Idle detection for SHIFT/scroll wheel, composite cache cleanup on shutdown |
| `INPUT/MOUSE.BM` | Spray SHIFT constraint, mousewheel zoom `GUI_NEEDS_REDRAW%` |
| `TOOLS/DRW.BM` | DRW format v2 save/load (blend mode, opacity lock), opacity cache cleanup on load |

---

## Breaking Changes

None. All existing functionality, tools, and keyboard shortcuts are preserved. DRW v1 files
load without issue.

---

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

Requires QB64-PE v3.12 or later.
