# DRAW — UI: Menus, Commands, Toolbar, Organizer, Edit Bar

---

## Menu Bar (`GUI/MENUBAR.BI` / `GUI/MENUBAR.BM`, ~1382 lines)

Root menus (indices 0–10): FILE(0), EDIT(1), VIEW(2), SELECT(3), TOOLS(4), BRUSH(5), LAYER(6), PALETTE(7), IMAGE(8), HELP(9), AUDIO(10), plus **AI** — registered only when `CFG.AI_ENABLED` is on, so its root index is not fixed. `MENUBAR_rebuild` is called when the flag is toggled so the menu appears/disappears immediately.

**`MENU_MAX_ITEMS` is 400** (raised from 300 when the crash-log items landed at 298/300). `MENUBAR_register_item` drops overflow **silently** — past the cap a new menu item simply never appears, with no error. Check the current total before adding items.

- **ALT tap toggle**: ALT pressed then released without other keys → toggle FILE menu
- **Keyboard nav (`kbActive%`)**: Arrow keys navigate items. When `kbActive% = TRUE`, mouse hover is ignored until mouse actually moves.
- **Recent files submenu**: Cascading submenu for action ID 213. Right arrow opens, Left/Escape closes.
- **Cascading submenus**: Any menu item marked as a submenu parent gets a `▶` indicator and spawns a child submenu on hover/right-arrow. Managed by `MENUBAR_cascading_submenu_*` helpers. Used by Recent Files (213), Layout (442), Transform (330), Preview Window (2012), and Preview Recent (2018).
- **Layout submenu**: Under View → Layout; 10 items — dock left/right actions for Toolbox (443/444), Layer Panel (445/446), Edit Bar (447/448), Character Map (2051/2052), Advanced Bar (450/451).
- **Dynamic state sync**: `MENUBAR_update_checkboxes` syncs checkboxes from live state (grid, snap, tool visibility, undo/redo availability, recent files).
- **Click dispatch**: `MENUBAR_handle_click` → `CMD_execute_action(item.actionId)`

---

## Command System (`GUI/COMMAND.BI` / `GUI/COMMAND.BM`, ~1992 lines)

`CMD_execute_action(action_id%)` — central dispatcher for ALL application actions (menus, keyboard shortcuts, command palette, toolbar clicks).

### Action ID Ranges

