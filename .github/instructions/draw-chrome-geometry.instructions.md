---
applyTo: "**/SCREEN.BM, **/SCREEN.BI, **/TOOLBAR.BI, **/TOOLBAR.BM, **/ORGANIZER.BI, **/ORGANIZER.BM, **/DRAWER.BI, **/DRAWER.BM, **/MENUBAR.BI, **/STATUS.BI, **/PALETTE-STRIP.BI, **/PALETTE-STRIP.BM, **/LAYERS.BI, **/EDITBAR.BI, **/EDITBAR.BM, **/ADVANCEDBAR.BI, **/ADVANCEDBAR.BM, **/PREVIEW.BI, **/SCROLLBAR.BI, **/CONFIG-THEME.BI"
---

# DRAW UI Chrome Geometry Reference

All dimensions are in **unscaled viewport pixels** unless noted. Elements in
the "toolbar column" (toolbar, organizer, drawer) scale by `CFG.TOOLBAR_SCALE%`
(1-4, referred to as **TB** below). Other elements use fixed pixel sizes.

---

## Overall Layout (Vertical Stacking)

The viewport (`SCRN.w&` × `SCRN.h&`) is the internal rendering resolution.
The OS window is `viewport × DISPLAY_SCALE`.

```
┌──────────────────────────────────────────────────────────┐
│  Menu Bar (12px, fixed, full width)                      │
├──────┬─────────────────────────────────────┬─────┬───────┤
│      │                                     │     │       │
│ Edit │       Canvas Work Area              │ TB  │ Layer │
│ Bar  │                                     │ Col │ Panel │
│(opt) │  (uiLeftEdge .. uiRightEdge)        │     │       │
│      │                                     ├─────┤       │
│      │                                     │ Org │       │
│      │                                     ├─────┤       │
│      │                                     │Drawr│       │
│      │                                     │     │       │
├──────┴─────────────────────────────────────┴─────┴───────┤
│  Status Bar (11px, fixed) + Palette Strip (dynamic)      │
└──────────────────────────────────────────────────────────┘
```

Panels dock LEFT or RIGHT via config (`CFG.TOOLBOX_DOCK_EDGE`,
`CFG.LAYERS_PANEL_DOCK_EDGE`, `EDIT_BAR.dockSide%`). The diagram shows the
default RIGHT toolbar + RIGHT layers + LEFT editbar arrangement.

Computed layout fields set by `SCREEN_compute_layout()`:
- `SCRN.uiLeftEdge%` / `SCRN.uiRightEdge%` — canvas work-area bounds
- `SCRN.toolboxX%` — toolbar column left X
- `SCRN.layerPanelX%` — layer panel left X
- `SCRN.editBarX%` — edit bar left X
- `SCRN.menuBarLeftEdge%` / `SCRN.menuBarRightEdge%` — menubar span

---

## Toolbar Column (Vertical Stack)

Stacked top-to-bottom inside the toolbar column. All elements in this column
scale by TB (`CFG.TOOLBAR_SCALE%`).

### Toolbar Buttons — `GUI/TOOLBAR.BI`

| Constant       | Value | Description            |
|----------------|-------|------------------------|
| `TB_BTN_W`     | 11    | Button width (native)  |
| `TB_BTN_H`     | 11    | Button height (native) |
| `TB_BTN_PADDING`| 1    | Gap between buttons    |
| `TB_COLS`      | 4     | Columns per row        |
| `TB_ROWS`      | 7     | Number of rows         |
| `TB_TOTAL`     | 28    | Total button count     |

**Scaled dimensions:**
```
buttonW    = TB_BTN_W × TB          = 11 × TB
buttonH    = TB_BTN_H × TB          = 11 × TB
gapH       = TB_BTN_PADDING × TB    =  1 × TB

toolbarH   = (TB_ROWS × buttonH) + ((TB_ROWS - 1) × gapH)
           = (7 × 11 × TB) + (6 × 1 × TB)
           = 83 × TB

toolboxW   = (TB_COLS × buttonW) + ((TB_COLS - 1) × gapH) + 2
           = (4 × 11 × TB) + (3 × 1 × TB) + 2
           = 47 × TB + 2
```

