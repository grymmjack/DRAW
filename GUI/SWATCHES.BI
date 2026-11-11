''
' DRAW - GUI/SWATCHES.BI
' =============================================================================
' Swatches panel (View > Swatches, action 2600): a grid of color swatches from
' a swatch set - Photoshop .aco, GIMP .gpl and friends (QB64_GJ_LIB/SWATCH) -
' laid out the way the set was made: its columns, empty cells, row breaks.
' Left-click a swatch = FG, right-click = BG. Beside the palette strip, not
' instead of it: the strip stays the document palette.
'
' Bar: the set's name (click: the set list - the document palette, My
' Swatches, the shipped swatch sets and palettes) and a gear (layout: columns,
' cell size, gap, stretch, square, borders; Load Swatches...).
'
' A floating-panel family member (GUI/FLOAT-PANEL: title bar, drag, close,
' dock, per-panel scale, auto-hide while drawing over it, F11). Docked it is a
' flex panel like the Preview: it takes the slot's height and scrolls; floating
' it has its own size (CFG.SWATCHES_W / _H, native px) with a corner grip.
'
' Imports never touch the original: an .aco (or any other format) is converted
' to a .gpl in My Swatches (PATHS_data$("SWATCHES/")) and that copy is used.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST SWP_ACT_TOGGLE = 2600 ' View > Swatches
CONST SWP_ACT_LOAD   = 2601 ' Load swatches... (any format -> My Swatches)
CONST SWP_ACT_FOLDER = 2602 ' Open the My Swatches folder

CONST SWP_MIN_W = 64  ' native px
CONST SWP_MIN_H = 60
CONST SWP_GRIP  = 7   ' floating resize grip (native px, bottom-right)
CONST SWP_SBAR_W = 4  ' scroll bar width (native px)

' menus (SWP.menu)
CONST SWP_MENU_NONE = 0
CONST SWP_MENU_SETS = 1 ' the set list
CONST SWP_MENU_GEAR = 2 ' layout options
CONST SWP_MENU_EDIT = 3 ' edits (the ☰ button, Shift+right-click)

' menu row kinds
CONST SWP_MI_ITEM   = 0 ' a choice / action
CONST SWP_MI_HEAD   = 1 ' a group header (not clickable)
CONST SWP_MI_SEP    = 2 ' a divider
CONST SWP_MI_CHECK  = 3 ' an on / off option
CONST SWP_MI_CHIPS  = 4 ' a row of choices ("COLS  SET FIT 8 12 16")

CONST SWP_MENU_MAX  = 400 ' rows
CONST SWP_MENU_VIS  = 22  ' rows shown before it scrolls

TYPE SWATCHES_PANEL_OBJ
    visible           AS INTEGER
    positioned        AS INTEGER
    initialized       AS INTEGER
    autoHidden        AS INTEGER
    hiddenByToggleAll AS INTEGER

    docked      AS INTEGER ' in a dock slot: the slot places + sizes it
    dispX       AS INTEGER ' viewport px
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE  ' native -> viewport

    panelImg AS LONG
    panelW   AS INTEGER ' native size it draws at
    panelH   AS INTEGER
    fitW     AS INTEGER ' docked: native size its slot gives it (0 = floating)
    fitH     AS INTEGER

    ' layout (native px, SWP_layout)
    barY  AS INTEGER
    barH  AS INTEGER
    gridX AS INTEGER
    gridY AS INTEGER
    gridW AS INTEGER ' the cells' area (scroll bar excluded)
    gridH AS INTEGER
    statY AS INTEGER
    cols  AS INTEGER ' columns in use
    cellW AS INTEGER
    cellH AS INTEGER
    gap   AS INTEGER
    rows  AS LONG    ' rows the set takes
    contentH AS LONG ' px
    scrollY  AS LONG ' px scrolled
    sbar     AS INTEGER ' the scroll bar shows
    flowOk   AS INTEGER ' SWP_ER / SWP_EC are current

    ' the set showing
    setKey   AS STRING  ' its path ("" = the document palette)
    setLabel AS STRING
    palSig   AS STRING  ' document palette signature (refresh when it changes)

    hoverIdx   AS LONG    ' entry under the pointer (0 = none)

    ' selection (SWS(i).sel): click / Shift+click range / Ctrl+click toggle /
    ' a box dragged from an empty place (Ctrl+box adds); Ctrl+A, Esc
    anchor   AS LONG    ' where a Shift+click range starts
    boxing   AS INTEGER ' a box drag is on
    boxMoved AS INTEGER ' ... and has moved (a plain click on an empty place just clears)
    boxAdd   AS INTEGER ' Ctrl / Shift held at the start: add to the selection
    boxX0    AS INTEGER ' native x, content y (scroll included)
    boxY0    AS LONG
    boxX1    AS INTEGER
    boxY1    AS LONG
    selBase  AS STRING  ' the selection before an adding box (CHR$(0/1) per entry)
    ' dragging swatches: a press on a selected swatch arms it, 4 px of travel
    ' starts the move; the release drops before dragDrop (Ctrl = a copy)
    dragArm    AS INTEGER ' B1 went down on a selected swatch
    dragMoving AS INTEGER ' ... and has travelled: a move / copy is on
    dragFrom   AS LONG    ' the swatch pressed
    dragX0     AS INTEGER ' native px where it was pressed
    dragY0     AS INTEGER
    dragDrop   AS LONG    ' insert before this entry (SWS_N + 1 = the end; 0 = no drop: off the panel)
    dragRow    AS LONG    ' the grid row the pointer is on (where the drop marker goes)
    dragPend   AS INTEGER ' the press was on a selected swatch: its click waits for the release (no drag = the click)
    dragPendShift AS INTEGER
    dragPendCtrl  AS INTEGER
    ' live edit: one swatch selected, the color panels change it (SWP_tick)
    liveIdx  AS LONG           ' the swatch being followed (0 = none)
    liveLast AS _UNSIGNED LONG ' the FG last seen
    liveOpen AS INTEGER        ' an edit step is open (closed on the mouse-up)
    clickT   AS DOUBLE         ' the last press on a swatch (double-click = edit its color)
    clickI   AS LONG
    closeHover AS INTEGER
    hoverBar   AS INTEGER ' 1 = the set name, 2 = the gear

    dragging    AS INTEGER ' title-bar drag
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
    resizing    AS INTEGER ' corner grip (floating)
    rsStartW    AS INTEGER
    rsStartH    AS INTEGER
    sbDrag      AS INTEGER ' scroll bar thumb drag
    sbGrabY     AS INTEGER
    sbStartScroll AS LONG

    ' menu (own native image, drawn over the panel like the ACP's)
    menu      AS INTEGER ' SWP_MENU_*
    menuImg   AS LONG
    menuX     AS INTEGER ' viewport px
    menuY     AS INTEGER
    menuW     AS INTEGER ' native px
    menuRows  AS INTEGER
    menuTop   AS INTEGER ' first row shown (scrolled)
    menuHover AS INTEGER
    menuChip  AS INTEGER ' chip under the pointer in a chips row
    menuRowH  AS INTEGER
    menuAtMouse AS INTEGER ' the next SWP_menu_open opens at the pointer (Shift+right-click)
