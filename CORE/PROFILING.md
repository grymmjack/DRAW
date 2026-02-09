# DRAW Render Pipeline Profiling

## Quick Start

1. Build DRAW normally: `qb64pe -w -x -o DRAW.run DRAW.BAS`
2. Run with logging enabled:
   ```bash
   QB64PE_LOG_HANDLERS=file \
   QB64PE_LOG_LEVEL=1 \
   QB64PE_LOG_FILE_PATH=./perf.log \
   ./DRAW.run
   ```
3. Use the app for a bit (move mouse, click, draw, make selections)
4. Exit and read the log:
   ```bash
   grep "PERF" perf.log
   ```

Reports are emitted every **120 frames** (~2 seconds at 60fps).

To log to both console and file:
```bash
QB64PE_LOG_HANDLERS=console,file \
QB64PE_LOG_SCOPES=runtime,qb64 \
QB64PE_LOG_LEVEL=1 \
QB64PE_LOG_FILE_PATH=./perf.log \
./DRAW.run
```

---

## How It Works

The profiling system lives in two files:

- **`CORE/PERF.BI`** — Constants for section IDs, `DIM SHARED` accumulators, section name strings
- **`CORE/PERF.BM`** — `PERF_start`, `PERF_stop`, `PERF_frame_end` implementations

Each measured section is bracketed by `PERF_start SECTION_ID` / `PERF_stop SECTION_ID` calls which use `TIMER(0.001)` for sub-millisecond wall-clock timing. `PERF_frame_end` (called once per main loop iteration) accumulates results and logs averages every `PERF_LOG_INTERVAL` frames via `_LOGINFO`.

### Instrumented Sections

| ID | Constant | What It Measures |
|----|----------|------------------|
| 0 | `PERF_RENDER_TOTAL` | Entire `SCREEN_render` call |
| 1 | `PERF_GUI_ONLY_PATH` | GUI-only refresh path (scene cache + GUI overlay) |
| 2 | `PERF_DIRTY_RECT_PATH` | Dirty-rect fast path (partial restore + partial scale) |
| 3 | `PERF_FULL_CLS_GUI` | Full render: CLS + conditional GUI rebuild |
| 4 | `PERF_FULL_CHECKERBOARD` | Full render: transparency checkerboard |
| 5 | `PERF_FULL_LAYERS` | Full render: layer compositing loop (the big one) |
| 6 | `PERF_FULL_GRIDS` | Full render: regular grid + pixel grid |
| 7 | `PERF_FULL_SYMMETRY` | Full render: symmetry guide overlay |
| 8 | `PERF_FULL_TOOL_PREVIEW` | Full render: all tool previews (line, rect, ellipse, etc.) |
| 9 | `PERF_FULL_GUI_OVERLAY` | Full render: GUI layer composite + status bars |
| 10 | `PERF_FULL_CROSSHAIR_CMD` | Full render: crosshair + command palette |
| 11 | `PERF_SCENE_CACHE_SAVE` | Scene cache save (`_PUTIMAGE` canvas → cache) |
| 12 | `PERF_SELECTION_OVERLAY` | Selection overlay (marching ants, after SkipToPointer) |
| 13 | `PERF_POINTER_RENDER` | `POINTER_update` + `POINTER_render` |
| 14 | `PERF_FINAL_SCALE` | Scale CANVAS → WINDOW_IMG (`_PUTIMAGE` resize) |
| 15 | `PERF_DISPLAY_CALL` | `_DISPLAY` call (SDL2 buffer swap) |
| 16 | `PERF_MOUSE_INPUT` | `MOUSE_input_handler` |
| 17 | `PERF_KEYBOARD_INPUT` | `KEYBOARD_input_handler` |
| 18 | `PERF_STICK_INPUT` | `STICK_input_handler` |
| 19 | `PERF_IDLE_DETECT` | Idle detection logic |
| 20 | `PERF_LIMIT_WAIT` | `_LIMIT` wait time |
| 21 | `PERF_MAIN_LOOP_TOTAL` | Entire main loop iteration |
| 22 | `PERF_POST_INPUT` | Post-render input handler loops |

### Reading the Report

```
==== PERF REPORT (120 frames) ====
  Path distribution: GUI-only=0 DirtyRect=68 Full=3 Idle(skipped)=49
RENDER TOTAL: avg=2.9ms total=208ms hits=71
  dirty-rect path: avg=.33ms total=22ms hits=68 (11% of render)
  full: layers: avg=17ms total=52ms hits=3 (603% of render)
  ...
  Frame budget: 16ms @ 60fps | Render uses 17%
==== END PERF ====
```

- **Path distribution**: How many frames used each render path. Idle frames skip rendering entirely.
- **avg**: Average time per hit (in milliseconds)
- **total**: Sum over the interval
- **hits**: How many times that section ran
- **% of render**: What fraction of `RENDER TOTAL` this section consumes (can exceed 100% for sub-sections that only run in the full path, since the average is compared against the overall render average which is dominated by fast dirty-rect frames)
- **Frame budget**: Shows what % of the target frame time (e.g. 16.67ms @ 60fps) the render consumes

---

## Render Pipeline Architecture

DRAW has **3 render paths** in `SCREEN_render`, chosen based on frame state:

