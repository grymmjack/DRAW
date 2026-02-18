# DRAW ISSUES LIST

## FILE OPERATIONS
[ ] (NEW FEATURE) All file operations should remember the last directory they were used in.
  - Persist this in DRAW.cfg for each type of operation.
    - LAST_DIR_OPEN, LAST_DIR_SAVE, LAST_DIR_IMPORT, LAST_DIR_EXPORT_BRUSH, LAST_DIR_EXPORT_LAYER
  - Open
  - Save
  - Import
  - New From Template
    - Append "..." to end of MENU OPTION text to indicate the user will be opening a dialog.
      - NEW FROM TEMPLATE...
  - Export Brush
  - Export Layer

[ ] (BUG) Saving file and reopening does not honor GRID TYPE at time of save

[ ] (NEW FEATURE) New from Template
  - Add TEMPLATE_DIR to DRAW.cfg - if set opens to this directory when engaged from menu bar.
  - Allow to Open any image (PNG, DRAW, etc.) that we can normally open or import.
  - After opening what makes this a template is:
    - First time you press CTRL-S it prompts to save in LAST_DIR_SAVE if set
    - First time you press Save as, or use Menu Save, same.
    - After which, same as regular file.
    - THE ONLY THING THAT IS UNIQUE IS user gets to open existing files/projects
      - WHICH do not get overwritten, and are simply treated as new documents,
      - NOT documents that are opened normally with File -> Open
        - So when CTRL-S or Save is used, it does not overwrite original file but prompts instead.
        - AFTER this point, it's a regular old file.


## GUI
[ ] (BUG) Hint bar / Status bar is not visible when:
  - Importing Image
  - Move Tool Transforming Selection
  - Selection Created


## MARQUE TOOL 
[ ] (NEW FEATURE) SHIFT - Need to be snap to grid
  - When resizing selection
  - When dragging with mouse to move the selection
  - NOTE: This should NOT be the same logic as for MOVE - keep the SHIFT as constrain aspect ratio there.
  - This should be in effect for Image Import as well
  - Should honor grid settings.
    - Grid snap and grid type should be honored.


## MENU BAR
[ ] (CHANGE) Append "..." to MENU OPTION text when engaging option opens a dialog:
  - FILE:
    - OPEN...
    - SAVE AS...
    - NEW FROM TEMPLATE...
    - EXPORT LAYER...
    - EXPORT BRUSH...
    - IMPORT IMAGE...
    - RECENT... > (right justified submenu > arrow opens sub-menu (see below))
  - VIEW:
    - LOAD REFERENCE...
  - PALETTE:
    - IMPORT...
    - EXPORT...
  - TOOLS:
    - COMMAND HELP...
  - HELP:
    - CHEAT SHEET...

[ ] (BUG) Tools -> Spray does not select spray tool

[ ] (CHANGE) Tools -> Code
  - Gray out and disable menu option
  - Change text to: 
    - CODE...

[ ] (CHANGE) Brush root level menu item should be grayed out not unopenable
  - Still allow it to be open so users can discover the submenu options.

[ ] (NEW FEATURE) File -> Revert - Add new Revert option which is enabled only after saving, or loading an image.
  - Revert when used will reload to the state at the last save, or open.

[ ] (NEW FEATURE) File -> Recent -> Add tracking of recent files. Store up to 10 Recent files in DRAW.cfg
  - RECENT_FILE_1_PATH, 2_PATH, ... RECENT_FILE_10_PATH.
  - When rendering Recent files, make it a sub menu of Recent.
  - Recent MENU OPTION should have a right facing arrow to open the menu.
  - Arrow keys should be able to navigate to open the Recent sub menu, with right arrow, and left arrow to close it.
  - Arrow keys should be able to navigate up and down the recent list.
  - At the bottom of the recent file menu list, add a MENU DIVIDER then under "Clear" option
    - Clear should unset all recent files both in DRAW.cfg and in the menu in real time.

[ ] (BUG) File -> New - Prompts to save unsaved changes even if NOTHING was drawn.

[ ] (BUG) File -> Open - After image opens, shows dirty canvas * even if not drawing when simply using menu bar.
  - * should only be appended if anything in the draw canvas was changed, layers were rearranged, etc.
  - Create unified change detection perhaps that can be called/checked with 1 line from subs and dispatchers.

[ ] (CHANGE) File -> Export Brush 
  - This should be grayed out and unable to be accessed unless there is a custom brush in use.

[ ] (CHANGE) File -> Import Image:
  - After choosing file to import, the cursor is wrong.
    - It should be the MOVE tool
    - It should show resize cursors like the MOVE tool when over edges/corners.
    - When over the inside part of the bounding box, it should show HAND cursor.

[ ] (BUG) Edit -> Cut then Edit -> Paste in Place then Edit -> Cut then Edit Past in Place 
  - Does nothing
  - What I expected is it would just be idempotently cutting and pasting repeatably.

