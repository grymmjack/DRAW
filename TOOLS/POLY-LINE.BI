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
    HAS_LAST AS INTEGER    ' TRUE if we have a last position
END TYPE

DIM SHARED POLY_LINE AS POLY_LINE_TYPE
POLY_LINE.LAST_X = 0
POLY_LINE.LAST_Y = 0
POLY_LINE.HAS_LAST = FALSE