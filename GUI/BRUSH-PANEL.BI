''
' DRAW - GUI/BRUSH-PANEL.BI
' =============================================================================
' The brush palette (Rick 2026-11-18: "a real brush size palette ... that can be docked
' down to 1 column, 2 columns, tall, wide, whatever ... with thumbnail for each size"):
' a dock panel (DP_BRUSHES, View > Brush Palette, CFG.BRUSH_PANEL) for the brush the
' brush / eraser / line / shape tools paint with (TOOLS/BRUSH-SIZE):
'   shape chips   ROUND / SQUARE / SLANT / / SLANT \ (BRUSH_SIZE.SHAPE)
'   SIZE slider   the size index 1..25 (1, 3, 5 .. 49 px; [ / ])
'   SOFT slider   edge softness 0..100 % (BRUSH_SIZE.SOFT = CFG.BRUSH_SOFT; round + slant)
'   the grid      a thumbnail per size of the shape as it paints (PAINT_shape_dab's
'                 coverage, shrunk to the cell), click = that size; it wraps into the
'                 width it gets and scrolls in the height (any dock shape)
' The sliders take the universal value input (GUI/PANEL-SLIDER).
'
$INCLUDEONCE

CONST BSP_MIN_W = 64     ' narrowest (its units): one column of cells
CONST BSP_COL_W = 160    ' the width it asks of a column
CONST BSP_SLIDER_W = 150 ' a slider's width when the two sit side by side
CONST BSP_GAP = 2        ' between cells
CONST BSP_NSIZES = 25

' controls (BSP.hover / hit ids; cells are BSPB_CELL0 + size index)
CONST BSPB_ROUND = 1
CONST BSPB_SQUARE = 2
CONST BSPB_SLASH = 3
CONST BSPB_BACKSLASH = 4
CONST BSPB_SIZE = 10 ' slider
CONST BSPB_SOFT = 11 ' slider
CONST BSPB_CELL0 = 100

CONST BSP_ACT_PANEL = 2689 ' View > Brush Palette (GUI/COMMAND.BM; free range checked 2026-11-18)

TYPE BSP_OBJ
    x       AS INTEGER ' the rect it was given (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    visible AS INTEGER
    hover   AS INTEGER ' the control / cell under the pointer (BSPB_*)
    drag    AS INTEGER ' the slider held (BSPB_SIZE / BSPB_SOFT, 0 = none)
    scroll  AS INTEGER ' first grid row shown
    cols    AS INTEGER ' last drawn: grid columns, rows that fit, rows in all
    rowsFit AS INTEGER
    rowsAll AS INTEGER
    cell    AS INTEGER
    gridX   AS INTEGER
    gridY   AS INTEGER
    chipY   AS INTEGER ' the shape chips' row
    sw      AS INTEGER ' a slider's width, label / value columns
    lw      AS INTEGER
    vw      AS INTEGER
    thumbKey AS STRING ' what the cached thumbnails show (shape, soft, cell, AA, colour)
END TYPE
DIM SHARED BSP AS BSP_OBJ
DIM SHARED BSP_CX(1 TO 4) AS INTEGER, BSP_CW(1 TO 4) AS INTEGER        ' shape chips (its units)
DIM SHARED BSP_SX(BSPB_SIZE TO BSPB_SOFT) AS INTEGER, BSP_SY(BSPB_SIZE TO BSPB_SOFT) AS INTEGER ' sliders
DIM SHARED BSP_THUMB(1 TO BSP_NSIZES) AS LONG ' a cell x cell picture per size (BSP_thumbs)
DIM SHARED BSP_ICON(1 TO 4) AS LONG           ' the chips' shapes
DIM SHARED BSP_ICON_KEY AS STRING
