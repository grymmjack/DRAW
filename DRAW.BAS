''
' DRAW - DRAW.BAS
' =============================================================================
' Main program. 
'
' @depends ./_ALL.BI
' @depends ./_ALL.BM
' @author Rick Christy <grymmjack@gmail.com>
'
$CONSOLE

'$INCLUDE:'./_ALL.BI'



' Main Loop
DIM k AS LONG
DIM exitConfirmed AS INTEGER
exitConfirmed% = FALSE

DO
    k& = _KEYHIT
    
    ' Check for ESC key with confirmation if canvas is dirty
    ' BUT: If poly line tool is active, let keyboard handler reset it instead
    IF k& = 27 THEN
        IF CURRENT_TOOL% = TOOL_POLYGON AND POLY_LINE.HAS_LAST THEN
            ' Poly line is active, let keyboard handler reset it (don't exit)
            ' The keyboard handler will process this ESC
        ELSEIF CANVAS_DIRTY% THEN
            IF SHOW_exit_confirm% THEN
                EXIT DO  ' Exit immediately if OK clicked
            END IF
            ' If cancelled, continue loop
        ELSE
            EXIT DO  ' Clean canvas, exit immediately
        END IF
    END IF
    
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
LOOP
MAIN_shutdown



''
' Runs at the start of the loop before any other code
' 
SUB LOOP_start ()
    ' Don't update MARQUEE here - let mouse handler control it
END SUB


''
' Runs at the end of the loop just before next iteration
' 
SUB LOOP_end ()
END SUB


''
' Simple message box using native QB64PE dialog
' Returns TRUE if Yes clicked, FALSE if No
'
FUNCTION SHOW_exit_confirm% ()
    DIM result AS LONG
    result& = _MESSAGEBOX("Exit Confirmation", "Are you sure you want to exit?", "yesno", "question", 0)
    IF result& = 1 THEN
        SHOW_exit_confirm% = TRUE
    ELSE
        SHOW_exit_confirm% = FALSE
    END IF
END FUNCTION


''
' Runs at shutdown of main program
' 
SUB MAIN_shutdown ()
    _MOUSESHOW
    SCREEN 0
    CLS
    _FREEIMAGE SCRN.CANVAS&
    _FREEIMAGE SCRN.PAINTING&
    _FREEIMAGE SCRN.GUI&
    _FREEIMAGE SCRN.CURSOR&
    SYSTEM
END SUB

'$INCLUDE:'./_ALL.BM'
