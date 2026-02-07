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
  
' Parse command line arguments (just store filename, load after first frame)
DIM cmdArg$
cmdArg$ = _TRIM$(COMMAND$)
IF cmdArg$ <> "" THEN
    ' Remove surrounding quotes if present
    IF LEFT$(cmdArg$, 1) = CHR$(34) AND RIGHT$(cmdArg$, 1) = CHR$(34) THEN
        cmdArg$ = MID$(cmdArg$, 2, LEN(cmdArg$) - 2)
    END IF
    ' Store for deferred loading
    IF _FILEEXISTS(cmdArg$) THEN
        CMDLINE_PENDING_FILE$ = cmdArg$
    END IF
END IF

' Apply config startup defaults (tool, brush size, directories)
' Must be called after all modules are initialized via includes
CONFIG_apply_startup_defaults

' Pre-load all cursor PNGs (must be after THEME.BI sets filenames and
' SCREEN_init calls CONFIG_load so CFG.THEME$ is available)
CURSOR_load_all

' Main Loop
DIM k AS LONG
DIM exitConfirmed AS INTEGER
exitConfirmed% = FALSE
    
DO
    ' Deferred command line file loading (after first frame when everything is initialized)
    IF CMDLINE_FIRST_FRAME% AND CMDLINE_PENDING_FILE$ <> "" THEN
        CMDLINE_FIRST_FRAME% = FALSE
        DIM pendingExt$
        pendingExt$ = LCASE$(RIGHT$(CMDLINE_PENDING_FILE$, 4))
        IF pendingExt$ = ".drw" THEN
            DRW_load CMDLINE_PENDING_FILE$
        ELSE
            ' Image file - use image import
            DIM loadResult%
            loadResult% = IMAGE_IMPORT_load_file%(CMDLINE_PENDING_FILE$)
        END IF
        CMDLINE_PENDING_FILE$ = ""  ' Clear after loading
    ELSEIF CMDLINE_FIRST_FRAME% THEN
        CMDLINE_FIRST_FRAME% = FALSE
    END IF
    k& = _KEYHIT
    
    ' Handle display scale hotkeys using _KEYHIT (more reliable than _KEYDOWN for complex combos)
    ' CTRL+ALT+SHIFT+= to scale up, CTRL+ALT+SHIFT+- to scale down
    IF NOT CFG.FULLSCREEN% THEN
        DIM scale_ctrl AS INTEGER, scale_shift AS INTEGER, scale_alt AS INTEGER
        scale_ctrl% = (_KEYDOWN(100305) OR _KEYDOWN(100306))   ' Left or Right Ctrl
        scale_shift% = (_KEYDOWN(100304) OR _KEYDOWN(100303)) ' Left or Right Shift
        scale_alt% = (_KEYDOWN(KEY_LALT&) OR _KEYDOWN(KEY_RALT&))
        
        IF scale_ctrl% AND scale_shift% AND scale_alt% THEN
            ' Check _KEYHIT for the actual key (works better on Linux with modifier combos)
            ' Numpad + : 43 (NumLock ON), 19968 (NumLock OFF)
            ' Numpad - : 45 (NumLock ON), 18944 (NumLock OFF)
            IF k& = 43 OR k& = 19968 THEN
                SCREEN_set_display_scale SCRN.displayScale% + 1
            ELSEIF k& = 45 OR k& = 18944 THEN
                SCREEN_set_display_scale SCRN.displayScale% - 1
            END IF
        END IF
    END IF
    
    ' Check for ESC key with confirmation if canvas is dirty
    ' If a tool/modal is active, let keyboard handler process ESC instead of exiting
    IF k& = 27 THEN
        IF SHOULD_block_exit% THEN
            ' Tool/modal active - let keyboard handler process ESC
        ELSEIF CANVAS_DIRTY% THEN
            IF SHOW_exit_confirm% THEN EXIT DO
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
' Check if ESC should be blocked from exiting (tool/modal is active)
' Returns TRUE if a tool or modal state should handle ESC instead of exiting
'
FUNCTION SHOULD_block_exit% ()
    SHOULD_block_exit% = PALETTE_MENU_VISIBLE% _
        OR CMD_PALETTE.visible _
        OR (IMG_IMPORT.STATE > IMPORT_STATE_IDLE) _
        OR (CURRENT_TOOL% = TOOL_MOVE AND MOVE.ACTIVE) _
        OR (CURRENT_TOOL% = TOOL_POLYGON AND POLY_LINE.HAS_LAST) _
        OR (CURRENT_TOOL% = TOOL_TEXT AND TEXT.ACTIVE) _
        OR LAYER_PANEL_is_dragging% _
        OR (CURRENT_TOOL% = TOOL_MARQUEE AND MARQUEE.MAGIC_WAND_MODE AND MARQUEE.WAND_HAS_SELECTION) _
        OR (CURRENT_TOOL% = TOOL_MARQUEE AND MARQUEE.ACTIVE%)
END FUNCTION


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
    IF MOVE.SELECTION_IMAGE < -1 THEN _FREEIMAGE MOVE.SELECTION_IMAGE
    
    ' Free custom cursor if loaded (ensure default cursor is shown first)
    _MOUSESHOW  ' Ensure using default system cursor before freeing cursors
    CURSOR_cleanup
    
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
