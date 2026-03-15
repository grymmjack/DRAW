''
' DRAW - TOOLS/FILL.BI
' =============================================================================
' UDT for fill (PAINT) tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE FILL_POINT
    x AS INTEGER
    y AS INTEGER
END TYPE

TYPE FILL_TOOL
    ACTIVE   AS INTEGER  ' Is the fill tool currently active?
    COLOR    AS _UNSIGNED LONG  ' Color to fill with
    BOUNDARY AS _UNSIGNED LONG  ' Boundary color (0 = any different color)
END TYPE

DIM SHARED FILL AS FILL_TOOL

DECLARE FUNCTION FILL_generate_mask& (x AS INTEGER, y AS INTEGER, bx1 AS INTEGER, by1 AS INTEGER, bx2 AS INTEGER, by2 AS INTEGER)

FILL_init
