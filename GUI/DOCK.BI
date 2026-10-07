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
DIM SHARED DOCK_CUSTOM AS INTEGER ' a [DOCK] arrangement is in effect (else the default tree is rebuilt from the dock keys every layout)
' DOCK_layout results: the canvas edges and the menu bar's span
DIM SHARED DOCK_LX AS INTEGER
DIM SHARED DOCK_RX AS INTEGER
DIM SHARED DOCK_MENU_LX AS INTEGER
DIM SHARED DOCK_MENU_RX AS INTEGER
