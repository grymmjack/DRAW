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

### drAn Chunk (animation frame layout)

A sheet with frames (`TOOLS/ANIM`, see `draw-animation.md`) adds a second ancillary chunk,
`drAn`, right after `drAw` (`DRW_save`). It is **not** inside the drAw payload, so a DRAW
without animation reads drAw and opens the file as a plain picture (round 2 R-10), and the
.draw version did not change. `DRW_load_from_png` reads it from a .draw **or a plain PNG**
(a PNG sprite sheet can carry frames too) after the canvas size is known, via
`ANIM_deserialize%`; data that does not fit the canvas opens the picture without frames.
Not deflated - it is small. Little-endian INTEGERs (`ANIM_serialize$`):

```
version (ANIM_CHUNK_VERSION = 2), frameW, frameH, gutter, margin,
count, current, fps, loopMode (0 FWD 1 REV 2 PING 3 ONCE),
nHolds, then nHolds holds (frames 1..nHolds; the rest hold 1)
v2, only when a layer has flags: nFlags, then per entry
    historyId (LONG), flags (1 = reference layer, 2 = same on every frame)
v3 (ANIM_CHUNK_VERSION_LINKS), only when there are linked cells (4.3): the version field
    is 3, the flags block is always there (nFlags may be 0), then nLinks, per entry
    historyId (LONG), frame, group (cells of one layer with the same group show one drawing;
    the lowest frame is the source)
v4 (ANIM_CHUNK_VERSION_TAGS), only when there are tags (4.4): the version field is 4, the
    flags and links blocks are always there (counts may be 0), then nTags, per tag
    from (2), to (2), nameLen (2), name (nameLen bytes, at most 32)
v5 (ANIM_CHUNK_VERSION_NOTES), only when a frame has a note (4.5): the version field is 5,
    every block before is there (counts may be 0), then nNotes, per note
    frame (2), textLen (2), text (at most 80)
v6 (ANIM_CHUNK_VERSION_SOUND), only when there is a soundtrack (L.1): the version field is 6,
    every block before is there (counts may be 0), then pathLen (2), path (as picked; on
    open, a path that is gone is looked for by its file name beside the document),
    offset ms (4, where frame 1 starts in the sound)
```

