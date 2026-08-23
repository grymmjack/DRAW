# IDEAS

## MULTIPLE DRAW INSTANCE SUPPORT
- [ ] Allow (by user setting preference) multiple copies of DRAW to run at the same time in isolation of one another but with shared clipboard support, drag layers back and forth, etc.

## IMPROVED DRAG AND DROP SUPPORT
- [ ] FOR ALL Drop targets: If the image is larger than the current canvas, use the File -> Import Image workflow with pan, zoom, crop, etc. otherwise just place it where user drops it. IF holding shift while dropped, drop it in the direct center of the canvas, otherwise top left of canvas.
- [ ] Drag onto layer panel to create new layer (new layer -> image import (for crop/pan/zoom/etc))
- [ ] Drag onto brush bin to drop the image into a bin as a custom brush. If there are no bin slots free create new bins to hold in new blank bin page, etc. populating.
- [ ] Drag onto canvas to drop into current layer (destructive, undoable)
- [ ] Drag onto menu bar to open as new image, in separate DRAW instance

## _WINDOWSIZELIMIT [(minWidth, minHeight)] [- (maxWidth, maxHeight)]  ✅ DONE (branch window-size-limit)
- [x] Restricts the user-resizable dimensions of the window to minimum and/or maximum width and height bounds. — `SCREEN_apply_window_size_limits` in OUTPUT/SCREEN.BM calls `_WINDOWSIZELIMIT` (OS-enforced via GLFW) at startup and on every displayScale change.
- [x] Taking into consideration of the scaling, hdpi, etc. — min is a chrome-safe floor (`SCREEN_effective_min_w&/h&`: menubar+status+editbar+min-canvas, floored by CFG.WIN_MIN and 320×200) × displayScale; `_WINDOWSIZELIMIT` applies the same content-scale conversion as window creation, so HiDPI is handled. The window can no longer be shrunk small enough to hide the docked controls.

## GUI SCALE independent of CANVAS scale
- [ ] We need to be able to scale the GUI independent of the canvas
- [ ] Currently it's unified
  - [ ] I had this before, but we removed it
  
## Animation Support
- [ ] TBD (this needs deep thought)

## Tilemap Support
- [ ] TBD (this needs deep thought)

## ANTIALIAS MODE 
- [ ] See plan: <a href="./ANTI-ALIASING-PLAN.md">Anti-Aliasing Plan</a>
- [ ] Everything operates in anti-aliased mode. (this is a big one)

## ADDITIONAL TABLE LAYOUT MODE

Like HTML table, with resizable columns/rows with row span, col span, padding, 
cell alignment inside, borders, border widths, border colors, etc.

### OPERATIONS
- Select entire table
- Select a column across whole table
- Select a row across whole table
- Select multiple columns
- Select multiple rows
- Apply a column span
- Apply a row span
- Remove a column span
- Remove a row span
- Insert a column to the right
- Insert a column to the left
- Delete a column
- Delete selected columns
- Insert a row above
- Insert a row below
- Delete a row
- Delete selected rows
- Move table
- Export table
- Convert table to GUIDE layer
- DIVIDE EVENLY (visually)1

---

## COMPLETED


## Add color chips to popup palettes menu — DONE (v1.6.0+)
- [x] It would be great if the actual palette chips were rendered in the palette picker popup menu
  - [x] Add a setting to enable this or disable it
        (`PALETTE_MENU_SHOW_CHIPS` in DRAW.cfg, PALETTE > SHOW COLOR CHIPS IN MENU, action 1519)
  - [x] Maximum 64 chips in 32 chips across rows
    - [x] Optimize chip rows to be divisible by 8 
      - [x] If 8 colors - 1 row
      - [x] If 16 colors - 1 row (less than 32)
      - [x] If 24 colors - 1 row
      - [x] If 32 colors - 1 row
      - [x] More than 32 colors - second row but up to 64 total displayed with a "...and # more" to emphasize there are more colors displayed and # is the number of chips that aren't displayed.
- Implementation: chips render inline to the right of the palette name at 4x4px,
  so the dropdown's fixed row height / hit-test / scroll math is unchanged.
  Colors come from `PALETTE_PREVIEW_*` in GUI/PALETTE-LOADER.BM — a lazily-parsed,
  index-keyed cache with an 8-files-per-frame budget so opening the menu never
  stalls on a large Lospec collection.

## AI: generate multiple at once (batch / grid)

Extend the generate dialog with a batch mode:
- [x] "Generate multiple" toggle
- [x] Layer group name: [____]  (results land in one group)
- [x] Number of generations: dropdown 1-20
- [x] Optional: arrange as a GRID on one layer instead of N layers
      (contact-sheet style, cell = generation size, auto rows/cols)

Design notes / gotchas for whoever picks this up:

1. **The runner is deliberately single-job.** AI_JOB is ONE record and
   AI_JOB_start% refuses a second run while one is in flight. Batch needs
   either a job QUEUE (start the next when the previous imports) or a
   single tool invocation that produces N images. Queue is the safer
   shape: it keeps the existing one-at-a-time invariant, gives per-item
   progress, and lets Cancel stop the remainder.

2. **Import currently takes the NEWEST png only.** AI_JOB_newest_png$
   returns one file; a batch must import ALL new PNGs in {outdir},
   ignoring "_" prefixed names, in a defined order (mtime, then name).

3. **Generators can do this natively.** pixelmon has `-n N` (N seeds) and
   `--batch "a,b,c"` (subject per folder). One invocation with `-n N` is
   far faster than N invocations — the model stays loaded. Prefer passing
   a {count} macro through to the tool and importing everything it
   produces, falling back to a queue only for tools without a count flag.
   Note `--batch` writes into per-subject SUBFOLDERS, which the importer
   would have to walk.

4. **Seeds must differ per image**, or all N come back identical. Either
   let the tool vary them (pixelmon does with -n) or increment per queued
   job and record each layer's own seed so any one can be reproduced.

5. Group creation already exists: LAYERS_new_group%. Each result then
   sets parentGroupIdx to it.

## AI Integration — IN PROGRESS (branch: ai-integration)
Implemented: AI menu (gated on Settings > General > Enable AI Features, off by
default and fully invisible while off), generator tool registry + editor dialog,
style editor, prompt-preset editor, DRAW_InfoParser$ macros, async job runner,
AI layer type with [AI] tag / tooltip / context menu, .draw v29 persistence,
File > New from AI, Layer > New from AI, 3x3 position presets, selection-driven
size and placement.

Not yet done: AI Settings TAB inside the Settings dialog (tools/styles/prompts
are edited from the AI menu instead), model/seed reported back FROM the tool,
{limg}/{dimg}/{bimg} steering exports are wired but untested.