### Organizer — `GUI/ORGANIZER.BI`

Sits directly below toolbar. Same column width as toolbar.

| Constant     | Value | Description            |
|--------------|-------|------------------------|
| `ORG_COL_W`  | 11    | Column width (native)  |
| `ORG_ROW0_H` | 10   | Row 0 height           |
| `ORG_ROW1_H` | 10   | Row 1 height           |
| `ORG_ROW2_H` | 10   | Row 2 height           |
| `ORG_BRUSH_H`| 21   | Brush size (rows 0+1)  |
| `ORG_PADDING`| 1    | Gap between cells      |
| `ORG_COLS`   | 4    | Columns                |

**Layout:** 4 × 3 grid (11 widgets, brush-size spans rows 0+1)

**Scaled dimensions:**
```
organizerH = (3 × 10 × TB) + (2 × 1 × TB) = 32 × TB
organizerW = (4 × 11 × TB) + (3 × 1 × TB) = 47 × TB   (matches toolbar)
```

### Drawer Panel — `GUI/DRAWER.BI` + `GUI/DRAWER.BM`

Fills vertical space between Organizer bottom and Status+Palette Strip top.

| Constant / Source      | Default | Description                              |
|------------------------|---------|------------------------------------------|
| `DRAWER_GRID_COLS`     | 3       | Bin columns                              |
| `DRAWER_GRID_ROWS`     | 10      | Bin rows                                 |
| `DRAWER_SLOT_COUNT`    | 30      | Total slots (cols × rows)                |
| `THEME.BINS_BRUSH_WIDTH%`  | 9   | Bin cell width (unscaled)                |
| `THEME.BINS_BRUSH_HEIGHT%` | 9   | Bin cell height (unscaled)               |
| `THEME.DRAWER_BIN_GAP_X%` | 1   | Horizontal gap between bins (unscaled)   |
| `THEME.DRAWER_BIN_GAP_Y%` | 1   | Vertical gap between bins (unscaled)     |
| `THEME.DRAWER_PANEL_PAD_X%`| 1  | Panel horizontal padding (unscaled)      |
| `THEME.DRAWER_PANEL_PAD_Y%`| 1  | Panel vertical padding (unscaled)        |
| `THEME.DRAWER_PANEL_GAP_Y%`| 1  | Internal separator gap (unscaled)        |

**Bins area scaled dimensions (using defaults):**
```
binW       = BINS_BRUSH_WIDTH × TB    =  9 × TB  (min: 9 × TB)
binH       = BINS_BRUSH_HEIGHT × TB   =  9 × TB  (min: 9 × TB)
binGapX    = DRAWER_BIN_GAP_X × TB    =  1 × TB  (min: 1)
binGapY    = DRAWER_BIN_GAP_Y × TB    =  1 × TB  (min: 1)

binsH      = (ROWS × binH) + ((ROWS - 1) × binGapY)
           = (10 × 9 × TB) + (9 × 1 × TB)
           = 99 × TB

padY       = DRAWER_PANEL_PAD_Y × TB  =  1 × TB  (min: 1)
```

**Panel Y bounds:**
```
DRAWER.panelY1% = ORGANIZER.panelY2% + 1
DRAWER.panelY2% = SCRN.h& - toolbarBottomBars% - 1
  where toolbarBottomBars% = STATUS_height + PALETTE_STRIP_get_height%
```

**Mini-palette rail** occupies ~34% of panel width (right side):

| Source                            | Default | Description           |
|-----------------------------------|---------|----------------------|
| `THEME.DRAWER_MINI_PALETTE_COLS%` | 2       | Mini palette columns |
| `THEME.DRAWER_MINI_PALETTE_ROWS%` | 8       | Mini palette rows    |
| `THEME.DRAWER_MINI_PALETTE_CELL_W%` | 3     | Cell width (unscaled)|
| `THEME.DRAWER_MINI_PALETTE_CELL_H%` | 3     | Cell height (unscaled)|
| `THEME.DRAWER_MINI_PALETTE_GAP_X%`  | 1     | Cell gap X (unscaled)|
| `THEME.DRAWER_MINI_PALETTE_GAP_Y%`  | 1     | Cell gap Y (unscaled)|
| `THEME.DRAWER_MINI_PALETTE_PAGE_BTN_W%` | 3 | Page button W        |
| `THEME.DRAWER_MINI_PALETTE_PAGE_BTN_H%` | 3 | Page button H        |

