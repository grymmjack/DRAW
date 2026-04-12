# IDEAS

## COLOR MIXER (replaces COLOR-OPS)
- Toggle with COLOR MIXER button on/off 
  - rename color-ops-off.png to color-mixer-off.png
  - rename color-ops-on.png to color-mixer-on.png
  - color-mixer-off = color dialog invisible
  - color-mixer-on = color dialog visible
  - New Tooltip: L-CLICK to show/hide color dialog
  - Add to PALETTE -> [x] Color Mixer 
  - Should remain at same z-index as Preview Window
  - Can be freely moved inside DRAW window like preview window
  - Should be hidden if user drags over it while drawing like other chrome
  - State should be remembered per session, per document, etc.
    - DRAW_CFG COLOR_MIXER_VISIBLE = true/false
  - When picking colors from ANYWHERE else in DRAW, synchronize to the color mixer
    and pick that same color, if possible, honoring quantization, etc. if setup.


## FILE DIALOG IMPROVEMENTS
- Add tooltip for buttons and panes
  - DIALOG TITLE BAR AREA:
    - Resize and move as needed your preference will be remembered
  - BUTTONS:
    - Up directory - BACKSPACE, or L-CLICK to cd ..
    - Create directory - Create new directory in current directory
    - Detail View - Show files with icon, name, type, size, and modified time
    - List View - Show files just with icon, name and extension
    - Thumbnail View - Show files as thumbnail images - CTRL+M-WHEEL to zoom in/out
    - Show Hidden Files - Show hidden files (. (dot) files)
    - Toggle Image Preview Pane - Show or hide the image preview pane
  - PANES:
    - Current Path - You are here
    - / - File System Root - Root of the entire computer file system
    - Home - Users Home Directory - Also known as $HOME or ~
    - Desktop - Users Desktop Directory - ~/Desktop (or Desktop if Windows)
    - Documents - Users Documents Directory - ~/Documents or (My Documents if Windows)
    - Downloads - Users Downloads Directory - ~/Downloads (or My Downloads if Windows)
    - Pictures - Users Pictures Directory - ~/Pictures (or My Pictures if Windows)
    - Music - Users Music Directory - ~/Music (or My Music if Windows)
    - Videos - Users Video Directory - ~/Videos (or My Videos if Windows)
    - DRAW SPECIFIC:
      - DRAW - DRAW Program Directory - where the binary/exe ran from
      - Samples - DRAW Samples Directory - Inspiration and examples of what you can do
      - User Data - DRAW User Data Directory - your own DRAW stuff! Palettes, Drawer Sets, Fonts, etc.
      - Palettes - DRAW ASSETS: Palletes - All the built-in palettes
      - Drawer Sets - DRAW ASSETS: Drawer Sets - All the built-in drawer sets
    - CUSTOM PLACES:
      - User Favorited Places - R-CLICK on any folder to add to favorite places! R-CLICK again to remove
- Make the cursor focus default to the filename for:
  - Save dialogs
  
## LOSPEC DIALOG IMPROVEMENTS
- Fix the alignment of the text in the search box
  - Is Lospec dialog even using our text input lib?

## SPARE PAGE
- Implement Spare page

## PALETTE BUTTON IN DRAWER
- Load Palette
- Load from Lospec


## QB64PE EXPORT
- Each layer is a SUB
  - When duplicating a layer, do not duplicate the layer, just refer to the SUB in the export
  - So if a layer is duplicated it needs a new icon (SUB) to show it's not the original
  - Only the original layer is editable, [SUB] which when edited updates all (SUB)
- Restrict to use only these tools:
  - DOT (`PSET`)
  - BRUSH (`PSET`)
  - LINE (`LINE`)
    - IF BRUSH SIZE > 1px EXPORT USING MULTIPLE `LINE`
  - POLY LINE (`LINE`)
  - RECT (`LINE BF`)
  - CIRCLE (`CIRCLE`)
  - FILLED POLY LINE (`LINE + PAINT`)
  - FILLED RECT LINE (`BF + PAINT`)
  - FILLED CIRCLE (`CIRCLE + PAINT`)
  - NOT TRACKED IN CODE EXPORT EXCEPT FINAL OUTPUT
    - MARQUEE
    - MOVE
  - TEXT TOOL
    - EXPORT code for `_LOADFONT`, copy font to export dir, etc.
    - TEXT LAYERS have (SUB:TXT)/[SUB:TXT]
- If using ANY other tool the layer becomes a (SUB:IMG) layer, when exported the layer becomes LAYER_NAME.PNG and referenced in code using `_LOADIMAGE`
  - CAN DUPLICATE IMG layer, but only [SUB:IMG] source is editable - when edited updates everywhere
  

## Image Browser (For drag/drop to brush and pattern slots)


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
- DIVIDE EVENLY (visually)






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
  - [ ] Themes
  - [ ] Patterns
  - [ ] Gradients
  - [ ] Brushes
  - [ ] Palettes
  - [ ] Fonts
    - [ ] Bitmap
    - [ ] Truetype/etc.
  - [ ] Text styles
  - [ ] Templates
- Name field
- Description field
- Screenshot chooser
- Export button



---

## COMPLETED

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
