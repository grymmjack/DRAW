''
' DRAW - TOOLS/PAN.BI
' =============================================================================
' UDT for pan tool (dedicated LMB panning mode).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PAN_OBJ
    ACTIVE AS INTEGER  ' TRUE when pan tool is selected as current tool
END TYPE

DIM SHARED PAN AS PAN_OBJ

PAN.ACTIVE = FALSE
