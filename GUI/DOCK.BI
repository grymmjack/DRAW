''
' DRAW - GUI/DOCK.BI
' =============================================================================
' The dock tree: Photoshop/GIMP-style arrangement of the side panels.
' Plan: PLANS/_/DOCKING-PLAN.md. Only the LEFT and RIGHT screen edges dock; the
' menu bar stays on top, the status bar + color strip at the bottom.
'
'   column  a vertical strip on one edge (side, order from the outside in,
'           width). FULL columns run from the top of the window (the menu bar
'           starts after them); the others start under the menu bar.
'   slot    one rect in a column, top to bottom: a height share, collapsed or
'           not, and one or more panels (tabs, one active).
'   panel   toolbox, organizer, drawer, layers, edit bar, advanced bar,
'           character map (docked panels) + the floating windows (P5).
'
' DOCK_layout (DOCK.BM) turns the tree into rects and hands them to the
' panels; every panel renders and hit-tests inside the rect it is given.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' --- panels -------------------------------------------------------------------
CONST DP_NONE      = 0
CONST DP_TOOLBOX   = 1
CONST DP_ORGANIZER = 2
CONST DP_DRAWER    = 3
CONST DP_LAYERS    = 4
CONST DP_EDITBAR   = 5
CONST DP_ADVBAR    = 6
CONST DP_CHARMAP   = 7
CONST DP_PREVIEW   = 8
CONST DP_MIXER     = 9
CONST DP_ADVCP     = 10
CONST DP_CS3D      = 11
CONST DP_PEN       = 12
CONST DP_BROWSER   = 13
CONST DP_COUNT     = 13

' how a panel's height is decided inside its column
CONST DP_H_FIXED = 1 ' its own content height (toolbar rows, organizer)
CONST DP_H_FLEX  = 2 ' shares the leftover height by weight

TYPE DOCK_PANEL_OBJ
    nm       AS STRING  ' name used in [DOCK] lines ("layers")
    title    AS STRING  ' shown on title strips / tabs ("Layers")
    hmode    AS INTEGER ' DP_H_FIXED / DP_H_FLEX
    tall     AS INTEGER ' makes its column FULL height (beside the menu bar)
    bordered AS INTEGER ' draws its own 1px frame: shares the frame row with a bordered neighbour above
    floats   AS INTEGER ' has its own floating window (P5)
    slot     AS INTEGER ' DOCK_SLOT index it sits in (0 = not docked)
    ' floating ([FLOAT] in workspaces; P5): its window rect in viewport px
    fl       AS INTEGER ' floating
    fx       AS INTEGER
    fy       AS INTEGER
    fw       AS INTEGER
    fh       AS INTEGER
    ' where it was docked, for "dock back" (not saved: falls back to the nearest side)
    hside    AS INTEGER
    hcol     AS INTEGER ' column order on that side
    hslot    AS INTEGER ' slot order in that column
    halone   AS INTEGER ' it was the column's only slot (dock back = a column of its own again)
    ' the rect DOCK_layout gave it this frame (valid while rVis)
    rVis     AS INTEGER
    rx       AS INTEGER
    ry       AS INTEGER
    rw       AS INTEGER
    rh       AS INTEGER
END TYPE
DIM SHARED DPANEL(1 TO DP_COUNT) AS DOCK_PANEL_OBJ

' --- columns ------------------------------------------------------------------
CONST DOCK_LEFT  = 1
CONST DOCK_RIGHT = 2
CONST DOCK_MAX_COLS = 12

TYPE DOCK_COL_OBJ
    used  AS INTEGER
    side  AS INTEGER ' DOCK_LEFT / DOCK_RIGHT
    ord   AS INTEGER ' 1 = outermost
    wpx   AS INTEGER ' width in px set for the column (0 = the panels' own width)
    ' this frame's layout
    vis   AS INTEGER ' has a visible slot
    autoh AS INTEGER ' hidden by the layout this frame (the window is too narrow) - not saved
    full  AS INTEGER ' FULL height (holds a tall panel)
    x     AS INTEGER
    y     AS INTEGER
    w     AS INTEGER
    h     AS INTEGER
END TYPE
DIM SHARED DOCK_COL(1 TO DOCK_MAX_COLS) AS DOCK_COL_OBJ

' --- slots --------------------------------------------------------------------
CONST DOCK_MAX_SLOTS = 32
CONST DOCK_MAX_TABS  = 8

