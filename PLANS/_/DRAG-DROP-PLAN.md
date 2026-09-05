# Improved Drag-and-Drop — Implementation Plan

Design + code anchors for the "IMPROVED DRAG AND DROP SUPPORT" feature
(`PLANS/IDEAS.md:3-8`). This doc is the source of truth for the `.claude/TASKS.md`
loop — read it before each box so the work survives compaction.

## Feature spec (verbatim from IDEAS.md)
- For ALL drop targets: if the image is **larger than the current canvas**, use the
  File → Import Image workflow (pan/zoom/crop). Otherwise just place it where dropped.
  Holding **Shift** while dropping → center of canvas; otherwise top-left.
- Drop onto **layer panel** → create new layer (new layer → image import for crop/pan/zoom).
- Drop onto **brush bin** (drawer) → add image as a custom brush; if no free slot, make a new blank page and populate.
- Drop onto **canvas** → drop into the current layer (destructive, undoable).
- Drop onto **menu bar** → open as a new image in a separate DRAW instance.

## Key constraint (discovered)
**QB64-PE OS file-drop exposes NO drop coordinates** — `_DROPPEDFILE$`/`_TOTALDROPPEDFILES`
give only the file list. The workaround: at the frame the drop fires, read
`MOUSE.RAW_X%/RAW_Y%` (the cursor sits at the drop point) and hit-test regions with it.
This is exactly what the internal browser drag already does
(`GUI/BROWSER.BM:895 BROWSER_execute_file_drop`, reads `MOUSE.RAW_X/Y`).
Risk to verify on each OS during testing: GLFW must have updated the cursor position to
the drop location by the time the drop event is polled. If a platform reports a stale
cursor pos, that target's dispatch will be wrong — note it, don't silently misroute.

## Current drop handler (all-OS, NOT $IF WIN guarded)
`DRAW.BAS:443-470`. Reads only `_DROPPEDFILE$(1)`, then:
- `.drawlayer` → `LAYERXFER_read_bytes$` + `LAYERXFER_deserialize%` (new layer). KEEP AS-IS.
- `.draw` → `DRW_load` (replace document). KEEP AS-IS.
- else (image) → `IMAGE_IMPORT_load_file%(path)` → interactive placement for ALL sizes.
`_ACCEPTFILEDROP` armed at `DRAW.BAS:258`.

## Dispatch mechanism
`REGION_hit_test%(mouseX%, mouseY%)` — `INPUT/INPUT.BM:736`. Returns the topmost ACTIVE
region id at a logical-pixel point (same space as `MOUSE.RAW_X/Y`; confirmed
`.claude/instructions/input-system.md:78`). Relevant region constants (`INPUT/INPUT.BI`):
- `REGION_CANVAS = 1` (whole viewport floor; registered `OUTPUT/SCREEN.BM:2749`)
- `REGION_MENUBAR = 3` (`GUI/MENUBAR.BM:982`)
- `REGION_LAYER_PANEL = 4` (`GUI/LAYERS.BM:2171`; inactive when panel hidden)
- `REGION_DRAWER = 9` = the brush bin (`GUI/DRAWER.BM:1729`)
- `REGION_PALETTE_STRIP = 5` (full-width palette; not a drop target here)

## Image-placement building blocks
- `IMAGE_IMPORT_load_file%(path$)` — `TOOLS/IMAGE-IMPORT.BM:67`. Loads + enters interactive
  placement (LOADED state). Takes a PATH (not a handle). Main loop drives the overlay.
- `IMAGE_IMPORT_apply` — `TOOLS/IMAGE-IMPORT.BM:603`. Commits placement onto a **new layer**
  (LAYERS_new%), pushes undo via `HISTORY_refresh_layer_add_snapshot` (`:711`).
- Browser "quick add to layer" model (fits → skip overlay): `GUI/BROWSER.BM:941-943`
  calls `IMAGE_IMPORT_load_file%` then immediately `IMAGE_IMPORT_apply`.
- Canvas image rect (for size compare / centered placement math):
  `OUTPUT/SCREEN.BM:3281-3282` — `dx=(SCRN.w-zw)\2+offsetX+panelShiftX`, `dy=(SCRN.h-zh)\2+offsetY`,
  `zw/zh = canvasDims * SCRN.zoom!`. Canvas pixel dims: `SCRN.canvasW&/canvasH&`.