END TYPE

DIM SHARED SWP AS SWATCHES_PANEL_OBJ
REDIM SHARED SWP_ER(1 TO 64) AS LONG    ' each entry's row (0-based) in the grid
REDIM SHARED SWP_EC(1 TO 64) AS INTEGER ' and column

' menu rows
TYPE SWP_MENU_ROW
    kind  AS INTEGER ' SWP_MI_*
    label AS STRING
    id    AS INTEGER ' what it does (SWP_menu_act)
    chk   AS INTEGER ' checked / the chosen chip (1-based)
    chips AS STRING  ' SWP_MI_CHIPS: "|"-separated choices
END TYPE
DIM SHARED SWP_MI(1 TO SWP_MENU_MAX) AS SWP_MENU_ROW

' undo / redo of swatch edits, per set (the key is the set's path): a
' snapshot (SWS_snapshot$) before each edit. Kind 0 = undo, 1 = redo.
CONST SWP_UNDO_MAX = 200
DIM SHARED SWP_UNDO_N AS INTEGER
DIM SHARED SWP_UNDO_KEY(1 TO SWP_UNDO_MAX) AS STRING
DIM SHARED SWP_UNDO_SNAP(1 TO SWP_UNDO_MAX) AS STRING
DIM SHARED SWP_UNDO_KIND(1 TO SWP_UNDO_MAX) AS INTEGER
DIM SHARED SWP_SAVES AS LONG ' times the set was written (QA)

' the set list (SWP_scan_sets): 0 = the document palette
DIM SHARED SWP_SET_N AS INTEGER
REDIM SHARED SWP_SET_PATH(0 TO 16) AS STRING
REDIM SHARED SWP_SET_LABEL(0 TO 16) AS STRING
REDIM SHARED SWP_SET_GROUP(0 TO 16) AS STRING
