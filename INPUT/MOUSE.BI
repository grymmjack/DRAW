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
    RAW_X AS INTEGER         ' Raw screen X coordinate (for GUI hover)
    RAW_Y AS INTEGER         ' Raw screen Y coordinate (for GUI hover)
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
    DEFERRED_ACTION AS INTEGER  ' Action to perform after mouse processing (0=none, 1=save, 2=load)
END TYPE

DIM SHARED MOUSE AS MOUSE_OBJ

MOUSE_init
