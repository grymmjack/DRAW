# [ ] CHARMAP TESTING

## [x] PANEL VISIBILITY AND TOGGLING

### [x] Opening and Closing the Character Map Panel
Verify the character map panel can be toggled via keyboard shortcut, menu, and command palette. Panel shows a 16x16 grid of 256 glyphs from the current font.

#### [x] Toggle via Ctrl+M
1. [x] Press `Ctrl+M` — verify the character map panel appears
2. [x] Verify a 16×16 grid of glyphs (0–255) is rendered
3. [x] Verify the panel is docked on the expected side (default: RIGHT)
4. [x] Press `Ctrl+M` again — verify the panel hides
5. [x] Verify canvas work area expands to fill the freed space

#### [x] Toggle via View menu
1. [x] Open View menu → click "CHARACTER MAP"
2. [x] Verify the panel appears with a checkmark next to the menu item
3. [x] Open View menu → click "CHARACTER MAP" again
4. [x] Verify the panel hides and the checkmark is removed

#### [x] Toggle via Command Palette
1. [x] Press `?` to open the Command Palette
2. [x] Type "character" and select "Toggle Character Map"
3. [x] Verify the panel appears
4. [x] Repeat to hide

#### [x] Panel state persists across sessions
1. [x] Open the character map (`Ctrl+M`)
2. [x] Exit and restart DRAW
3. [x] Verify the character map is still visible on startup (check `DRAW.cfg` for `CHARMAP_VISIBLE=1`)

#### [x] Toggle-all (F11) includes charmap
1. [x] Open character map (`Ctrl+M`)
2. [x] Press `F11` to hide all UI panels
3. [x] Verify the character map panel hides along with toolbar/statusbar/layers
4. [x] Press `F11` again to restore all panels
5. [x] Verify character map is restored (was auto-hidden, not manually hidden)

---

## [x] PANEL DOCKING

### [x] Docking Left and Right
Verify the character map panel can be docked to either side of the workspace and that layout reflows correctly.

#### [x] Dock Left via menu
1. [x] Open character map (`Ctrl+M`)
2. [x] Open View → Layout → "Character Map Left"
3. [x] Verify the panel moves to the left side of the canvas
4. [x] Verify the canvas work area shrinks on the left to accommodate the panel

#### [x] Dock Right via menu
1. [x] With panel docked left, open View → Layout → "Character Map Right"
2. [x] Verify the panel moves to the right side
3. [x] Verify the canvas work area adjusts accordingly

#### [x] Quick dock toggle (Ctrl+Shift+Click)
1. [x] Open character map
2. [x] Ctrl+Shift+Left-Click on the character map panel
3. [x] Verify the panel toggles from one side to the other

#### [x] Docking position persists in config
1. [x] Dock the character map to the LEFT
2. [x] Exit and restart DRAW
3. [x] Verify the panel is still docked LEFT (check `DRAW.cfg` for `CHARMAP_PANEL_DOCK_EDGE=LEFT`)

#### [x] Coexistence with other docked panels
1. [x] Dock character map LEFT, toolbox RIGHT, layer panel RIGHT
2. [x] Verify all three panels render without overlap
3. [x] Verify the canvas work area is correctly calculated between the panels
4. [x] Dock character map RIGHT alongside toolbox RIGHT
5. [x] Verify panels stack correctly (charmap inside editbar zone)

---

## [ ] GLYPH GRID RENDERING

### [ ] Grid Display and Font Syncing
Verify the 16×16 glyph grid renders correctly and syncs with the text tool's active font.

#### [x] Grid shows 256 cells
1. [x] Open character map
2. [x] Verify there are 16 columns × 16 rows = 256 cells
3. [x] Verify cells are numbered/indexed 0-255 (row 0: chars 0-15, row 1: chars 16-31, etc.)

#### [ ] Glyphs match current text font
1. [ ] Select the Text tool (`T`)
2. [ ] Choose a font from the TEXT BAR font dropdown (e.g., "Tiny5")
3. [ ] Open character map
4. [ ] Verify glyphs in the grid match the font shown in the TEXT BAR
5. [ ] Change font in TEXT BAR to a different font
6. [ ] Verify the character map grid updates to show the new font's glyphs

> **FAILED**: Cell width/height are not adjusting to the active font dimensions; appears to affect both height and width. — 2026-03-22

