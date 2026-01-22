''
' DRAW - INPUT/MOUSE.BI
' =============================================================================
' UDT for mouse input handling.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE MOUSE_OBJ
    X     AS INTEGER
    Y     AS INTEGER
    OLD_X AS INTEGER
    OLD_Y AS INTEGER
    CON_X AS INTEGER
    CON_Y AS INTEGER
    B1    AS INTEGER
    B2    AS INTEGER
    B3    AS INTEGER
    OLD_B1 AS INTEGER
    OLD_B2 AS INTEGER
    OLD_B3 AS INTEGER
    OSW   AS INTEGER
    SW    AS INTEGER
    DRAG  AS STRING
    B3_CLICK_TIME AS DOUBLE
    TOOLBAR_CLICKED AS INTEGER
END TYPE

DIM SHARED MOUSE AS MOUSE_OBJ

MOUSE_init
