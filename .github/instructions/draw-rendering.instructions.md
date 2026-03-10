---
applyTo: "**/SCREEN.BM, **/LAYERS.BM, **/COMPOSITE*.B*"
---

# DRAW — Rendering & Layer System

---

## Rendering Pipeline (`OUTPUT/SCREEN.BM` → `SCREEN_render`)

Composited back-to-front onto `SCRN.CANVAS&`, then GPU-scaled to window via `_PUTIMAGE`:

1. Transparency checkerboard
2. Layer compositing (by zIndex, bottom-to-top)
   - Normal blend: direct `_PUTIMAGE` (fast path)
   - Non-Normal blend: per-pixel composite via `COMPOSITE_BUFFER&` using `_MEM` access
   - Partial composite cache: layers below current layer cached in `COMPOSITE_BELOW_CACHE&`
   - Opacity adjustment: cached per-layer in `opacityCacheImg&` (invalidated by `contentDirty%`)
3. Grid overlay
4. Symmetry guides
5. Canvas border
6. Image import preview
7. **Tool previews** (marquee, line, rect, ellipse, polygon, move, text, zoom)
8. GUI layer (`SCRN.GUI&` — toolbar, organizer, drawer panel, edit bar, status bar, palette strip, layer panel, menubar)
9. Crosshair overlay
10. Scrollbars
11. **Scene cache save** → `SCENE_CACHE&`
12. `SkipToPointer:` — fast path target for cursor-only updates
13. **Selection overlay** (marching ants) — AFTER cache, so animation doesn't invalidate it
14. Pointer cursor (`POINTER_update` + `POINTER_render`)
15. **Preview window** (`PREVIEW_render`) — before the second GUI composite so menus and overlays stay above it
16. GUI recomposite + scrollbars + contextual status bars
17. Picker loupe overlay (`PICKER_LOUPE_render`) when the picker is active
18. **Final overlay popups** (blend-mode popup, drawer context menu, command palette)
19. Cursor overlay
20. Scale `SCRN.CANVAS&` to window (integer scaling, nearest neighbor)
21. `_DISPLAY`

### Scene Cache (`SCENE_CACHE&`, `SCENE_DIRTY%`)

When only the cursor moved, `SCENE_DIRTY%` stays FALSE. The renderer copies the cached scene image, then jumps to `SkipToPointer:` — skipping all layer compositing, grid rendering, and tool previews.

**What sets `SCENE_DIRTY%`**: Key press, mouse button held, GUI redraw, panning, scroll wheel, active tool states, menubar open.

**What sets `FRAME_IDLE% = FALSE` but NOT `SCENE_DIRTY%`**: Mouse movement alone (cursor-only fast path), active selections (marching ants animate after `SkipToPointer:`).

**Rule**: Per-frame animations MUST render after `SkipToPointer:`. Placing them before forces `SCENE_DIRTY% = TRUE` every frame, defeating the cache.

**Overlay rule**: Any overlay that must remain visible above the recomposited GUI layer belongs after the second GUI composite. The picker loupe and final popup overlays are the current examples. The preview window is the counterexample: it renders before the second GUI composite so menus, status overlays, and pickers can remain on top of it.

### Performance Patterns

- **Persistent buffers**: `COMPOSITE_BUFFER&`, `SCENE_CACHE&`, `PG_CACHE_IMG&` — allocated once, never reallocated per frame
- **Conditional GUI redraw**: `GUI_NEEDS_REDRAW%` gates toolbar/status/palette/layer re-rendering
- **Layer render order**: `RENDER_ORDER%()` lookup table, rebuilt when `RENDER_ORDER_DIRTY%`
- **Opacity cache**: Per-layer `opacityCacheImg&` + `opacityCacheVal%` + `contentDirty%`. Cache hit skips expensive per-pixel `_MEM` opacity loop. Only mark `contentDirty% = TRUE` when pixel content actually changes.
- **`contentDirty%` discipline**: `BLEND_invalidate_cache` does NOT mark layers `contentDirty%`. It only sets `BLEND_COMPOSITE_DIRTY%`, `RENDER_ORDER_DIRTY%`, `SCENE_DIRTY%`, and `COMPOSITE_BELOW_VALID% = FALSE`.
- **Blend composite cache**: `COMPOSITE_BELOW_CACHE&` stores composited layers below `CURRENT_LAYER%`. When only the current layer changes, layers below are restored from cache instead of re-composited.

---

## Layer System (`GUI/LAYERS.BI` / `GUI/LAYERS.BM`, ~2305 lines)

### DRAW_LAYER Type

| Field            | Type       | Purpose                                                 |
| ---------------- | ---------- | ------------------------------------------------------- |
| zIndex           | INTEGER    | Compositing order                                       |
| imgHandle&       | LONG       | QB64 image handle for pixel data                        |
| visible          | INTEGER    | Layer visibility                                        |
| name             | STRING\*64 | Layer name                                              |
| opacity          | INTEGER    | 0–255                                                   |
| opacityLock      | INTEGER    | Prevent alpha changes                                   |
| blendMode        | INTEGER    | One of 19 blend modes                                   |
| contentDirty%    | INTEGER    | Pixel content changed — invalidates opacity cache       |
| opacityCacheImg& | LONG       | Cached opacity-adjusted image                           |

Max 64 layers. 19 blend modes (Normal through Divide).

`LAYER_current_image&`: Returns `LAYERS(CURRENT_LAYER%).imgHandle&` or falls back to `SCRN.PAINTING&`.

### Multi-Layer Select

| Variable                     | Type     | Purpose                                          |
| ---------------------------- | -------- | ------------------------------------------------ |
| `MULTI_SELECT_LAYERS(1..64)` | INTEGER  | TRUE for each selected layer index               |
| `MULTI_SELECT_COUNT%`        | INTEGER  | Number of selected layers (always ≥ 1)           |
| `MULTI_SELECT_has_any%`      | FUNCTION | Returns TRUE when `MULTI_SELECT_COUNT% > 1`      |

- **Ctrl+Click / Shift+Click**: toggle layer into/out of multi-selection
- **Plain left-click**: calls `LAYERS_select` → `MULTI_SELECT_clear` → resets to 1 layer

When 2+ layers selected: Edit operations (Clear, Fill, Flip, Scale, Rotate) and `Layer → Merge Selected` apply to all. `Select → From Selected Layers` creates a union selection mask.

Helpers: `MULTI_SELECT_clear`, `MULTI_SELECT_toggle layerIndex%`

---

## Cache Invalidation Rules

### Mark `contentDirty% = TRUE` when layer pixels actually change:
- Drawing/painting committed (brush stroke, fill, text stamp)
- `LAYERS_clear`, `LAYERS_merge_down`, `LAYERS_duplicate`
- `WORKSPACE_UNDO_undo` / `_redo` when restoring pixel data
- Any `_COPYIMAGE` / `_PUTIMAGE` modifying layer `imgHandle&`

**Do NOT** blanket-set `contentDirty%` on all layers in `BLEND_invalidate_cache`.

### Call `BLEND_invalidate_cache` when layer structure/visibility changes (not pixels):
- Layer added, deleted, reordered
- Visibility toggled, opacity changed, blend mode changed
- Current layer selection changed
- File loaded (`DRW_load`)

### Scene cache boundary summary:
- Rendered **before** step 12: cached → only redrawn when `SCENE_DIRTY%`
- Rendered **after** step 13 (`SkipToPointer:`): redrawn every active frame regardless
