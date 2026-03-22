# IDEAS

## BITMAP FONT LOADING / CHARACTER MAP

### LOADING SUPPORT
Support loading fonts made with: https://github.com/a740g/VGA-Font-Editor
Support loading fonts made with: https://github.com/viler-int10h/fontraption
- VGA Fonts
- VGA ROM Fonts
- romfont
- Fontraption .F?? fonts

#### FONT DIRECTORIES
- DRAW provided bitmap fonts are at ASSETS/FONTS/BITMAP/*
- User supplemental fonts can be in USER/FONTS/BITMAP/*

### CHARACTER MAP VIEW (View -> Character Map)
A character map panel with a grid the can be docked to left or right side.
See: https://blog.glyphdrawing.club/moebiusxbin-ascii-and-text-mode-art-editor-with-custom-font-support/
Views the current font chosen in text tool.

#### SELECTING CHARACTERS FROM PANEL

##### MOUSE
- Hover over character cell 
  - Unhover any other cell previously hovered
  - Change state to over on cell mouse pointer is over
- Click with mouse on a character cell - change state to selected 
  - Deselect any other cell previously selected
  - Change state to selected on cell mouse pointer is over
- Click on existing selected char
  - Deselect selected char

##### PAINTING CHARACTERS
- L-Click to draw character with FG color
- R-Click to draw character with BG color
- Treat the characters as custom brushes when they are picked
  - Allow ALL custom brush operations on the character picked, as it's literally
    a custom brush
  - Allow all fill modes and draw modes and everything for custom brush
  - ENABLE BRUSH RECOLOR MODE
- Can be placed exactly like a custom brush
- Honors all grid operations
- Honors all selection masks
- Honors all layer stuff
- Is treated like a TEXT layer and allows re-editing

##### TYPING CHARACTERS
- If text tool is active and [USE CHARS] is ON
  - Use the characters from the map
  - When user types a character flash it's FG color `TEXT_TYPE_USE_CHARS_FG`
  - If Function keys are used let them plot the cell # which is ASCII CODE value
      - MAP F-Keys to cells so can emulate ANSI editor mode:
        F1 - 176
        F2 - 177
        F3 - 178
        F4 - 219
        F5 - 223
        F6 - 220
        F7 - 221
        F8 - 222
        F9 - 254
        F10 - 250
        F11 - 32
        F12 - 32 
- Allow all normal editing as normal text with:
  - Selections
  - Cursor movement
  - Deletions
  - Span selections
  - Guards for screen edges
  - etc.

### MENU CHANGES
- View -> Layout -> CHARACTER MAP RIGHT
- View -> Layout -> CHARACTER MAP LEFT
- View -> ------
- View -> [x] SNAP to CHAR GRID
- View -> [x] CHAR GRID
- View -> ------

### TEXT BAR CHANGES
- Add [USE CHARS] button
  - When ON: 
    - allow characters to be selected in char map and placed
    - enable CHAR grid
    - Show hint in title bar (CHAR MODE)
  - When OFF: regular text tool operation
    - Hide hint in title bar (CHAR MODE)
- When font is chosen and CHARACTER MAP is visible
  - Load font characters as custom brushes into all 255 slots of character map
- If font chosen is a bitmap or BIOS or VGA font
  - Automatically enable MONOSPACE
  - Automatically enable AUTO line height
  - Modify CHAR GRID width and height to match chosen font glyph cell W/H

### TEXT TOOL CHANGES
- If [USE CHARS] is on in TEXT BAR
  - Show hint in title bar (CHAR MODE)
  - Automatically enable View -> SNAP to CHAR GRID
  - Automatically enable View -> CHAR GRID
  - Automatically enable Brush -> Recolor Mode
  - Create custom brush from selected character in map
  - If no character selected in map, select first non whitespace character available.
  - Click while text tool is active will draw selected character
    - L-Click = FG
    - R-Click = BG
  - MAP F-Keys to cells so can emulate ANSI editor mode:
    F1 - 176
    F2 - 177
    F3 - 178
    F4 - 219
    F5 - 223
    F6 - 220
    F7 - 221
    F8 - 222
    F9 - 254
    F10 - 250
    F11 - 32
    F12 - 32

### DRAW.cfg settings for character map panel
- `CHARMAP_CELL_W`
- `CHARMAP_CELL_H`
- `CHARMAP_CELL_PADDING`
- `CHARMAP_DEFAULT_FONT`
- `CHARMAP_PANEL_DOCK_EDGE`
- `CHAR_GRID_COLOR_FG`
- `CHAR_GRID_WIDTH`
- `CHAR_GRID_HEIGHT`
- `CHAR_GRID_OPACITY`
- `TEXT_BAR_USE_CHARS` - State for USE CHARS button in text bar
- `CHARMAP_CHAR_SELECTED` - This is to remember the last character selected in map
- `TEXT_BAR_TAB_CHARS` - Number of chars for TAB

### THEME.cfg settings for character map styles
- `CHARMAP_BG`
- `CHARMAP_FG`
- `CHARMAP_SELECTED_FG`
- `CHARMAP_SELECTED_BG`
- `CHARMAP_HOVER_FG`
- `CHARMAP_HOVER_BG`
- `CHARMAP_GRID_FG`
- `TEXT_TYPE_USE_CHARS_FG` - Used for highlighting which character is typed on map
- `CHAR_GRID_COLOR_FG`

### UPDATE PLANS / DIAGRAMS
- When finished implementation create graphviz state diagram for this mode
- Ammend other state diagrams accordingly for this new functionality as needed




## LOAD IMAGES INTO BINS
- Add to right click on brush bin, pattern bin:
  - LOAD IMAGES
  - Show FILE OPEN DIALOG
  - Allow multiple files to be selected and loaded into the bins in whatever mode
    - Honor the DRAWING MODE



## SMART GUIDES

Automatically snap to layer candidates when near X/Y/W/H bounds of neighbors

- When hovering over canvas draw horizontal line for horizontal snaps to neighbor bounds
- When hovering over canvas darw vertical line for vertical snaps to neighbor bounds

### MENU CHANGES
- View -> Smart Guides
- View -> Snap Smart Guides



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

## GUIDE LAYERS