> **FAILED**: Cells now resize, but can exceed panel bounds and some cells render behind the text bar background area. — 2026-03-22

> **FAILED**: Cells are still breaking out past the edit bar area on the right edge. — 2026-03-22

> **FAILED**: On startup, charmap initially overlaps (same right-edge overflow), then corrects after first mouse move/frame update. — 2026-03-22

#### [ ] Cache rebuild on font change
1. [ ] Open character map with one font active
2. [ ] Note the glyph appearance
3. [ ] Switch font in TEXT BAR
4. [ ] Verify cache rebuilds (glyphs visually change to new font)
5. [ ] Switch font size
6. [ ] Verify cache rebuilds again with new size

#### [ ] Cell padding and dimensions from config
1. [ ] Check `DRAW.cfg` for `CHARMAP_CELL_W`, `CHARMAP_CELL_H`, `CHARMAP_CELL_PADDING`
2. [ ] Edit these values in `DRAW.cfg` and restart
3. [ ] Verify the cell sizes and padding reflect the new settings

---

## [ ] CELL INTERACTION — MOUSE

### [ ] Hover State
Verify glyph cells highlight on mouse hover and show appropriate visual feedback.

#### [ ] Hover highlights cell
1. [ ] Open character map
2. [ ] Move mouse over a cell (e.g., the 'A' cell, index 65)
3. [ ] Verify the cell background changes to the hover color (THEME.CHARMAP_HOVER_BG)
4. [ ] Verify the glyph color changes to the hover foreground (THEME.CHARMAP_HOVER_FG)

#### [ ] Hover index tracks correctly
1. [ ] Move mouse across multiple cells
2. [ ] Verify only one cell is highlighted at a time
3. [ ] Move mouse off the grid entirely
4. [ ] Verify no cell is highlighted (hoverIdx = -1)

### [ ] Left-Click Selection
Verify left-clicking selects/deselects glyphs and routes them appropriately.

#### [ ] Select a glyph
1. [ ] Open character map
2. [ ] Left-click on cell 'A' (index 65)
3. [ ] Verify the cell shows selected highlight (THEME.CHARMAP_SELECTED_BG/FG)
4. [ ] Verify `selectedIdx` is 65

#### [ ] Deselect by clicking same cell
1. [ ] With cell 'A' selected, left-click 'A' again
2. [ ] Verify selection is cleared (selectedIdx = -1)
3. [ ] Verify cell returns to default colors

#### [ ] Select different cell replaces selection
1. [ ] Left-click cell 'A' to select it
2. [ ] Left-click cell 'B' (index 66)
3. [ ] Verify 'A' is deselected and 'B' is now selected
4. [ ] Verify only one cell is highlighted as selected at a time

#### [ ] Glyph copies to custom brush (non-text context)
1. [ ] Switch to Brush tool (`B`)
2. [ ] Open character map
3. [ ] Left-click a visible glyph (e.g., 'X', index 88)
4. [ ] Verify status bar shows `CB` (custom brush active)
5. [ ] Verify the custom brush contains the glyph shape
6. [ ] Click on canvas to stamp the glyph — verify it paints correctly
7. [ ] Verify recolor mode is automatically enabled (CB+RECOLOR)

#### [ ] Glyph inserts into text layer (text tool + Use Chars)
1. [ ] Switch to Text tool (`T`), click canvas to start text
2. [ ] Enable Use Chars mode via [CHAR] button in TEXT BAR
3. [ ] Open character map
4. [ ] Left-click glyph '©' (index 169) or another special character
5. [ ] Verify the character is inserted at the text cursor position
6. [ ] Verify the cursor advances past the inserted character

### [ ] Right-Click — BG Color Brush
Verify right-clicking copies the glyph to custom brush with BG color tinting.

#### [ ] Right-click copies glyph with BG color
1. [ ] Set a visible BG color (e.g., blue)
2. [ ] Switch to Brush tool (`B`)
3. [ ] Open character map
4. [ ] Right-click on glyph 'H' (index 72)
5. [ ] Verify custom brush is activated with the glyph shape
6. [ ] Verify the paint color is now the BG color (blue)
7. [ ] Click on canvas — verify the glyph stamps in BG color

#### [ ] Right-click while text tool active
1. [ ] Switch to Text tool, enable Use Chars
2. [ ] Right-click a glyph in the character map
3. [ ] Verify the glyph is selected
4. [ ] Verify it copies to custom brush with BG color (not inserted as text)

