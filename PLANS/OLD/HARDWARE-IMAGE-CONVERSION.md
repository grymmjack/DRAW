# Hardware Image Conversion Plan for DRAW

## Executive Summary

Convert DRAW's rendering pipeline to use QB64PE hardware images (`_COPYIMAGE mode 33`)
where possible, leveraging GPU-accelerated texture scaling and compositing via OpenGL.
This is a **hybrid approach** — pixel editing surfaces must remain software, but the
display pipeline and read-only assets can be moved to GPU.

---

## QB64PE Hardware Image Capabilities & Constraints

### What hardware images CAN do
- GPU-accelerated `_PUTIMAGE` (texture scaling, nearest-neighbor or smooth)
- GPU-accelerated alpha blending (standard alpha only)
- `_MAPTRIANGLE` for 3D/rotated rendering
- Created via `_COPYIMAGE(handle&, 33)` or `_LOADIMAGE(file$, 33)`
- `_DISPLAYORDER` controls render layer ordering: `_SOFTWARE, _HARDWARE, _GLRENDER, _HARDWARE1`
- Unlimited count (limited by GPU VRAM, not CPU)
- Near-zero CPU cost for display

### What hardware images CANNOT do
- Cannot be used as `_DEST` (no drawing to them)
- Cannot be used as `_SOURCE` for `POINT()` reads
- Cannot use `PSET`, `LINE`, `CIRCLE`, `PAINT` on them
- Cannot use `_MEMIMAGE` / `_MEM` for pixel access
- Cannot use `_SETALPHA` on them
- No custom blend modes (multiply, overlay, etc.) — only standard alpha
- Cannot `_COPYIMAGE` *from* a hardware image back to software

### Key API
```qb64
' Create hardware image from software image
hw& = _COPYIMAGE(softwareImage&, 33)

' Load file directly as hardware image
hw& = _LOADIMAGE("file.png", 33)

' Display hardware image (scaled) — destination MUST be 0 (screen)
_PUTIMAGE (0, 0)-(winW% - 1, winH% - 1), hw&, 0

' Control render layer ordering
_DISPLAYORDER _SOFTWARE, _HARDWARE

' Free hardware image
_FREEIMAGE hw&
```

---

## Current Image Inventory

### Images That MUST Stay Software (require pixel access / drawing)

| Image | Location | Why Software Required |
|-------|----------|----------------------|
| `LAYERS(i%).imgHandle&` (×64) | LAYERS.BI | PSET, POINT, LINE, CIRCLE, _MEM — all drawing tools |
| `LAYERS(i%).opacityCacheImg&` (×64) | LAYERS.BI | `_MEMIMAGE` per-pixel opacity adjustment |
| `SCRN.CANVAS&` | SCREEN.BI | Main compositing target — `_DEST`, LINE, PSET, CIRCLE |
| `SCRN.GUI&` | SCREEN.BI | `_DEST` — toolbar/status/palette rendering |
| `SCRN.PAINTING&` | SCREEN.BI | Legacy painting surface — `_DEST`, `_SOURCE` |
| `COMPOSITE_BUFFER&` | LAYERS.BI | `_DEST`, `_MEM` — blend mode compositing |
| `COMPOSITE_BELOW_CACHE&` | LAYERS.BI | `_DEST`, `_PUTIMAGE` copy target |
| `SCENE_CACHE&` | SCREEN.BI | `_DEST` — scene cache save/restore |
| `GRID.imgHandle&` | GRID.BI | `_DEST` — LINE drawing for grid |
| `PIXEL_GRID.imgHandle&` | GRID.BI | `_DEST` — LINE drawing for pixel grid |
| `PG_CACHE_IMG&` | SCREEN.BI | `_DEST` — LINE, `_SETALPHA` |
| `SYMMETRY.imgHandle&` | GUI/SYMMETRY | `_DEST` — LINE drawing for guides |
| `TRANSPARENCY.imgHandle&` | TRANSPARENCY.BI | `_DEST` — LINE drawing for checker |
| `MOVE.SELECTION_IMAGE` | MOVE.BI | `_DEST`, `_PUTIMAGE` — pixel manipulation |
| `MOVE.PREVIEW_BUFFER` | MOVE.BI | `_DEST`, `_PUTIMAGE` — transform preview |
| `CLIPBOARD.IMAGE` | SELECTION.BI | `_DEST`, `_PUTIMAGE` — clipboard pixels |
| `CUSTOM_BRUSH.IMAGE&` | CUSTOM-BRUSH.BI | `_DEST`, POINT — brush pixel data |
| `MARQUEE.SELECTION_MASK` | MARQUEE.BI | `_DEST`, PSET, POINT — mask pixel data |