### Path 1: Idle (skipped)
When `FRAME_IDLE% = TRUE` (no input at all), `SCREEN_render` is not called. The previous frame remains on display. Throttled to `IDLE_FPS_LIMIT` (15fps).

### Path 2: GUI-Only Refresh
When `NOT SCENE_DIRTY% AND GUI_NEEDS_REDRAW%`. Restores scene from cache, re-renders only the GUI overlay (toolbar, status bar, palette strip, layer panel), then jumps to pointer rendering.

### Path 3: Dirty-Rect Fast Path
When `NOT SCENE_DIRTY%` (cursor moved but nothing else changed). Calculates union bounding box of old + new pointer areas, restores that region from scene cache, redraws selection overlay + pointer, and does a **partial scale** to `WINDOW_IMG` (only the dirty rectangle). This is the dominant path during normal mouse movement (~95% of non-idle frames).

### Path 4: Full Render
When `SCENE_DIRTY% = TRUE` (button press, key press, panning, etc.). Runs the complete pipeline: CLS → GUI rebuild → transparency checkerboard → layer compositing → grids → symmetry → tool previews → GUI overlay → crosshair → command palette → scene cache save → selection overlay → pointer → full scale → `_DISPLAY`.

---

## Baseline Results (Linux, 2x display scale, 640×400 canvas)

### Cursor-Only Movement (dirty-rect path)

| Section | Time |
|---------|------|
| Dirty-rect path | 0.33–0.53ms |
| `_DISPLAY` | 1.1–1.3ms |
| **Total render** | **1.6–2.7ms** |
| **Budget used** | **9–16%** |

### Full Render (mouse click / key press)

| Section | Time | Notes |
|---------|------|-------|
| **Layer compositing** | **17ms** | #1 bottleneck — per-pixel `_MEMIMAGE` opacity loop |
| **Final scale** | **12–18ms** | #2 bottleneck — full-canvas `_PUTIMAGE` resize |
| CLS + GUI rebuild | 1–2ms | |
| GUI overlay | 1ms | |
| Checkerboard | 0.33–1ms | |
| Pointer render | <0.01ms | |
| Selection overlay | <0.01ms | |
| Scene cache save | <0.01–1ms | |

### Input Handlers

| Section | Time |
|---------|------|
| Mouse input | <0.01ms |
| Keyboard input | <0.01ms |
| Stick input | <0.01ms |
| Idle detection | <0.01ms |

---

## Known Bottlenecks

### 1. Layer Compositing (17ms avg during full render)

The per-pixel `_MEMIMAGE` opacity loop in `SCREEN_render` iterates every pixel of every layer with `opacity < 255` when `contentDirty%` is TRUE. On a 640×400 canvas with one semi-transparent layer, that's 256,000 pixels × `_MEMGET` + alpha math + `_MEMPUT` per layer.

**Mitigation**: Only set `LAYERS(idx%).contentDirty% = TRUE` when actual pixel content changes (drawing, clear, merge, undo/redo). Do NOT set it during blend mode, visibility, or opacity changes — those invalidate the cache differently via `BLEND_invalidate_cache`.

### 2. Final Scale (12–18ms during full render)

The `_PUTIMAGE` from 640×400 to 1280×800 (2x scale) is a CPU software blit with nearest-neighbor interpolation. Higher display scales (3x, 4x) will be proportionally slower.

**Note**: The dirty-rect path avoids this by only scaling the small dirty rectangle (~64×64 pixels around the cursor), which is why cursor movement stays under 2ms total.

### 3. `_DISPLAY` (1.1–1.3ms every frame)

This is the SDL2 buffer present/swap. It's an unavoidable system call.

### 4. Windows-Specific Cursor Lag

On Windows, the custom cursor may feel laggy despite fast render times because:

- **Windows DWM** (Desktop Window Manager) adds 1–2 frames of composition latency to all windows
- **Windows timer resolution** defaults to 15.6ms granularity, causing irregular frame pacing with `_LIMIT`
- **SDL2 vsync** may be forced by the Windows GPU driver, adding blocking time to `_DISPLAY`
- **Full render stalls**: A single full render (17ms layers + 12ms scale = ~30ms) drops below 30fps for that frame, creating a visible hitch

None of these are fixable in application code — they're platform-level behaviors.

---

## Adding New Profiling Sections

1. Add a new `CONST PERF_MY_SECTION = N` in `CORE/PERF.BI` (increment from last ID)
2. Increment `PERF_SECTION_COUNT`
3. Add `PERF_names(PERF_MY_SECTION) = "my section"` in the name initialization block
4. Bracket the code with `PERF_start PERF_MY_SECTION` / `PERF_stop PERF_MY_SECTION`

---

## Disabling Profiling

To remove profiling overhead, comment out the `$INCLUDE` lines in `_ALL.BI` and `_ALL.BM`:
```qb64
' '$INCLUDE:'./CORE/PERF.BI'
' '$INCLUDE:'./CORE/PERF.BM'
```

Then remove or comment out all `PERF_start`, `PERF_stop`, and `PERF_frame_end` calls. The overhead when enabled is negligible (<0.01ms per frame for all timing calls combined) since it's just `TIMER()` reads and array additions.