- [x] Add support for AI image generation
  - [x] Create new Menu option AI (just before help)
    - [x] Settings
      - [x] Tools (list)
        - [x] Add
        - [x] Remove
        - [x] Edit
          - [x] Name
          - [x] Executable
          - [x] Directory
          - [x] Arguments
        - [x] Tool Entry:
          - [x] Executable
          - [x] Directory
          - [x] Arguments (parsed through DRAW_InfoParser$)
            - [x] Options parameter macros (derived by new function DRAW_InfoParser$)
              - [x] Seed: {seed}
              - [x] Image filename: {if}
              - [x] Image directory: {id}
              - [x] Image width: {ih}
              - [x] Image height: {iw}
              - [x] Selection width: {sw}
              - [x] Selection height: {sh}
              - [x] Brush w: {bw}
              - [x] Brush h: {bh}
              - [x] Grid width: {gw}
              - [x] Grid height: {gh}
              - [x] Palette: {pal}
              - [x] Colors: {numpal}
              - [x] Num Layers: {numlayers}
              - [x] Current layer index: {lidx}
              - [x] Current layer name: {lname}
              - [x] Current layer width: {lw}
              - [x] Current layer height: {lh}
              - [x] Current layer x pos: {lx}
              - [x] Current layer x pos: {ly}
              - [x] BG color: {bg}
              - [x] FG color: {fg}
              - [x] Paint Mode: {pmode}
              - [x] Active tool: {tool}
              - [x] Pointer x: {px}
              - [x] Pointer y: {py}
              - [x] Active font: {font}
              - [x] Font size: {fsize}
              - [x] Path to font: {fontfile}
              - [x] Path to layer image: {limg} (for steering and hinting)
              - [x] Path to flattened document: {dimg} (for steering and hinting)
              - [x] Path to brush image: {bimg}
    - [x] Style Editor (prefix/postfix) (list)
      - [x] Add
      - [x] Remove
      - [x] Edit
        - [x] Tool (picker)
        - [x] Name
        - [x] Text
        - [x] Description
        - [x] Seed
    - [x] Prompt Editor
      - [x] Preset prompts simple text lists/paragraphs for steering AI
      - [x] Add
      - [x] Remove
  - [x] Create new layer menu option: New from AI (creates new AI layer with prompts):
      - [x] Style (picker)
      - [x] Prompt (textbox)
      - [x] Layer dimensions: W x H  - button: [Image Size]
      - [x] Layer position: X, Y  (default 0,0)
        - [x] Button position presets: (math based on image size)
            [TL] [T] [TR]
            [L]  [M] [R]
            [BL] [B] [BR]
      - [x] Seed
  - [x] Create new Layer type: AI Layer
    - [x] AI Layer is created with text to image (pixelmon)
    - [x] AI Layer shows [AI] for type of layer
    - [x] AI Layer tooltip shows Prompt, Style, and engine with model/seed on second line
    - [x] Prompt is embedded into layer for later regeneration
    - [x] Generated pixels embed seed, model, etc.
    - [x] Right click on AI layer shows menu:
      - [x] Prompt
      - [x] Style -> Style options, one checked
      - [x] Generate (runs the AI generator tool and style for the prompt)
  - [x] When a selection is present, pass that to the width and height for the tool
    - [x] Inserts as selection, keeps selection active (for later regen)
  - [x] Create new file menu option:
    - [x] New from AI
      - [x] Dialog:
        - [x] Tool (picker)
        - [x] Style (picker)
        - [x] Seed
        - [x] Prompt (textbox)
        - [x] Image dimensions: W x H
    - [x] Prompt is embedded into image for later regeneration
    - [x] Generated pixels embed tool, args, model, seed, etc.

### TEXT TOOL

#### TEXT STYLES

- [x] Add text style dropdown with save/delete and name for text styles:
  - Font
  - Font size
  - Font bold, italic, underline, strikethrough settings
  - Font mono setting
  - Font lineheight
  - Font CHAR MODE setting
  - Font BG color
  - Font FG color
- Dropdown should have a simple name
- Layout like this:
  ```
  STYLE: [ Heading 1 ^ ] [U] [S] [X]
  ```
- Dropdown with the names of styles
- [U] to Update selected dropdown style based on current setup
- [S] to save new dropdown style based on current setup
  - Show dialog for name
- [X] to delete a style

- [x] When scrolling with the wheel of my mouse over the text dropdown when it is open i do not see a selected item color.
      - I want to be able to hover over a different font in the list to see a realtime preview of the font change

- [x] I would also like to be able to use my arrow keys on the keyboard to go up and down, to choose the font.
    - In this way i can quickly preview fonts in realtime.
    - So if I open the picker, and go to a font with the wheel, then choose down arrow, or whatever, it loads that font but   
      keeps the picker open so i can quickly preview fonts for my text layer/selected text.
      - If the text has selection, just change the selected text, if not, the entire text
      - Keep the same other settings for bold, italic, strikethrough, underline, size, color, baseline, kerning, position, etc.

- [x] I would like to have the option to arrow through fonts in the dropdown menu to show a popup preview
      of the font
      - DRAW.cfg settings:
        - FONT_PREVIEW_FONT_SIZE        - DEFAULT: 16
        - FONT_PREVIEW_PADDING          - DEFAULT: 4
        - FONT_PREVIEW_DELAY            - DEFAULT: 2 seconds
      - THEME.cfg settings:
        - FONT_PREVIEW_FONT_FG_COLOR    - DEFAULT: RGB(0,0,0)
        - FONT_PREVIEW_FONT_BG_COLOR    - DEFAULT: RGB(255,255,255)
        - FONT_PREVIEW_BORDER_COLOR     - DEFAULT: same as tooltip border color
        - FONT_PREVIEW_BORDER_WIDTH     - DEFAULT: same as tooltip border width
        - FONT_PREVIEW_OFFSET_X         - DEFAULT: 10
        - FONT_PREVIEW_OFFSET_Y         - DEFAULT: 4
      - The popup should use the DRAW.cfg and THEME.cfg settings

- [x] I would like to be able to Outline text in a separate color, and have a outline width setting for that color
  - This should live in the font property bar
  - Outline text should work as a per character / selected text attribute and only apply to selected text if it's on.
  - So a checkbox [x] Outline (__) (color chip - click to pick), [ 1->10px ] outline size dropdown

- [x] I would like to be able to have a Shadow text in a separate color, and a X/Y distance for that setting.
  - This should live in the font property bar
  - Shadow text should work as a per character / selected text attribute
  - So a checkbox [x] Shadow (__) (color chip - click to pick), Offset: x:[ 1->10px ] (dropdown) y:[ 1->10px ] dropdown

- [x] I would like a text align in font property bar:
    - [ L | C | R ] (left, center, right)
    - The text should align to the entire body of the text.
    - So if I press L, all text new lines start Left justified same X position for all lines, flush left.
    - So if I press C, all text is centered across all lines in the whole text layer
    - So if I press R, all text is right justified to the edge of the longest line in the text layer,
      and the x position stays the same - spaces are used to position the text so it is flush right.



- [x] Extended editing in text mode with word-processor-style navigation
  - Ctrl+Left / Ctrl+Right: jump to previous/next word boundary (via `TEXT_LAYER_prev_word_pos%` / `TEXT_LAYER_next_word_pos%`)
  - Ctrl+Shift+Left / Ctrl+Shift+Right: select to previous/next word boundary
  - Shift+Home / Shift+End: select from cursor to start/end of line (already existed)
  - Tab: insert 4 spaces
  - Up / Down arrows: move cursor vertically to same X position on adjacent line (with key repeat)
  - Shift+Up / Shift+Down: extend selection vertically
  - Gated global hotkeys during text editing: Ctrl+Shift+Arrow (side toggles), Tab (toolbar toggle), Shift+Tab (pattern tile mode)

- [x] Bold style is good for faux bold, but it makes letters too close together
  - Faux bold synthesis now adds +1px advance for the synthesis pixel, guaranteeing 1px gap
  - Background fill, underline, and strikethrough extend to cover faux bold width
  - Cursor X recomputed after any style toggle (bold/italic/underline/strike) via `TEXT_BAR_apply_style_to_selection`
  - Hit-test and cursor-position functions all account for faux bold advance consistently

- [x] Home, End, Page up, Page down - are causing global transforms while the text tool is still editing and active
  - Added `TEXT.ACTIVE` guard in `KEYBOARD_handle_custom_brush` to skip Home/End/PgUp/PgDn transform handlers when text tool is editing
  - Keys now fall through to `KEYBOARD_handle_text_tool%` for proper cursor navigation

- [x] Pressing enter does not move to new line
  - Fixed TEXT_LAYER_add_char line break shift: `>=` → `>` so chars after Enter belong to the new line
  - Fixed TEXT_LAYER_get_char_x to reset curX to startX when charIdx sits at a line break position

- [x] I should not be able to type off the canvas
  - Auto-wraps text at right canvas edge (word-wrap with char-wrap fallback)
  - Blocks typing/Enter when text would overflow bottom edge
  - Plays pitched-down alert sound + flashing black/white cursor on overflow

