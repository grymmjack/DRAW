# IDEAS

## TEXT TOOL PICKUP STYLE
- [x] When user arrows back to previous character, automatically adjust the text style to reflect current cell

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


## Line ends (arrows, cubes, brackets, dots)
- [ ] Press s to cycle shapes for start of line
- [ ] Press e to cycle shapes for end of line
- [ ] Press r to reset

## Bezier Curve
- [ ] Like photoshop pen tool

## Smart Shapes

### Polygon
- [ ] Start as triangle
- [ ] Up arrow add edges,
- [ ] Down arrow remove edges
- [ ] Left arrow decrease point depth
- [ ] Right arrow increase point depth

### Pie / Donut
- [ ] Start as circle
- [ ] Up arrow add segments
- [ ] Down arrow remove segments
- [ ] Left arrow decrease hole size
- [ ] Right arrow increase hole size

### Rounded Rect
- [ ] Start as rect with 3px roundedness
- [ ] Up arrow increase corner radius 
- [ ] Down arrow decrease corner radius

### Tab
- [ ] Start as rect
- [ ] Up arrow round top corners more
- [ ] Down arrow round top corners less
- [ ] Left arrow cycle tab bottom side left
- [ ] Right arrow cycle tab bottom side right

### Pill
- [ ] Start as rect
- [ ] Up arrow increase roundness 
- [ ] Down arrow decrease roundness
- [ ] Left arrow decrease segments
- [ ] Right arrow increase segments

### Pac-Man
- [ ] Start as circle
- [ ] Up arrow increase mouth size
- [ ] Down arrow decrease mouth size
- [ ] Left arrow decrease inner hole
- [ ] Right arrow increase inner hole

### 3D cube / 3D polygon (dice)
- [ ] Start as rect
- [ ] Up arrow increase z-depth
- [ ] Down arrow decrease z-depth
- [ ] Left arrow rotate left
- [ ] Right arrow rotate right
- [ ] Mouse wheel up rotate up
- [ ] Mouse wheel down rotate down

### Bevel rect
- [ ] Start as rect
- [ ] Up arrow increase bevel size
- [ ] Down arrow decrease bevel size
- [ ] Left arrow decrease border size
- [ ] Right arrow increase border size
- [ ] Press I - change to inner
- [ ] Press O - change to outer
- [ ] Mouse wheel up increase z-depth (angled edges)
- [ ] Mouse wheel down decrease z-depth angled edges

### Arrow
- [ ] Start with arrow shape
- [ ] Up arrow make arrow stem fatter
- [ ] Down arrow make arrow stem skinnier
- [ ] Left arrow make arrow head shorter
- [ ] Right arrow make arrow head longer
- [ ] Mouse wheel up increase head concavity
- [ ] Mouse wheel down decrease head concavity



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