### [ ] Flash State
Verify glyphs flash briefly when typed via keyboard or F-key.

#### [ ] Typing flashes the glyph
1. [ ] Open character map, enable Use Chars, activate Text tool, click canvas
2. [ ] Type 'A' on keyboard
3. [ ] Verify cell 65 (A) flashes briefly (THEME.CHARMAP_FLASH_FG color, ~0.3 second)
4. [ ] Verify `selectedIdx` syncs to 65

#### [ ] F-key flashes the ANSI glyph
1. [ ] With Use Chars active and Text tool on canvas
2. [ ] Press F1
3. [ ] Verify cell 176 (░) flashes briefly
4. [ ] Press F4
5. [ ] Verify cell 219 (█) flashes

#### [ ] Flash expires after ~0.3 seconds
1. [ ] Type a character and observe the flash
2. [ ] Wait ~0.5 seconds
3. [ ] Verify the flash has expired and the cell returns to selected highlight

---

## [ ] USE CHARS MODE

### [ ] Enabling and Disabling Character Mode
Verify the [CHAR] button in TEXT BAR toggles Character Mode and auto-enables related features.

#### [ ] Toggle via [CHAR] button
1. [ ] Activate Text tool (`T`)
2. [ ] Verify TEXT BAR appears with a [CHAR] button
3. [ ] Click [CHAR] — verify it activates (button shows active/highlighted state)
4. [ ] Click [CHAR] again — verify it deactivates

#### [ ] Auto-show Character Map panel
1. [ ] Ensure character map is hidden
2. [ ] Activate Text tool, click [CHAR] to enable Use Chars
3. [ ] Verify the character map panel automatically appears
4. [ ] Verify `CHARMAP.useChars%` is TRUE

#### [ ] Auto-enable Char Grid overlay
1. [ ] Ensure char grid is OFF
2. [ ] Enable Use Chars via [CHAR] button
3. [ ] Verify the on-canvas character grid overlay appears
4. [ ] Verify View → CHAR GRID now shows a checkmark

#### [ ] Auto-enable Snap to Char Grid
1. [ ] Ensure snap-to-char-grid is OFF
2. [ ] Enable Use Chars
3. [ ] Verify snap-to-char-grid is now active
4. [ ] Verify View → SNAP TO CHAR GRID now shows a checkmark

#### [ ] Auto-enable Brush Recolor Mode
1. [ ] Enable Use Chars
2. [ ] Verify custom brush recolor mode is enabled
3. [ ] Select a glyph from charmap while Brush tool is active
4. [ ] Paint on canvas — verify glyphs paint in FG color (recolor active)

#### [ ] Default glyph selection
1. [ ] With no glyph selected (selectedIdx <= 32)
2. [ ] Enable Use Chars
3. [ ] Verify cell 65 ('A') is automatically selected

#### [ ] Use Chars state persists in config
1. [ ] Enable Use Chars
2. [ ] Exit and restart DRAW
3. [ ] Activate Text tool
4. [ ] Check `DRAW.cfg` for `CHARMAP_USE_CHARS=1`

### [ ] Title Bar CHAR MODE Hint
Verify the title bar shows "(CHAR MODE)" when Use Chars is active.

#### [ ] Title bar updates on enable
1. [ ] Note the title bar text (e.g., "DRAW v1.x - filename.drw")
2. [ ] Enable Use Chars
3. [ ] Verify title bar now ends with "(CHAR MODE)"

#### [ ] Title bar updates on disable
1. [ ] With Use Chars active, verify "(CHAR MODE)" is in title
2. [ ] Disable Use Chars (click [CHAR] again)
3. [ ] Verify "(CHAR MODE)" is removed from the title bar

#### [ ] CHAR MODE hint coexists with dirty indicator
1. [ ] Enable Use Chars
2. [ ] Draw something to mark canvas dirty
3. [ ] Verify title bar shows both " *" (dirty) and "(CHAR MODE)" — e.g., "DRAW v1.x - file.drw * (CHAR MODE)"

### [ ] F-Key ANSI Character Mapping
Verify F1-F12 insert ANSI block characters when Use Chars mode is active in the text tool.

#### [ ] F1 inserts ░ (176)
1. [ ] Activate Text tool, click canvas, enable Use Chars
2. [ ] Press F1
3. [ ] Verify character ░ (code 176) is inserted into the text
4. [ ] Verify cell 176 flashes in the character map