Newer versions append fields; a reader takes the ones it knows (version >= 1; the flags are
read even when the frames don't fit; a v2 reader drops v3's links and opens the cells as they
are, unlinked; a v3 reader drops v4's tags, a v4 reader v5's notes, a v5 reader v6's soundtrack). No frames and no layer flags = no chunk; a picture with
a reference layer but no frames writes the chunk with frameW 0 / count 0. Every document path calls `ANIM_reset` first (gotcha 15). The re-slice / resize
answer and playback are session state, not saved. Test: `QA/tests/file-anim-chunk.sh`
(`QA/fixtures/png-chunk.py put|get` writes / reads chunks for fixtures).

### drAx Chunk (drawer slots past the classic 30)

2.8 raised `DRAWER_SLOT_COUNT` from 30 to 96 per mode **without a .draw version bump**: the
drAw payload still holds exactly `DRAWER_FILE_SLOTS` (30) slots in every place it did (drawer
state, gradient defs, stop types), and slots 31 .. last used ride in their own ancillary chunk
`drAx`, written by `DRW_embed_chunk_in_png` only when a slot past 30 holds something. An older
DRAW skips the chunk and opens the file with its 30 slots. Payload: `MKL$(raw size)` +
`_DEFLATE$(raw)`, raw = `DRAWER_write_ext_draw`:

```
version (DRAWER_EXT_VERSION = 1), lastSlot,
then per slot 31 .. lastSlot: brush image, pattern image, gradient image
    (DRAWER_save_slot_image: hasImage -1/0, w, h, w*h _UNSIGNED LONG),
    gradient record (DRAWER_put_grad_record = the .dset v2 per-slot record)
```

`DRW_load_from_png` reads it after `DRW_load_binary` (which emptied every slot) through
`DRAWER_read_ext_draw`; a custom brush saved on a slot past 30 is set up there
(`DRAWER_PENDING_CUSTOM`). A slot index past this build's `DRAWER_SLOT_COUNT` is read and dropped.

**.dset** gets the same treatment: the classic 30 slot images (+ 30 gradient records in v2),
then - only when a slot past 30 is used - `DSX1` (`DRAWER_EXT_MAGIC$`), lastSlot(2), per slot
its image (+ its gradient record for a gradient set). An older DRAW stops reading after the
30. Both readers (set cycling / defaults and the import dialog) go through
`DRAWER_read_dset_slots`; the writer truncates first so a shorter set never keeps an old tail.
Test: `QA/tests/drawer-slots.sh`, fixtures `QA/fixtures/make-drawer-fixtures.py`.

### drAb Chunk / DSA1 block (AnimBrush bins, A4)

A Drawer brush slot can hold an AnimBrush (`DRAW_BRUSH.CELS` = the cels side by side, `N`,
`CW`, `CH`; `IMG` stays cel 1, so every older path - and an older DRAW - sees a one-picture
brush). The cels ride outside every existing layout: a `.draw` gets an ancillary `drAb` chunk
(`MKL$(raw size)` + `_DEFLATE$(raw)`, raw = `AB_drab$`: version(2) = `AB_DRAB_VERSION`, count(2),
per slot: slot(2), n(2), cw(2), ch(2), the strip's BGRA bytes), read after drAx by
`AB_read_drab` (which re-picks the custom brush from its slot so the AnimBrush comes back).
A brush `.dset` gets `DSA1` (`AB_DSET_MAGIC$`) + the same count / slot records after the
slots and any `DSX1` block (`AB_slots_write_dset` / `AB_slots_read_dset`, from
`DRAWER_read_dset_slots`). Strips wider than 32767 px are not stored (the bin keeps one
picture). Test: `QA/tests/animbrush-bin.sh` (fixtures made in the test).
Names (2026-11-12): after the last slot record, in both DSA1 and drAb, an optional
`ABN1` (`AB_NAMES_MAGIC$`) + count(2) + per name slot(2), length(2), the name (<= 32). Older
DRAWs stop reading after the records, so no version bump; `AB_names_from_blob` reads it
(`animbrush-hold-pickup.sh`).

### drCl Chunk (clip layers, 2026-11-12)

A clip layer (`LAYER_TYPE_CLIP` = 6, `TOOLS/CLIP`) is written into drAw as a plain IMAGE layer
with the pixels it shows, so an older DRAW opens it baked. Its clip rides in an ancillary
`drCl` chunk after drAb: `MKL$(raw size)` + `_DEFLATE$(raw)`, raw = `CLIP_chunk$`: version(2)
= `CLIP_CHUNK_VERSION`, source count(2), per source: index(2), n(2), cw(2), ch(2),
binSlot(2), name length(2), the name, the strip's BGRA bytes (n*cw x ch); then instance
count(2), per instance whose layer exists: the layer's historyId(4) + the 20-byte
`CLIP_inst_blob$` (src, in, out, start cel, every, mode, flipX, flipY, px, py, 2 bytes each).
**Version 2** (phase 2 K7, 2026-11-12) appends the sound cues: count(2), per cue of a written
source: source index(2), kind(2) (0 on cel, 1 when the clip starts, 2 each time it starts
over), cel(2) (kind 0; else 0), path length(2), the path as picked (found later the way
soundtrack files are: that path, else the same name beside the document). A version-1 reader
stops after the instances, so an older DRAW keeps the clips and drops the sounds.
Only sources an instance uses are written; nothing is written without a clip layer. `CLIP_read_chunk` (after `AB_read_drab` in `DRW_load_binary`)
sets those layers back to CLIP and rebuilds them. Tests: `QA/tests/clip-layers.sh`, `clip-cues.sh`.

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
| Drawer State    | visible(2), mode(2), miniPaletteOffset(2), selected slots(2 each), customBrushActive(2), 30 brush slots, 30 pattern slots, 30 gradient slots (`DRAWER_FILE_SLOTS`; slots past 30 are in the `drAx` chunk) | v10+ |
| Pattern Tile Mode | enabled(2) | v11+ |
| Gradient Definitions | per-slot gradient defs, color stops, opacity stops | v12+ |
| Gradient Stop Types | per-slot stop type arrays for gradient editors/export | v13+ |
| Extract Images Config | bgMode(2), namingMethod(2), startNumber(2), appendDims(2), mergeLayers(2), baseFilename(64), destDir(260) | v14+ |
| Text Layer Data | textLayerCount(2), per-layer: layerIdx(2), startX(2), startY(2), charCount(2), lineCount(2), fontIdx(2), fontSize(2), defaultLeading(2), cursorPos(2), per-char: char(1)+fg(4)+bg(4)+bold(2)+italic(2)+underline(2)+strike(2)+fontIdx(2)+fontSize(2), per-line: lineBreakIdx(2) | v15+ |
| Text Layer Monospace | monospace(2) flag per text layer | v16+ |
| Text Bar State | selectedFontIdx(2), selectedSize(2), boldActive(2), italicActive(2), underlineActive(2), strikeActive(2), monoActive(2) | v17+ |
| Character Grid State | charGridShow(2), charGridSnap(2), charGridW(2), charGridH(2) | v18+ |
| Character Mode | useChars(2) | v19+ |
| Text Layer Outline/Shadow | alignment(1), antialias(1), per-char: outline(1)+outlineColor(4)+outlineSize(1)+shadow(1)+shadowColor(4)+shadowX(1)+shadowY(1) | v20+ |
| Grid Height | gridHeight(2) — allows non-square grids | v21+ |
| Pixel Grid Visibility | show(2) | v22+ |
| Grid Config | gridColorFG(4), gridOpacity(2), pixelgridColorFG(4), pixelgridOpacity(2), gridAngle(4), charGridWidth(2), charGridHeight(2), charGridOpacity(2), charGridColorFG(4) | v23+ |
| Layer Groups | per-layer: layerType(2), parentGroupIdx(2), collapsed(2), passThrough(2); group layers skip pixel data write (no imgHandle) | v24+ |
| Symbol Layer Fields | per-layer: symbolParentId(4), symbolParentDirty(2, always 0 on save), symbolScaleX(4), symbolScaleY(4), symbolOffsetX(2), symbolOffsetY(2) | v25+ |
| Extract Grid Config | gridColCount(2), gridRowCount(2), gridCellW(2), gridCellH(2), extractGridDestDir(260), extractGridBaseFilename(64), gridNamingMethod(2), gridStartNumber(2) | v26+ |
| Symbol Child Rotation | per-layer: symbolRotation(2) — 0=none, 1=90CW, 2=180, 3=270CW | v27+ |
| Layer Name Width | Layer name field expanded from 16 bytes to 64 bytes (allows longer layer names up to 63 chars) | v28+ |
| AI Layer Data | aiLayerCount(2), then per AI layer: layerIdx(2), seedVal(4), genW(2), genH(2), and four **length-prefixed** strings — prompt, styleName, toolName, modelName (each: len(2) + bytes, written only when len > 0) | v29+ |
| Color Cycling Ranges | blobLen(4), then `PCYC_serialize$`: count(2), per range lo(2), hi(2), rate(4, ILBM CRNG units: 16384 = 60 steps/s), cmode(2: 0 FWD, 1 REV, 2 PING), active(2), heldStep(4). Read into a local and adopted **after** `PALETTE_OPS_reset` (which clears ranges) | v30+ |

Constants: `DRW_MAGIC$ = "DRW1"`, `DRW_VERSION% = 30`, `DRW_CHUNK_VERSION% = 1`

**AI layer strings are length-prefixed, not fixed-width.** `AI_LAYER_OBJ` declares
`prompt AS STRING * 512` and friends, but writing those fixed widths would add ~670
bytes per AI layer to every project file. Save `RTRIM$`es each field and writes
`len(2) + bytes`; load reads the length first. Only layers with
`layerType% = LAYER_TYPE_AI` **and** a live `aiDataIdx%` pool entry are counted and
written, so `aiLayerCount` is not `LAYER_COUNT%`.

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
NEXT_GROUP_NUM% = 0
' Per-layer: layerType% = 0, parentGroupIdx% = 0, collapsed% = FALSE, passThrough% = FALSE
LAYER_PANEL.scrollOffset% = 0: LAYER_PANEL.soloLayer% = 0
LAYER_PANEL.visSwiping% = FALSE: LAYER_PANEL.dragPending% = FALSE
LAYER_PANEL.isDragging% = FALSE: LAYER_PANEL.dragLayerIdx% = 0
LAYER_PANEL.opacityDrag% = FALSE
```

**When adding new tool/panel state, add its reset to all THREE document-creation
paths** — `DRW_load_binary` (open), `DRW_new_canvas` (File > New) and
`DRW_create_canvas_at_size` (New from Clipboard / New from AI) — then diff them
against each other. They have already drifted apart once in both directions:
New reset the ten smart-shape sub-tools and the custom brush but not the basic
shape tools, the transform overlay or the panel modes; Open reset the panel modes
but neither shape-tool set.

Transient tool state is not cosmetic. `TRANSFORM` holds a handle to the previous
layer's content, and `BEZIER`, `POLY_LINE`, `SPRAY` and `ERASER` each hold a
canvas snapshot captured for undo — carrying one across a document switch leaks
the handle and lets a commit record an undo state from a document that is no
longer open. The multi-click tools make this reachable without holding the mouse:
place two polygon vertices, open another project, click once more.

Audit by extracting the reset calls from each SUB and diffing:

```
grep -o '[A-Z_]*_reset[a-z_]*' <each SUB> | sort -u   # then comm -3 the results
```

Use `ZOOM_drag_reset`, never `ZOOM_reset`, in the **open** path — the latter
resets `SCRN.zoom!` and the pan offsets the loader is restoring.

---

## Config System (`CFG/CONFIG.BI` / `CONFIG.BM`, ~1019 lines)

Config file: `DRAW.cfg` — plain text, one `key=value` per line. Loaded by `CONFIG_load`, saved by `CONFIG_save`.

### Key Config Fields

| Category | Fields |
| -------- | ------ |
| Display  | `UI_SCALE%` (MASTER scale, 0=auto / 1-8; drives `DISPLAY_SCALE` + `TOOLBAR_SCALE` and dialog/browser scales), `DISPLAY_SCALE%`, `HIDPI_AWARE%` ([Windows] mark process DPI-aware; no effect on Linux/macOS), `LINUX_HIDPI_SCALE%` ([Linux] opt-in, default FALSE — auto-detect the desktop display-scale and fold it into `SCREEN_DPI_DIVISOR!`; no effect at 100% or on Windows/macOS), `SPLASH_ENABLED%`, `FULLSCREEN%`, `FPS_LIMIT%` |
| Scaling ratios | `SCALE_RATIO_*!` (SINGLE per-widget magnification vs the master scale, 1.0 = equal): `CANVAS`, `TOOLBAR`, `ORGANIZER`, `DRAWER`, `FLYOUT`, `TOOLTIP`, `PREVIEW`, `MIXER`, `DIALOG`, `ABOUT`, `PALETTE_PICKER`, `FD_FONT`, `FD_ICON`, `COLORPICK`, `MSGBOX`, `INPUTBOX`, `BROWSER`, `BROWSER_FONT`, `BROWSER_ICON`. Legacy explicit overrides (`TOOLBAR_SCALE_OVR%`, `FD_FONT_SCALE%`, `FD_ICON_SCALE%`; >0 wins over the ratio) |
| CRT      | `CRT_ENABLED%`, `CRT_INTENSITY%` (0-100), `CRT_SCANLINES%`, `CRT_PHOSPHOR%`, `CRT_VIGNETTE%`, `CRT_TINT%` (0=none,1=amber,2=green,3=cool,4=custom), `CRT_TINT_AMOUNT%`, `CRT_TINT_CUSTOM_COLOR~&`, `CRT_SCANLINE_COLOR~&`, `CRT_VIGNETTE_AMOUNT%`, `CRT_VIGNETTE_COLOR~&`, `CRT_SCANLINE_THICKNESS%` (1-3), `CRT_SCANLINE_GAP%` (1-8) — colors must be `~&` |
| Canvas   | `SCREEN_WIDTH%`, `SCREEN_HEIGHT%` (written as 0 when `UI_SCALE>0` so the viewport is never frozen against a stale scale) |
| Palette  | `DEFAULT_PALETTE$`, `PALETTE_CHIP_WIDTH/HEIGHT%`, `PALETTE_MIN/MAX_ROWS%` |
| Brush    | `DEFAULT_TOOL%`, `DEFAULT_BRUSH_SIZE%`, `DEFAULT_BRUSH_SHAPE%`, `DEFAULT_DRAW_MODE%`, `DEFAULT_BIN_MODE%` |
| Grid     | `GRID_MODE%`, `GRID_SIZE_X/Y%`, `GRID_CELL_FILL%`, `SMART_GUIDES_ENABLED%`, `SMART_GUIDES_SNAP%` |
| Crosshair | `CROSSHAIR_OUTLINE_FG$`, `CROSSHAIR_OUTLINE_OPACITY%`, `CROSSHAIR_OUTLINE_WIDTH%` |
| Apron    | `APRON_ENABLED%` — TRUE=preserve off-canvas pixels in per-layer extended buffer; `APRON_SIZE_RATIO!` — fraction of canvas size (0.5 = ±50% extra on each side) |
| Undo     | `HISTORY_MAX_RECORDS` (1024)                            |
| Picker   | `PICKER_LOUPE_*` overlay layout, font, and colors |
| Preview / Panels | `PREVIEW_*` (incl. `PREVIEW_MODE%`, `PREVIEW_COLOR_PICK%`, `PREVIEW_BIN_QUICK_LOOK%`, `PREVIEW_FLOAT_IMAGE_PATH$`, `PREVIEW_FLOAT_LAST_DIR$`), `EDIT_BAR_VISIBLE%`, `EDIT_BAR_DOCK_POSITION$`, `LAYER_PANEL_WIDTH%`, `LAYERS_PANEL_DOCK_EDGE$`, `TOOLBOX_DOCK_EDGE$`, `ADV_BAR_DOCK_POSITION$`, `ADV_BAR_VISIBLE%`, `COLOR_MIXER_VISIBLE%`, `COLOR_MIXER_X%`, `COLOR_MIXER_Y%` |
| Palette UI | `PALETTE_SHOW_LOSPEC%`, `PALETTE_SHOW_CREATED%`, `PALETTE_CREATE_MAX_COLORS%`, `PALETTE_MENU_SHOW_CHIPS%` (color chips in the palette dropdown, default on) |
| AI       | `AI_ENABLED%` — master opt-in, **default 0**. While off, no AI menu, item, command, layer tag or status text is registered or drawn. Every AI action re-checks it, since actions are reachable by ID as well as through menus. Tools/styles/prompts live in a separate `DRAW.ai.cfg` |
| Crash    | `[CRASH]` section: `CRASH_LOGS_ENABLED` (TRUE/FALSE, default TRUE) — write crash reports to `<Desktop>/DRAW-log/DRAW-crash-logs/` |
| Drawer / Templates | `DEFAULT_DSET_*_FILE$`, `TEMPLATE_DIR$` |
| Export   | `BAS_EXPORT_BG_COLOR~&`, `BAS_WIP_ENABLED%` |
| Audio    | `SOUNDS_ENABLED%`, `SOUNDS_VOLUME%`, `SOUNDS_MUTED%`, `MUSIC_ENABLED%`, `MUSIC_VOLUME%`, `MUSIC_MUTED%`, `MIDI_SF2_FILE$` (path to SoundFont2 file; empty = built-in FM OPL3) |
| Cursor   | `SYSTEM_CURSORS_ENABLED%` — TRUE=OS native cursors for UI/canvas; FALSE=always custom PNG |
| Dialogs  | `FD_FONT%` (8=compact, 16=standard), `FD_FONT_SCALE%` (1-4) — font settings for FILE_DIALOG, COLOR_PICKER, MSG_BOX |
| Dirs     | `LAST_DIR_OPEN$`, `LAST_DIR_SAVE$`, `LAST_DIR_IMPORT$`, `LAST_DIR_EXPORT_BRUSH/LAYER$`, `LAST_DIR_PALETTE$`, `LAST_DIR_EXTRACT$` |

Defaults: DOT tool, brush size 1, square shape, 60 FPS, 128×128 canvas, 4 layers.

**Auto-Detection (first launch)**: When `UI_SCALE=0` (default), the master scale auto-detects — `SCREEN_detect_display_scale%` targets 90% of desktop resolution at highest integer scale (capped at 4) and `TOOLBAR_SCALE` derives from viewport height (≥800=4x, ≥600=3x, ≥400=2x, else 1x). Set `UI_SCALE=1..8` to drive the whole UI from one knob (it sets `DISPLAY_SCALE` and derives `TOOLBAR_SCALE` via `SCREEN_chrome_scale_from_display%`; per-widget `SCALE_RATIO_*` tune individual widgets). On Windows, `HIDPI_AWARE=1` (default) calls `SetProcessDPIAware` at the top of `SCREEN_init` so the desktop reports true pixels before auto-detect runs. On Linux, `LINUX_HIDPI_SCALE=TRUE` (opt-in, default off) makes `SCREEN_detect_linux_dpi_scale!` read the desktop display-scale (`QT_SCALE_FACTOR` → `GDK_DPI_SCALE` → `GDK_SCALE` → `QT_SCREEN_SCALE_FACTORS` → `Xft.dpi` via `xrdb`) and fold any factor > 1.0 into the same `SCREEN_DPI_DIVISOR!` seam Windows uses — correcting UI sizing on fractionally-scaled X11 desktops (Wayland pre-scales, so detection returns 1.0 and nothing is applied). Saved on first launch via `CONFIG_NEEDS_INITIAL_SAVE%`.

Command-line config helpers: `--config <file>` / `-c <file>` selects an explicit config file, `--config-upgrade` backfills newly-added keys into an existing config, and `--reset-defaults` overwrites the config with built-in factory defaults.

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
