''
' DRAW - INPUT/MOUSE.BI
' =============================================================================
' UDT for mouse input handling.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

$IF MOUSE_BI = UNDEFINED THEN
    $LET MOUSE_BI = 1
$END IF

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
    OSW   AS INTEGER
    SW    AS INTEGER
    DRAG  AS STRING
END TYPE

