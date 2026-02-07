''
' DRAW - TOOLS/SPRAY.BI
' =============================================================================
' UDT for spray paint tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SPRAY_OBJ
    ACTIVE    AS INTEGER  ' TRUE while spraying
END TYPE

DIM SHARED SPRAY AS SPRAY_OBJ

SPRAY.ACTIVE = FALSE