### Images That CAN Become Hardware (read-only after creation)

| Image | Location | Current Usage | Conversion Benefit |
|-------|----------|--------------|-------------------|
| `SCRN.WINDOW_IMG&` | SCREEN.BI | Final display (SCREEN target) — only written to by `_PUTIMAGE` scaling | **HIGH** — GPU scaling is the #1 win |
| Cursor PNGs (×20+) | CURSOR.BI | `_LOADIMAGE` then `_PUTIMAGE` only | **MEDIUM** — small images, many of them |
| Layer panel icons (×9) | LAYERS.BI | `_LOADIMAGE` then `_PUTIMAGE` only | **LOW** — tiny images, infrequent render |
| `TRANSPARENCY.imgHandle&` | TRANSPARENCY.BI | Created once per size, displayed via `_PUTIMAGE` | **MEDIUM** — could convert after creation |

---

## Conversion Strategy: 3 Phases

### Phase 1: Hardware Display Pipeline (Highest Impact)

**Goal**: Eliminate the CPU-side integer scaling step (`CANVAS → WINDOW_IMG`) and use
GPU scaling instead. This is the single biggest performance win.

**Current flow**:
```
SCRN.CANVAS& (320×200, software) 
  → _PUTIMAGE scaled → SCRN.WINDOW_IMG& (640×400, software, SCREEN target)
  → _DISPLAY
```

**New flow**:
```
SCRN.CANVAS& (320×200, software — all compositing stays here)
  → _COPYIMAGE(SCRN.CANVAS&, 33) → hw_frame& (320×200, hardware texture)
  → _PUTIMAGE scaled → destination 0 (screen, hardware layer)
  → _DISPLAY
  → _FREEIMAGE hw_frame& (or reuse)
```

**Changes required**:

1. **SCREEN.BI**: 
   - Add `HW_FRAME AS LONG` to `SCREEN_OBJ` for persistent hardware frame handle
   - Keep `SCRN.WINDOW_IMG&` as the `SCREEN` target (defines window size) but stop drawing to it via CPU `_PUTIMAGE`

2. **SCREEN_init** (SCREEN.BM):
   - After creating `SCRN.WINDOW_IMG&` and calling `SCREEN SCRN.WINDOW_IMG&`, add:
     ```qb64
     _DISPLAYORDER _HARDWARE, _SOFTWARE
     ```
   - This makes hardware images render on top of (or instead of) software

3. **SCREEN_render** (SCREEN.BM) — **End of function**:
   - Replace the final scaling block:
     ```qb64
     ' OLD: CPU scaling
     _DEST SCRN.WINDOW_IMG&
     _DONTBLEND SCRN.WINDOW_IMG&
     _PUTIMAGE (0,0)-(_WIDTH(SCRN.WINDOW_IMG&)-1, _HEIGHT(SCRN.WINDOW_IMG&)-1), SCRN.CANVAS&, SCRN.WINDOW_IMG&
     ```
   - With GPU scaling:
     ```qb64
     ' NEW: GPU scaling
     IF SCRN.HW_FRAME& < -1 THEN _FREEIMAGE SCRN.HW_FRAME&
     SCRN.HW_FRAME& = _COPYIMAGE(SCRN.CANVAS&, 33)
     _PUTIMAGE (0, 0)-(_WIDTH(SCRN.WINDOW_IMG&) - 1, _HEIGHT(SCRN.WINDOW_IMG&) - 1), SCRN.HW_FRAME&, 0
     ```