- [x] After resizing text, re-editing, pressing Enter shows overflow flash instead of creating new line
  - `TEXT_newline` overflow check was requiring room for TWO lines (current + phantom next) instead of one
  - Fixed to check only whether the actual new line fits: `nlCurY% + nlLineH% - 1 > canvasH - 1`

- [x] Key repeat rate is too fast
  - Arrowing back after typing some text ...
  - and pressing DELETE sometimes deletes more than 1 character

- [x] Hide/Show All is not hiding the text properties bar
  - F11 should hide/show all chrome / widgets in the UI

- [x] I should be able to click while entering text if I click ON previously entered text (in the same text entry session)
  - To move the cursor there
  - Added `TEXT_LAYER_get_cursor_at_pos%()` — nearest-position hit-test for canvas clicks
  - Modified `MOUSE_tool_text()` to move cursor within active text layer on single-click
  - Clicking outside the text area still creates a new layer as before

- [x] Cannot choose transparent as background color
  - Left-click FG/BG swatches opens palette picker; right-click toggles transparent
  - BG/FG color changes now sync to all existing characters in active text layer
  - Choosing transparent BG from the picker now applies to currently selected text, including when BG was already transparent before opening the picker
  - Fixed _PRINTSTRING filling char cells with opaque black (_PRINTMODE _KEEPBACKGROUND)
  - Fixed _MEM clear for guaranteed transparent buffer before text render

- [x] When the canvas is panned under the text tool properties bar i am able to still pick colors
  and interact with the canvas, even though the mouse pointer is over the
  text properties bar.
  - Added catch-all guard in `MOUSE_handle_gui_early%` that blocks all canvas interaction when mouse is within `TEXT_BAR_in_bounds%`, regardless of button state
  - Fresh button presses on the bar are flagged via `UI_CHROME_CLICKED%` to prevent spurious tool-release actions

- [x] I cannot select any characters to change their properties.
  - I cannot use SHIFT to select
  - I cannot span select with mouse, etc.
  - When I click anything in the text tool properties bar, like color, style, etc.
  - It changes all text.
  - I want to be able to change individual parts of the text like in photoshop,
  or word, etc. Where you can have rich editing experience.
  - **Fixed**: Added full selection system (Shift+Arrow, Shift+Home/End, mouse drag, Shift+click, Ctrl+A)
  - Style buttons (B/I/U/S), font, size, and color changes now apply only to selected range
  - Ctrl+C/X/V clipboard with rich formatting preservation (per-character attributes)
  - Ctrl+A → Delete/Backspace now visually clears (TEXT_LAYER_render clears imgHandle when charCount=0)
  - All Ctrl+letter hotkeys (A/B/C/I/U/V/X) work with CapsLock on or off

- [x] I cannot re-edit the existing text of the layer, the idea I am after is to have
      a non-destructive, always editable (until rasterized) text layer type.
  - **Fixed**: Single-click on a committed text layer enters re-edit mode (cursor at click position)
  - Double-click also positions cursor at click point instead of end-of-text
  - `TEXT_sync_bar_to_cursor` syncs TEXT_BAR style toggles (B/I/U/S, font, size) from character at cursor
  - Text layers remain `LAYER_TYPE_TEXT` until explicitly rasterized — fully non-destructive

- [x] Add settings in DRAW.cfg for:
  - FONT_DEFAULT_FONT - default font to choose when entering text if empty use as we have already
  - FONT_DEFAULT_SIZE - default size in legal range if empty use program default

- [x] The font dropdown menu should be longer down the screen, to about 75% of the size 
  - If there are enough fonts to warrant that, otherwise render as long down as the fonts need.
 
- [x] Add ./DRAW_FONT_BLACKLIST.txt support (if it exists)
  - This should contain lists of fonts by path/filename that are NOT shown in the font picker

- [x] Add ./DRAW_FONT_FAVORITES.txt support (if it exists)
  - This should contain a list of fonts that are shown at the very top of the font picker list.
  - Just the font name, not the whole filename obviously, should be in the dropdown.
  - Then a divider --- after them


## Native DIalogs
- [x] Open
- [x] Save
- [x] Message Box
- [x] Input Box
- [x] Color Palette Mixer
  - [x] RGB
  - [x] HSL
- [x] DRAW Settings Configuration Dialog


## - [x] Palette Ops

### States
- Tracked when it is active in global.
- Turn off when: clicking any other tool, using any other menu option
- When active show image: `THEMES/{theme}/IMAGES/DRAWER/canvas-ops-on.png`
- When inactive show image: `THEMES/{theme}/IMAGES/DRAWER/canvas-ops-off.png`
- When L-CLICK turn on
- When L-CLICK while on, turn off

### Palette Ops should do this:
- L-CLICK on Palette Ops button: 
  1. Automatically remap to the current palette like Palette -> Remap to Palette.
    - Present no dialog

#### Pallete Ops Mode (when on)
- Double L-CLICK on any palette strip color = Change color using custom color dialog
- When the color has changed, automatically change the old color that was used in the image to the new color
- L-CLICK on any palette strip color marquee magic-wand select across entire image the color chosen
  - After a 500ms delay
  - Deselect to remove wand selection
- Middle-CLICK on any palette strip color = Delete color (but not on disk this is temporary)
  - Deleted color if used in image should remap to next nearest neighbor
- R-CLICK on any palette strip color mark it
  - Marked colors can be deleted with middle click
- SHIFT+Middle Click on any palette strip color = Insert new blank color between currently clicked color and the one next to it.
- DRAG on any palette strip color to rearrange it
- ALL of these click options should block/guard against similar gestures/hotkeys/states

## PIXEL ART COACH

- Analyze artwork for:
  - [x] Pixel Perfect Deviations - Jaggies
  - [x] Clusters
  - [x] Islands
  - [x] Readability
  - [x] Pillow Shading
  - [x] Over Dithering
  - [x] Banding
  - [x] Fat Pixels
  - [x] Light Source Inconsistencies
  - [x] Contrast Issues
  - [x] Value Issues
  - [x] Noise

> A coach to make good pixel art



## FILE FORMATS IMPORT
- [x] ASEPRITE Using QB64_GJ_LIB/ASEPRITE
- [x] PSD
- [x] PCX (built into LOADIMAGE)



## ADD FILE -> EXPORT

> Create new File submenu with all these options to export flattened image:

- [x] PNG (DRAW NATIVE)
- [x] PNG
- [x] GIF
- [x] JPG
- [x] TGA
- [x] BMP
- [x] HDR
- [x] ICO
- [x] QOI



## FILE DIALOG
- [x] Allow custom places between OS places, and user favorites:
  - This will allow us to have DRAW specific directories included for convenience
  - [x] Modify File DIALOG API to support
    - [x] Place name, color, hotkey, icon, directory
  - [x] `FD_add_custom_place` / `FD_clear_custom_places` API in FD-API.BM
  - [x] `DRAW_FD_register_custom_places` in GJ-DIALOG-SCALE.BM injects: DRAW, Samples, User Data, Palettes, Brush Sets
- [x] Font size is too small - make it configurable.
  - [x] 9 per-element font scale fields in `FD_CONFIG_OBJ` (FD-TYPES.BI)
  - [x] Rendering uses scales in FD-RENDER.BM, FD-API.BM layout
  - [x] Dynamic row/bar heights in `FD_STATE_OBJ` replace old hardcoded constants
  - [x] FD-INPUT.BM and FD-FS.BM converted to use dynamic heights
  - [x] Persisted in `DRAW.cfg` as `FD_FONT_SCALE` (0=use TOOLBAR_SCALE, 1-4 explicit)
  - [x] Injected via `DRAW_FD_apply_font_scale` in GJ-DIALOG-SCALE.BM before every dialog open
  - [x] Clamped 1–4x, defaults to TOOLBAR_SCALE when 0
  - Config keys: `titleFontScale`, `placesFontScale`, `pathFontScale`, `contentFontScale`, `previewFontScale`, `inputFontScale`, `filterFontScale`, `statusFontScale`, `sortFontScale`

