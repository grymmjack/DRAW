''
' DRAW - DRAW.BAS
' =============================================================================
' Main program. 
'
' @depends ./_ALL.BI
' @depends ./_ALL.BM
' @author Rick Christy <grymmjack@gmail.com>
'

'$INCLUDE:'./_ALL.BI'
$RESIZE:STRETCH
$CONSOLE
  
' Main Loop
DIM k AS LONG
DIM exitConfirmed AS INTEGER
exitConfirmed% = FALSE
    
DO
    k& = _KEYHIT
    
    ' Check for ESC key with confirmation if canvas is dirty
    ' BUT: If poly line, text tool, image import is active, move tool is active, or palette menu is open, let keyboard handler process it instead
    IF k& = 27 THEN
        IF PALETTE_MENU_VISIBLE% THEN
            ' Palette menu is open, let keyboard handler close it (don't exit)
            ' The keyboard handler will process this ESC
        ELSEIF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN
            ' Image import is active, let keyboard handler cancel it (don't exit)
            ' The keyboard handler will process this ESC
        ELSEIF CURRENT_TOOL% = TOOL_MOVE AND MOVE.ACTIVE THEN
            ' Move tool is active, let keyboard handler cancel the transform (don't exit)
            ' The keyboard handler will process this ESC
        ELSEIF CURRENT_TOOL% = TOOL_POLYGON AND POLY_LINE.HAS_LAST THEN
            ' Poly line is active, let keyboard handler reset it (don't exit)
            ' The keyboard handler will process this ESC
        ELSEIF CURRENT_TOOL% = TOOL_TEXT AND TEXT.ACTIVE THEN
            ' Text tool is active, let keyboard handler apply text (don't exit)
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
    
    ' Validate FPS limit before applying (Windows fix for invalid _LIMIT causing input issues)
    IF CFG.FPS_LIMIT% > 0 AND CFG.FPS_LIMIT% <= 1000 THEN
        _LIMIT CFG.FPS_LIMIT%
    ELSE
        _LIMIT 60  ' Safe fallback
    END IF
    
    SCREEN_render
    MOUSE_input_handler_loop
    KEYBOARD_input_handler_loop
    STICK_input_handler_loop
    LOOP_end
LOOP

' Check if display scale changed during session and prompt to save
IF CFG.DISPLAY_SCALE_CHANGED% THEN
    DIM save_result AS LONG
    _MOUSESHOW
    save_result& = _MESSAGEBOX("Save Configuration?", "Display scale changed to " + _TRIM$(STR$(SCRN.displayScale%)) + "x. Save configuration for next time?", "yesno", "question", 0)
    _MOUSEHIDE
    IF save_result& = 1 THEN
        ' Update the display scale in config before saving
        CFG.DISPLAY_SCALE% = SCRN.displayScale%
        CONFIG_save
    END IF
END IF

MAIN_shutdown



''
' Runs at the start of the loop before any other code
' 
SUB LOOP_start ()
    ' Reset undo save flag once per frame
    UNDO_saved_this_frame% = FALSE
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
    _MOUSESHOW
    result& = _MESSAGEBOX("Exit Confirmation", "Are you sure you want to exit?", "yesno", "question", 0)
    _MOUSEHIDE
    
    ' Clear input buffers
    DO WHILE _MOUSEINPUT : LOOP
    _MOUSEMOVE _WIDTH \ 2, _HEIGHT \ 2
    MOUSE_force_buttons_up
    
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
    DIM i AS INTEGER
    _MOUSESHOW
    SCREEN 0
    CLS
    
    ' Free main screen buffers
    IF SCRN.CANVAS& < -1 THEN _FREEIMAGE SCRN.CANVAS&
    IF SCRN.PAINTING& < -1 THEN _FREEIMAGE SCRN.PAINTING&
    IF SCRN.GUI& < -1 THEN _FREEIMAGE SCRN.GUI&
    IF SCRN.CURSOR& < -1 THEN _FREEIMAGE SCRN.CURSOR&
    IF SCRN.WINDOW_IMG& < -1 THEN _FREEIMAGE SCRN.WINDOW_IMG&
    
    ' Free all toolbar button images
    FOR i% = 0 TO 13
        IF GUI_TB(i%).iHnd& < -1 THEN _FREEIMAGE GUI_TB(i%).iHnd&
        IF GUI_TB(i%).iHndAlt& < -1 THEN _FREEIMAGE GUI_TB(i%).iHndAlt&
    NEXT i%
    
    ' Free undo history images
    UNDO_clear
    
    ' Free move selection image if active
    IF MOVE.SELECTION_IMAGE <> 0 THEN _FREEIMAGE MOVE.SELECTION_IMAGE
    
    ' Free custom cursor if loaded (ensure default cursor is shown first)
    IF POINTER.IMG& <> 0 AND POINTER.IMG& < -1 THEN
        _MOUSESHOW  ' Ensure using default system cursor before freeing custom
        _FREEIMAGE POINTER.IMG&
    END IF
    
    ' Free Tiny5 font if loaded
    IF TEXT.FONT_HANDLE > 0 THEN
        _FREEFONT TEXT.FONT_HANDLE
    END IF
    ' Free custom font if loaded
    IF TEXT.CUSTOM_FONT_HANDLE > 0 THEN
        _FREEFONT TEXT.CUSTOM_FONT_HANDLE
    END IF

    SYSTEM
END SUB

'$INCLUDE:'./_ALL.BM'
