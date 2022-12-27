''
' DRAW - CFG/STICK.BI
' =============================================================================
' UDT for joystick bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'

$IF CONFIG_STICK_BI = UNDEFINED THEN
    $LET CONFIG_STICK_BI = 1
$END IF

TYPE DRAW_STICK_BINDINGS
    ' MOUSE EMULATION ---------------------------------------------------------
    MOUSE_L               AS STRING
    MOUSE_R               AS STRING
    MOUSE_U               AS STRING
    MOUSE_D               AS STRING
    MOUSE_L_N             AS STRING
    MOUSE_R_N             AS STRING
    MOUSE_U_N             AS STRING
    MOUSE_D_N             AS STRING
    MOUSE_CLICK_L         AS STRING
    MOUSE_CLICK_M         AS STRING
    MOUSE_CLICK_R         AS STRING
    MOUSE_SCROLL_U        AS STRING
    MOUSE_SCROLL_D        AS STRING
END TYPE

DIM SHARED SB AS DRAW_STICK_BINDINGS
