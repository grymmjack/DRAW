# DRAW — post-merge bug/feature sweep

## 🔨 NOW — doing right now

- [ ] ➡️ **ANSI import Target radio** — Document / New Layer / Selection(zoom-pan-crop) + "will replace document" warning when no selection.

## Tasks

- [ ] ANSI region-select import — draw a rect in the preview to import just that part, char-grid-locked, show selection size in chars.
- [ ] Apron clip (HARD — reprioritized last) — text layer clips off-canvas-right. Needs apron-aware `TEXT_LAYER_render` (offset glyphs by apronW/apronH) + promote text layers to apron when text bounds exceed the canvas. Deep change to two fragile subsystems (text layers + apron gotcha #14); do carefully.

## Done

- [x] **Text transform → rasterize (destructive)** — Scale 2x/−50% (CASE 318/317) + `TRANSFORM_activate` call `TEXT_LAYER_rasterize` before transforming. Committed a91c282.
- [x] **Preview-window resize cursor** — resize cursor drew *behind* the preview window. `POINTER_build` now locks the cursor to the grabbed `resizeEdge%` while `PREVIEW.resizing%` (independent of hit-testing), and both `POINTER_draw` (skip in-scene) and `POINTER_render_cursor_overlay` (draw on top after `PREVIEW_render`) honor `PREVIEW.resizing%`.