#### [ ] F2 inserts ▒ (177)
1. [ ] Press F2 — verify ▒ (177) is inserted

#### [ ] F3 inserts ▓ (178)
1. [ ] Press F3 — verify ▓ (178) is inserted

#### [ ] F4 inserts █ (219)
1. [ ] Press F4 — verify █ (219) is inserted — the solid block

#### [ ] F5 inserts ▀ (223)
1. [ ] Press F5 — verify ▀ (223) is inserted — upper half block

#### [ ] F6 inserts ▄ (220)
1. [ ] Press F6 — verify ▄ (220) is inserted — lower half block

#### [ ] F7 inserts ▌ (221)
1. [ ] Press F7 — verify ▌ (221) is inserted — left half block

#### [ ] F8 inserts ▐ (222)
1. [ ] Press F8 — verify ▐ (222) is inserted — right half block

#### [ ] F9 inserts ■ (254)
1. [ ] Press F9 — verify ■ (254) is inserted — small square

#### [ ] F10 inserts · (250)
1. [ ] Press F10 — verify · (250) is inserted — middle dot

#### [ ] F11 inserts space (32)
1. [ ] Press F11 — verify space (32) is inserted

#### [ ] F12 inserts space (32)
1. [ ] Press F12 — verify space (32) is inserted

#### [ ] F-keys only work in Use Chars mode
1. [ ] Disable Use Chars (click [CHAR] to deactivate)
2. [ ] Press F1 — verify it does NOT insert an ANSI character
3. [ ] Verify F1 performs its normal action (e.g., drawer brush mode)

#### [ ] F-keys require text tool active on canvas
1. [ ] Enable Use Chars but do NOT activate text tool on canvas
2. [ ] Press F1 — verify no ANSI character insertion occurs (F-keys should fall through)

### [ ] Keyboard Input Syncing with Character Map
Verify typed characters sync the character map selection and flash.

#### [ ] Printable ASCII syncs map
1. [ ] Enable Use Chars, activate text tool, click canvas
2. [ ] Type 'Z'
3. [ ] Verify cell 90 ('Z') is selected and flashes in the character map

#### [ ] Tab inserts config-backed spaces
1. [ ] Check `DRAW.cfg` for `CHARMAP_TAB_CHARS` (default 4)
2. [ ] Press Tab
3. [ ] Verify 4 spaces are inserted into the text
4. [ ] Verify cell 32 (space) flashes in the character map

---

## [ ] CHARACTER GRID OVERLAY

### [ ] Toggling the On-Canvas Character Grid
Verify the character grid can be shown/hidden on the canvas independently of the charmap panel.

#### [ ] Toggle via View → CHAR GRID
1. [ ] Open View menu → click "CHAR GRID"
2. [ ] Verify a grid overlay appears on the canvas matching character cell dimensions
3. [ ] Click "CHAR GRID" again — verify the overlay hides

#### [ ] Toggle via Command Palette
1. [ ] Open Command Palette (`?`), search "Toggle Char Grid"
2. [ ] Verify grid toggles on/off

#### [ ] Grid dimensions match font
1. [ ] Select a font with known dimensions (e.g., VGA 8×16)
2. [ ] Enable char grid
3. [ ] Verify grid cell width = 8px, grid cell height = 16px on the canvas
4. [ ] Change to a different font (e.g., 8×8)
5. [ ] Verify grid updates to 8×8 cells

#### [ ] Grid visible at zoom >= 1.0
1. [ ] Enable char grid
2. [ ] Zoom out to 50% (below 100%)
3. [ ] Verify the character grid is NOT rendered (performance optimization)
4. [ ] Zoom in to 100%
5. [ ] Verify the character grid appears
6. [ ] Zoom in to 200%, 400%, 800%
7. [ ] Verify the grid remains visible and scales correctly at each level

#### [ ] Grid uses theme/config color
1. [ ] Check `DRAW.cfg` for `CHAR_GRID_COLOR_FG` and `CHAR_GRID_OPACITY`
2. [ ] If set, verify the grid uses that color
3. [ ] If not set (0), verify the grid uses `THEME.CHAR_GRID_COLOR_FG`

### [ ] Snap to Character Grid
Verify cursor coordinates snap to character grid cell boundaries.

