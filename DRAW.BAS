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
DIM k AS LONG
DO:   
    k& = _KEYHIT
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
END SUB


''
' Runs at the end of the loop just before next iteration
' 
SUB LOOP_end ()
    PAL_FG_IDX% = PAL_clamp_color_index(PAL_FG_IDX%)
    PAL_BG_IDX% = PAL_clamp_color_index(PAL_BG_IDX%)
END SUB


''
' Runs at shutdown of main prorgam
' 
SUB MAIN_shutdown ()
    _MOUSESHOW
    SCREEN 0
    CLS
    _FREEIMAGE SCRN.CANVAS&
    _FREEIMAGE SCRN.PAINTING&
    _FREEIMAGE SCRN.GUI&
    SYSTEM
END SUB



$IF ALL_BM = UNDEFINED THEN 
'$INCLUDE:'./_ALL.BM'
$END IF