4. **Dirty-rect fast path** (SCREEN.BM):
   - The dirty-rect partial scaling also needs conversion. Currently it does:
     ```qb64
     _PUTIMAGE (dr_x1%*sc%, dr_y1%*sc%)-(...), SCRN.CANVAS&, SCRN.WINDOW_IMG&, (dr_x1%, dr_y1%)-(dr_x2%, dr_y2%)
     ```
   - For hardware mode, the entire canvas must be re-uploaded since hardware images are
     immutable textures. The dirty-rect optimization applies differently:
     - **Option A**: Always upload full canvas to hardware (simple, works for small canvases).
       The GPU scaling is so fast that partial updates aren't needed.
     - **Option B**: Keep dirty-rect for software WINDOW_IMG as fallback when canvas is large.
   - For pixel art (typically ≤512×512), Option A is recommended. The `_COPYIMAGE(, 33)`
     upload of a 320×200×4 = 256KB image is negligible.

5. **SCREEN_set_display_scale** (SCREEN.BM):
   - Update to account for hardware rendering mode
   - Still need WINDOW_IMG for window sizing via SCREEN statement

**Performance impact**: 
- Eliminates CPU-side `_PUTIMAGE` scaling (the largest single-operation cost per frame)
- GPU handles nearest-neighbor upscaling essentially for free
- Estimated CPU reduction: 10-30% depending on display scale

**Risk**: Low. Software compositing pipeline stays identical. Only the final display
step changes. Easy to toggle between HW and SW with a config flag.

---

### Phase 2: Hardware Static Assets (Medium Impact)

**Goal**: Load cursor PNGs and icons directly as hardware images to eliminate per-frame
software `_PUTIMAGE` for overlay elements.

**Current flow** (cursors):
```
_LOADIMAGE("cursor.png", 32) → software handle
Per frame: _PUTIMAGE (x,y), cursor_handle&, SCRN.CANVAS&  (software → software)
```

**Problem with direct hardware**: Cursors are currently `_PUTIMAGE`'d onto `SCRN.CANVAS&`
(a software image). You **cannot** `_PUTIMAGE` from a hardware source to a software
destination. So cursors can't simply become hardware images under the current pipeline.

**Solution — Two-layer rendering**:
1. Keep `SCRN.CANVAS&` as software for all compositing including the cursor
2. **OR** render cursors in the hardware layer, on top of the software canvas

**Approach**: After Phase 1 establishes hardware display, render cursors as a separate
hardware `_PUTIMAGE` call to destination 0, positioned and scaled appropriately:
```qb64
' After uploading canvas to hardware and scaling:
_PUTIMAGE (0,0)-(winW%-1, winH%-1), hw_canvas&, 0    ' Scaled canvas
_PUTIMAGE (cursorScreenX%, cursorScreenY%), hw_cursor&, 0  ' Hardware cursor on top
```

**Changes required**:

1. **CURSOR.BI/BM** — `CURSOR_load_all`:
   - Load cursor PNGs with `_LOADIMAGE(file$, 33)` for hardware
   - Keep software copies too (needed for cursor-on-canvas in certain modes)
   - Add `HW_` prefixed fields to cursor handle arrays

2. **POINTER.BM** — `POINTER_render`:
   - In hardware mode: skip drawing cursor onto `SCRN.CANVAS&`
   - Instead: store cursor position and let SCREEN_render draw hardware cursor

3. **Layer panel icons** — `LAYER_PANEL_load_icons`:
   - These render onto `SCRN.GUI&` (software), so they must ALSO remain software
   - Hardware conversion only useful if GUI becomes a separate hardware layer

