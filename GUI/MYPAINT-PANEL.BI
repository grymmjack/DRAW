''
' DRAW - GUI/MYPAINT-PANEL.BI
' =============================================================================
' The MyPaint brush palette (PLANS/MYPAINT.md M4): a dock panel (DP_MYPAINT, View >
' MyPaint Brushes, CFG.MYPAINT_PANEL) - a header with the group (< NAME >) and LOAD / SAVE,
' the brush in use (or the one under the pointer) with its size, then a grid of the
' brushes' _prev.png thumbnails at CFG.MYPAINT_CELL px. Click a brush = use it (and pick
' the MyPaint tool); the wheel scrolls the grid, over the header it changes the group.
' Groups: ASSETS/BRUSHES/MYPAINT/order.conf (MyPaint's own grouping), then MY BRUSHES
' (<data>/MYPAINT-BRUSHES/, where SAVE writes - with a preview painted by the brush).
'
$INCLUDEONCE

CONST MYPP_MIN_W  = 120 ' narrowest (its units): the grid has at least one column
CONST MYPP_COL_W  = 214 ' the width it asks of a column (four 48 px cells)
CONST MYPP_MAX_GROUPS = 40
CONST MYPP_MAX_BRUSHES = 1024
CONST MYPP_GAP    = 2   ' between cells

' header buttons (MYPP.hover / hit ids; cells are 100 + index in the group)
CONST MYPPB_PREV = 1
CONST MYPPB_NEXT = 2
CONST MYPPB_LOAD = 3
CONST MYPPB_SAVE = 4
CONST MYPPB_GROUP = 5 ' the group name (a click: the group dropdown, MYPP_menu_open)
CONST MYPPB_CELL0 = 100
CONST MYPP_ACT_GROUP = 100 ' the group dropdown's row values: + the group (DOCK_UI.menuMyp)

TYPE MYPP_OBJ
    scanned AS INTEGER ' the groups are read (MYPP_rescan)
    nGroups AS INTEGER
    group   AS INTEGER ' the group shown (1..nGroups)
    x       AS INTEGER ' the rect it was given (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    visible AS INTEGER
    hover   AS INTEGER ' the control / cell under the pointer (MYPPB_*)
    scroll  AS INTEGER ' first grid row shown
    cols    AS INTEGER ' last drawn: grid columns, rows that fit, rows in all
    rowsFit AS INTEGER
    rowsAll AS INTEGER
    cell    AS INTEGER ' last drawn cell size
    gridX   AS INTEGER
    gridY   AS INTEGER
    thumbsOf AS INTEGER ' the group whose thumbnails are loaded (0 = none)
    thumbCell AS INTEGER ' the cell size they were shrunk to (MYPP_load_thumbs)
END TYPE
DIM SHARED MYPP AS MYPP_OBJ
DIM SHARED MYPP_MENU_NEXT AS INTEGER ' set before DOCK_menu_open: the next menu is the group dropdown
DIM SHARED MYPP_GNAME(1 TO MYPP_MAX_GROUPS) AS STRING
DIM SHARED MYPP_GFIRST(1 TO MYPP_MAX_GROUPS) AS INTEGER ' its first brush in MYPP_PATH
DIM SHARED MYPP_GN(1 TO MYPP_MAX_GROUPS) AS INTEGER     ' its brush count
DIM SHARED MYPP_NB AS INTEGER
DIM SHARED MYPP_PATH(1 TO MYPP_MAX_BRUSHES) AS STRING   ' every brush (.myb path), group by group
DIM SHARED MYPP_THUMB(1 TO MYPP_MAX_BRUSHES) AS LONG    ' loaded thumbnail, cell x cell (the shown group only)
' header controls as last drawn (its units)
DIM SHARED MYPP_BX(1 TO 5) AS INTEGER, MYPP_BW(1 TO 5) AS INTEGER, MYPP_BY AS INTEGER
