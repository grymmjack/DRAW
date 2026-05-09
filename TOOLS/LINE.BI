''
' DRAW - TOOLS/LINE.BI
' =============================================================================
' UDT for line tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST LINE_CAP_NONE  = 0
CONST LINE_CAP_ARROW = 1
CONST LINE_CAP_CUBE  = 2
CONST LINE_CAP_DOT   = 3
CONST LINE_CAP_COUNT = 4

TYPE LINE_TYPE
    DRAGGING  AS INTEGER ' TRUE when dragging to create line
    START_X   AS INTEGER ' Line start X
    START_Y   AS INTEGER ' Line start Y
    END_X     AS INTEGER ' Line end X (current mouse position)
    END_Y     AS INTEGER ' Line end Y (current mouse position)
    SPOKES    AS INTEGER ' Extra radial lines from start point at equidistant angles (0=none)
    START_CAP AS INTEGER ' Cap shape at start point (LINE_CAP_*)
    END_CAP   AS INTEGER ' Cap shape at end point (LINE_CAP_*)
END TYPE

DIM SHARED LINE_TOOL AS LINE_TYPE
LINE_TOOL.DRAGGING  = FALSE
LINE_TOOL.START_X   = 0
LINE_TOOL.START_Y   = 0
LINE_TOOL.END_X     = 0
LINE_TOOL.END_Y     = 0
LINE_TOOL.SPOKES    = 0
LINE_TOOL.START_CAP = LINE_CAP_NONE
LINE_TOOL.END_CAP   = LINE_CAP_NONE