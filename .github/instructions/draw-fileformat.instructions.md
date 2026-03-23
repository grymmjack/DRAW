---
applyTo: "**/DRW*.B*, **/CONFIG*.B*, **/THEME*.B*, **/FILE-*.B*"
---

# DRAW — File Format, Config & Theme

---

## Native File Format (.draw)

A **valid PNG** containing a custom `drAw` ancillary chunk before IEND. The PNG image is a flattened preview of all visible layers. The chunk contains DEFLATE-compressed binary project data.

Extension changed from `.drw` to `.draw` in v0.7.4 (CorelDRAW conflict).

### drAw Chunk Payload

```
[2 bytes] Chunk format version (little-endian INTEGER)
[4 bytes] Uncompressed data size (little-endian LONG)
[N bytes] DEFLATE-compressed binary project data
```

### Binary Project Data

| Section         | Fields | Version |
| --------------- | ------ | ------- |
| Header          | Magic `"DRW1"`, version(2), canvasW(4), canvasH(4) | v1+ |
| Palette         | count(2), colors(4 each), fg_idx(2), bg_idx(2) | v1+ |
| Layers          | count(2), current(2), per-layer: name(16), visible(2), opacity(2), zIndex(2), blendMode(2), opacityLock(2), pixel data (W×H×4) | v1+ |
| Tool State      | tool(2), brush_size(2), pixel_perfect(2), grid_visible(2), grid_size(2) | v1+ |
| Palette Name    | name(64) | v3+ |
| Reference Image | hasImage(2), filename(260), posX/Y(4), scaleW/H(4), visible(2), opacity(2) | v4+ |
| Brush Shape     | shape(2) | v5+ |
| Grid State      | mode(2), cellFill(2), snap(2), alignMode(2) | v6+ |
| Unified History | stable layer ids + history records/payloads for replay/export | v7+ |
| Drawer State    | visible(2), mode(2), miniPaletteOffset(2), selected slots(2 each), customBrushActive(2), 30 brush slots, 30 pattern slots, 30 gradient slots | v10+ |
| Pattern Tile Mode | enabled(2) | v11+ |
| Gradient Definitions | per-slot gradient defs, color stops, opacity stops | v12+ |
| Gradient Stop Types | per-slot stop type arrays for gradient editors/export | v13+ |
| Extract Images Config | bgMode(2), namingMethod(2), startNumber(2), appendDims(2), mergeLayers(2), baseFilename(64), destDir(260) | v14+ |
| Text Layer Data | textLayerCount(2), per-layer: layerIdx(2), startX(2), startY(2), charCount(2), lineCount(2), fontIdx(2), fontSize(2), defaultLeading(2), cursorPos(2), per-char: char(1)+fg(4)+bg(4)+bold(2)+italic(2)+underline(2)+strike(2)+fontIdx(2)+fontSize(2), per-line: lineBreakIdx(2) | v15+ |
| Text Layer Monospace | monospace(2) flag per text layer | v16+ |
| Text Bar State | selectedFontIdx(2), selectedSize(2), boldActive(2), italicActive(2), underlineActive(2), strikeActive(2), monoActive(2) | v17+ |
| Character Grid State | charGridShow(2), charGridSnap(2), charGridW(2), charGridH(2) | v18+ |
| Character Mode | useChars(2) | v19+ |

Constants: `DRW_MAGIC$ = "DRW1"`, `DRW_VERSION% = 19`, `DRW_CHUNK_VERSION% = 1`

**Per-document vs global config**: Character Mode (`useChars%`) is saved per-document in v19+ — it is NOT stored in `DRAW.cfg`. On fresh launch (no file loaded), `useChars%` defaults to FALSE. Character grid visibility/snap state is also per-document (v18+).

### Key Functions

- `DRW_load filename$` — auto-detects PNG vs legacy binary format
- `DRW_save` — creates flattened PNG + embeds drAw chunk
- `DRW_save_dialog` / `DRW_open_dialog` — set `CURRENT_DRW_FILENAME$`, add to recent files

