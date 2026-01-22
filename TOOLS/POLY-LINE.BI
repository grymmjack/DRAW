''
' DRAW - TOOLS/POLY-LINE.BI
' =============================================================================
' UDT for polygon line tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
TYPE POLY_LINE_TYPE
    LAST_X AS INTEGER      ' Last point X for continuing line
    LAST_Y AS INTEGER      ' Last point Y for continuing line
    FIRST_X AS INTEGER     ' First point X for closing shape
    FIRST_Y AS INTEGER     ' First point Y for closing shape
    HAS_LAST AS INTEGER    ' TRUE if we have a last position
    FILLED AS INTEGER      ' TRUE for filled polygon
    POINT_COUNT AS INTEGER ' Number of points in polygon
END TYPE

DIM SHARED POLY_LINE AS POLY_LINE_TYPE
DIM SHARED POLY_POINTS_X(1000) AS INTEGER ' Array to store X coordinates
DIM SHARED POLY_POINTS_Y(1000) AS INTEGER ' Array to store Y coordinates

POLY_LINE.LAST_X = 0
POLY_LINE.LAST_Y = 0
POLY_LINE.FIRST_X = 0
POLY_LINE.FIRST_Y = 0
POLY_LINE.HAS_LAST = FALSE
POLY_LINE.FILLED = FALSE
POLY_LINE.POINT_COUNT = 0