---

## Full Toolbar Column Height (for `SCREEN_chrome_min_h&`)

```
Scaled elements (all × TB):
  Toolbar:   83
  Organizer: 32
  Drawer bins (10 rows): 10 × 7 + 9 × 1 = 79
  Drawer padding: 2 × 1 = 2
  ───────────
  Subtotal: 196 × TB

Fixed elements (never scaled):
  Organizer→Drawer gap: 1px
  Status bar:          11px
  Palette strip (min): 12px
  ───────────
  Subtotal: 24px

TOTAL = (196 × TB) + 24
```

*Examples: TB=1 → 220px, TB=2 → 416px, TB=3 → 612px, TB=4 → 808px*

---

## Menu Bar — `GUI/MENUBAR.BI`

**Always 12px tall. Never scales.** Spans `menuBarLeftEdge` to `menuBarRightEdge`
(inside layers+toolbox but outside editbar).

| Constant            | Value | Description                       |
|---------------------|-------|-----------------------------------|
| `MENU_BAR_HEIGHT`   | 12    | Bar height (8px font + 4px pad)   |
| `MENU_ITEM_HEIGHT`  | 12    | Submenu row height                |
| `MENU_DIVIDER_HEIGHT`| 5    | Submenu separator height          |
| `MENU_PAD_LEFT`     | 4     | Root label left padding           |
| `MENU_PAD_RIGHT`    | 4     | Root label right padding          |
| `MENU_ROOT_GAP`     | 8     | Gap between root labels           |
| `MENU_SUB_PAD_LEFT` | 16    | Submenu left pad (checkbox room)  |
| `MENU_SUB_PAD_RIGHT`| 8     | Submenu right padding             |
| `MENU_SUB_HOTKEY_GAP`| 16   | Gap: label → hotkey column        |
| `MENU_CHECK_WIDTH`  | 12    | Checkbox column width             |
| `MENU_MAX_ITEMS`    | 256   | Max total menu items              |
| `MENU_MAX_ROOT`     | 12    | Max root-level entries            |

---

## Status Bar — `CFG/CONFIG-THEME.BI`

| Source                  | Default | Description           |
|-------------------------|---------|----------------------|
| `THEME.STATUS_height%`  | 11      | Bar height (fixed px)|

Font: `THEME.GLOBAL_FONT_SIZE%` = 8pt. Full viewport width.

---

## Palette Strip — `GUI/PALETTE-STRIP.BI` + `GUI/PALETTE-STRIP.BM`

Sits below the canvas area, above or combined with the status bar.

| Constant / Source              | Default | Description                     |
|--------------------------------|---------|---------------------------------|
| `PALETTE_STRIP_ARROW_WIDTH`    | 12      | Left/right arrow button width   |
| `PALETTE_MENU_MIN_WIDTH`       | 180     | Minimum popup menu width        |
| `CFG.PALETTE_CHIP_WIDTH%`      | 16      | Color chip width                |
| `CFG.PALETTE_CHIP_HEIGHT%`     | 8       | Color chip height               |
| `CFG.PALETTE_MAX_CHIPS_PER_ROW%` | 32   | Max chips per row               |
| `CFG.PALETTE_MAX_ROWS%`        | 3       | Maximum palette rows            |
| `CFG.PALETTE_MIN_ROWS%`        | 1       | Minimum palette rows            |

**Dynamic height:**
```
row_height     = PALETTE_CHIP_HEIGHT + 1                = 9
strip_height   = (num_rows × row_height) + 3

Minimum (1 row): (1 × 9) + 3 = 12px
Maximum (3 rows): (3 × 9) + 3 = 30px
```

---

## Layer Panel — `GUI/LAYERS.BI`

