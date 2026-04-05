---
applyTo: "**/MENUBAR.BM, **/COMMAND.BM, **/TOOLBAR.BM, **/TOOLBAR.BI, **/ORGANIZER.BM, **/ORGANIZER.BI, **/EDITBAR.BM, **/EDITBAR.BI, **/ADVANCEDBAR.BM, **/ADVANCEDBAR.BI, **/TOOLTIP.BM, **/TOOLTIP.BI, **/SETTINGS.BM, **/SETTINGS.BI, **/SETTINGS-TABS.BM, **/SETTINGS-WIDGETS.BM"
---

# DRAW — UI: Menus, Commands, Toolbar, Organizer, Edit Bar

---

## Menu Bar (`GUI/MENUBAR.BI` / `GUI/MENUBAR.BM`, ~1382 lines)

Root menus (indices 0–10): FILE(0), EDIT(1), VIEW(2), SELECT(3), TOOLS(4), BRUSH(5), LAYER(6), PALETTE(7), IMAGE(8), HELP(9), AUDIO(10)

- **ALT tap toggle**: ALT pressed then released without other keys → toggle FILE menu
- **Keyboard nav (`kbActive%`)**: Arrow keys navigate items. When `kbActive% = TRUE`, mouse hover is ignored until mouse actually moves.
- **Recent files submenu**: Cascading submenu for action ID 213. Right arrow opens, Left/Escape closes.
- **Cascading submenus**: Any menu item marked as a submenu parent gets a `▶` indicator and spawns a child submenu on hover/right-arrow. Managed by `MENUBAR_cascading_submenu_*` helpers. Used by Recent Files (213), Layout (442), Transform (330), Preview Window (2012), and Preview Recent (2018).
- **Layout submenu**: Under View → Layout; dock left/right actions for Toolbox (443/444), Layer Panel (445/446), Edit Bar (447/448), Character Map (2051/2052).
- **Dynamic state sync**: `MENUBAR_update_checkboxes` syncs checkboxes from live state (grid, snap, tool visibility, undo/redo availability, recent files).
- **Click dispatch**: `MENUBAR_handle_click` → `CMD_execute_action(item.actionId)`

---

## Command System (`GUI/COMMAND.BI` / `GUI/COMMAND.BM`, ~1992 lines)

`CMD_execute_action(action_id%)` — central dispatcher for ALL application actions (menus, keyboard shortcuts, command palette, toolbar clicks).

### Action ID Ranges

