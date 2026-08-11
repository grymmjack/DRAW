# DRAW — post-merge bug/feature sweep

## 🔨 NOW — doing right now

(idle — all items complete)

## Tasks

## Done

- [x] **Text transform → rasterize (destructive)** — Scale 2x/−50% (CASE 318/317) + `TRANSFORM_activate` call `TEXT_LAYER_rasterize` before transforming. Committed a91c282.
- [x] **Preview-window resize cursor** — resize cursor drew *behind* the preview window. `POINTER_build` now locks the cursor to the grabbed `resizeEdge%` while `PREVIEW.resizing%`, and both `POINTER_draw` and `POINTER_render_cursor_overlay` honor `PREVIEW.resizing%`. Committed fa92e8d.
- [x] **ANSI import Target radio** — Document / New Layer / Into Selection, with a "Replaces the entire document" warning on the destructive Document choice; Selection offered/defaulted only when a selection is active. Committed 3faf4e3.
- [x] **ANSI region-select import** — REGION toggle boxes a char-grid-locked cell rect in the preview (live outline + "N x M chars" readout), cropped via `ANS_crop_cells_to_region` before build; applies to all three targets. Committed 7208da4.
- [x] **Scrollbar lane click-to-jump** — Settings content scrollbar now jumps to a lane click (canvas + layer-panel already did; those and Settings are the only draggable-thumb scrollbars). Committed 0fcd6ed.
- [x] **Apron clip (text layer off-canvas)** — `TEXT_LAYER_render` is now apron-aware (apOffX/apOffY pen origin, all 4 call sites pass the layer apron); `TEXT_LAYER_ensure_apron` promotes when text bounds exceed the canvas (called from the render trigger); MOVE commit re-renders the text apron-aware at the new origin before the history snapshot. Committed 0acdc29.