TYPE DOCK_SLOT_OBJ
    used      AS INTEGER
    col       AS INTEGER ' DOCK_COL index
    ord       AS INTEGER ' 1 = top
    share     AS INTEGER ' height weight among the flex slots (default 1)
    collapsed AS INTEGER ' only its title strip shows
    autoc     AS INTEGER ' collapsed by the layout this frame (the column is too short) - not saved
    ntabs     AS INTEGER
    act       AS INTEGER ' active tab (1..ntabs)
    ' this frame's layout
    vis       AS INTEGER
    x         AS INTEGER
    y         AS INTEGER
    w         AS INTEGER
    h         AS INTEGER
END TYPE
DIM SHARED DOCK_SLOT(1 TO DOCK_MAX_SLOTS) AS DOCK_SLOT_OBJ
DIM SHARED DOCK_TAB(1 TO DOCK_MAX_SLOTS, 1 TO DOCK_MAX_TABS) AS INTEGER ' panel ids

DIM SHARED DOCK_READY  AS INTEGER ' the tree has been built (DOCK_build_default)
DIM SHARED DOCK_PARSE_NOTE AS STRING ' what the last DOCK_parse_col% skipped (unknown / repeated panel names), "" = nothing
DIM SHARED DOCK_CUSTOM AS INTEGER ' a [DOCK] arrangement is in effect (else the default tree is rebuilt from the dock keys every layout)
' DOCK_layout results: the canvas edges and the menu bar's span
DIM SHARED DOCK_LAID_OUT AS INTEGER ' DOCK_layout has run (DOCK_live% is meaningful)
DIM SHARED DOCK_LX AS INTEGER
DIM SHARED DOCK_RX AS INTEGER
DIM SHARED DOCK_MENU_LX AS INTEGER
DIM SHARED DOCK_MENU_RX AS INTEGER

' --- slot chrome (P3) -----------------------------------------------------------
CONST DOCK_GRIP_H  = 3  ' hover grip at the top of a chromeless panel (viewport px)
CONST DOCK_TITLE_H = 11 ' title / tab strip of a titled slot (tabbed, collapsed, docked window)
CONST DOCK_ACT_DOCKBACK = 6
CONST DOCK_MENU_ITEM_H = 12

' handle menu actions
CONST DOCK_ACT_LEFT  = 1
CONST DOCK_ACT_RIGHT = 2
CONST DOCK_ACT_RESET = 3
CONST DOCK_ACT_COLLAPSE = 4
CONST DOCK_ACT_FLOAT = 5
CONST DOCK_ACT_BAND_TOP = 7    ' the Browser only: dock along the top / bottom
CONST DOCK_ACT_BAND_BOTTOM = 8

TYPE DOCK_UI_OBJ
    hoverSlot AS INTEGER ' slot whose handle the pointer is over (0 = none)
    menuOpen  AS INTEGER
    menuPanel AS INTEGER ' panel the menu acts on
    menuX     AS INTEGER
    menuY     AS INTEGER
    menuW     AS INTEGER
    menuN     AS INTEGER
    menuHover AS INTEGER
    ' slot divider drag (the boundary between two stacked flex slots)
    divA      AS INTEGER ' slot above (0 = no divider drag)
    divB      AS INTEGER ' slot below
    divTop    AS INTEGER ' top of A when grabbed
    divTotal  AS INTEGER ' A + B heights when grabbed
    divHover  AS INTEGER ' a divider is under the pointer
    ' moving a panel by its handle
    mvPanel   AS INTEGER ' panel pressed on (0 = none)
    mvSlot    AS INTEGER ' slot whose handle was pressed
    mvFloat   AS INTEGER ' the panel pressed on is a floating one (its title bar)
    mvNative  AS INTEGER ' a native floating window is dragging itself (its own code moves it; DOCK only targets)
    mvOffX    AS INTEGER ' grab offset inside its window
    mvOffY    AS INTEGER
    lastClick AS DOUBLE  ' time of the last title click (double-click = collapse)
    lastSlot  AS INTEGER
    mvActive  AS INTEGER ' past the drag threshold: a real move
    mvX0      AS INTEGER
    mvY0      AS INTEGER
    tgtKind   AS INTEGER ' DOCK_TGT_*
    tgtSide   AS INTEGER
    tgtCol    AS INTEGER
    tgtOrd    AS INTEGER
    tgtSlot   AS INTEGER
    tgtX      AS INTEGER ' drop preview rect
    tgtY      AS INTEGER
    tgtW      AS INTEGER
    tgtH      AS INTEGER
    mvGroup   AS INTEGER ' pressed on a tab strip outside its tabs: the whole slot (every tab) moves
    mvCancel  AS INTEGER ' a right-click cancelled docking for this window drag (it just moves)
    lbX       AS INTEGER ' the drop label as last drawn (re-blitted above the native windows)
    lbY       AS INTEGER
    lbW       AS INTEGER
    lbH       AS INTEGER