| Range     | Category     | Key Actions |
| --------- | ------------ | ----------- |
| 101–118   | Tools        | Brush, Dot, Fill, Picker, Line, Polygon, Rect, Ellipse, Marquee, Move, Text, MagicWand, Eraser |
| 201–217   | File         | Open, Save, SaveAs, Export, ExportSelection, Import, New, Template, Revert, Recent, Exit, ExtractImages(214), OpenAseprite(215), OpenPSD(216), ExportAsFlyout(217) |
| 301–324   | Edit         | Undo, Redo, Copy, Cut, Paste, Clear, SelectAll, Fill FG/BG, Flip, Scale, Rotate, CopyToNewLayer, StrokeSelection |
| 325–330   | Transform    | Overlay modes: Scale(325), Distort(326), Perspective(327), Rotate(328), Shear(329); 330=TRANSFORM_ACT_FLYOUT (opens the TRANSFORM... submenu) |
| 401–451   | View/Audio   | Toolbar, StatusBar, LayerPanel, MenuBar, Zoom, DisplayScale (408=Up/409=Down/416=Reset), BrushCursorToggle(412), Preview Window (434=toggle), Edit Bar (435=toggle), Left/Right Side UI (436/437), Pattern Tile Mode (440=toggle), Canvas Border (441), Layout Submenu (442 parent, 443–448 dock left/right for Toolbox/LayerPanel/EditBar), Advanced Bar (449=toggle, 450/451 dock left/right), SFX/Music controls (427=NextTrack, 428=PrevTrack, 429=RandomMOD, 430=RandomIT, 431=RandomXM, 432=RandomRAD, 433=RandomAny) |
| 501–517   | Color        | Opacity presets (10–100%), Swap FG/BG |
| 601–609   | Brush        | Size dec/inc, presets, preview, shape, pixel perfect |
| 701–714   | Layer        | New, Delete, MoveUp/Down, MergeDown, MergeVisible, Duplicate, ArrangeTop/Bottom, ExportLayerPNG, MergeSelected, NewTextLayer(712), RasterizeText(713), RasterizeAllText(714) |
| 801–802   | Canvas       | Pan, Reset Pan |
| 901–909   | Grid/Fill    | Toggle, Pixel Grid, Snap, Size, AlignMode, MatchBrush, CellFill, Fill Adjustment Mode (909) |
| 1001–1003 | Symmetry     | Cycle, Clear, Set Center |
| 1101–1112 | Custom Brush | Capture, Clear, Recolor, Outline, Flip, Scale, Export, Rotate |
| 1201–1206 | Assistants   | Constrain, AngleSnap, Square/Circle, Center, Clone, TempPicker |
| 1401–1414 | Selection    | SelectFromLayer, Nudge 1/10px, Expand/Contract, SelectFromSelectedLayers |
| 1501–1517 | Palette/Ref  | RefImage, GPL Import (1510), GPL Export (1511), Random, Color Picker, Swap FG/BG, Load from Lospec, Create from Image, Remap to Palette, Show Lospec Palettes |
| 1601–1609 | Help/Tools   | About, CheatSheet, Manual, GitHub, Issues, Credits, PixelArtAnalyzer(1609) |
| 1701–1704 | Tools (menu) | Zoom, Spray, CmdPalette, CodeExport |
| 1801–1804 | Canvas       | Resize dialog (1801), Crop dialog (1802), FlipCanvasH(1803), FlipCanvasV(1804) |
| 1911–1914 | Drawer Sets  | Load, Save, Clear, Explore drawer-set folder |
| 2001–2010 | Image Adj    | BrightnessContrast, HueSaturation, Levels, ColorBalance, Blur, Sharpen, Invert, Desaturate, Posterize, Pixelate |
| 2012–2020 | Preview Win  | PreviewWindowSubmenu(2012), FollowMode(2013), FloatingImageMode(2014), BinQuickLook(2015), AllowColorPicking(2016), LoadImage(2017), RecentImages(2018), ClearRecentImages(2019), GrayscalePreview(2020) |
| 2050–2054 | Character Map | ToggleCharMap(2050), DockLeft(2051), DockRight(2052), ToggleCharGrid(2053), ToggleSnapToCharGrid(2054) |
| 2201–2216 | Export As    | ExportPNGNative(2201), ExportPNG(2204), ExportGIF(2205), ExportJPG(2206), ExportTGA(2208), ExportBMP(2209), ExportHDR(2210), ExportICO(2211), ExportQOI(2216) |

### Command Palette

Opened with Ctrl+Shift+P. Fuzzy search (`CMD_fuzzy_match%`) checks characters appear in order. Keyboard navigation: up/down/page. Mouse click to execute.

---

## Toolbar (`GUI/TOOLBAR.BI` / `GUI/TOOLBAR.BM`)

4-column layout. `TOOLBAR_BUTTON_ORDER(27)` maps position → icon constant. `TOOLBAR_BUTTON_TO_TOOL(27)` maps position → tool constant.

Row layout (left→right):

```
Row 0: Move          | Pan            | Zoom           | Crop
Row 1: Select Rect   | Select Free    | Select Poly    | Select Ellipse
Row 2: Select Wand   | Picker         | Text           | Eraser
Row 3: Dot           | Brush          | Spray          | Fill
Row 4: Line          | Polygon        | Polygon Fill   | Save
Row 5: Rect          | Rect Filled    | Export Sel     | QB64 Export
Row 6: Help          | Ellipse        | Ellipse Fill   | Open
```

