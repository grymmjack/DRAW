''
' DRAW - DRAW.BAS
' =============================================================================
' Main program. 
'
' @depends ./_ALL.BI
' @depends ./_ALL.BM
' @author Rick Christy <grymmjack@gmail.com>
'

$IF ALL_BI = UNDEFINED THEN 
'$INCLUDE:'./_ALL.BI'
$END IF



' Main Loop
DO:   
    LOOP_start

    MOUSE_input_handler
    KEYBOARD_input_handler
    STICK_input_handler

    _LIMIT CFG.FPS_LIMIT%

    SCREEN_render

    MOUSE_input_handler_loop
    KEYBOARD_input_handler_loop
    STICK_input_handler_loop

    LOOP_end
LOOP UNTIL k&=27
MAIN_shutdown



''
' Runs at the start of the loop before any other code
' 
SUB LOOP_start ()
    DELAY .001
END SUB


''
' Runs at the end of the loop just before next iteration
' 
SUB LOOP_end ()
    IF PAINT_COLOR% > 15 THEN PAINT_COLOR% = 15
    IF PAINT_COLOR% < 0  THEN PAINT_COLOR% = 0
END SUB


''
' Runs at shutdown of main prorgam
' 
SUB MAIN_shutdown ()
    _MOUSESHOW
    SYSTEM
END SUB

$IF ALL_BI = UNDEFINED THEN 
'$INCLUDE:'./_ALL.BM'
$END IF