#### [ ] Toggle via View → SNAP TO CHAR GRID
1. [ ] Open View menu → click "SNAP TO CHAR GRID"
2. [ ] Verify the menu item shows a checkmark
3. [ ] Click again — verify the checkmark is removed

#### [ ] Cursor snaps to char cell boundaries
1. [ ] Enable char grid + snap-to-char-grid
2. [ ] Select Dot tool or Brush tool
3. [ ] Move mouse slowly across the canvas
4. [ ] Verify canvas coordinates (shown in status bar) jump in increments matching the char cell size
5. [ ] Verify drawing occurs at snapped positions

#### [ ] Snap respects Ctrl+Shift bypass
1. [ ] Enable snap-to-char-grid
2. [ ] Hold Ctrl+Shift while moving mouse
3. [ ] Verify the cursor moves freely (snap is bypassed)
4. [ ] Release Ctrl+Shift — verify snap resumes

#### [ ] Char grid snap + regular grid snap
1. [ ] Enable both regular grid snap (`;`) and char grid snap
2. [ ] Verify coordinates snap first to regular grid, then to char grid
3. [ ] Move mouse — verify snapping applies both systems

---

## [ ] AUTO-HIDE AND RESTORE

### [ ] Auto-Hide While Drawing
Verify the character map panel auto-hides when the user draws over it and restores when drawing stops.

#### [ ] Auto-hide on draw start over panel
1. [ ] Open character map, dock it on a side
2. [ ] Select Brush tool, start drawing over the area where the charmap is displayed
3. [ ] Verify the charmap panel auto-hides while the mouse button is held
4. [ ] Verify canvas drawing continues unimpeded

#### [ ] Auto-restore on mouse release
1. [ ] After auto-hiding (above), release the mouse button
2. [ ] Verify the character map panel automatically restores itself
3. [ ] Verify the panel returns to the same dock position

#### [ ] Manual hide prevents auto-restore
1. [ ] Manually hide the charmap (`Ctrl+M`)
2. [ ] Draw over where the panel was
3. [ ] Release mouse button
4. [ ] Verify the panel does NOT auto-restore (it was manually hidden, not auto-hidden)

---

## [ ] BITMAP FONT LOADING

### [ ] Font Directory Scanning
Verify bitmap fonts (.F??, .PSF, .BDF, .PCF) are detected from asset and user directories.

#### [ ] Scan ASSETS/FONTS/BITMAP/
1. [ ] Place a .PSF font file in `ASSETS/FONTS/BITMAP/`
2. [ ] Restart DRAW
3. [ ] Open TEXT BAR font dropdown
4. [ ] Verify the bitmap font appears in the list (with WxH dimensions in display name)

#### [ ] Scan USER/FONTS/BITMAP/
1. [ ] Place a .BDF font file in `USER/FONTS/BITMAP/`
2. [ ] Restart DRAW
3. [ ] Verify the font appears in the TEXT BAR font dropdown

#### [ ] Fontraption .F?? format detection
1. [ ] Place a Fontraption .F16 file (raw 8×16 binary, exactly 256*16 = 4096 bytes)
2. [ ] Restart DRAW
3. [ ] Verify the font is detected and appears as "fontname 8x16" in the dropdown

#### [ ] PSF v1 format detection
1. [ ] Place a PSFv1 font file (magic 0x36 0x04)
2. [ ] Restart DRAW
3. [ ] Verify the font is detected with correct width (8) and height from header

#### [ ] PSF v2 format detection
1. [ ] Place a PSFv2 font file (magic 0x72 0xB5 0x4A 0x86)
2. [ ] Restart DRAW
3. [ ] Verify the font is detected with correct width and height from v2 header

#### [ ] BDF format detection
1. [ ] Place a .BDF font file with FONTBOUNDINGBOX header
2. [ ] Restart DRAW
3. [ ] Verify the font is detected with dimensions from FONTBOUNDINGBOX

#### [ ] PCF format detection
1. [ ] Place a .PCF font file (magic 0x01 0x66 0x63 0x70)
2. [ ] Restart DRAW
3. [ ] Verify the font is detected and dimensions are read from the PCF_METRICS table

#### [ ] Unrecognized format logged
1. [ ] Place a random .txt file renamed to .PSF in the bitmap font dir
2. [ ] Restart DRAW with logging enabled
3. [ ] Verify a warning is logged ("unrecognized format")

### [ ] Bitmap Font Auto-Settings
Verify that selecting a bitmap font auto-enables monospace and auto line height.

