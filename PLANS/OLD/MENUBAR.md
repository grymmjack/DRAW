# MENU

NOTE:
  DIVIDERS are not selectable. DEFINED AS ---
  CHECKBOXes are DEFINED AS [x] - [x] = checked [ ] = not checked

## Vertical Position: Top

## Horizontal Position:
- If LAYERS PANEL is NOT visible:
  - X should be screen edge left
  - W should be to where the UI of the toolbox begins (the border)
- If LAYERS PANEL and TOOLBOX is NOT visible:
  - X should be screen edge left
  - W should be the entire width of the screen
- IF LAYERS PANEL is visible and TOOLBOX is NOT visible:
  - X should be where the LAYERS PANEL ends
  - W should be from X to width of the screen
- IF LAYERS PANEL is visible and TOOLBOX IS visible:
  - X should be where the LAYERS PANEL ends
  - W should be to where the UI of the toolbox begins (the border)

## Font
- Tiny 5, 8px

## Colors
- Modify THEME.BI and DRAW.cfg to support
  - MENU.BAR_BG_COLOR               DEFAULT: #797979
  - MENU.BAR_FG_COLOR               DEFAULT: #000000
  - MENU.BAR_BORDER_COLOR           DEFAULT: #000000
  - MENU.BAR_DIVIDER_COLOR          DEFAULT: #797979
  - MENU.BAR_BG_SELECTED_ITEM       DEFAULT: #555555
  - MENU.BAR_FG_SELECTED_ITEM       DEFAULT: #FFFFFF
  - MENU.SUBMENU_BG_COLOR           DEFAULT: #797979
  - MENU.SUBMENU_FG_COLOR           DEFAULT: #000000
  - MENU.SUBMENU_BORDER_COLOR       DEFAULT: #000000
  - MENU.SUBMENU_DIVIDER_COLOR      DEFAULT: #797979
  - MENU.SUBMENU_BG_SELECTED_ITEM   DEFAULT: #555555
  - Menu.SUBMENU_FG_SELECTED_ITEM   DEFAULT: #FFFFFF

## New MENU GUI widget
- X - the x position of where the menu bar starts
- Y - the y position of where the menu bar starts
- W - the width of the menu bar
- H - the height of the menu bar
- PAD_LEFT - left side padding where root level MENU_ITEMs begin on the X
- PAD_RIGHT - right side padding where root level MENU_ITEMs end on the X (max)
- PAD_TOP - top side padding where root level MENU_ITEMs begin on the Y
- PAD_BOT - bottom side padding where root level MENU_ITEMs end on the Y
- ITEMS - Array of MENU_ITEM (see below)
- VISIBLE - Boolean is visible or not
- BORDER_WIDTH - default: 1
- BAR_BG_COLOR
- BAR_FG_COLOR
- BAR_BORDER_COLOR
- BAR_DIVIDER_COLOR
- BAR_BG_SELECTED_ITEM
- BAR_FG_SELECTER_ITEM
- SUBMENU_BG_COLOR
- SUBMENU_FG_COLOR
- SUBMENU_BORDER_COLOR
- SUBMENU_DIVIDER_COLOR
- SUBMENU_BG_SELECTED_ITEM
- SUBMENU_FG_SELECTED_ITEM

## New MENU_ITEM GUI widget (complements MENU)
- PARENT_MENU_ITEM_IDX - INTEGER (= -1 for ROOT)
- LABEL - STRING
- HOTKEY - STRING (OPTIONAL)
- STATUS_TEXT - STRING (OPTIONAL)
- HAS_ICON - BOOLEAN
- ICON_IMG - STRING
- HAS_CHECKBOX - BOOLEAN
- IS_DIVIDER - BOOLEAN
- CHECKED - BOOLEAN
- ENABLED - BOOLEAN
- COMMAND - STRING:(see COMMANDS.BI/BM)

## DRAW MENU BAR DEFINITION
>> = JUSTIFY RIGHT

### ROOT:
FILE | EDIT | VIEW | SELECT | TOOLS | BRUSH | LAYER | PALETTE | >> HELP

#### FILE:
- NEW
- NEW FROM TEMPLATE
- IMPORT IMAGE
- ---
- SAVE
- SAVE AS DRAW
- SAVE AS PNG
- ---
- EXPORT LAYER
- EXPORT BRUSH
- ---
- QUIT

#### EDIT:
- UNDO
- REDO
- ---
- CUT
- COPY
- PASTE
- PASTE IN PLACE
- ---
- CLEAR
- ---
- FILL WITH FG
- FILL WITH BG
- ---
- FLIP HORIZONTAL
- FLIP VERTICAL
- SCALE -50%
- SCALE +50%

#### VIEW:
- [x] MENU BAR
- [x] LAYER PANEL
- [x] TOOLBOX
- [x] COLOR STRIP/STATUS
- ---
- HIDE/SHOW ALL
- ---
- [x] GRID
- [x] SNAP TO GRID
- [x] PIXEL GRID
- [x] CURSORS
- ---
- ZOOM 100%
- ZOOM IN
- ZOOM OUT
- ---
- RESET CANVAS

#### SELECT:
- ALL
- NONE
- ---
- INVERT
- ---
- FROM CURRENT LAYER
- ---
- NUDGE 1PX LEFT
- NUDGE 1PX RIGHT
- NUDGE 1PX DOWN
- NUDGE 1PX UP
- NUDGE 10PX LEFT
- NUDGE 10PX RIGHT
- NUDGE 10PX DOWN
- NUDGE 10PX UP

#### TOOLS:
- SAVE PNG
- SAVE DRAW
- IMPORT IMAGE
- OPEN DRAW
- ---
- SELECT
- MOVE
- PAN
- ZOOM
- COLOR PICKER
- ---
- TEXT
- DOT
- BRUSH
- SPRAY
- LINE
- FILL
- POLY LINE
- POLY LINE FILLED
- RECTANGLE
- RECTANGLE FILLED
- ELLIPSE
- ELLIPSE FILLED
- ---
- COMMAND HELP
- ---
- CODE

#### BRUSH:
- CLEAR
- EXPORT AS PNG
- ---
- [ ] RECOLOR MODE
- ---
- FLIP HORIZONTAL
- FLIP VERTICAL
- SCALE -100%
- SCALE +100%

#### LAYER:
- NEW
- DUPLICATE
- DELETE
- ---
- MERGE DOWN
- MERGE ALL
- ---
- ARRANGE TO TOP
- ARRANGE UP
- ARRANGE DOWN
- ARRANGE TO BOTTOM
- ---
- EXPORT AS PNG
- ---
- SET BLENDING MODE

##### SET BLENDING MODE:
- NORMAL
- MULTIPLY
- SCREEN
- OVERLAY
- ADD
- SUBTRACT
- DIFFERENCE
- DARKEN
- LIGHTEN
- COLOR DODGE
- COLOR BURN
- HARD LIGHT
- SOFT LIGHT
- EXCLUSION
- VIVID LIGHT
- LINEAR LIGHT
- PIN_LIGHT
- COLOR
- LUMINOSITY

#### PALETTE:
- IMPORT
- EXPORT
- ---
- RANDOM
- ---
- COLOR PICKER

#### HELP:
- ABOUT DRAW
- ---
- CHEAT SHEET
- MANUAL
- ---
- GITHUB
- ISSUE TRACKER
- ---
- CREDITS
- ---
- EXAMPLES