END TYPE
DIM SHARED DOCK_UI AS DOCK_UI_OBJ
CONST DOCK_MIN_FLEX_H = 24 ' a flexible slot never shrinks below this by a divider drag
' drop targets for a panel being moved
CONST DOCK_TGT_NONE   = 0
CONST DOCK_TGT_NEWCOL = 1 ' a new column (tgtSide, tgtOrd)
CONST DOCK_TGT_SPLIT  = 2 ' a new slot in a column (tgtCol, tgtOrd)
CONST DOCK_TGT_TAB    = 3 ' a tab in a slot (tgtSlot)
CONST DOCK_TGT_FLOAT  = 4 ' a floating window (P5)
CONST DOCK_TGT_BAND   = 5 ' the Browser's top / bottom band (tgtSide = DOCK_BAND_*)
CONST DOCK_MIN_CANVAS_W = 160 ' narrower than this and the outermost dock columns hide (small windows)
CONST DOCK_EDGE_ZONE  = 16 ' px from a screen edge / column side that means "new column here"
CONST DOCK_DRAG_START = 5  ' px the pointer travels before a press on a handle becomes a move
CONST DOCK_FLOAT_GRIP_H = 6 ' a floating thin bar's handle: a grip strip, no title (the title wouldn't fit)
CONST DOCK_FLOAT_EDGE = 3   ' px inside a floating panel's right / bottom border that resize it
' resizing a floating panel by its right / bottom edge or corner
TYPE DOCK_RZ_OBJ
    id    AS INTEGER ' panel being resized (0 = none)
    edge  AS INTEGER ' 1 = right, 2 = bottom, 3 = corner
    x0    AS INTEGER
    y0    AS INTEGER
    w0    AS INTEGER
    h0    AS INTEGER
END TYPE
DIM SHARED DOCK_RZ AS DOCK_RZ_OBJ

' --- test hook ----------------------------------------------------------------
' DOCK_DUMP=<path> (--option only; never saved): DOCK_layout writes the live tree,
' every column / slot rect and every panel's rect + handle rect to <path> when
' they change, with a sequence number - the QA dock tests read it to find where
' to grab and drop (QA/dock-lib.sh).
DIM SHARED DOCK_DUMP_PATH AS STRING
DIM SHARED DOCK_DUMP_LAST AS STRING
DIM SHARED DOCK_DUMP_SEQ AS LONG

' --- the Browser's band (an exception to "only the left and right edges dock") --
' The Browser alone can also dock in a band along the top (under the menu bar)
' or the bottom (above the palette strip) of the canvas area, between the side
' docks. Saved as BAND=TOP|BOTTOM,<height> in the arrangement.
CONST DOCK_BAND_TOP    = 1
CONST DOCK_BAND_BOTTOM = 2
CONST DOCK_BAND_MIN_H  = 80
DIM SHARED DOCK_BAND_SIDE AS INTEGER ' 0 = the Browser is not in a band
DIM SHARED DOCK_BAND_H    AS INTEGER ' the band's height (px)
DIM SHARED DOCK_BAND_X    AS INTEGER ' this frame's band rect (valid while DOCK_BAND_W > 0)
DIM SHARED DOCK_BAND_Y    AS INTEGER
DIM SHARED DOCK_BAND_W    AS INTEGER
DIM SHARED DOCK_BAND_HH   AS INTEGER ' this frame's band height (DOCK_BAND_H clamped to the room)
DIM SHARED DOCK_SHIFT_Y   AS INTEGER ' the canvas centre's vertical shift for the band (SCRN.panelShiftY)
DIM SHARED DOCK_TOPBAR_H  AS INTEGER ' height of the text bar under the menu bar this frame (set by SCREEN_compute_layout)
DIM SHARED DOCK_L_BARY1   AS INTEGER ' the last layout's dock top / bottom (drop targets)
DIM SHARED DOCK_L_DOCKY2  AS INTEGER
DIM SHARED DOCK_RZ_BAND   AS INTEGER ' dragging the band's inner edge
DIM SHARED DOCK_RZ_BY0    AS INTEGER
DIM SHARED DOCK_RZ_BH0    AS INTEGER