#### [ ] Auto-monospace on bitmap font selection
1. [ ] Open Text tool, open font dropdown
2. [ ] Select a bitmap font (appears with "WxH" suffix)
3. [ ] Verify the [MONO] button in TEXT BAR activates automatically
4. [ ] Verify text renders in monospaced mode

#### [ ] Auto line-height on bitmap font selection
1. [ ] Select a bitmap font
2. [ ] Verify the [AUTO] line height button activates automatically
3. [ ] Verify line height matches the font's native glyph height

### [ ] Bitmap Font Glyph Rendering in Character Map
Verify bitmap font glyphs render correctly in the 16×16 charmap grid.

#### [ ] Fontraption glyph rendering
1. [ ] Select a Fontraption .F?? bitmap font
2. [ ] Open character map
3. [ ] Verify all 256 glyphs render correctly (white pixels on transparent background)
4. [ ] Verify glyph shapes match the font's expected appearance (e.g., CP437 glyphs for IBM fonts)

#### [ ] PSF glyph rendering
1. [ ] Select a PSF bitmap font
2. [ ] Open character map
3. [ ] Verify glyphs render with correct dimensions and pixel patterns

#### [ ] BDF glyph rendering
1. [ ] Select a BDF bitmap font
2. [ ] Open character map
3. [ ] Verify glyphs render correctly; check special characters (box-drawing, accented)

#### [ ] PCF glyph rendering
1. [ ] Select a PCF bitmap font
2. [ ] Open character map
3. [ ] Verify glyphs render correctly

#### [ ] Copying bitmap glyph to custom brush
1. [ ] Select a bitmap font, open charmap
2. [ ] Left-click a glyph (e.g., box-drawing character ═, index 205)
3. [ ] Verify custom brush activates with the glyph's pixel shape
4. [ ] Paint on canvas — verify the stamped glyph matches the charmap preview

---

## [ ] CUSTOM BRUSH INTEGRATION

### [ ] Glyph to Custom Brush Pipeline
Verify that clicking a glyph correctly creates a reusable custom brush.

#### [ ] Stamp glyph with brush tool
1. [ ] Switch to Brush tool
2. [ ] Open charmap, click glyph 'X' (index 88)
3. [ ] Verify custom brush is active (status bar shows `CB+RECOLOR`)
4. [ ] Click on canvas — verify 'X' is stamped at the click position

#### [ ] Glyph respects symmetry
1. [ ] Enable Vertical symmetry (`F7`)
2. [ ] Select a glyph, stamp it on canvas
3. [ ] Verify the glyph appears in both the original and mirrored positions

#### [ ] Glyph respects zoom levels
1. [ ] Zoom to 100%, stamp glyph — verify 1:1 pixel size
2. [ ] Zoom to 200%, stamp glyph — verify 1:1 pixel size (not 2x)
3. [ ] Zoom to 400%, stamp glyph — verify 1:1 pixel size

#### [ ] Glyph custom brush can be flipped
1. [ ] Select a glyph into custom brush
2. [ ] Press `Home` to flip horizontally
3. [ ] Stamp on canvas — verify glyph is horizontally mirrored
4. [ ] Press `End` to flip vertically — verify vertical flip

#### [ ] Glyph custom brush can be scaled
1. [ ] Select a glyph into custom brush
2. [ ] Press `PgUp` to scale up — verify brush grows
3. [ ] Press `PgDn` to scale down — verify brush shrinks
4. [ ] Press `/` to reset scale — verify original size

#### [ ] Glyph recolor mode uses FG color
1. [ ] Set FG color to red
2. [ ] Select glyph from charmap (recolor auto-enabled)
3. [ ] Paint on canvas — verify glyph stamps in red
4. [ ] Change FG to green — stamp again — verify green glyph

#### [ ] Right-click glyph uses BG color for painting
1. [ ] Set BG color to blue (bright, visible)
2. [ ] Right-click a glyph in the charmap
3. [ ] Paint on canvas
4. [ ] Verify the glyph stamps in the BG color (blue)

---

## [ ] RENDERING

### [ ] Panel Rendering
Verify the character map panel renders correctly at various screen configurations.

#### [ ] Panel renders at different display scales
1. [ ] Set display scale to 1x (`Ctrl+PgDn` until 1x)
2. [ ] Open character map — verify it renders correctly, cells are visible
3. [ ] Set display scale to 2x — verify rendering is correct
4. [ ] Set display scale to 3x — verify no rendering artifacts

