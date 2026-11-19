''
' DRAW - TOOLS/SPRAY.BI
' =============================================================================
' UDT for spray paint tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SPRAY_OBJ
    ACTIVE             AS INTEGER ' TRUE while spraying
    HISTORY_BEFORE_IMG AS LONG
    HISTORY_COLOR      AS _UNSIGNED LONG
    AB_FRESH           AS INTEGER ' airbrush: TRUE until the stroke's first spray (set on press)
    AB_LX              AS SINGLE  ' airbrush: the last spray centre (path between frames)
    AB_LY              AS SINGLE
    AB_LT              AS DOUBLE  ' airbrush: TIMER of the last spray (paint flows per second)
END TYPE

DIM SHARED SPRAY AS SPRAY_OBJ

SPRAY.ACTIVE             = FALSE
SPRAY.HISTORY_BEFORE_IMG = 0
SPRAY.HISTORY_COLOR~&    = 0