[ ] (BUG) Edit -> Cut top layer Clears to BG color (sometimes)
  - Edit -> Cut should clear to transparency
  - This should happen regardless of top most layer or not

[ ] (CHANGE) Tools -> Command Help should show just like as if hotkey ? was pressed
  - Right now it does not have the filter search box

[ ] (BUG) Edit -> Copy Merged
  - Does not copy merged 
    - of whole document - only visible layers
    - with blending styles applied

[ ] (BUG) Edit -> Flip H/V when Selection is active
  - Engages Move tool, and does flip
  - Should not, should just flip and keep selection
  - Keep whatever tool was in use at time

[ ] (BUG) Edit -> Rotate 90 CW/CCW with > and < not working at all
  - Not working from menu options
  - Not working from hotkeys
  - When using < - it duplicates the active layer?!

[ ] (BUG) View -> Hide/Show All
  - Not hiding Layer Panel or Menu bar
  - Only Color Strip/Status and Toolbox
  - (REFACTOR OPPORTUNITY)
    - ***IMPORTANT*** MAKE SURE that engaging options in menu do not have:
      - Separate code for the SAME operation used for hotkey/clicks/etc. elsewhere
      - We want UNIFIED code, not fragmented nonsense
      - CHECK ALL menu commands to make sure that this is true!

[ ] (BUG) View -> Cursors
  - (CHANGE) MENU OPTION Text to BRUSH CURSORS
  - Does not hide Spray cursor - keep spray preview brush but not cursor


## MOVE TOOL
[ ] (CHANGE) When moving is active and transform is happening...
  - Allow CTRL-Z to abort the move, and return to previous tool
    - The same function that ESC has when moving to abort
    - This should not create an UNDO step - since nothing "happened"
      - Even though the CTRL-Z is the undo keyboard shortcut


## POLY LINE and POLY FILL
[ ] (CHANGE) After finishing with RIGHT CLICK, ENTER, or ESC...
  - DO NOT select NULL tool, keep the existing tool selected


## HAND PAN TOOL
[ ] (CHANGE) When SPACEBAR is pressed - currently it is not changing cursor on SPACE down
  - IMMEDIATELY change cursor to HAND
  - Temporarily select HAND PAN tool in toolbox temporarily while held
  - When it is released rechoose the previous tool
  - This is the tool pattern where the tool is engaged temporarily that is already in use for 
    - PICKER with ALT


## TEXT TOOL
[ ] (BUG) Showing NULL cursor and I beam text cursor. 
  - Should not show NULL cursor on top of I beam text cursor.


## UNDO / REDO
[ ] (BUG) Edit -> Cut to New Layer 
  - Partially working - leaves behind a empty New Layer that was cut TO
[ ] (BUG) Layer count is not properly updated to reflect actual layer count


## SYMMETRY
[ ] (BUG) Grid Fill Mode does not honor symmetry, it should.


## ORGANIZER
[ ] (BUG) When using mousewheel over organizer it should not zoom the canvas
  - Treat it like it's over the toolbox, that's already working that way.

[ ] (CHANGE) Allow mousewheel when over brush size in organizer to cycle through brush size presets F1,F2,F3,F4

[ ] (CHANGE) Allow mousewheel to cycle through GRID types when over GRID visibility icon
  - When GRID Rect (default)
    - IMAGE OFF: `grid-off-rect.png`
    - IMAGE ON: `grid-on-rect.png`
  - WHEN GRID 45 degrees
    - IMAGE OFF: `grid-off-45.png`
    - IMAGE ON: `grid-on-45.png`
  - WHEN GRID Isometric
    - IMAGE OFF: `grid-off-iso.png`
    - IMAGE ON: `grid-on-iso.png`
  - WHEN GRID hex
    - IMAGE OFF: `grid-off-hex.png`
    - IMAGE ON: `grid-on-hex.png`

[ ] (CHANGE) Allow mousewheel to cycle through GRID align types when over GRID snap mode
  - When GRID snap mode is GRID Tile mode
    - IMAGE OFF: `grid-snap-center-off.png`
    - IMAGE ON: `grid-snap-center-on.png`
  - When GRID snap mode is NOT GRID Tile mode
    - IMAGE OFF: `grid-snap-edge-off.png`
    - IMAGE ON: `grid-snap-edge-on.png`


## TOOLBOX
[ ] (CHANGE) When View -> Grid Cell Fill is ON:
  - IMAGE: `fill-grid-cell.png`

[ ] (CHANGE) When View -> Grid Cell Fill is OFF:
  - IMAGE `fill.png`

[ ] (CHANGE) Fill button image name: `fill.png` (was `paint.png`)

[ ] (CHANGE) Dot button image name: `dot.png` (was `pset.png`)