#### [ ] Panel does not overlap other panels
1. [ ] Open charmap, toolbar, layer panel, edit bar simultaneously
2. [ ] Verify no panel overlaps another
3. [ ] Verify the canvas work area is correctly bounded between all panels

#### [ ] Character grid overlay renders on canvas
1. [ ] Enable char grid overlay
2. [ ] Zoom to 200%
3. [ ] Verify grid lines are visible on the canvas as colored lines
4. [ ] Verify grid lines align with character cell boundaries

#### [ ] Character grid does not appear below 100% zoom
1. [ ] Enable char grid overlay
2. [ ] Zoom out to 50%
3. [ ] Verify the character grid is NOT visible (performance optimization)

---

## [ ] UNDO / REDO

### [ ] Glyph Stamp Undo
Verify that stamping glyphs from the character map can be undone.

#### [ ] Undo glyph stamp
1. [ ] Switch to Brush tool, select glyph from charmap, stamp on canvas
2. [ ] Press `Ctrl+Z` to undo
3. [ ] Verify the stamped glyph is removed from the canvas
4. [ ] Press `Ctrl+Y` to redo
5. [ ] Verify the glyph reappears

#### [ ] Multiple glyph stamps undo in order
1. [ ] Stamp glyph 'A' at position (10, 10)
2. [ ] Stamp glyph 'B' at position (20, 10)
3. [ ] Stamp glyph 'C' at position (30, 10)
4. [ ] `Ctrl+Z` — verify 'C' is removed
5. [ ] `Ctrl+Z` — verify 'B' is removed
6. [ ] `Ctrl+Z` — verify 'A' is removed

#### [ ] Glyph insertion into text undo
1. [ ] Activate text tool, click canvas, enable Use Chars
2. [ ] Click glyph '©' in charmap to insert it
3. [ ] Press `Ctrl+Z` — verify the inserted character is undone

---

## [ ] UI CHROME CLICKED GUARD

### [ ] Clicks on Charmap Don't Paint on Canvas
Verify that UI_CHROME_CLICKED prevents canvas tool actions when clicking on the charmap.

#### [ ] Left-click on charmap does not paint
1. [ ] Switch to Dot tool, open charmap
2. [ ] Left-click on a glyph cell
3. [ ] Verify no pixel is placed on the canvas
4. [ ] Verify only the glyph selection occurs

#### [ ] Right-click on charmap does not paint
1. [ ] Switch to Brush tool, open charmap
2. [ ] Right-click on a glyph cell
3. [ ] Verify no BG-color stroke is started on the canvas
4. [ ] Verify the glyph is copied to custom brush with BG color

#### [ ] Release after charmap click does not trigger tool release
1. [ ] Open charmap, switch to Line tool
2. [ ] Left-click on a glyph in the charmap, then release
3. [ ] Verify no line endpoint is registered on the canvas
4. [ ] Verify no spurious history state is created

---

## [ ] CONFIG PERSISTENCE

### [ ] All CHARMAP Config Keys
Verify all character map configuration values are saved and loaded correctly.

#### [ ] CHARMAP_VISIBLE persists
1. [ ] Toggle charmap visibility
2. [ ] Exit and restart — verify state matches

#### [ ] CHARMAP_PANEL_DOCK_EDGE persists
1. [ ] Dock LEFT, exit, restart — verify LEFT
2. [ ] Dock RIGHT, exit, restart — verify RIGHT

#### [ ] CHARMAP_CELL_W / CHARMAP_CELL_H / CHARMAP_CELL_PADDING
1. [ ] Edit `DRAW.cfg` to set custom cell dimensions (e.g., W=10, H=12, PADDING=2)
2. [ ] Start DRAW — verify the charmap uses those dimensions

#### [ ] CHARMAP_DEFAULT_FONT persists
1. [ ] Set a custom font name in config
2. [ ] Verify it's loaded on startup

#### [ ] CHARMAP_CHAR_SELECTED persists
1. [ ] Select glyph index 88 ('X')
2. [ ] Exit and restart — verify cell 88 is still selected

#### [ ] CHARMAP_USE_CHARS persists
1. [ ] Enable Use Chars, exit
2. [ ] Restart — verify Use Chars is restored