Icon PNGs: `ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/*.png`

### Active Button Indicator

1. Filled rect (`LINE ... BF`) in `THEME.TOOLBAR_btn_overlay~&` over the whole button
2. Four non-overlapping border rects in `THEME.TOOLBAR_btn_stroke~&`

Four-rect approach (not `LINE ... B`) avoids double alpha-compositing at corners.

### Marquee Variant Tracking

All 5 marquee variants set `CURRENT_TOOL% = TOOL_MARQUEE` but `MARQUEE.VARIANT` stores which variant (`TOOL_SELECT_*`). The toolbar checks `MARQUEE.VARIANT` when highlighting the active button. Set it in every activation path (toolbar, keyboard, command).

Each variant maps to a distinct cursor via `POINTER_marquee_cursor_for_variant%`:
`TOOL_SELECT_RECT`→13, `_FREE`→14, `_POLY`→15, `_ELLIPSE`→16, `_WAND`→11, fallback→5

---

## Organizer Panel (`GUI/ORGANIZER.BI` / `GUI/ORGANIZER.BM`, ~642 lines)

4×3 grid of widget buttons beneath the toolbar. 11 slots (Brush Size spans 2 rows):

| Slot | ID                | Purpose        | Mousewheel Action |
| ---- | ----------------- | -------------- | ----------------- |
| 2    | ORG_BRUSH_SIZE    | Brush size     | Cycles 4 size presets |
| 4    | ORG_PALETTE_OPS   | Palette ops    | Toggles palette ops mode on/off |
| 7    | ORG_SYMMETRY_MODE | Symmetry       | Cycles 4 states (off + 3 modes) |
| 8    | ORG_GRID_VIS      | Grid visibility| Cycles grid modes (must call `GRID_draw`) |
| 9    | ORG_GRID_SNAP     | Grid snap      | Toggles snap + alignment |

Layout:
```
Row 0: [COLOR OPS]     [CANVAS OPS]    [BRUSH SIZE top]  [PATTERN MODE]
Row 1: [PALETTE OPS]   [TRANSFORM OPS] [BRUSH SIZE bot]  [GRADIENT MODE]
Row 2: [SYMMETRY MODE] [GRID VIS]      [GRID SNAP]       [COLOR MODE]
```

Each widget has up to 4 state images loaded from the theme directory. Icon filenames in code must exactly match filenames on disk.

## Drawer Panel (`GUI/DRAWER.BI` / `GUI/DRAWER.BM`)

30-slot panel rendered directly beneath the organizer in a 3×10 grid. The drawer has three modes: Brush, Pattern, and Gradient.

- `F1` → Brush drawer
- `F2` → Gradient drawer
- `F3` → Pattern drawer
- Left-click slot: select slot and activate the corresponding paint mode
- `Shift+Left Click` slot: store current brush / clipboard image / FG→BG gradient into the slot
- Right-click slot: open slot context menu
- Middle-click slot: cycle drawer mode (Brush → Pattern → Gradient)
- `Shift+Middle Click` slot: clear the clicked slot
- `Shift+Right Click` slot: queue slot import via deferred dialog
- Mini palette left/right clicks set FG/BG directly

Brush drawer slots load into the custom brush pipeline. Pattern and gradient drawers switch `DRAWER.paintMode%` for the active drawing tools.

The drawer context menu uses `POPUP_MENU_*` helpers and exposes mode-specific actions plus drawer-set management: load `.dset`, save `.dset`, clear active set, explore folder, and gradient editing when in gradient mode.

## Preview Window (`GUI/PREVIEW.BI` / `GUI/PREVIEW.BM`)

Floating live preview panel toggled with `F4` / action ID `434`.