| Constant / Source                  | Default | Description              |
|------------------------------------|---------|--------------------------|
| `CFG.LAYER_PANEL_WIDTH%`           | 100     | Panel width (min 40)     |
| `LAYER_ROW_HEIGHT`                 | 20      | Per-layer row height     |
| `LAYER_BTN_SIZE`                   | 12      | Icon button size         |
| `LAYER_NAME_HARD_MAX`              | 64      | Max name characters      |
| `THEME.LAYER_PANEL_header_height%` | 16      | Header bar height        |
| `THEME.LAYER_PANEL_btn_bar_height%`| 16      | Button bar height        |

Full viewport height (minus menu bar and status/palette strip areas).

---

## Edit Bar — `GUI/EDITBAR.BI`

| Constant / Source                      | Default | Description          |
|----------------------------------------|---------|----------------------|
| `THEME.EDIT_BAR_WIDTH%`               | 18      | Bar content width    |
| `THEME.EDIT_BAR_LEFT_BORDER_WIDTH%`   | 1       | Left border width    |
| `THEME.EDIT_BAR_RIGHT_BORDER_WIDTH%`  | 1       | Right border width   |
| `EDITBAR_TOTAL_SLOTS`                 | 25      | Slots (20 + 5 divs) |
| `EDITBAR_ACTION_SLOTS`                | 20      | Clickable icons      |
| `EDITBAR_DOCK_LEFT`                   | 0       | Dock side constant   |
| `EDITBAR_DOCK_RIGHT`                  | 1       | Dock side constant   |

**Total width:** `EDIT_BAR_WIDTH + LEFT_BORDER + RIGHT_BORDER = 18 + 1 + 1 = 20px`

Hidden by default (`SCRN.showEditBar% = FALSE`).

---

## Advanced Bar — `GUI/ADVANCEDBAR.BI`

| Constant / Source                      | Default | Description          |
|----------------------------------------|---------|----------------------|
| `THEME.ADV_BAR_WIDTH%`                | 18      | Bar content width    |
| `THEME.ADV_BAR_LEFT_BORDER_WIDTH%`    | 1       | Left border width    |
| `THEME.ADV_BAR_RIGHT_BORDER_WIDTH%`   | 1       | Right border width   |
| `ADVBAR_DOCK_LEFT`                    | 0       | Dock side constant   |
| `ADVBAR_DOCK_RIGHT`                   | 1       | Dock side constant   |

**Total width:** `ADV_BAR_WIDTH + LEFT_BORDER + RIGHT_BORDER = 18 + 1 + 1 = 20px`

Hidden by default (`SCRN.showAdvBar% = FALSE`). Docks independently from EditBar.

---

## Preview Window — `GUI/PREVIEW.BI`

Floating, draggable, resizable window. Not part of the layout chrome calculation.

| Constant / Source                  | Default | Description           |
|------------------------------------|---------|-----------------------|
| `PREVIEW_DEFAULT_W`               | 120     | Initial width         |
| `PREVIEW_DEFAULT_H`               | 100     | Initial height        |
| `PREVIEW_MIN_W`                   | 120     | Minimum width         |
| `PREVIEW_MIN_H`                   | 100     | Minimum height        |
| `THEME.PREVIEW_title_height%`     | 14      | Title bar height      |
| `THEME.PREVIEW_border_width%`     | 1       | Border stroke width   |
| `THEME.PREVIEW_resize_handle_size%`| 6      | Resize handle area    |
| `THEME.PREVIEW_button_width%`     | 12      | Close/minimize button W|
| `THEME.PREVIEW_button_height%`    | 10      | Close/minimize button H|
| `THEME.PREVIEW_checkbox_size%`    | 8       | Checkbox size         |
| `THEME.PREVIEW_padding%`          | 2       | Content padding       |
| `THEME.PREVIEW_initial_padding%`  | 8       | Edge pad on first open|
| `THEME.PREVIEW_font_size%`        | 8       | Font point size       |

---

## Scrollbar — `GUI/SCROLLBAR.BI`

| Constant              | Value | Description             |
|-----------------------|-------|-------------------------|
| `SCROLLBAR_THICKNESS` | 8     | Width/height of bar     |
| `SCROLLBAR_MIN_THUMB` | 16    | Minimum thumb size      |
| `SCROLLBAR_GAP`       | 2     | Gap from adjacent GUI   |

---