- [x] Use button images for file dialog functions:
  - [x] Up directory (`FD_ICON_TB_UP`)
  - [x] View Modes:
    - [x] List (`FD_ICON_TB_LIST`)
    - [x] Details (`FD_ICON_TB_DETAILS`)
    - [x] Thumbnails (`FD_ICON_TB_THUMBS`)
  - [x] Show hidden files (`FD_ICON_TB_HIDDEN`)

- [x] Custom icons:
  - [x] Places bar types:
    - [x] Root (`FD_ICON_PLACE_ROOT`)
    - [x] Home (`FD_ICON_PLACE_HOME`)
    - [x] Desktop (`FD_ICON_PLACE_DESKTOP`)
    - [x] Downloads (`FD_ICON_PLACE_DOWNLOADS`)
    - [x] Pictures (`FD_ICON_PLACE_PICTURES`)
    - [x] Music (`FD_ICON_PLACE_MUSIC`)
    - [x] Videos (`FD_ICON_PLACE_VIDEOS`)
  - [x] Content file types (case insensitive matching via `FD_ICONS_for_extension%`):
    - [x] DRAW stuff:
      - [x] DSETs (.dset) — `FD_ICON_DSET`
      - [x] Palettes (.pal) — `FD_ICON_PALETTE`
      - [x] Gradients (.grad) — `FD_ICON_GRADIENT`
    - [x] Any other document — `FD_ICON_DOCUMENT`
    - [x] Folder — `FD_ICON_FOLDER`
    - [x] Fonts (.ttf, .otf, .psf, .f??, .fon) — `FD_ICON_FONT`
    - [x] Images (.bmp, .drw, .gif, .jpg, .jpeg, .png, .webp, .qoi) — `FD_ICON_IMAGE`
    - [x] Executables (.run, .sh, .exe, .bat, .ps1) — `FD_ICON_EXECUTABLE`
    - [x] Text files (.txt, .md, .doc) — `FD_ICON_TEXT`
    - [x] Text mode files (.ans, .asc, .xb, .xbin) — `FD_ICON_TEXTMODE`
    - [x] Sounds (.wav, .mp3, .ogg, .sf2, .rad, .mod, .s3m, .xm, .it, .mid) — `FD_ICON_SOUND`
    - [x] Config files (.cfg, .rc, .ini) — `FD_ICON_CONFIG`
  - [x] 12 icon tint colors in FD-THEME.BI (`FD_CLR_ICON_*`)
  - [x] Procedural rendering via `FD_ICONS_render` in FD-ICONS.BM (29 icon IDs, no PNG assets needed)



## [x] LOAD IMAGES INTO BINS
- [x] Add to right click on brush bin, pattern bin:
  - [x] LOAD IMAGES
  - [x] Show FILE OPEN DIALOG
  - [x] Allow multiple files to be selected and loaded into the bins in whatever mode
    - Honor the DRAWING MODE





## - [x] SMART GUIDES
Automatically snap to layer candidates when near X/Y/W/H bounds of neighbors
- [x] When hovering over canvas draw horizontal line for horizontal snaps to neighbor bounds
- [x] When hovering over canvas draw vertical line for vertical snaps to neighbor bounds

### MENU CHANGES
- [x] View -> Smart Guides
- [x] Edit -> Snap Smart Guides

## GUIDE LAYERS
- [x] Already completed through smart guides ;) 
  - Any opaque line becomes a guide, which can be snapped to



## DRAWER SET WHEEL LOAD FROM DISK
- [x] Using mousewheel over the bins of the drawers for each mode ...
  - [x] Load the next dset available on disk with mousewheel down
  - [x] Load the previous dset available on disk with mousewheel up


## - [x] Color BITMAP fonts
- [x] See DEV/FONTS/COLOR_BITMAP
- [x] Lots of examples there



## - [x] COLOR MIXER (replaces COLOR-OPS)
- [x] Toggle with COLOR MIXER button on/off 
  - [x] rename color-ops-off.png to color-mixer-off.png
  - [x] rename color-ops-on.png to color-mixer-on.png
  - [x] color-mixer-off = color dialog invisible
  - [x] color-mixer-on = color dialog visible
  - [x] New Tooltip: L-CLICK to show/hide color dialog
  - [x] Add to PALETTE -> [x] Color Mixer 
  - [x] Should remain at same z-index as Preview Window
  - [x] Can be freely moved inside DRAW window like preview window
  - [x] Should be hidden if user drags over it while drawing like other chrome
  - [x] State should be remembered per session, per document, etc.
    - [x] DRAW_CFG COLOR_MIXER_VISIBLE = true/false
  - [x] When picking colors from ANYWHERE else in DRAW, synchronize to the color mixer
    and pick that same color, if possible, honoring quantization, etc. if setup.


## - [x] FILE DIALOG IMPROVEMENTS
- [x] Make the cursor focus default to the filename for:
  - [x] Save dialogs

- [x] Use custom fonts (like colorpicker in QB64_GJ_LIB/COLOR_PICKER)
- [x] Use a theme (like colorpicker in QB64_GJ_LIB/COLOR_PICKER)

- [x] Add tooltip for buttons and panes
  - [x] DIALOG TITLE BAR AREA:
    - [x] Resize and move as needed your preference will be remembered
  - [x] BUTTONS:
    - [x] Up directory - BACKSPACE, or L-CLICK to cd ..
    - [x] Create directory - Create new directory in current directory
    - [x] Detail View - Show files with icon, name, type, size, and modified time
    - [x] List View - Show files just with icon, name and extension
    - [x] Thumbnail View - Show files as thumbnail images - CTRL+M-WHEEL to zoom in/out
    - [x] Show Hidden Files - Show hidden files (. (dot) files)
    - [x] Toggle Image Preview Pane - Show or hide the image preview pane
  - [x] PANES:
    - [x] Current Path - You are here
    - [x] / - File System Root - Root of the entire computer file system
    - [x] Home - Users Home Directory - Also known as $HOME or ~
    - [x] Desktop - Users Desktop Directory - ~/Desktop (or Desktop if Windows)
    - [x] Documents - Users Documents Directory - ~/Documents or (My Documents if Windows)
    - [x] Downloads - Users Downloads Directory - ~/Downloads (or My Downloads if Windows)
    - [x] Pictures - Users Pictures Directory - ~/Pictures (or My Pictures if Windows)
    - [x] Music - Users Music Directory - ~/Music (or My Music if Windows)
    - [x] Videos - Users Video Directory - ~/Videos (or My Videos if Windows)
    - [x] DRAW SPECIFIC:
      - [x] DRAW - DRAW Program Directory - where the binary/exe ran from
      - [x] Samples - DRAW Samples Directory - Inspiration and examples of what you can do
      - [x] User Data - DRAW User Data Directory - your own DRAW stuff! Palettes, Drawer Sets, Fonts, etc.
      - [x] Palettes - DRAW ASSETS: Palletes - All the built-in palettes
      - [x] Drawer Sets - DRAW ASSETS: Drawer Sets - All the built-in drawer sets
    - [x] CUSTOM PLACES:
      - [x] User Favorited Places - R-CLICK on any folder to add to favorite places! R-CLICK again to remove


## LOSPEC DIALOG IMPROVEMENTS
- Fix the alignment of the text in the search box
  - Is Lospec dialog even using our text input lib?



## - [x] SYMBOL LAYERS
- [x] Menu: Layer -> New Symbol Layer
- [x] Menu: Layer -> Synchronize Children (when parent symbol layer is selected)
- [x] SYMBOL LAYERS exist as 1 source layer identified as [SYM] known as symbol parents
  - [x] In essence symbol parent layer is embedded image exactly the size of the extents of the symbol parent content
        when it is duplicated from the symbol parent layer and creates symbol children