| Range     | Category     | Key Actions |
| --------- | ------------ | ----------- |
| 101–118   | Tools        | Brush, Dot, Fill, Picker, Line, Polygon, Rect, Ellipse, Marquee, Move, Text, MagicWand, Eraser |
| 201–219   | File         | Open, Save, SaveAs(204, image), SaveProjectAs(203, native .draw → DRW_save_dialog), Export, ExportSelection, Import, New, Template, Revert, Recent, Exit, ExtractImages(214), OpenAseprite(215), OpenPSD(216), ExportAsFlyout(217), ExtractFromGrid(218), ExtractToLayersFromGrid(219) |
| 301–324   | Edit         | Undo, Redo, Copy, Cut, Paste, Clear, SelectAll, Fill FG/BG, Flip, Scale, Rotate, CopyToNewLayer, StrokeSelection |
| 325–330   | Transform    | Overlay modes: Scale(325), Distort(326), Perspective(327), Rotate(328), Shear(329); 330=TRANSFORM_ACT_FLYOUT (opens the TRANSFORM... submenu) |
| 401–453   | View/Audio   | Toolbar, StatusBar, LayerPanel, MenuBar, Zoom, DisplayScale (408=Up/409=Down/416=Reset), BrushCursorToggle(412), Preview Window (434=toggle), Edit Bar (435=toggle), Left/Right Side UI (436/437), Pattern Tile Mode (440=toggle), Canvas Border (441), Layout Submenu (442 parent, 443–448 dock left/right for Toolbox/LayerPanel/EditBar), Advanced Bar (449=toggle, 450/451 dock left/right), Fullscreen (453=toggle — mirrors the native `Alt+Enter`/`_ALLOWFULLSCREEN`; the menu checkmark tracks `CFG.FULLSCREEN%`, kept in sync each frame with live `_FULLSCREEN()` in `DRAW.BAS`), SFX/Music controls (427=NextTrack, 428=PrevTrack, 429=RandomMOD, 430=RandomIT, 431=RandomXM, 432=RandomRAD, 433=RandomAny) |
| 470–473   | View (Pan)   | Pan Canvas Up(470)/Down(471)/Left(472)/Right(473) — step = `CANVAS_PAN_STEP` (40px). Bindable to the mouse wheel/tilt in Customize Controls (default: unbound; the vertical wheel keeps zoom). |
| 501–517   | Color        | Opacity presets (10–100%), Swap FG/BG |
| 601–609   | Brush        | Size dec/inc, presets, preview, shape, pixel perfect |
| 701–734   | Layer        | New, Delete, MoveUp/Down, MergeDown, MergeVisible, Duplicate, ArrangeTop/Bottom, ExportLayerPNG, MergeSelected, NewTextLayer(712), RasterizeText(713), RasterizeAllText(714), NewGroup(720), GroupFromSelection(721), Ungroup(722), MergeGroup(723), ToggleCollapse(724), SelectAllInGroup(725), RenameLayer(726), SelectionFromGroup(727), SelectionFromLayer(728), ConvertToSymbol(730), NewSymbolLayer(731), AddSymbolInstance(732), SyncSymbols(733), RasterizeSymbol(734) |
| 801–802   | Canvas       | Pan, Reset Pan |
| 901–911   | Grid/Fill    | Toggle, Pixel Grid, Snap, Size, AlignMode, MatchBrush, CellFill, Fill Adjustment Mode (909), Smart Guides Enable (910), Smart Guides Snap (911) |
| 950–957   | CRT Effect   | ToggleCRT(950, Ctrl+Alt+O), CRTSettingsDialog(951 → `DIALOG_CRT_open`), Scanlines(952), PhosphorMask(953), Vignette(954), VerticalScanlines(955), CycleTint(957) — all toggle `CFG.CRT_*` + set `CRT.dirty%` |
| 1001–1003 | Symmetry     | Cycle, Clear, Set Center |
| 1101–1112 | Custom Brush | Capture, Clear, Recolor, Outline, Flip, Scale, Export, Rotate |
| 1201–1206 | Assistants   | Constrain, AngleSnap, Square/Circle, Center, Clone, TempPicker |
| 1401–1414 | Selection    | SelectFromLayer, Nudge 1/10px, Expand/Contract, SelectFromSelectedLayers |
| 1501–1519 | Palette/Ref  | RefImage, GPL Import (1510), GPL Export (1511), Random, Color Picker, Swap FG/BG, Load from Lospec, Create from Image, Remap to Palette, Show Lospec Palettes, ShowColorChipsInMenu(1519) |
| 1601–1611 | Help/Tools   | About, CheatSheet, Manual, GitHub, Issues, Credits, Examples(1607), ShowTooltips(1608), PixelArtAnalyzer(1609), CaptureCrashLogs(1610), CrashLogsFolder(1611) |
| 1701–1704 | Tools (menu) | Zoom, Spray, CmdPalette, CodeExport |
| 1801–1805 | Canvas       | Resize dialog (1801), Crop dialog (1802), FlipCanvasH(1803), FlipCanvasV(1804), Resize Image with Content (1805) |
| 1820–1828 | AI           | NewAILayer(1820), RegenerateLayer(1821), CancelGeneration(1822), ToolsDialog(1823), ToggleAIFeatures(1824), NewFromAI(1825), EditPrompt(1826), StyleEditor(1827), PromptEditor(1828) |