### State Reset on File Load (`DRW_load_binary`)

```qb64
IF TEXT.ACTIVE THEN TEXT_cancel
TEXT_LAYER_DATA pool clear: TEXT.editingTextLayer% = 0: TEXT_BAR.editingLayerIdx% = 0
HISTORY_clear: MARQUEE_reset: MOVE_init: MAGIC_WAND_reset: ERASER_reset
DRAWER_reset: PREVIEW_reset: EXTRACT_reset_saved_config
LAYER_PANEL.scrollOffset% = 0: LAYER_PANEL.soloLayer% = 0
LAYER_PANEL.visSwiping% = FALSE: LAYER_PANEL.dragPending% = FALSE
LAYER_PANEL.isDragging% = FALSE: LAYER_PANEL.dragLayerIdx% = 0
LAYER_PANEL.opacityDrag% = FALSE
```

**When adding new tool/panel state, add its reset here.**

---

## Config System (`CFG/CONFIG.BI` / `CONFIG.BM`, ~1019 lines)

Config file: `DRAW.cfg` — plain text, one `key=value` per line. Loaded by `CONFIG_load`, saved by `CONFIG_save`.

### Key Config Fields

| Category | Fields |
| -------- | ------ |
| Display  | `DISPLAY_SCALE%`, `FULLSCREEN%`, `FPS_LIMIT%` |
| Canvas   | `SCREEN_WIDTH%`, `SCREEN_HEIGHT%` |
| Palette  | `DEFAULT_PALETTE$`, `PALETTE_CHIP_WIDTH/HEIGHT%`, `PALETTE_MIN/MAX_ROWS%` |
| Brush    | `DEFAULT_TOOL%`, `DEFAULT_BRUSH_SIZE%`, `DEFAULT_BRUSH_SHAPE%`, `DEFAULT_DRAW_MODE%`, `DEFAULT_BIN_MODE%` |
| Grid     | `GRID_MODE%`, `GRID_SIZE_X/Y%`, `GRID_CELL_FILL%` |
| Crosshair | `CROSSHAIR_OUTLINE_FG$`, `CROSSHAIR_OUTLINE_OPACITY%`, `CROSSHAIR_OUTLINE_WIDTH%` |
| Undo     | `HISTORY_MAX_RECORDS` (1024)                            |
| Picker   | `PICKER_LOUPE_*` overlay layout, font, and colors |
| Preview / Panels | `PREVIEW_*` (incl. `PREVIEW_MODE%`, `PREVIEW_COLOR_PICK%`, `PREVIEW_BIN_QUICK_LOOK%`, `PREVIEW_FLOAT_IMAGE_PATH$`, `PREVIEW_FLOAT_LAST_DIR$`), `EDIT_BAR_VISIBLE%`, `EDIT_BAR_DOCK_POSITION$`, `LAYER_PANEL_WIDTH%`, `LAYERS_PANEL_DOCK_EDGE$`, `TOOLBOX_DOCK_EDGE$` |
| Palette UI | `PALETTE_SHOW_LOSPEC%`, `PALETTE_SHOW_CREATED%`, `PALETTE_CREATE_MAX_COLORS%` |
| Drawer / Templates | `DEFAULT_DSET_*_FILE$`, `TEMPLATE_DIR$` |
| Export   | `BAS_EXPORT_BG_COLOR~&`, `BAS_WIP_ENABLED%` |
| Audio    | `SOUNDS_*`, `MUSIC_*` |
| Cursor   | `SYSTEM_CURSORS_ENABLED%` — TRUE=OS native cursors for UI/canvas; FALSE=always custom PNG |
| Dirs     | `LAST_DIR_OPEN$`, `LAST_DIR_SAVE$`, `LAST_DIR_IMPORT$`, `LAST_DIR_EXPORT_BRUSH/LAYER$`, `LAST_DIR_PALETTE$`, `LAST_DIR_EXTRACT$` |

Defaults: DOT tool, brush size 1, square shape, 60 FPS, 128×128 canvas, 4 layers.