- [x] A symbol parent layer that is duplicated creates (SYM@) symbol child instances
- [x] A symbol parent layer, when edited will automatically update any other symbol child used in other places except for these properties which remain untouched for each other child instance of the symbol:
  - [x] Visibility
  - [x] Opacity
  - [x] Opacity lock
  - [x] Position
  - [x] Scale
  - [x] Rotation
  - [x] Blend mode
- [x] When symbol layer is duplicated it creates symbol children instance layers
- [x] A symbol childs instance layers pixel data cannot be edited directly
- [x] Symbol child instance layers can have unique properties from the symbol root:
  - [x] Visibility
  - [x] Opacity
  - [x] Opacity lock
  - [x] Position
  - [x] Scale
  - [x] Rotation
  - [x] Blend mode
- [x] Symbols parents and children are treated otherwise identically as regular layers
  - [x] They can be grouped
  - [x] Selections can be made with them
  - [x] They can be selected
  - [x] They can be rearranged in any order
- [x] Symbol parent layers can be hidden in the canvas while their child instances can still be visible
  - [x] Independent of the parent because of the unique properties
- [x] When a child symbol layer is selected
  - [x] Modifications made to it for scale, and rotation must be non-destructive and operate as an instance of the parent symbols own image data

  

## - [x] EXTRACT FROM GRID
- [x] Menu: FILE -> EXTRACT FROM GRID
  - [x] Exports a flattened image (whatever layers are visible)
    - [x] According to the grid width and height.
    - [x] In this way I can quickly build icons and tiles
    - [x] Evaluate each grid cell:
      - [x] If the grid cell contains ANY non-transparent pixels:
        - [x] Consider the entire cell exportable and save a flattened image of that cell:
          - [x] X,Y = grid cell X, Y top left, and W, H = width and height of grid
          - [x] If the pixel contents exist only on a single layer (or within a layer group)
            - [x] Export the image as the layer name or layer group name
          - [x] Else: export the image as the image filename-grid-### where ### is a number
- [x] If before choosing this menu option, a selection exists:
  - [x] Operate only on any grid cells present in the selection area
  - [x] The selection area can be non rectangular as well, but to qualify being part of the extraction, the entire grid cell must be part of the selection.


## - [x] EXTRACT TO LAYERS FROM GRID
- [x] Menu: LAYER -> EXTRACT TO LAYERS FROM GRID
- [x] Same logic and ruleset as FILE -> EXTRACT FROM GRID, but instead of SAVING files
  - [x] Just creates new layers in place, with the same numbering, etc. 
  - [x] The new layer for the grid cell maintains it's pixel data and position.
    - [x] After extracting the grid cell, position the cell where the original layer cell was, just on top.
  - [x] Same rules, same schemes.


## Global Fill
- [x] With Fill tool, hold `f` while flood filling to replace contiguous colors on all layers with filled color, honors FG and BG
- [x] With Fill tool, hold `Shift+f` while flood filling to replace all colors across document and all layers with filled color, honors FG and BG
- [x] Left click = Fill with FG
- [x] Right click = Fill with BG

## Image Browser (For drag/drop to brush and pattern slots)
- [x] Since drag and drop is not ubiquitously available across all OS in QB64PE...
  - [x] Create a Image Browser using FILE_DIALOG from QB64_GJ_LIB includes library
    - [x] OK to add new modes/features in base library as necessary to make it a floating panel compatible
      - [x] Add library setting/option to configure so most code is reused as possible!
      - [x] Theme can be identical
      - [x] Render at same display scale as the COLOR MIXER, if possible because that provides a lot more room,
  - [x] Identical to File -> Open / File -> Save (as) Dialogs already in DRAW, EXCEPT:
    - [x] Floats like COLOR MIXER
    - [x] Is toggleable via a menu item View -> Browser
      - [x] Hide / Show with the checkmark thing
    - [x] Is toggleable from and Replaces 'File Import image' from 'Open File' Toolbar button with browser show/hide (open tool open.png, etc.)
      - [x] When it is open and visible show with outline on the button border
      - [x] When it is closed no border on button
    - [x] Remembers width/height and position
    - [x] Uses the same PLACES as regular dialogs
    - [x] Default to Thumbnail view Zoom of 2x
    - [x] Default to Preview Pane open
    - [x] Remembers the last directory it was open to with the file
    - [x] Allows dragging multiple files outside of the browser onto:
      - [x] Canvas (handled via File -> Import Image function)
      - [x] Layer panel -> Creates a new layer named as filename (with same File -> Import Image function)
      - [x] Brush Bins and Pattern Bins -> Imports Image(s) to bin (using same method as right click context for this)
        - [x] Should honor the existing way that works about how to position things, etc.
        - [x] If dragging more than 30 things, create new dynamic DSETs on disk in USER called dynamic_import_n where n = number for the DSET if it needs to make 10 DSETs becuase there were 100 images dropped, for example ... DSETs should be immediately navigable with mousewheel hover like always, after DROP.
    - [x] Use existing file dialog theme colors and font sizes and dimensions besides.
    - [x] Title floating window title bar as BROWSER
- [x] Add additional Right Click menu to files for FILE_DIALOG (ok to modify library):
  - [x] IF right click on file:
    - [x] Rename
    - [x] Supports multiple files selected (same level in menu as Rename though):
      - [x] Copy
      - [x] Cut
      - [x] Paste
      - [x] ---
      - [x] Delete
      - [x] ---
      - [x] Add to Recent Files List
    - [x] Open with Default OS Program
    - [x] Reveal Folder
      - [x] Uses OS specific opening of folder the file resides in whatever program OS deems to do
    - [x] Open in DRAW (loads file as new project, with unsaved-changes prompt)
  - [x] IF right click on empty area in file pane:
    - (IF have copied or cut files previous in BROWSER):
      - [x] Paste (Copy)
      - [x] Move (Cut)
    - [x] Create Folder
    - [x] Reveal Folder
    - [x] Add to Browser Places
- [x] Needs cleanup on exit for all image handles / fonts used, etc.
- [x] Initial size of Browser should be configurable in DRAW.cfg with:
  - [x] BROWSER_WIDTH
  - [x] BROWSER_HEIGHT
  - [x] BROWSER_POS_X
  - [x] BROWSER_POS_Y
  - [x] BROWSER_DEFAULT_FOLDER
  - [x] BROWSER_DEFAULT_VIEW_MODE
  - [x] BROWSER_DEFAULT_ZOOM_LEVEL (used for Thumbnail view)
  - [x] BROWSER_DEFAULT_SORT_TYPE
  - [x] BROWSER_DEFAULT_SORT_ORDER
  - [x] BROWSER_DEFAULT_PREVIEW_OPEN (true/false)
    - [x] This lets user open to a specific folder by default
    - [x] If not specified use the following in order (as available/applicable):
      - [x] Last open directory from BROWSER as loaded in from FILE
      - [x] Current file directory (if one is loaded already)
      - [x] Users Pictures directory
      - [x] Users Documents directory
      - [x] DRAW program directory

## CANVAS RESIZE
- [x] Currently Image -> Resize does not do anything to the content, this should then be moved to Image -> Resize Canvas...

### IMAGE RESIZE
- [x] We do need an option to resize the image and all layers in it WITH the content, up and downscale accordingly
  - [x] Under Image -> Resize Canvas... put Image -> Resize Image with Content...
  - [x] You may need to increase the number of valid menu options

## ADVANCED BAR AND EDIT BAR
- [x] If the contents of the bar buttons cannot be shown all at once, allow the edit bar and advanced bar to be scrolled with mousewheel up/down

## MARQUEE RECT IMPROVEMENTS

