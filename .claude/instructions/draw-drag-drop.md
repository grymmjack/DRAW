# Drag-and-drop dispatch (`INPUT/DROP.BM`)

Target-aware OS file-drop handling. Full design + code anchors:
`PLANS/DRAG-DROP-PLAN.md`.

## Entry point
`_ACCEPTFILEDROP` armed at `DRAW.BAS:258`. The main loop reads `_DROPPEDFILE$(1)` +
`_FINISHDROP` and calls `DROP_handle_dropped_file(dropFile$)` (`DRAW.BAS:443` area). Only
file #1 is consumed — a multi-file OS drop discards the rest.

## The no-coordinates constraint
QB64-PE's file-drop exposes **only the file list — no drop x/y**. `DROP_handle_dropped_file`
reads `MOUSE.RAW_X%/RAW_Y%` at the drop frame (the cursor sits at the drop point) and
hit-tests with `REGION_hit_test%` (`INPUT/INPUT.BM:736`). `MOUSE.RAW_X/Y` and region bounds
are both in **logical (pre-display-scale) pixels**, so they compare directly. If a platform
ever reports a stale cursor position at drop time, target routing would be wrong — verify per
OS. Shift state comes from `MODIFIERS.shift%`.

## Routing (`DROP_handle_dropped_file` → `DROP_handle_image`)
1. `.drawlayer` → `LAYERXFER_deserialize%` (new layer). `.draw` → `DRW_load` (document).
   Both bypass targeting **except** a menu-bar drop of an openable file.
2. `REGION_MENUBAR` (not `.drawlayer`) → `INSTANCE_launch_new_with_file` opens it in a new
   isolated instance (auto-isolated even when `ALLOW_MULTIPLE_INSTANCES` is FALSE).
3. Image files → `DROP_handle_image`:
   - `REGION_DRAWER` → custom brush: hovered slot if empty else `DRAWER_first_free_slot%`;
     full bin → `DRAWER_new_page_with_brush` (auto-saves a dirty set to
     `USER/DRAWER-SETS/autosave-brush-NN.dset`, clears to a blank page, imports to slot 1).
   - `REGION_CANVAS`, fits → `DROP_place_on_current_layer` (destructive stamp, undoable via a
     `HISTORY_record_brush` full-layer before-snapshot).
   - `REGION_LAYER_PANEL`, fits → `DROP_place_on_new_layer` (suppress the empty auto layer-add,
     verbatim `_DONTBLEND` stamp, one `HISTORY_record_layer_add`).
   - larger-than-canvas, or any other region → interactive `IMAGE_IMPORT_load_file%`.

## Placement
Fits + no Shift → top-left `(0,0)`. Fits + Shift → centered on the canvas. Canvas coords are
mapped to the (possibly apron-promoted) layer buffer via `LAYERS_canvas_to_buf_x%/y%`
(gotcha #14). "Larger than canvas" = `imgW > SCRN.canvasW& OR imgH > SCRN.canvasH&`.

## Gotchas that bit / to respect
- Undo: destructive canvas stamp uses `HISTORY_record_brush` (it takes ownership of the
  before-snapshot); new-layer place mirrors `LAYERXFER_add_layer%` (record the layer-add
  AFTER content so redo restores pixels). Guard with `IF NOT HISTORY_saved_this_frame%`.
- The non-dialog `.dset` writer is `DRAWER_save_set_to_file` (extracted from
  `DRAWER_export_set_dialog`). Never clear a brush page without saving a dirty set first.
- Sound cues: `SND_DRAG_DROP` on canvas/brush drops, `SND_NEW_LAYER` on a new-layer place.
- QA: OS drops can't be synthesized headlessly — `QA/tests/drag-drop-targets.sh` is a smoke
  + source-route regression guard; real behavior is a manual per-OS fleet check.
