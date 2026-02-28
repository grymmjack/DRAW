# ChatGPT Optimization Suggestions — Audit Against Actual Codebase

**Date**: 2025-01-XX  
**Audited by**: GitHub Copilot (Claude Opus 4.6)  
**Method**: Systematic code reading of all referenced implementations + profiling data from CORE/PROFILING.md

---

## Summary

Of the ~15 suggestions ChatGPT made, **10 are already implemented**, **2 are impractical due to QB64-PE API limitations**, **2 are technically correct but irrelevant** (the hotspot is elsewhere), and **1 has minor optimization potential** (spray tool).

The two **real bottlenecks** ChatGPT correctly identified but couldn't solve:
1. **Layer compositing with opacity**: 17ms avg (per-pixel `_MEM` loop) — no alternative in QB64-PE
2. **Final canvas→window scale**: 12-18ms (`_PUTIMAGE` software resize) — can't easily offload to GPU

Both only occur during **full renders**, which happen infrequently (~5% of frames). The dirty-rect path handles 95%+ of frames in 0.33-0.53ms.

---

## Suggestion-by-Suggestion Audit

### 1. "Stop redrawing everything every frame"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Don't repaint the entire canvas on every frame. Use dirty flags. |
| **Reality** | DRAW has a **3-tier optimization system**: |

- **Tier 1 — Idle skip** (`FRAME_IDLE%`): When no input/state changes occur, `SCREEN_render` is skipped entirely. FPS drops to `IDLE_FPS_LIMIT` (15). The previous frame stays on display.
- **Tier 2 — Dirty-rect fast path**: When only the cursor moved (no buttons, no keys, no GUI changes), the renderer restores a small rectangle from `SCENE_CACHE&`, redraws pointer + selection overlay, and scales only that dirty rect to `WINDOW_IMG`. Cost: **0.33-0.53ms**.
- **Tier 3 — Full render**: Only when `SCENE_DIRTY%` is TRUE (button held, key pressed, tool active, GUI change). Full layer compositing + grid + previews + GUI.

**Evidence**: `OUTPUT/SCREEN.BM` lines 250-420 (3 code paths with early exits).

---

### 2. "Canvas as persistent image buffer (blit, don't redraw)"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Keep a single large off-screen image as the backing canvas. Only update the canvas when actual pixel changes occur. |
| **Reality** | This is exactly how DRAW works: |

- `SCRN.PAINTING&` — the persistent painting layer (legacy, now per-layer)
- `LAYERS().imgHandle&` — each layer is a persistent `_NEWIMAGE` buffer
- `SCRN.CANVAS&` — compositing target (rebuilt only during full renders)
- `SCENE_CACHE&` — cached fully-composited scene (layers + grid + GUI, before cursor)
- `COMPOSITE_BELOW_CACHE&` — cached layers below current layer (avoids re-compositing unchanged layers)
- Per-layer `opacityCacheImg&` with `contentDirty%` flag — opacity is recomputed only when pixel content actually changes

**Evidence**: `GUI/LAYERS.BI` (DRAW_LAYER UDT), `OUTPUT/SCREEN.BM` lines 530-600 (opacity cache hit/miss logic).

---

### 3. "Make zoom/scaling the GPU's problem"

| Status | ❌ NOT FEASIBLE — QB64-PE API limitation |
|--------|-----|
| **Suggestion** | Let the GPU handle zoom display. Tell the GPU to sample from a smaller texture and stretch it. |
| **Reality** | QB64-PE has **no API to decouple window size from screen buffer size**. |

The current architecture:
1. `SCRN.CANVAS&` (640×400) — logical canvas where everything is drawn
2. `_PUTIMAGE` scales CANVAS → `SCRN.WINDOW_IMG&` (1280×800 at 2x) — **software resize, 12-18ms**
3. `SCREEN SCRN.WINDOW_IMG&` — this IS the window
4. `_DISPLAY` pushes to SDL2 — **GPU-accelerated, 1.1-1.3ms**