> **⚠ Duplicate `CASE` labels compile silently — always grep before allocating an ID.**
> `CMD_execute_action` is a single `SELECT CASE action_id%` spanning
> `GUI/COMMAND.BM:719`–`:5120`. BASIC takes the **first** matching `CASE` and jumps to
> `END SELECT`, so a second `CASE` with the same value is unreachable dead code.
> QB64-PE emits no warning for this, and at ~4,400 lines the duplicate is invisible
> to review.
>
> **Fixed in 1.7.0:** the AI actions originally shipped as 1801–1809, shadowing the
> Canvas actions of the same IDs. Image → Resize Canvas / Crop / Flip H / Flip V did
> nothing, and Resize Image with Content silently toggled AI features. AI was
> renumbered to 1820–1828 (`GUI/COMMAND.BM`, `GUI/MENUBAR.BM`, `GUI/LAYERS.BM`
> context menu, `INPUT/INPUT.BM` Ctrl+Alt+K).
>
> **Also fixed in 1.7.0 (the bug pre-dated 1.6.0):** `1510`/`1511`/`1512` were
> allocated to both the Palette GPL actions and the text-style actions. The Palette
> cases won, leaving Import / Export Text Styles as unreachable dead code — no menu
> item misbehaved because nothing dispatched them. Text styles moved to `1520`–`1522`
> and are now registered in `CMD_init`, so the command palette can reach them.
>
> **Audit for duplicates before allocating:**
> ```
> grep -n '^        CASE [0-9]' GUI/COMMAND.BM | sed 's/.*CASE //' | awk '{print $1}' | sort | uniq -d
> ```
> This must print nothing.
| 1911–1914 | Drawer Sets  | Load, Save, Clear, Explore drawer-set folder |
| 2001–2010 | Image Adj    | BrightnessContrast, HueSaturation, Levels, ColorBalance, Blur, Sharpen, Invert, Desaturate, Posterize, Pixelate |
| 2012–2020 | Preview Win  | PreviewWindowSubmenu(2012), FollowMode(2013), FloatingImageMode(2014), BinQuickLook(2015), AllowColorPicking(2016), LoadImage(2017), RecentImages(2018), ClearRecentImages(2019), GrayscalePreview(2020) |
| 2021      | Color Mixer  | ToggleColorMixer(2021) |
| 2023      | Advanced Color Picker | ToggleAdvColorPicker(2023) — View menu, `Ctrl+Shift+M`, middle-click the Color Mixer organizer button |
| 2024      | 3D Color Space | Toggle3DColorSpace(2024) — View menu, command palette (`GUI/COLOR-SPACE-3D`) |
| 2025      | OKLCh Ramp   | GenerateOklchRamp(2025) — Palette menu, command palette (`PALETTE_LOADER_create_oklch_ramp`) |
| 2026      | Mix Brush    | ToggleMixBrush(2026) — Brush menu checkbox, command palette; `CFG.BRUSH_MIX%` (`TOOLS/BRUSH-MIX`) |
| 2027      | Pigment Mix  | GeneratePigmentMix(2027) — Palette menu, command palette (`PALETTE_LOADER_create_pigment_mix`) |
| 2028      | Pen Pressure | TogglePenPanel(2028) — View menu checkbox, command palette (`GUI/PEN-PANEL`, `PENP_toggle`) |
| 2060–2069 | Color Cycling | ToggleCycling(2060, `Shift+Tab`, Palette → Cycle Colors ✓), RangeFromMarked(2061), DeleteRange(2062), ClearRanges(2063), Direction(2064), PauseRange(2065), Faster(2066), Slower(2067), RestartAll(2068), CheckDuplicates(2069) — Palette → Color Cycling flyout, command palette, `PCYC_action`; whitelisted to keep Color Ops on |
| 2330–2335 | Cycling I/O  | ExportCycleBas(2330), ExportGifCrng(2331), ExportAnimGif(2332), ExportILBM(2333), ExportPBM(2334), OpenDeluxePaintGrafX2(2335) — File → Color Cycling flyout, command palette, `CYCX_action` |
| 2022      | Browser      | ToggleBrowser(2022) |
| 2050–2054 | Character Map | ToggleCharMap(2050), DockLeft(2051), DockRight(2052), ToggleCharGrid(2053), ToggleSnapToCharGrid(2054) |
| 2100      | Settings     | ACTION_SETTINGS — open Settings dialog (Ctrl+,; Ctrl+punctuation handled in `KEYBOARD_input_handler`, see CLAUDE.md gotcha #6); tabbed UI in `GUI/SETTINGS-TABS.BM` incl. Display tab's master UI Scale, and Panels tab's *Warn Drawing on Group* / *Auto-Add Layer to Group* (`CFG.GROUP_DRAW_NOTIFY%` / `CFG.GROUP_DRAW_AUTO_LAYER%`) |
| 2201–2216 | Export As    | ExportPNGNative(2201), ExportPNG(2204), ExportGIF(2205), ExportJPG(2206), ExportTGA(2208), ExportBMP(2209), ExportHDR(2210), ExportICO(2211), ExportQOI(2216) |
| 2300–2319 | ANSI import/export | ANS_ACT_EXPORT(2300), ANS_ACT_IMPORT(2301), ANS_ACT_EXPORT_QUICK(2302); consts in `OUTPUT/FILE-ANS.BI` |

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

The drawer context menu uses `POPUP_MENU_*` helpers and exposes mode-specific actions plus drawer-set management: load `.dset`, save `.dset`, clear active set, explore folder, **Load Images** (batch-import images into consecutive slots), and gradient editing when in gradient mode.

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

## Floating panel look (`GUI/FLOAT-PANEL.BI` / `GUI/FLOAT-PANEL.BM`)

Hand-drawn floating panels (3D Color Space, Pen Pressure) must look like the Color Mixer. `FPANEL_*` holds that look in one place: the themed UI font (`THEME.GLOBAL_FONT_*`, loaded once, shared) and the mixer's geometry, derived from the font height exactly like `CP_THEME_scale_geometry` (`FPANEL.titleH/rowH/sliderH/gap/section/pad`). The drawing helpers mirror the CP library's renderers and use `THEME.CP_*` colors: `FPANEL_title_bar` (close box with hover), `FPANEL_chip` (posterize-chip states), `FPANEL_track` (slider well + fill + thumb) and `FPANEL_checkbox`.

- Wrap panel drawing in `oldFont& = FPANEL_begin&` … `_FONT oldFont&`. Never draw panel text with `_FONT 8`, which is the blocky built-in font the mixer doesn't use.
- Derive layout from `FPANEL.*`, never fixed pixel constants (see `PENP_layout`), so a theme font change re-flows the panel.
- Library widgets take the font via their own hook; for example, `C3D_set_font FPANEL.font&` resizes the C3D rows to fit it.
- **One title bar everywhere.** The Advanced Color Picker and the Preview window use `FPANEL_title_bar` too: `ADVCP_title_h%` and `PREVIEW_title_h%` return `FPANEL.titleH`, so `THEME.PREVIEW_title_height%`/`button_*` no longer drive the Preview. The Preview adds a minimize box (one `titleH` square left of the close box) and its FP/CP `FPANEL_checkbox` after the title (`PREVIEW_cb_x%`/`PREVIEW_cb_w%`). The close button everywhere is the drawn cross `FPANEL_close_icon`, and the Color Mixer's comes from the same cross in `CP_RENDER_title_bar`.
- **One width.** The color / pen panels share `FPANEL_panel_w%`, which is the Color Mixer's CP `dialogW`. The ACP wheel, the C3D widget (inside `pad`) and `PENP.panelW` are all sized from it.

**Placement (snap + no overlap).** All six floating windows run their title-bar drag through `FPANEL_place`: the Color Mixer, Advanced Color Picker, 3D Color Space, Pen Pressure, Image Browser and Preview (see `FPANEL_float_region%`).

- **Snapping.** Edges snap within `FPANEL_SNAP` (6 viewport px), and the nearest target wins. Targets are: butting against another floating window's side, top or bottom (when the rows or columns overlap, or come within the snap distance); lining up with any other window's left, right, top or bottom edge, wherever it is; and the work-area chrome edges.
- **No overlap.** A spot that overlaps another floating window is replaced by the nearest free spot, whose edges touch an obstacle or the work area, so a dragged window slides along what it hits. If nothing is free, the window keeps its previous spot.
- **Where the rects come from.** Other windows' rectangles are read from `REGION_BOUNDS_TABLE`. Input runs before the next render, so it holds last frame's footprints, and hidden windows never block.
- **Drag pattern.** Remember prev x/y → set desired → own clamp → `FPANEL_place` → own clamp.
- **Opening.** The four color/pen panels also call `FPANEL_place` when toggled open.
- **Startup.** `FPANEL_settle_once`, after the first `SCREEN_render` in `DRAW.BAS`, pulls apart windows restored from overlapping saved positions.
- **Adding a floating window.** Add it to `FPANEL_float_region%`, `FPANEL_get_pos` and `FPANEL_set_pos`, and bump `FPANEL_FLOAT_COUNT`.
- **Not covered.** Resizing (Preview, Image Browser) is not constrained.

---

## Edit Bar (`GUI/EDITBAR.BI` / `GUI/EDITBAR.BM`)

Vertical icon bar that mirrors Edit menu actions as clickable icon buttons. Dockable LEFT (adjacent to layers panel) or RIGHT (adjacent to toolbox/drawer). Toggle with F5 or action ID 435.

- **32 slots**: 25 action icons + 7 dividers
- **Groups**: History (Undo/Redo) | Clipboard (Cut/Copy/CopyMerged/Paste/PasteInPlace) | Layer ops (CutToLayer/CopyToLayer) | Clear | Fill/Stroke (FillFG/FillBG/StrokeSelection) | Quick transforms (FlipH/FlipV/Scale-/Scale+/RotateCW/RotateCCW) | Smart Guides (Enable/Snap) | Pixel Perfect | Flip Canvas (H/V)
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

Vertical icon bar with 26+ quick-access toggle buttons for view options, tool toggles, and feature controls. Dockable LEFT or RIGHT (independently from EditBar). Defaults to LEFT dock. Toggle with Shift+F5 or action ID 449.

- **30 slots** (`ADVBAR_TOTAL_SLOTS`): 24 action icons + 6 dividers, organized by category (View, Grid, Brush, Reference, Layer Distribution, etc.). A workspace's `[ADVANCED_BAR] BUTTONS=` filters them (`ADVBAR_SHOW()`, see draw-workspaces.md)
- **Buttons include**: Char Map, Char Grid, Char Snap, Preview, EditBar, Tile Preview, Grid Cell Fill, Grid Show, Fill Adjust, Brush Edges, Angle Snap, Grayscale Preview, Ref Image controls, Distribute Layers, Crosshair, Smart Guides, and more
- **Config**: `ADVANCEDBAR_VISIBLE%`, `ADVANCEDBAR_DOCK_POSITION$` ("LEFT"/"RIGHT")
- **Theme fields**: `ADV_BAR_WIDTH%`, `ADV_BAR_*_BORDER_WIDTH%`, `ADV_BAR_ICON_PADDING%`, plus 26 `ADV_BAR_ICON_*$` filename strings and color fields (`ADV_BAR_BG~&`, `ADV_BAR_HOVER~&`, `ADV_BAR_BORDER*~&`)
- **Icon dir**: `ASSETS/THEMES/DEFAULT/IMAGES/ADVANCEDBAR/*.png`
- **Disabled dimming**: Unavailable toggles render with reduced alpha and are unclickable
- **Lazy icon loading**: Same pattern as EditBar — `ADVBAR_load_icons` on first render, not init
- **Auto-hide visibility**: Same `PREVIEW_init` pattern as EditBar — `showAdvBar% = FALSE` + `advBarManuallyHidden% = TRUE` by default

---

## Help card (`GUI/HELP-CARD.BI` / `GUI/HELP-CARD.BM`, prefix `HCARD_`)

A gesture reference that is **not** a tooltip: docked to an edge of the canvas work area
(`CFG.HELP_CARD_EDGE`: 0 bottom — just above the palette strip —, 1 top, 2 left, 3 right),
colored gradient header, 2-column table of rows drawn as keycaps + a 9x13 mouse glyph
(pressed button / wheel / drag arrow / "2x"). Cards: `HCARD_PALOPS` (hover the strip in Palette
Ops) and `HCARD_CYCLE` (same, while `PCYC.ENABLED`): cycling gestures + live hovered-range line +
band legend. Key names come from the live binding (`HCARD_key_for_action$`, follows rebinds).
- `HCARD_update` runs right after `TOOLTIP_update` (DRAW.BAS); the idle block keeps frames live
  while the delay counts (`HCARD.WANT <> NONE AND SHOWN = NONE`). Show/hide sets `SCENE_DIRTY`
  (the card sits over the canvas).
- `HCARD_render SCRN.CANVAS&` is called right before **each** of the 3 `TOOLTIP_render` sites,
  `HCARD_reblit_to_screen0` before each `TOOLTIP_reblit_to_screen0` (above floating panels).
- Config: `HELP_CARD_ENABLED`, `HELP_CARD_EDGE` (BOTTOM/TOP/LEFT/RIGHT), `HELP_CARD_DELAY`;
  Settings → General → Cursors & Tooltips. QA: `palette-ops-help-card.sh`, `-top.sh`.
- Adding a card: a `HCARD_*` const, rows in `HCARD_build`, a want-rule in `HCARD_update`.

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