- [x] I would like the edges of the marquee rectangle selections and crop boundaries to be resizable from the entire edge, not just the center anchor if that's possible.
  - [x] The anchor is often not in view, and makes it very painful to have to pan the canvas find the anchor resize, then go back to what i was doing.
  - [x] No modifier key needed — full-edge hit detection works everywhere along the edge.

## GRID HOTKEY IMPROVEMENTS
> I would like to modify the grid hotkeys:

- [x] Hold `g` and: 
  - [x] Up arrow = resize grid height up
  - [x] Down arrow = resize grid height down
  - [x] Left arrow = resize grid width down
  - [x] Right arrow = resize grid width up
- [x] Remove the , and . bindings and change them accordingly.

> Also, I would like to be able to offset the grid from the top left origin

- [x] Hold `g` and `CTRL` plus the arrows to position the offset:
  - [x] Up arrow = move offset up (negative OK)
  - [x] Down arrow = move offset down
  - [x] Right arrow = move offset right
  - [x] Left arrow = move offset left
- [x] We need new DRAW.cfg settings for the grid offset as well:
  - [x] GRID_OFFSET_X
  - [x] GRID_OFFSET_Y
- [x] We also need to provide a way to change this in Edit -> Settings


## CROP TOOL IMPROVEMENTS
- [x] Allow crop tool bounding box to grow the canvas size.
  - [x] When the crop tool selects the entire canvas, it can grow top, bottom, left, right
  - [x] This should allow the crop tool bounding box to reach on top of the apron
  - [x] When the crop boundary is larger than the existing canvas size, resize the canvas:
    - [x] If the canvas is being grown to the right, anchor the contents to the left
    - [x] If the canvas is being grown to the left, anchor the contents to the right
    - [x] If the canvas is being grown up, anchor the contents to the bottom
    - [x] If the canvas is being grown down, anchor the contents to the top
    - [x] If the canvas is being grown in more than one direction, attempt to make it sane anchor:
      - [x] If both top and left are being grown: anchor to bottom right
      - [x] If both bottom and right are being grown: anchor to top left
      - [x] etc.
      - [x] If all sides are being grown anchor to center
  - Operation should happen the same as Image -> Resize Canvas... (except no size prompt, and custom anchoring).
- [x] Crop tool INSIDE existing bounds operates as it does now.

## RECT GRID MODIFIER
- [x] While drawing a Rect, before releasing, user can press arrows:
  - [x] Right = add equidistant divisible section 
    - [x] Press right 1 time = center of rect horizontally
    - [x] Press right 2 times = divide rect into 3rds
    - [x] Press right 4 times = divide rect into 4ths, etc.
  - [x] Left = subtract a section
  - [x] Up = subtract a vertical section
  - [x] Down = divide vertically like horizontal, same idea.


## ELLIPSE GRID MODIFIER
- [x] Same as RECT grid, but with polar coordinates
  - [x] Left/right = in pie slices
  - [x] Up/down = add concentric circles inside equidistant


## LINE RAY MODIFIER
- [x] Same as RECT grid, but draw spokes out of the line according to equidistant angles


## COLOR MIXER IMPROVEMENTS

### COLOR MIXER HEX CODE
- [x] Clicking in hex code input should select it by default so user can quickly replace with paste from external text source, etc.

### COLOR MIXER COLOR HISTORY
- [x] Add color history under SNAP area for up to 16 recent colors
  - [x] 2 rows of 8 color chips

### COLOR MIXER COLOR FG<->BG BLENDER
- [x] Add color blender with two stops FG on left, BG on right
  - [x] Interpolate the color between FG and BG in a strip
  - [x] Allow user to pick the color from anywhere on the blended strip
  - [x] Honor SNAP setting if enabled


## MIDI MUSIC
- [x] Allow playback of .MID files if they exist using default QB64PE font, or configured SF2 file.


## TEXT TOOL PICKUP STYLE
- [x] When user arrows back to previous character, automatically adjust the text style to reflect current cell


## Line ends (arrows, cubes, dots)
- [x] Press s to cycle shapes for start of line
- [x] Press e to cycle shapes for end of line


## Bezier Curve
- [x] Like photoshop pen tool





## Smart Shapes
> When clicking and holding on the smart shape button, present a submenu of buttons that looks like:
> DEV/smart-shapes.png
> Each of these buttons is separate and engages the smart shape below:
> Present them in a straight row starting from the side of the smart-shape button that is facing towards the canvas, and create a strip of buttons to choose shape, one of:
> Polygon, Pie/Donut, Rounded Rect, Tab, Pill, Pac-Man, 3D Cube, Bevel Rect, or Arrow
> As the user holds left button to choose a shape, keep the row of buttons expanded.
> When the user moves the mouse while holding the left button down (left drag), highlight the shape button they are hovering over like we do to show the shape is picked in the toolbox
> When the user releases the left button, the tool that is engaged is the tool they are over.
> IF the user is not over a tool when they release the button, no tool change happens
> WHEN the user releases the left button hide/collapse the button row of smart shapes and make the smart shape button render as the selected smart shape. 
> On document start/open always set the smart shape to the default smartshape.png, but keep the current smart shape remembered if it is changed DURING a session - does not need to restore or maintain state in documents.

The idea of smart shapes is that the user begins drawing, and then uses keys to
modify the shape they are making. All smart shapes should snap to the grid and honor the grid and symmetry according to regular shapes like rect/ellipse.

See below for how each shape works once engaged:

### Polygon
> A polygons minimum sides is 3, and maximum is 30

Movement of the mouse as the shape is created makes it wider/taller/shorter/etc. as normal rect drawing would. 

The depth of the points needs explaining. So if user draws a polygon with 5 sides, pressing the right arrow would create a middle dividing point so that it can make a star shape, the depth of this star is determined by left arrow and right arrow. The star can have depth less than the perimeter of the polygon, or greater than. In this way the polygon can have bursts, stars, and so on.

- [x] Start as triangle
- [x] Up arrow add edges,
- [x] Down arrow remove edges
- [x] Left arrow decrease point depth
- [x] Right arrow increase point depth

> TOOLTIP LINE 1: SMART-SHAPE: POLYGON - UP-ARROW: Add edge, DOWN-ARROW: Remove edge
> TOOLTIP LINE 2: LEFT-ARROW: Decrease point depth, RIGHT-ARROW: Increase point depth


### Pie / Donut
> Pie / Donut the user can create pie charts with equidistant divisions of slices of pie, or adjusted custom slice sizes. If the user uses the left arrow or right arrow, a new hole inside the middle of the pie chart should be created, which consists of an outline, and a blank area so it looks like an outlined O or donut, the idea is that we can create very quick GUI dials and things using this method by creating a simple knob with spokes (the slices), in donut mode which makes it look like a outlined O, but with the spokes neatly divided perfectly around the circle/donut, and enclosed by two ellipses/circles..

> The minimum amount of slices is 0 and maximum is 30.
The maximum radius of the middle donut hole is 90% of the size of the shape, with minimum being 0 (or no donut hole)

- [x] Start as circle
- [x] Up arrow add segments
- [x] Down arrow remove segments
- [x] Left arrow decrease hole size
- [x] Right arrow increase hole size

> TOOLTIP LINE 1: SMART-SHAPE: PIE/DONUT - UP-ARROW: Add segment, DOWN-ARROW: Remove segment
> TOOLTIP LINE 2: LEFT-ARROW: Decrease donut hole size, RIGHT-ARROW: Increase donut hole size


### Rounded Rect
> Rounded rectangle just draws a rect that's got round corners.
User can decrease corner radius to 1 so it's a regular rect with only 1 px round edge, or up to a full radius of 30 with max roundness, but the radius should be impossible to create intersecting radius corners. so if the rect is 10x10 the maximum radius for corners would be 5 because they would touch, etc. Can accommodate up to 30 radius but only if shape is > 60px height or width.
- [x] Start as rect with 3px roundedness
- [x] Up arrow increase corner radius 
- [x] Down arrow decrease corner radius