**Complexity**: Medium. Requires splitting cursor rendering into SW and HW paths.
The cursor must appear at the correct position accounting for display scale.

**Performance impact**: Small. Cursor is a tiny image.

---

### Phase 3: Hardware Overlay Layers (Lower Impact, Higher Complexity)

**Goal**: Render static/cached overlays (checkerboard, grid, GUI) as separate hardware
layers instead of compositing them in software.

**Concept**: Use `_DISPLAYORDER _HARDWARE` and multiple hardware `_PUTIMAGE` calls to
build the final frame from independent layers, all GPU-composited:

```
Hardware layer stack (back to front):
1. hw_checkerboard&  — transparency checkerboard (static until zoom/pan)
2. hw_canvas_content& — composited layers (updated when layers change)
3. hw_grid&          — grid overlay (static until zoom changes)
4. hw_gui&           — toolbar/status/palette (static until GUI changes)
5. hw_cursor&        — mouse cursor (moves every frame, tiny upload)
```

Each layer is only re-uploaded to hardware when its content changes. The GPU handles
alpha compositing and scaling of all layers simultaneously.

**Changes required**:

1. **SCREEN_render** complete rewrite:
   - Split into independent layer rendering functions
   - Each function returns a software image → convert to hardware
   - Upload only changed layers
   - All `_PUTIMAGE` calls go to destination 0 with hardware sources
   - Remove WINDOW_IMG entirely

2. **Cache invalidation tracking**:
   - Track which hardware layers need re-upload (already partially done with
     `SCENE_DIRTY%`, `GUI_NEEDS_REDRAW%`, etc.)