- "Larger than canvas" = `imgW > SCRN.canvasW& OR imgH > SCRN.canvasH&`.

## Layer building blocks
- `LAYERS_new%` — creates a new layer (auto-records LAYER_ADD unless `HISTORY_IN_PROGRESS%`).
- Current layer image handle: `LAYER_current_image&` (used by IMAGE_IMPORT_apply `:693`).
- Destructive stamp onto current layer needs a full-layer undo snapshot. RESEARCH the right
  `HISTORY_record_*` in `TOOLS/HISTORY.BM` (model on how paste / fill snapshot a layer's
  content). Guard with `IF NOT HISTORY_saved_this_frame%` per gotcha #4.
- Apron offset (gotcha #14): a promoted layer's buffer is larger than the canvas; map canvas
  (cx,cy) → buffer (cx+apronW, cy+apronH). Use existing paint helpers rather than raw PSET.

## Brush-bin (drawer) building blocks
- 30 fixed slots: `DRAWER_BRUSH_SLOTS(1..30)` (`GUI/DRAWER.BI:126`), `DRAWER_SLOT_COUNT=30`.
- Add from file: `DRAWER_import_file_to_slot(filename$, slotIndex%, mode%)` — `GUI/DRAWER.BM:1399`
  (use mode `DRAWER_MODE_BRUSH`). Loads `_LOADIMAGE(...,32)`, stores IMG/W/H, activates.
- Empty-slot test: `DRAWER_BRUSH_SLOTS(i).IMG >= -1` is EMPTY (valid handle is `< -1`).
  There is NO "first free slot" helper — add one (`DRAWER_first_free_slot%`).
- Per-slot hit-test: `DRAWER_slot_at%(mx%,my%)` — `GUI/DRAWER.BM:1795` (returns 1..30 or 0).
- "Bin pages" = `.dset` files cycled by the wheel (`DRAWER_handle_wheel` `:3024`,
  `DRAWER_load_dset_file% :3423`, `DRAWER_scan_dset_files :3650`). No in-memory page stack,
  and NO auto-new-page logic exists — must be built. Sets live in `ASSETS/DSETS/BRUSHES/*.dset`.

## Menu-bar → new instance building blocks
- `INSTANCE_launch_new` — `CORE/INSTANCE.BM:262`. Currently launches a bare peer (no file arg).
  Add a variant that appends a quoted file path so the child opens it. Child already loads a
  command-line file on first frame (`DRAW.BAS:437 CMDLINE_PENDING_FILE$`). Windows path uses
  `SHELL _DONTWAIT _HIDE`; non-Win appends ` &`.
- Auto-isolation policy: a manually/programmatically launched extra copy is always isolated
  even when `ALLOW_MULTIPLE_INSTANCES` is FALSE — so a menu-bar drop may launch regardless of
  the pref (it is an explicit user action). Confirm this matches the multi-instance design.

## Unified drop model (target of the refactor)
At drop of an image file (`.draw`/`.drawlayer` keep current behavior):
1. Capture `rawX=MOUSE.RAW_X%`, `rawY=MOUSE.RAW_Y%`, `shift%` (Shift held).
2. `target% = REGION_hit_test%(rawX, rawY)`.
3. Branch:
   - `REGION_MENUBAR` → launch new isolated instance opening the file. (no size logic)
   - `REGION_DRAWER` → add as custom brush into free slot; full → new blank page. (no size logic)
   - `REGION_LAYER_PANEL` → larger-than-canvas ? interactive import : new-layer + place(top-left/center-shift).
   - `REGION_CANVAS` → larger-than-canvas ? interactive import : current-layer stamp(destructive, undoable, top-left/center-shift).
   - anything else / `REGION_GLOBAL` → fallback to current interactive import (safe default).
4. Placement when fits: Shift → centered on canvas; else top-left (0,0).

Refactor the inline `DRAW.BAS:443-470` block into `DROP_handle_dropped_file(path$)` in a new
`INPUT/DROP.BI/BM` (wire into `_ALL.BI`/`_ALL.BM` in the INPUT group). Keep DRAW.BAS thin.

## Testing note
GUI-level OS drops can't be simulated headlessly (no drop coords, OS-level event). Test what
is unit-testable: `DRAWER_first_free_slot%`, the size-compare + placement math, and a smoke
build. Manual GUI verification happens on the fleet (per-OS, watching the cursor-pos caveat).