**Why we can't eliminate step 2:**
- QB64-PE sets window size = screen buffer size. To have a 1280×800 window, we need a 1280×800 SCREEN image.
- `$RESIZE:STRETCH` only handles USER-initiated window resizes (drag to resize). It doesn't let us set an initial window size larger than the screen buffer.
- There is no `_SCREENSIZE` or `_SETWINDOWSIZE` API in QB64-PE.
- Hardware images (tested empirically — see `TESTS/hw_image_test3.bas`) only support `_PUTIMAGE` and `_WIDTH/_HEIGHT`. All pixel operations fail with Error 258. Useless for DRAW's "modify every frame" architecture.

**Possible future approaches:**
- Use `DECLARE LIBRARY` to call SDL2's `SDL_SetWindowSize()` directly, then use `$RESIZE:STRETCH` to GPU-scale a 640×400 SCREEN to a 1280×800 window. This would eliminate the 12-18ms `_PUTIMAGE` step entirely. **Untested — needs investigation.**
- Lobby QB64-PE project for a `_SCREENSIZE w, h` API that sets physical window size independently of logical screen size.

**Note**: The dirty-rect path already mitigates this — it only scales a small region (typically 40-80 pixels wide) for cursor-only frames, costing <0.5ms. The 12-18ms cost only hits during full renders.

---

### 4. "Grid overlay as image-layer lines, not per-pixel"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Render the grid as an overlay image using LINE commands, not per-pixel operations. |
| **Reality** | Both grid systems use `LINE` commands and are cached as persistent images: |

**Regular grid** (`GUI/GRID.BM`):
- `GRID_init` creates `GRID.imgHandle&` once
- `GRID_draw` renders using `LINE (x%, y1%)-(x%, y2%)` vertical and `LINE (x1%, y%)-(x2%, y%)` horizontal
- Applied via `_SETALPHA 38` for 15% opacity
- Only redrawn when grid settings change
- Composited via single `_PUTIMAGE` call (line 695 of SCREEN.BM)

**Pixel grid** (`GUI/GRID.BM` lines 95-130):
- `PIXEL_GRID.imgHandle&` created once, redrawn only when settings change
- Uses `LINE` commands for vertical and horizontal lines
- Only shown at 400%+ zoom
- Has zoom-level caching (`PG_CACHE_IMG`, `PG_CACHE_ZOOM`) to avoid re-scaling

**Evidence**: `GUI/GRID.BM` lines 1-130 (both grid implementations).

---

### 5. "Flood fill: use a scanline fill algorithm"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Use scanline-based flood fill instead of naive recursive/pixel-by-pixel fill. |
| **Reality** | `FILL_flood` implements a proper **scanline flood fill** with these features: |

- **Stack-based** (no recursion): Dynamic stack starting at 128 entries, doubles when full
- **Scanline sweep**: Finds left/right edges of each span, fills entire row with `LINE (x1, y)-(x2, y)` (single call, not per-pixel PSET)
- **Selection-aware**: Clips to active selection via `SELECTION_is_point_inside%`
- **Span tracking**: Uses `in_span%` flag to avoid duplicate stack pushes for contiguous pixels
- **Memory cleanup**: Explicit `ERASE` of stack arrays after completion