**Auto-Detection (first launch)**: When `DISPLAY_SCALE=0`, `SCREEN_detect_display_scale%` targets 90% of desktop resolution at highest integer scale (capped at 4). `TOOLBAR_SCALE=0` auto-detects from viewport height (≥800=4x, ≥600=3x, ≥400=2x, else 1x). Saved on first launch via `CONFIG_NEEDS_INITIAL_SAVE%`.

Command-line config helpers: `--config <file>` / `-c <file>` selects an explicit config file, and `--config-upgrade` backfills newly-added keys into an existing config.

---

## Theme System

**Files**: `CFG/CONFIG-THEME.BI` (DRAW_THEME UDT + DECLARE), `CFG/CONFIG-THEME.BM` (runtime loader), `ASSETS/THEMES/DEFAULT/THEME.BI` (compiled-in defaults), `ASSETS/THEMES/DEFAULT/THEME.CFG` (runtime overrides)

### Two-Tier Loading

1. **Compile time** (`THEME.BI`): Hardcoded defaults at include time. Always present. Fallback.
2. **Runtime** (`THEME.CFG`): Human-editable `key=value`. Loaded twice due to `$INCLUDE` execution order.

**CRITICAL**: `THEME.BI` is included after `SCREEN.BI` in `_ALL.BI` and runs as inline code at include time, overwriting `THEME.*` back to compiled defaults. `THEME_load` must be called explicitly in `DRAW.BAS` immediately after `'$INCLUDE: './_ALL.BI'` to survive. Without this second call, all THEME.CFG overrides are silently discarded.

`THEME_load` parses `THEME.CFG`, dispatching via `SELECT CASE UCASE$(key$)`. Colors specified as `R,G,B,A`, parsed by `THEME_parse_rgba~&(val$)`.

### DRAW_THEME Color Fields

**Theme color fields MUST be `_UNSIGNED LONG` (`~&`), never `INTEGER`** — INTEGER truncates RGB32 values and causes color corruption when the palette changes.

Key fields:

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `TOOLBAR_btn_overlay~&` | `_UNSIGNED LONG` | Active toolbar button fill overlay |
| `TOOLBAR_btn_stroke~&`  | `_UNSIGNED LONG` | Active toolbar button border color |
| `DRAWER_PANEL_*` | `INTEGER` / `_UNSIGNED LONG` | Drawer layout, palette paging, scrollbar sizing, and drawer colors |
| `PREVIEW_*` | `INTEGER` / `_UNSIGNED LONG` / `STRING` | Preview window chrome, font, checkbox, and resize-handle styling |
| `EDIT_BAR_*` | `INTEGER` / `_UNSIGNED LONG` / `STRING` | Edit bar sizing, borders, colors, and icon filename configuration |
| `LOSPEC_*` | `_UNSIGNED LONG` / `INTEGER` | Lospec dialog search/list/preview/status theming |
| `TRANSFORM_FRAME_COLOR~&` | `_UNSIGNED LONG` | Transform overlay bounding-box outline |
| `TRANSFORM_FRAME_HANDLE_COLOR~&` | `_UNSIGNED LONG` | Transform overlay handle square fill |
| `TRANSFORM_FRAME_HANDLE_SIZE%` | `INTEGER` | Transform overlay handle half-size in pixels |
| `CROSSHAIR_outline_fg~&` | `_UNSIGNED LONG` | Crosshair outline stroke color |
| `CROSSHAIR_outline_opacity%` | `INTEGER` | Crosshair outline opacity (0–255) |
| `CROSSHAIR_outline_width%` | `INTEGER` | Crosshair outline width in pixels (0–8) |
| `LAYER_PANEL_header_height` | `INTEGER` | Header bar height in pixels |
| `LAYER_PANEL_btn_bar_height` | `INTEGER` | Button bar height in pixels |
| `LAYER_PANEL_bg~&` through `LAYER_PANEL_scrollbar~&` | `_UNSIGNED LONG` | 23 layer panel color fields |

All layer panel fields configurable at runtime via `THEME.CFG` — no recompile needed.