- Title-bar drag to move
- Resize handle in the bottom-right corner
- Independent wheel zoom and pan when follow-pointer is off
- Follow-pointer checkbox lives in the title bar and persists to config
- Minimize/close buttons live in the title bar
- Position is clamped to the current work area so the window stays recoverable
- **Two modes**: `PREVIEW_MODE_FOLLOW` (0) = canvas magnifier tracking pointer, `PREVIEW_MODE_FLOAT` (1) = display a loaded image file
- **Bin Quick Look**: When enabled (`CFG.PREVIEW_BIN_QUICK_LOOK%`), hovering a drawer slot shows its brush/pattern/gradient content in the preview pane; managed by `binQuickLookActive%`, `binQuickLookSlot%`, `binQuickLookImg&`
- **Color Picking**: When enabled (`CFG.PREVIEW_COLOR_PICK%`), Alt+click inside the preview samples FG color, Alt+right-click samples BG; dispatched by `PREVIEW_pick_color_at`
- **Recent Preview Images**: Up to 10 recently loaded floating images tracked via `RECENT_PREVIEW_FILES()` / `RECENT_PREVIEW_COUNT%`; managed by `RECENT_PREVIEW_add_file` / `RECENT_PREVIEW_clear`
- **Cascading submenus**: View → Preview Window (action 2012) with child items Follow(2013), Float(2014), Bin Quick Look(2015), Color Pick(2016), Load Image(2017), Recent(2018), Clear Recent(2019); menu state in `MENU_BAR.pvw*` / `MENU_BAR.pvwRecent*` fields

---

## Edit Bar (`GUI/EDITBAR.BI` / `GUI/EDITBAR.BM`)

Vertical icon bar that mirrors Edit menu actions as clickable icon buttons. Dockable LEFT (adjacent to layers panel) or RIGHT (adjacent to toolbox/drawer). Toggle with F5 or action ID 435.

- **25 slots**: 20 action icons + 5 dividers
- **Groups**: History (Undo/Redo) | Clipboard (Cut/Copy/CopyMerged/Paste/PasteInPlace) | Layer ops (CutToLayer/CopyToLayer) | Clear | Fill/Stroke (FillFG/FillBG/StrokeSelection) | Quick transforms (FlipH/FlipV/Scale-/Scale+/RotateCW/RotateCCW)
- **Config**: `EDIT_BAR_VISIBLE%`, `EDIT_BAR_DOCK_POSITION$` ("LEFT"/"RIGHT")
- **Theme fields**: `EDIT_BAR_WIDTH%`, `EDIT_BAR_*_BORDER_WIDTH%`, `EDIT_BAR_ICON_PADDING%`, `EDIT_BAR_DISABLED_ALPHA%`, plus 20 `EDIT_BAR_ICON_*$` filename strings and color fields (`EDIT_BAR_BG~&`, `EDIT_BAR_HOVER~&`, `EDIT_BAR_BORDER*~&`)
- **Icon dir**: `ASSETS/THEMES/DEFAULT/IMAGES/EDITBAR/*.png`

### Disabled Icon Dimming

When an action is unavailable (e.g., Undo when history is empty, Paste when clipboard is empty), the icon is rendered with reduced alpha (`EDIT_BAR_DISABLED_ALPHA%`). The button is visually dimmed and unclickable, providing clear feedback about which actions are currently enabled.

### Lazy Icon Loading (Critical Pattern)

Icons are loaded in `EDITBAR_load_icons`, called on **first render** — NOT in `EDITBAR_init`. This is mandatory because `EDITBAR_init` runs inside `SCREEN_init` (called inline from `SCREEN.BI`, `_ALL.BI` line 70), but `THEME.BI` (line 121) sets compiled-in icon filename defaults **after** `SCREEN_init` executes. Reading `THEME.EDIT_BAR_ICON_*$` in init returns empty strings, causing `_LOADIMAGE` to receive a bare directory path and crash with `std::bad_alloc`.

The `iconsLoaded%` flag guards one-time loading in `EDITBAR_render`:

```qb64
IF NOT EDIT_BAR.iconsLoaded% THEN
    EDITBAR_load_icons
END IF
```