> TOOLTIP LINE 1: SMART-SHAPE: ROUNDED RECTANGLE
> TOOLTIP LINE 2: UP-ARROW: Inc. corner radius DOWN-ARROW: Dec. corner radius


### Tab
> A tab is a rounded rectangle that has 1 flat edge vertically.
> Top left corner - rounded, top right corner - rounded, bottom left corner sharp 90, bottom right corner sharp 90.
The idea is the user can quickly create tabs. The flat edge can be cycled around each edge so the user could create a tab that is horizontal, or vertical, on any edge.

- [x] Start as rect
- [x] Up arrow round top corners more
- [x] Down arrow round top corners less
- [x] Left arrow cycle tab bottom side left
- [x] Right arrow cycle tab bottom side right

> TOOLTIP LINE 1: SMART-SHAPE: TAB - UP-ARROW: Round tab more, DOWN-ARROW: Round tab less
> TOOLTIP LINE 2: LEFT-ARROW: Cycle tab side left, RIGHT-ARROW: Cycle tab side right


### Pill
> A pill is a rounded rect, up to an oval in roundness, that has dividers evenly based on how many options there are. Like a radio control, it is meant to choose one of many options in the sections of the pill. THe shape is called pill because the left or right sides are ( ) in shape, a pill can exist vertically as well, but is less common, and we don't need to worry about that we can rotate it.

For example a user could create a sliding ON/OFF by creating a pill 20 wide, with 1 divider creating 2 options, one for off, one for on.

- [x] Start as rect
- [x] Up arrow increase roundness 
- [x] Down arrow decrease roundness
- [x] Left arrow decrease segments
- [x] Right arrow increase segments

> TOOLTIP LINE 1: SMART-SHAPE: PILL - UP-ARROW: Round pill more, DOWN-ARROW: Round pill less
> TOOLTIP LINE 2: LEFT-ARROW: Decrease segments, RIGHT-ARROW: Increase segments


### Pac-Man
> A Pac-man is simply a pie chart with a single slice that is cut out of the circle. 
> The slice size is the mouth. The mouth can be wider or closed completely.
> The hole in the middle affords the ability to create dials that show traversal like Ableton live does with the Pacman mout facing down, and the value traversal going through the body.

- [x] Start as circle
- [x] Up arrow increase mouth size
- [x] Down arrow decrease mouth size
- [x] Left arrow decrease inner hole
- [x] Right arrow increase inner hole

> TOOLTIP LINE 1: SMART-SHAPE: PAC-MAN - UP-ARROW: Inc. mouth size, DOWN-ARROW: Dec. mouth size
> TOOLTIP LINE 2: LEFT-ARROW: Decrease inner hole, RIGHT-ARROW: Increase inner hole



### 3D cube / 3D polygon (dice)
> 3D shape/polygon (we can start with cube)
> Simply draws a 3D cube wireframe (no lighting)
> Controls explain how it works.
> For now 3D cube is enough but I would love to be able to create polyhedron dice shapes for this tool etc. D4, D6, D8, D10, D12, D20, D30, etc. Press numbers while drawing for the dice sides: 4 = D4, 6 = D6, 8 = D8, 0 = D10, 2 = D20, 3 = D30, 1 = D12

User will take the wireframe and do what they want, fill or not.

- [x] Start as rect
- [x] Up arrow increase z-depth
- [x] Down arrow decrease z-depth
- [x] Left arrow rotate left
- [x] Right arrow rotate right
- [x] Mouse wheel up rotate up
- [x] Mouse wheel down rotate down

> TOOLTIP LINE 1: SMART-SHAPE: 3D - UP-ARROW: Inc. Z, DOWN-ARROW: Dec. Z
> TOOLTIP LINE 2: LEFT-ARROW: Rotate left X, RIGHT-ARROW: Rotate right X, MW-UP/Down: Rotate Y


### Bevel rect
> Idea of bevel rect is that the bevel is created using outlines/wireframes
> Often we need to create a beveled rectangle.
> THe controls explain

- [x] Start as rect
- [x] Up arrow increase bevel size
- [x] Down arrow decrease bevel size
- [x] Left arrow decrease border size
- [x] Right arrow increase border size
- [x] Press I - change to inner
- [x] Press O - change to outer
- [x] Mouse wheel up increase z-depth (angled edges)
- [x] Mouse wheel down decrease z-depth angled edges

> TOOLTIP LINE 1: SMART-SHAPE: BEVEL RECT. - UP-ARROW: Inc. bevel size, DOWN-ARROW: Dec. bevel size
> TOOLTIP LINE 2: LEFT-ARROW: Dec. border size, RIGHT-ARROW: Inc. border size, I:Inner, O:Outer, MW-Up/Down: Z


### Arrow
> Arrow consists of the stem (the line part facing the triangle)
> The triangle head, and it's concavity.
> User can change width/length of stem, and arrow fatness
> User can change concavity which makes arrow head curved

- [x] Start with arrow shape
- [x] Up arrow make arrow stem fatter
- [x] Down arrow make arrow stem skinnier
- [x] Left arrow make arrow head shorter
- [x] Right arrow make arrow head longer
- [x] Mouse wheel up increase head concavity
- [x] Mouse wheel down decrease head concavity

> TOOLTIP LINE 1: SMART-SHAPE: ARROW - UP-ARROW: Fatter stem, DOWN-ARROW: Thinner stem
> TOOLTIP LINE 2: LEFT-ARROW: Shorter head, RIGHT-ARROW: Longer head, MW-Up/Down: Head concavity



## 3D TEXT
- [x] Just like Smart Shape 3D, but on text.


## APRON .5 SIZE of canvas = phantom draw area (to prevent clips)
- [x] Right now the rotation/movement of something off the canvas into the apron area clips it.
  - [x] It should still not be visible when on the apron, or partially hidden when on part of the apron
  - [x] But the pixels should not be destroyed just by moving things into the apron
  - [x] This would let it not clip
- [x] User should be able to click on apron when drawing shapes, lines, etc. to end them, 
  - [x] so they continue beyond the canvas



## QOL - SELECTION HIDING
- [x] I would like to be able to use CTRL-h to hide and show the selections without clearing them
  - [x] This is just like photoshop.
- [x] Make sure CTRL is down then press h = toggle selection visibility if there is one to toggle

## QOL - MARQUEE CONTENT MOVES
- [x] When moving selections with content using CTRL+arrows, CTRL+SHIFT+arrows:
  - [x] Moved content leaves behind the background color
    - [x] Including if it's transparent background
  - [x] This will make it much easier and less time consuming to move stuff around



## TDF Font Support — DONE

- [x] Using what we learned in kaleidotron
      (format mirrors Mike Krueger's `retrofont`, which kaleidotron's
      `src/decode/tdf.rs` delegates to — see the verification note below)
- [x] Actual Rendering of the TDF as pixels, edit, type, like a regular font.
- [x] Include the 1000+ TDF fonts. (3757 unique faces shipped)
- [x] For TDF Fonts allow rendered with antialias and allow downsize with
      antialias so it can be resized in a way that doesn't lose information.

Implementation: `GUI/TDF-FONT.BI/BM` (parser + CP437 rasteriser),
`GUI/TDF-BROWSER.BI/BM` (picker). Menu: TOOLS > THEDRAW FONT...,
command palette "Browse TheDraw Fonts", action **1530**.

### Why it looks the way it does

**A TDF glyph is a grid of CP437 character cells, not pixels.** Each letter is
rasterised through the 8x16 VGA font, so it drops straight into DRAW's existing
bitmap-font path — `TEXT_LAYER_measure_char%` / `TEXT_LAYER_draw_bitmap_char`
needed one new branch each, no new pixel machinery. Colour faces carry per-cell
VGA attributes and are flagged `isColorBitmapFont` so the existing blit passes
their colours through untouched; block/outline faces tint with the paint colour.