## Command Palette — `CFG/CONFIG-THEME.BI`

| Source                          | Default | Description              |
|---------------------------------|---------|--------------------------|
| `THEME.CMD_PALETTE_width_ratio!`| 0.55    | Width as fraction of viewport|
| `THEME.CMD_PALETTE_min_width%`  | 280     | Minimum width            |
| `THEME.CMD_PALETTE_max_width%`  | 500     | Maximum width            |
| `THEME.CMD_PALETTE_top%`        | 40      | Top Y position           |

---

## Dialog Chrome — `CFG/CONFIG-THEME.BI`

| Source                              | Default | Description              |
|-------------------------------------|---------|--------------------------|
| `THEME.DIALOG_title_height%`        | 17      | Title bar bottom Y       |
| `THEME.DIALOG_slider_height%`       | 14      | Slider track height      |
| `THEME.DIALOG_preview_handle_size%` | 5       | Split handle half-size   |
| `THEME.DIALOG_font_size%`           | 8       | Font point size          |

---

## Popup Menu — `GUI/POPUP-MENU.BI`

| Constant                  | Value | Description         |
|---------------------------|-------|---------------------|
| `POPUP_MENU_MAX_ITEMS`    | 24    | Max menu items      |
| `POPUP_MENU_FLAG_DIVIDER` | 1     | Divider flag        |
| `POPUP_MENU_FLAG_DISABLED`| 2     | Disabled flag       |
| `POPUP_MENU_FLAG_CHECKED` | 4     | Checked flag        |

---

## Tooltip — `GUI/TOOLTIP.BI`

Sources: `TOOLTIP_SRC_NONE = 0`, `TOOLTIP_SRC_TOOLBAR = 1`,
`TOOLTIP_SRC_ORGANIZER = 2`, `TOOLTIP_SRC_MINI_PAL = 3`.
Dimensions computed dynamically from text content.

---

## Transform Overlay — `CFG/CONFIG-THEME.BI`

| Source                             | Default | Description              |
|------------------------------------|---------|--------------------------|
| `THEME.TRANSFORM_FRAME_HANDLE_SIZE%`| 5      | Handle half-size (px)    |

---

## Fonts

| Source                   | Default               | Description        |
|--------------------------|-----------------------|--------------------|
| `THEME.GLOBAL_FONT_FILE$`| `Tiny5-Regular.ttf`  | Primary UI font    |
| `THEME.GLOBAL_FONT_SIZE%`| 8                    | Size in points     |

---

## Minimum Viewport Formulas (`OUTPUT/SCREEN.BM`)

### Minimum Width — `SCREEN_chrome_min_w&(TB)`
```
toolboxW    = 4 × (11 × TB) + 3 × (1 × TB) + 2  = 47 × TB + 2
layerPanel  = 100
editBar     = 20
minCanvas   = 320

TOTAL       = toolboxW + layerPanel + editBar + minCanvas
            = (47 × TB + 2) + 100 + 20 + 320
            = 47 × TB + 442
```

*Examples: TB=1 → 489px, TB=2 → 536px, TB=3 → 583px, TB=4 → 630px*

### Minimum Height — `SCREEN_chrome_min_h&(TB)`
```
Toolbar column: (196 × TB) + 24     (see breakdown above)
Canvas column:  235                   (12 menu + 200 canvas + 11 status + 12 palette)

TOTAL = MAX(toolbar column, canvas column)
```

*Examples: TB=1 → 235px, TB=2 → 416px, TB=3 → 612px, TB=4 → 808px*

---

## Scaling Reference

| Element               | Scales with    | Default at TB=2 |
|-----------------------|----------------|-----------------|
| Toolbar buttons       | TB             | 22×22 + 2px gap |
| Organizer widgets     | TB             | 22×20           |
| Drawer bins           | TB             | 18×18 + 2px gap |
| Menu bar              | Fixed          | 12px            |
| Status bar            | Fixed          | 11px            |
| Palette strip         | Fixed          | 12-30px         |
| Layer panel width     | Fixed          | 100px           |
| Edit bar width        | Fixed          | 20px            |
| Scrollbars            | Fixed          | 8px             |
| Preview window        | Fixed          | 120×100 default |