3. **_DISPLAYORDER**:
   - `_DISPLAYORDER _HARDWARE` (don't render software layer at all)

**Complexity**: HIGH. Major rewrite of the rendering pipeline. The scene cache, dirty-rect,
and GUI-only refresh optimizations would all need redesign.

**Performance impact**: Potentially large for big canvases or high zoom levels. For typical
pixel art sizes (≤512×512), the improvement over Phase 1 alone is marginal.

**Recommendation**: Defer Phase 3 until Phase 1 is proven stable and profiled.

---

## Implementation Order & Milestones

### Phase 1 Implementation Steps (Recommended Start)

```
Step 1.1: Add HW_FRAME& to SCREEN_OBJ type in SCREEN.BI
Step 1.2: Add _DISPLAYORDER to SCREEN_init
Step 1.3: Add CFG.USE_HARDWARE_DISPLAY% config flag (default TRUE)
Step 1.4: Replace final scaling block in SCREEN_render with HW path
Step 1.5: Update dirty-rect fast path to use full-canvas HW upload
Step 1.6: Update GUI-only refresh path 
Step 1.7: Update SCREEN_set_display_scale for HW mode
Step 1.8: Handle _FREEIMAGE of HW_FRAME on resize/cleanup
Step 1.9: Test with SW fallback toggle (for debugging)
Step 1.10: Profile before/after CPU usage
```

### Files Modified (Phase 1 only)

| File | Changes |
|------|---------|
| `OUTPUT/SCREEN.BI` | Add `HW_FRAME` field to `SCREEN_OBJ` |
| `OUTPUT/SCREEN.BM` | `SCREEN_init`: add `_DISPLAYORDER`; `SCREEN_render`: replace final scaling |
| `CFG/CONFIG.BI` | Add `USE_HARDWARE_DISPLAY` to config type |
| `CFG/CONFIG.BM` | Load/save hardware display config |

### Rollback Strategy

Throughout Phase 1, all changes are gated behind `CFG.USE_HARDWARE_DISPLAY%`:
```qb64
IF CFG.USE_HARDWARE_DISPLAY% THEN
    ' Hardware path
    IF SCRN.HW_FRAME& < -1 THEN _FREEIMAGE SCRN.HW_FRAME&
    SCRN.HW_FRAME& = _COPYIMAGE(SCRN.CANVAS&, 33)
    _PUTIMAGE (0,0)-(winW%-1, winH%-1), SCRN.HW_FRAME&, 0
ELSE
    ' Software fallback (current code)
    _DEST SCRN.WINDOW_IMG&
    _DONTBLEND SCRN.WINDOW_IMG&
    _PUTIMAGE (0,0)-(winW%-1, winH%-1), SCRN.CANVAS&, SCRN.WINDOW_IMG&
END IF
_DISPLAY
```

---

## Potential Issues & Mitigations

### 1. `_COPYIMAGE(, 33)` cost per frame
- **Risk**: Uploading canvas texture to GPU every frame
- **Mitigation**: Canvas is small (typically 64×64 to 512×512 = 16KB to 1MB). GPU uploads
  of this size are sub-millisecond. Profile to confirm.
- **Alternative**: Only re-upload when `SCENE_DIRTY%` or cursor moved. Reuse previous
  hardware handle when frame is truly idle.

### 2. Display scale / window sizing
- **Risk**: `SCREEN SCRN.WINDOW_IMG&` sets the window size. Hardware images render into
  this window's OpenGL context. Must ensure coordinates align.
- **Mitigation**: Keep WINDOW_IMG for window sizing. Just stop CPU-scaling to it. The
  hardware `_PUTIMAGE` to destination 0 will fill the window correctly.

### 3. Nearest-neighbor vs smooth scaling
- **Risk**: GPU may default to bilinear filtering, making pixel art blurry
- **Mitigation**: QB64PE's `_PUTIMAGE` with hardware images uses the image's smooth setting. 
  Don't use `_SMOOTH` on the hardware image. Test to confirm nearest-neighbor is default.
- **Alternative**: If GPU forces bilinear, fall back to software scaling. Or use 
  `_MAPTRIANGLE` with explicit texture coordinates.

### 4. `_DISPLAY` behavior with hardware
- **Risk**: `_DISPLAY` renders both software and hardware layers. If software layer shows
  stale content, it may flash/flicker.
- **Mitigation**: Use `_DISPLAYORDER _HARDWARE` to suppress software layer rendering.
  Or clear software screen to transparent. Test thoroughly.

### 5. Platform compatibility
- **Risk**: Hardware images use OpenGL. Old/embedded GPUs may not support it.
- **Mitigation**: `CFG.USE_HARDWARE_DISPLAY%` flag allows SW fallback. Detect failure
  and auto-fallback if `_COPYIMAGE(, 33)` returns invalid handle.

### 6. Fullscreen mode
- **Risk**: `_FULLSCREEN _SQUAREPIXELS` may interact differently with hardware rendering.
- **Mitigation**: Test fullscreen specifically. May need to adjust `_PUTIMAGE` coordinates.

---

## What This Does NOT Change

- **All drawing operations** stay software (PSET, LINE, CIRCLE, PAINT, POINT)
- **Layer compositing** stays software (_MEM-based blend modes)
- **Undo/redo** stays software (layer image snapshots)
- **File I/O** stays software (save/load pixel data)
- **Selection masks** stay software (POINT-based flood fill)
- **Custom brushes** stay software
- **Opacity cache** stays software (_MEM per-pixel alpha)
- The core editing experience is unchanged — only the final display step changes

---

## Success Metrics

1. **CPU usage reduction**: Measure via `top`/`htop` before/after
2. **Frame time stability**: No dropped frames or stuttering
3. **Visual correctness**: Pixel-perfect match between SW and HW rendering
4. **No regressions**: All tools, overlays, cursors render correctly
5. **Smooth scaling test**: Confirm nearest-neighbor (no blur) at all scales 1-8×

---

## Decision: Start with Phase 1

Phase 1 is recommended because:
- Smallest scope of changes (~4 files, ~50 lines)
- Highest performance-per-effort ratio
- Easy rollback via config flag
- No changes to editing/tool code
- Foundation for Phases 2-3 if desired

Phases 2 and 3 should only be pursued after Phase 1 is stable and profiled.