**Assets are deduplicated, not raw.** The wild corpus is 1238 files / 8621 faces
/ 51 MB, of which **4864 faces are exact duplicates** (the same face repackaged
across collection bundles) and 148 files contribute nothing new at all.
`DEV/tdf-repack.py` hashes each face by content and repacks the survivors into
three bundles totalling 21.9 MB, copying each face record **verbatim** so no
glyph can drift:

| bundle | faces | size |
|--------|-------|------|
| `ASSETS/FONTS/THEDRAW/COLOR.TDF`   | 3560 | 21.1 MB |
| `ASSETS/FONTS/THEDRAW/BLOCK.TDF`   |  191 |  0.7 MB |
| `ASSETS/FONTS/THEDRAW/OUTLINE.TDF` |    6 |   25 KB |

**Each bundle has a `.TDX` sidecar index.** COLOR.TDF holds 3560 *variable
length* records, so listing face names by walking the file means reading all
21 MB every launch. The 111 KB index makes that a small read plus a `SEEK`.

**The declared glyph width/height bytes lie.** Parts of the corpus declare sizes
up to 244x223 cells — 1952x3568 px for a single character. Both the repacker and
`TDF_decode_glyph%` measure the true extent by walking the glyph byte stream
instead; real maximum is 55x41. `TDF_MAX_CELLS_W/H` clamp anything beyond.

**Face names are not unique** (4419 collisions across the corpus, and even after
content-deduplication one bundle holds three different faces called
"BigOutline"), so identity is `TDF://<BUNDLE>/<face name>#<ordinal>` — the
trailing ordinal is load-bearing, not decoration. Same key is used for the
favourites file.

**TheDraw faces are excluded from Character Mode and the Character Map.** Both
are fixed CP437 cell grids; a TDF glyph spans many cells and reports metrics
like 152x176 for one letter. Feeding those to the character map sized its cells
at 152x176 and built a ~2400px panel that swamped the UI. TDF faces are flagged
`isBitmapFont` only so the glyph *render* path is reused —
`TEXT_BAR_char_mode_font_is_safe%` now rejects them, `CHARMAP_toggle` refuses
while one is selected, and `CHARMAP_build_bitmap_cache` refuses any font
reporting cells above `CHARMAP_MAX_CELL_W/H` as a backstop.

### Verified, not just eyeballed

`DEV/EXPERIMENTS/TDF-TEST.BAS` dumps decoded cell grids; those were diffed
against the reference `retrofont` crate over **60 glyphs spanning all three face
types — 0 mismatches**, including 14 where both agree a glyph is undefined. All
3757 faces parse, 3729 decode an 'A', 0 allocate oversize.

### Known limitation

`.draw` files store a text layer's font as a raw `fontIdx` INTEGER
(`TEXT_LAYER_serialize$`), and the deserialiser sniffs format by *length* rather
than a version byte — so font identity cannot be added there without breaking
every existing document. TDF faces are registered on demand, which would have
made this worse than it is for TTFs, so used faces are recorded in
`DRAW_TDF_FONTS.txt` (config dir) and re-registered *before* `FONT_LIST_sort` on
the next launch. That gives them the same index stability as any other installed
font. Properly fixing font identity in `.draw` needs a versioned text-layer
record and is its own task.

## DRAW KITS
- User sharable and exportable kits which contain all or one of:
  - Themes
  - Patterns
  - Gradients
  - Brushes
  - Palettes
  - Fonts
    - Bitmap
    - Truetype/etc.
  - Text styles
  - Templates

### Install from zip
- Choose zip
- Show preview image
- Show description
- Show author information
- Click install

### Export to zip
- Dialog with checkboxes of what to export in current state
  - [x] Themes
  - [x] Patterns
  - [x] Gradients
  - [x] Brushes
  - [x] Palettes
  - [x] Fonts
    - [x] Bitmap
    - [x] Truetype/etc.
  - [x] Text styles
  - [x] Templates
- Name field
- Description field
- Screenshot chooser
- Export button

## Font Preview in popup ✅ SHIPPED (PR #97)
- [x] Add setting: 
  - [x] Checkbox - Enable font previews in menu
    - [x] Font size: ___ [8] [16] [24] [32] (buttons for numbers to insert)
    - [x] Max Width: ____ [32] [64] [128] (buttons for numbers to insert)
    - [x] Max Height: ____ [16] [32] [64] (buttons for numbers to insert)
    - [x] FG color: [ ] color chip picker
    - [x] BG color: [ ] color chip picker
    - [x] Divider color: [ ] color chip picker
    - [x] Preview Text: {font|FONT|Font} {NumGlyphs} __________ [ABCabc123] [DRAW SoMeThiNG!] (buttons insert the text)
      - [x] If {font|FONT|Font} - show that in the preview text of the font picker in the case accordingly
      - [x] NumGlyphs = how many total glyphs in the font, including the entire range, unicode or otherwise.
        - [x] Count only NON-Blank glyphs (via `FONT_count_ttf_range%` using `_UPRINTSTRING`)
          - [x] Count can be part of font as it's cached for previews, etc.
- When this is on:
  - [x] Immediately on Apply:
    - [x] Create previews for the dropdown font pickers
    - [x] The previews should show the name of the font
  - [x] Previews should be cached (`FONT_PREVIEW_*`, invalidated on font rescan)
    - [x] Cache can be wherever DRAW already stores it
  - [x] New fonts should be scanned/rendered on startup
  - [x] If the popups don't fit on the screen, render as much as it can and use ... for telling user.
    - [x] If popups don't fit in vertical space, use the same methods of scrolling/showing for the fonts that we already do for main menu, and mousehweel and arrowsa up/down, etc.

Implementation: previews render **under** each font name in the submenu (compact
12px main list, wide preview strip only in the flyout); TheDraw faces excluded
from the picker; stale-popup and click-away close fixed; DRAW.cfg/THEME.cfg keys
per the completed TEXT TOOL entry below. Shipped via the `font-previews` branch.

## Add ANSI IMPORT/EXPORT SUPPORT ✅ SHIPPED v1.9.0 (PR #96)
- [x] File -> Import ANSI | Export ANSI
- [x] Using IMG2ANS style export (~/git/IMG2ANS)
  - [x] Detect if EGA palette - automatically  *(auto-detects mode; ANS_detect_palette)*
  - [x] Detect if RGB palette - automatically
  - [x] Show preview in export dialog:
    - [x] Source image on left
    - [x] Exported ANSI on right  *(live split preview)*
  - [x] Style (radio):
    - [x] 8x8 Half block (only one choice now)
  - [x] Mode (radio):
    - [x] 16 Colors
    - [x] iCE
    - [x] 256 Colors (xbin)
    - [x] RGB Colors (xterm)
  - [x] Width: ____ [auto]  *(SIZE columns stepper + [auto])*
  - [x] Height: ____ [auto]  *(derived to preserve aspect)*
    - [x] Both are encoded as SAUCE
    - [x] Including the font type
- [x] Using kaleidotron style IMPORT for ANSI render to image -> Import (same funciton as import image)
- Shipped beyond the original spec:
  - [x] Export SOURCE: flattened document / current layer / marquee selection
  - [x] Export CELLS: per-pixel (max detail) vs 1:1 8px (round-trips terminal art); FONT VGA 8x16 / VGA50 8x8
  - [x] Import binary formats: BIN, XBIN (.xb/.xbin — palette/font/RLE), TundraDraw (.tnd)
  - [x] Import 256-color + 24-bit truecolor .ans; UTF-8 block/box art auto-detected -> CP437
  - [x] Import options dialog: 8/9-dot cell width, DOS aspect, 1-8x scale
  - [x] Install XBIN embedded font -> user bitmap fonts; custom palette -> user .GPL
  - [x] CLI open (`./DRAW.run art.xb`); validated against kaleidotron

## CREATE DARK THEME
- [x] To test the theme mode, we need a dark theme

