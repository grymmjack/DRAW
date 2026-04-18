''
' DRAW - CFG/STICK.BI
' =============================================================================
' UDT for joystick bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE DRAW_STICK_BINDINGS
    ' MOUSE EMULATION ---------------------------------------------------------
    MOUSE_L        AS STRING ' Move cursor left (DPad)
    MOUSE_R        AS STRING ' Move cursor right (DPad)
    MOUSE_U        AS STRING ' Move cursor up (DPad)
    MOUSE_D        AS STRING ' Move cursor down (DPad)
    MOUSE_L_N      AS STRING ' Move cursor left fast (thumbstick)
    MOUSE_R_N      AS STRING ' Move cursor right fast (thumbstick)
    MOUSE_U_N      AS STRING ' Move cursor up fast (thumbstick)
    MOUSE_D_N      AS STRING ' Move cursor down fast (thumbstick)
    MOUSE_CLICK_L  AS STRING ' Emulate left mouse click (A button)
    MOUSE_CLICK_M  AS STRING ' Emulate middle mouse click (B button)
    MOUSE_CLICK_R  AS STRING ' Emulate right mouse click (X button)
    MOUSE_SCROLL_U AS STRING ' Emulate scroll wheel up (trigger)
    MOUSE_SCROLL_D AS STRING ' Emulate scroll wheel down (trigger)
END TYPE

DIM SHARED SB AS DRAW_STICK_BINDINGS ' Global joystick binding configuration