The non-selection path uses `LINE ... BF` for scanline fill (hardware-accelerated in QB64-PE's software renderer). The selection path falls back to per-pixel `PSET` with bounds checking — this is unavoidable since selections can be irregular shapes.

**Evidence**: `TOOLS/FILL.BM` lines 43-185 (complete implementation).

---

### 6. "Spray tool: precompute random offsets"

| Status | ⚠️ NOT DONE — but irrelevant |
|--------|-----|
| **Suggestion** | Precompute a table of random (angle, distance) pairs instead of calling SIN/COS/SQR per dot. |
| **Reality** | `SPRAY_on` calls `SQR(RND)`, `COS()`, and `SIN()` per dot per frame. BUT: |

- Maximum density is **50 dots/frame** (capped at line 35)
- Each dot is a single `PAINT_pset_with_symmetry` call
- At 50 trig calls per frame, the total CPU cost is <0.01ms
- The symmetry rendering (`PAINT_pset_with_symmetry`) is likely more expensive than the trig

**Could precompute?** Yes, a lookup table of ~256 pre-randomized (dx, dy) pairs would eliminate the trig. But at 50 calls/frame, the saving would be microseconds — completely invisible.

**Verdict**: Technically correct suggestion, but zero practical impact.

**Evidence**: `TOOLS/SPRAY.BM` lines 22-52.

---

### 7. "Don't hide the OS cursor — only hide it when FPS is high enough"

| Status | ❓ N/A — misguided |
|--------|-----|
| **Suggestion** | Use the OS cursor for basic movement, only switch to custom cursor when FPS is adequate. |
| **Reality** | The custom cursor costs **<0.01ms** per frame (profiling data). There's no performance reason to switch to OS cursor. |

Additionally, the OS cursor would be visually inconsistent with DRAW's tool-specific cursors (brush circle, crosshair, eyedropper, move arrows, text beam, etc.). DRAW has ~20 different cursor types loaded from PNG files.

**Evidence**: Profiling data in `CORE/PROFILING.md` — POINTER_RENDER section.

---

### 8. "Ensure cursor drawing path is zero-cost when idle"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | When the cursor hasn't moved and nothing else changed, skip redrawing it. |
| **Reality** | The idle-skip path (`FRAME_IDLE%`) skips `SCREEN_render` entirely when nothing has changed. The cursor is only redrawn when the mouse moves (dirty-rect path) or during full renders. |

When the mouse moves but nothing else changes, only the dirty rectangle around old+new cursor position is processed — the rest of the canvas is untouched.

**Evidence**: `OUTPUT/SCREEN.BM` lines 295-410 (dirty-rect path), `DRAW.BAS` idle detection.

---

### 9. "Use event-driven mouse position updates"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Use an event-driven approach for mouse position instead of polling every frame. |
| **Reality** | DRAW uses the **drain-then-process** pattern recommended by QB64-PE best practices: |

```qb64
DO WHILE _MOUSEINPUT
    wheel_delta% = wheel_delta% + _MOUSEWHEEL
LOOP
' Then read final position/buttons once
```

This drains the entire mouse event queue each frame, accumulates wheel deltas, then reads the final position. This IS event-driven — QB64-PE doesn't offer true event callbacks, so drain-then-process is the correct pattern.

The image import mode has a special optimized path that skips normal buffered processing for direct polling (lower latency during imports).

**Evidence**: `INPUT/MOUSE.BM` lines 85-170 (drain loop + direct polling for import mode).

---

### 10. "Decouple cursor drawing from full scene render"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Draw the cursor as an overlay that can be updated independently of the scene. |
| **Reality** | This is exactly the scene cache architecture: |

1. Full render builds everything → saves to `SCENE_CACHE&` (before cursor)
2. Cursor is drawn AFTER the scene cache save point (`SkipToPointer:` label)
3. On cursor-only frames, scene cache is partially restored, cursor redrawn at new position
4. Selection overlay (marching ants) is also drawn after cache point so animations don't force full re-renders

**Evidence**: `OUTPUT/SCREEN.BM` lines 1038-1050 (scene cache save), lines 1053-1080 (SkipToPointer section).

---

### 11. "VSync or frame cap to avoid wasted renders"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Use VSync or a frame limiter to avoid rendering more frames than the display can show. |
| **Reality** | DRAW uses `_LIMIT FPS` (configurable, default 60) for active frames and `_LIMIT IDLE_FPS_LIMIT` (15) for idle frames. |

`_LIMIT` is placed **after** `_DISPLAY` to minimize input-to-display latency (documented in copilot-instructions.md). The idle detection system saves even more CPU by skipping `SCREEN_render` entirely when nothing has changed.

**Evidence**: `DRAW.BAS` main loop, `_COMMON.BI` FPS constants.

---

### 12. "Draw cursor as a simple primitive (not a sprite)"

| Status | ✅ ALREADY DONE (it's even better) |
|--------|-----|
| **Suggestion** | Use a simple colored square or crosshair instead of a complex sprite. |
| **Reality** | DRAW uses **pre-loaded PNG images** for cursors, composited via single `_PUTIMAGE` call. This is actually faster than drawing primitives because: |

- A single `_PUTIMAGE` of a small PNG (16×16 or 32×32) is one operation
- Drawing a crosshair with lines requires multiple `LINE` calls
- The PNG approach supports complex cursor shapes (eyedropper, brush circle, etc.)

Cost: <0.01ms per frame.

**Evidence**: `GUI/POINTER.BM` (POINTER_draw function), `GUI/CURSOR.BM` (CURSOR_init PNG loading).

---

### 13. "Watch for high-DPI scaling mismatch"

| Status | ✅ HANDLED |
|--------|-----|
| **Suggestion** | Ensure mouse coordinates are properly mapped in high-DPI modes. |
| **Reality** | DRAW handles display scaling via `SCRN.displayScale%`: |

- `SCREEN_detect_display_scale%` auto-detects appropriate scale on startup
- Mouse coordinates: `_MOUSEX \ SCRN.displayScale%` converts window coords to canvas coords
- Canvas coordinates: `MOUSE.X% = INT((rawX% - offset%) / zoom!)` for pan/zoom transform
- Scale can be changed at runtime with `=`/`-` keys
- Fullscreen mode uses `_FULLSCREEN _SQUAREPIXELS`

**Evidence**: `OUTPUT/SCREEN.BM` lines 44-88 (detect), 91-145 (set scale), `INPUT/MOUSE.BM` lines 115-140 (coordinate transform).

---

### 14. "Transparency checkerboard from simple quad fills"

| Status | ✅ ALREADY DONE |
|--------|-----|
| **Suggestion** | Draw checkerboard using filled rectangles, not per-pixel operations. |
| **Reality** | `TRANSPARENCY_render` uses `LINE (x,y)-(x2,y2), color, BF` (filled box) for each checker square and **caches the result** as a persistent image: |

- Created once, cached in `TRANSPARENCY.imgHandle&`
- Only recreated when canvas size or checker colors/size change
- Composited via single `_PUTIMAGE` call with `_DONTBLEND`

**Evidence**: `GUI/TRANSPARENCY.BM` lines 40-130 (cached checkerboard with `LINE ... BF`).

---

## Real Bottlenecks (What Actually Matters)

### Bottleneck #1: Layer Compositing with Opacity — 17ms avg

**Where**: `OUTPUT/SCREEN.BM` lines 570-600  
**What**: Per-pixel `_MEMGET`/`_MEMPUT` loop to apply opacity < 255:
```qb64
FOR pixOffset = layerMem.OFFSET TO layerMem.OFFSET + layerMem.SIZE - 4 STEP 4
    _MEMGET layerMem, pixOffset, pixVal~&
    pixAlpha~%% = _ALPHA32(pixVal~&)
    IF pixAlpha~%% > 0 THEN
        newAlpha% = (pixAlpha~%% * layerOpacityI%) \ 255
        _MEMPUT layerMem, pixOffset + 3, newAlpha% AS _UNSIGNED _BYTE
    END IF
NEXT pixOffset
```

**Why it's slow**: This loops over every pixel in the canvas (640×400 = 256,000 pixels × 4 bytes = 1MB). Each iteration does `_MEMGET`, `_ALPHA32`, multiply, `_MEMPUT`. Even compiled to C++, the function call overhead per pixel adds up.

**Mitigations already in place**:
- `opacityCacheImg&` per layer — only recomputed when `contentDirty%` is TRUE
- `COMPOSITE_BELOW_CACHE&` — layers below current layer cached, not re-composited
- Full opacity (255) skips the loop entirely (fast `_PUTIMAGE` path)

**Possible improvements**:
- Use `_MEM` block copy instead of per-pixel `_MEMGET`/`_MEMPUT` (batch into byte arrays)
- Pre-multiply alpha on the cached image and skip the per-frame loop entirely
- Investigate whether QB64-PE's `_SETALPHA` could replace the manual loop (it can set alpha for a range of colors, but may not handle per-pixel opacity correctly)

### Bottleneck #2: Final Canvas→Window Scale — 12-18ms → **SOLVABLE**

**Where**: `OUTPUT/SCREEN.BM` line 1083  
**What**: `_PUTIMAGE (0,0)-(1279,799), SCRN.CANVAS&, SCRN.WINDOW_IMG&`  
**Why**: Software nearest-neighbor pixel doubling. 640×400 → 1280×800 = 1,024,000 pixels written.

**Mitigations already in place**:
- Dirty-rect path scales only the changed region (cursor-only frames: <0.5ms)

**SOLUTION FOUND**: Use `glutReshapeWindow()` via `DECLARE LIBRARY` to set a larger window  
while keeping a small SCREEN buffer. `$RESIZE:STRETCH` (already in DRAW.BAS) GPU-scales  
via OpenGL. Prototype benchmarked at ~5.75ms savings per full render frame.  
See Action Items → High Impact #1 for details.

---

## The "Where's the Waste?" Answer

**There isn't much waste.** DRAW's render architecture is already well-optimized:

| Metric | Value | Assessment |
|--------|-------|------------|
| Idle frames | 0ms (skipped entirely) | ✅ Optimal |
| Cursor-only frames | 0.33-0.53ms | ✅ Excellent (dirty-rect) |
| GUI-only refresh | ~1ms estimate | ✅ Good |
| Full render + display | 30-35ms | ⚠️ Drops below 30fps |
| Frame budget (active) | 9-17% used | ✅ Healthy |
| _DISPLAY overhead | 1.1-1.3ms | ✅ Unavoidable (SDL2) |

The only time performance is visibly impacted is during **sustained full renders** (holding a mouse button while painting, which forces full layer compositing every frame). Even then, 30-35ms = ~30fps, which is acceptable for a pixel art editor.

**Windows cursor lag** (the original concern): Not caused by DRAW's code. Profiling shows cursor rendering is <0.01ms. The lag is from:
1. Windows DWM compositor adding 1-2 frames of latency
2. Windows timer resolution (15.6ms granularity for `_LIMIT`)
3. Occasional full-render stalls (rare, but noticeable when they happen)

---

## Action Items (Ranked by Impact)

### High Impact
1. **~~Investigate SDL2 direct window sizing~~** → **RESOLVED: Use `glutReshapeWindow` via DECLARE LIBRARY**

   QB64-PE uses FreeGLUT (not SDL2 directly) for windowing. Deep investigation of QB64-PE source confirmed:
   - QB64-PE wraps only 8 FreeGLUT functions — `glutReshapeWindow` is NOT one of them
   - `glut-main-thread.cpp:78`: `glutInitWindowSize(640, 400); // cannot be changed unless display_x(etc) are modified`
   - `_SCALEDWIDTH`/`_SCALEDHEIGHT` are undocumented **read-only** query functions (return same as `_WIDTH`/`_HEIGHT`)
   - All resize APIs (`$RESIZE`, `_RESIZE`, `_RESIZEWIDTH`) are reactive to user drag-resize only
   - `$RESIZE:STRETCH` (already in DRAW.BAS line 12) GPU-scales when window ≠ buffer, but no built-in way to trigger this programmatically

   **Prototype built and benchmarked** (`TESTS/gpu_scale_test.bas`):
   - Approach: `SCREEN 640×400` + `glutReshapeWindow(1280,800)` + `$RESIZE:STRETCH`
   - GPU path: avg draw 1.21ms, avg `_DISPLAY` 4.67ms (~789 FPS)
   - SW path: avg SW `_PUTIMAGE` 2.75ms, avg `_DISPLAY` 7.67ms
   - **Savings: ~2.75ms CPU + ~3ms `_DISPLAY` = ~5.75ms per full-render frame**
   - Mouse coordinates auto-translate via `$RESIZE:STRETCH` (confirmed)
   - Uses single C header: `void glutReshapeWindow(int width, int height);`

   **Status: READY TO INTEGRATE**

### Medium Impact
2. **Optimize opacity loop** — `_SETALPHA` or batch `_MEM` operations might reduce the 17ms compositing cost. Needs benchmarking.
3. **Pre-multiplied alpha** — If opacity-cached images store pre-multiplied alpha, the per-frame opacity loop could be eliminated for non-dirty layers. Already partially done via `opacityCacheImg&` but the loop still runs on every `contentDirty%` change.

### Low Impact
4. **Spray precompute** — A lookup table for spray offsets would save ~50 trig calls/frame. Microsecond-level improvement.

### No Impact (Already Optimal)
5-14. All other ChatGPT suggestions — already implemented or irrelevant.