#### [ ] CHAR_GRID_WIDTH / CHAR_GRID_HEIGHT
1. [ ] Set custom char grid dimensions in `DRAW.cfg`
2. [ ] Restart — verify grid uses those dimensions (0 = match font)

#### [ ] CHAR_GRID_OPACITY
1. [ ] Set opacity to 128 in `DRAW.cfg`
2. [ ] Restart — verify grid overlay uses the configured opacity

#### [ ] CHAR_GRID_COLOR_FG
1. [ ] Set `CHAR_GRID_COLOR_FG=FF0000` in `DRAW.cfg`
2. [ ] Restart — verify char grid renders in red
3. [ ] Remove the key (or set to empty) — verify it falls back to theme color

#### [ ] CHARMAP_TAB_CHARS
1. [ ] Set `CHARMAP_TAB_CHARS=8` in `DRAW.cfg`
2. [ ] Enable Use Chars, activate text tool, press Tab
3. [ ] Verify 8 spaces are inserted instead of default 4

---

## [ ] STATE MACHINE EDGE CASES

### [ ] State Transition Edge Cases from CHARMAP-STATES.DOT
Verify edge cases and boundary conditions in the character map state machine.

#### [ ] Hidden → Visible → Cache Stale → Visible cycle
1. [ ] Start with charmap hidden
2. [ ] Open charmap — verify glyphs render (VISIBLE state)
3. [ ] Change font in TEXT BAR — verify cache invalidates, then rebuilds
4. [ ] Verify glyphs now show the new font (back to VISIBLE state)

#### [ ] Rapid toggle show/hide
1. [ ] Press `Ctrl+M` rapidly 10 times
2. [ ] Verify the panel settles in the correct final state (shown or hidden)
3. [ ] Verify no rendering glitches or crashes

#### [ ] Selection survives panel hide/show
1. [ ] Select glyph 'Z' (index 90)
2. [ ] Hide charmap (`Ctrl+M`)
3. [ ] Show charmap (`Ctrl+M`)
4. [ ] Verify glyph 'Z' is still selected (index 90)

#### [ ] Use Chars OFF → F-key has no effect
1. [ ] Ensure Use Chars is OFF
2. [ ] Activate text tool, click canvas
3. [ ] Press F1 — verify no ANSI character is inserted
4. [ ] Verify F1 performs drawer brush mode switch instead

#### [ ] Cache stale during panel hidden
1. [ ] Open charmap, note current font
2. [ ] Hide charmap
3. [ ] Change font in TEXT BAR
4. [ ] Show charmap
5. [ ] Verify the cache rebuilds with the new font (not stale)

#### [ ] Click on panel during shape tool draw
1. [ ] Select Rectangle tool, start dragging a rectangle on canvas
2. [ ] Without releasing the mouse, observe the charmap panel area
3. [ ] Verify the rectangle tool is not affected by the charmap panel presence
4. [ ] Release mouse — verify the rectangle completes normally

#### [ ] DRW file load resets charmap state
1. [ ] Select a glyph, enable Use Chars, enable char grid
2. [ ] Open a .drw file (Ctrl+O)
3. [ ] Verify charmap state is properly reset after loading

---

## [ ] THEME INTEGRATION

### [ ] Theme Colors
Verify all charmap theme colors are applied correctly.

#### [ ] Background color (CHARMAP_BG)
1. [ ] Open charmap — verify panel background matches THEME.CHARMAP_BG

#### [ ] Default glyph color (CHARMAP_FG)
1. [ ] Verify unselected, unhovered glyphs render in THEME.CHARMAP_FG

#### [ ] Selected colors (CHARMAP_SELECTED_FG / CHARMAP_SELECTED_BG)
1. [ ] Select a glyph — verify foreground and background match selected theme colors

#### [ ] Hover colors (CHARMAP_HOVER_FG / CHARMAP_HOVER_BG)
1. [ ] Hover a cell — verify foreground and background match hover theme colors

#### [ ] Grid line color (CHARMAP_GRID_FG)
1. [ ] Verify grid lines between cells use THEME.CHARMAP_GRID_FG

#### [ ] Flash color (CHARMAP_FLASH_FG)
1. [ ] Type a character — verify the flash uses THEME.CHARMAP_FLASH_FG

#### [ ] Canvas char grid color (CHAR_GRID_COLOR_FG)
1. [ ] Enable char grid on canvas
2. [ ] Verify grid lines use THEME.CHAR_GRID_COLOR_FG (or config override)