### Auto-Hide Visibility Pattern

`EDITBAR_init` follows the `PREVIEW_init` pattern for default-hidden panels: sets `showEditBar% = FALSE` + `editBarManuallyHidden% = TRUE`, only clearing `ManuallyHidden` when config says visible. Without this, the auto-hide restore logic makes the panel visible on the first frame.

---

## Advanced Bar (`GUI/ADVANCEDBAR.BI` / `GUI/ADVANCEDBAR.BM`)

Vertical icon bar with 26+ quick-access toggle buttons for view options, tool toggles, and feature controls. Dockable LEFT or RIGHT (independently from EditBar). Toggle with Shift+F5 or action ID 449.

- **26+ slots**: Toggle icons with dividers, organized by category (View, Grid, Brush, Reference, Layer Distribution, etc.)
- **Buttons include**: Char Map, Char Grid, Char Snap, Preview, EditBar, Tile Preview, Grid Cell Fill, Grid Show, Fill Adjust, Brush Edges, Angle Snap, Grayscale Preview, Ref Image controls, Distribute Layers, Crosshair, and more
- **Config**: `ADVANCEDBAR_VISIBLE%`, `ADVANCEDBAR_DOCK_POSITION$` ("LEFT"/"RIGHT")
- **Theme fields**: `ADV_BAR_WIDTH%`, `ADV_BAR_*_BORDER_WIDTH%`, `ADV_BAR_ICON_PADDING%`, plus 26 `ADV_BAR_ICON_*$` filename strings and color fields (`ADV_BAR_BG~&`, `ADV_BAR_HOVER~&`, `ADV_BAR_BORDER*~&`)
- **Icon dir**: `ASSETS/THEMES/DEFAULT/IMAGES/ADVANCEDBAR/*.png`
- **Disabled dimming**: Unavailable toggles render with reduced alpha and are unclickable
- **Lazy icon loading**: Same pattern as EditBar — `ADVBAR_load_icons` on first render, not init
- **Auto-hide visibility**: Same `PREVIEW_init` pattern as EditBar — `showAdvBar% = FALSE` + `advBarManuallyHidden% = TRUE` by default

---

## Settings Dialog (`GUI/SETTINGS.BI` / `GUI/SETTINGS.BM` / `GUI/SETTINGS-TABS.BM` / `GUI/SETTINGS-WIDGETS.BM`)

GIMP-style tabbed settings dialog opened with `Ctrl+,` (action ID `ACTION_SETTINGS = 2100`). Modal dialog with left sidebar tabs and scrollable right content area.

### 8 Tabs

| Index | Constant | Tab |
| ----- | -------- | --- |
| 0 | `SETTINGS_TAB_GENERAL` | General |
| 1 | `SETTINGS_TAB_GRID` | Grid & Guides |
| 2 | `SETTINGS_TAB_PALETTE` | Palette |
| 3 | `SETTINGS_TAB_PANELS` | Panels |
| 4 | `SETTINGS_TAB_AUDIO` | Audio |
| 5 | `SETTINGS_TAB_FONTS` | Fonts & Text |
| 6 | `SETTINGS_TAB_APPEARANCE` | Appearance |
| 7 | `SETTINGS_TAB_DIRS` | Directories |

### Architecture

- **Shadow config pattern**: On open, a shadow copy of `CFG` is created. All edits modify the shadow. OK/Apply writes the shadow back to `CFG`; Cancel discards it.
- **Pending changes tracking**: `pendingChanges%` flag enables/disables the Apply button.
- **Layout**: 600×380 unscaled dialog. Left sidebar for tab buttons, right area scrollable content.
- **OK / Cancel / Apply** buttons along the bottom.
- **Widget helpers**: `SETTINGS-WIDGETS.BM` provides reusable checkbox, slider, dropdown, and color-swatch widget rendering/hit-testing.
- **Tab renderers**: `SETTINGS-TABS.BM` contains per-tab content rendering and input handling.
