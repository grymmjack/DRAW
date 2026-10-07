''
' DRAW - GUI/DOCK-RESIZE.BI
' =============================================================================
' Drag-resize for the side-docked panels (left/right screen edges only; the
' menu bar stays on top, the status bar and palette strip at the bottom).
' Each panel resizes by its INNER edge (the one facing the canvas):
'
'   toolbox      button columns (1-8)     -> [TOOLBOX] COLUMNS / TOOLBOX_COLUMNS
'   edit bar     icon columns (1-4)       -> [EDIT_BAR] COLUMNS / EDIT_BAR_COLUMNS
'   advanced bar icon columns (1-4)       -> [ADVANCED_BAR] COLUMNS / ADV_BAR_COLUMNS
'   layers       width in px (60-400)     -> [CHROME] LAYER_PANEL_WIDTH / LAYER_PANEL_WIDTH
'
' The content reflows live while dragging; on release the value is saved into
' the ACTIVE WORKSPACE (a user copy of a built-in), or into DRAW.cfg in Default.
' SCREEN_compute_layout registers the edges every layout (DOCK_set_edge).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST DOCK_NONE    = 0
CONST DOCK_TOOLBOX = 1
CONST DOCK_LAYERS  = 2
CONST DOCK_EDITBAR = 3
CONST DOCK_ADVBAR  = 4
CONST DOCK_COUNT   = 4
CONST DOCK_GRAB    = 2 ' px either side of the boundary that grab it

TYPE DOCK_EDGE_OBJ
    active AS INTEGER ' the panel is shown this layout
    bx     AS INTEGER ' boundary: first px past the panel's inner side
    side   AS INTEGER ' 1 = docked LEFT (inner edge on its right), -1 = docked RIGHT
    w      AS INTEGER ' panel width in px this layout
    y1     AS INTEGER ' vertical extent of the grab zone
    y2     AS INTEGER
END TYPE
DIM SHARED DOCK_EDGES(1 TO DOCK_COUNT) AS DOCK_EDGE_OBJ

TYPE DOCK_DRAG_OBJ
    which  AS INTEGER ' DOCK_* being dragged (0 = none)
    startX AS INTEGER ' mouse x at grab
    startW AS INTEGER ' panel width at grab
    lastV  AS INTEGER ' last value applied (columns or px)
    grabV  AS INTEGER ' value when grabbed (unchanged on drop = nothing saved)
END TYPE
DIM SHARED DOCK_DRAG AS DOCK_DRAG_OBJ
