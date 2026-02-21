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
'$CONSOLE
$EXEICON:'./ASSETS/ICONS/icon.ico'
  
' Parse command line arguments (just store filename, load after first frame)
' --config / -c args are already consumed by CONFIG.BI inline code
DIM cmdArg$

$IF MAC THEN
    ' macOS .app bundle: Finder passes file path via DRAW_OPEN_FILE env var
    ' (set by the launcher script in the .app bundle, since macOS uses Apple
    ' Events for file association opens, not command-line arguments)
    cmdArg$ = _TRIM$(ENVIRON$("DRAW_OPEN_FILE"))
    IF cmdArg$ = "" THEN
        ' Fallback: check COMMAND$ for direct terminal launch
        ' Skip --config / -c and its value when looking for file args
        DIM macArgIdx%
        macArgIdx% = 1
        DO WHILE macArgIdx% <= _COMMANDCOUNT
            DIM macArgVal$
            macArgVal$ = _TRIM$(COMMAND$(macArgIdx%))
            IF LCASE$(macArgVal$) = "--config" OR LCASE$(macArgVal$) = "-c" THEN
                macArgIdx% = macArgIdx% + 2 ' Skip flag + value
            ELSE
                cmdArg$ = macArgVal$
                EXIT DO
            END IF
        LOOP
    END IF
$ELSE
    ' Skip --config / -c and its value when looking for file args
    DIM argIdx%
    argIdx% = 1
    DO WHILE argIdx% <= _COMMANDCOUNT
        DIM argVal$
        argVal$ = _TRIM$(COMMAND$(argIdx%))
        IF LCASE$(argVal$) = "--config" OR LCASE$(argVal$) = "-c" THEN
            argIdx% = argIdx% + 2 ' Skip flag + value
        ELSE
            cmdArg$ = argVal$
            EXIT DO
        END IF
    LOOP
$END IF

' ESC no longer exits the program - use File > Quit or OS close button

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

' Pre-load layer panel icons from theme directory
LAYER_PANEL_load_icons

' Set initial window title
TITLE_update

$IF WIN THEN
    ' Windows: enable drag-and-drop file support
    _ACCEPTFILEDROP
$END IF

' Main Loop
DIM k AS LONG
DIM exitConfirmed AS INTEGER
exitConfirmed% = FALSE
    
DO
    ' Deferred command line file loading (after first frame when everything is initialized)
    IF CMDLINE_FIRST_FRAME% AND CMDLINE_PENDING_FILE$ <> "" THEN
        CMDLINE_FIRST_FRAME% = FALSE
        DIM pendingExt$
        pendingExt$ = LCASE$(RIGHT$(CMDLINE_PENDING_FILE$, 5))
        IF pendingExt$ = ".draw" THEN
            DRW_load CMDLINE_PENDING_FILE$
            CURRENT_DRW_FILENAME$ = CMDLINE_PENDING_FILE$
        ELSE
            ' Image file - use image import
            DIM loadResult%
            loadResult% = IMAGE_IMPORT_load_file%(CMDLINE_PENDING_FILE$)
        END IF
        CMDLINE_PENDING_FILE$ = ""  ' Clear after loading
    ELSEIF CMDLINE_FIRST_FRAME% THEN
        CMDLINE_FIRST_FRAME% = FALSE
    END IF

    $IF WIN THEN
        ' Windows: handle drag-and-drop files onto window
        IF _TOTALDROPPEDFILES THEN
            DIM dropFile$, dropExt$
            dropFile$ = _DROPPEDFILE$(1)
            _FINISHDROP
            IF dropFile$ <> "" AND _FILEEXISTS(dropFile$) THEN
                dropExt$ = LCASE$(RIGHT$(dropFile$, 5))
                IF dropExt$ = ".draw" THEN
                    DRW_load dropFile$
                    CURRENT_DRW_FILENAME$ = dropFile$
                ELSE
                    DIM dropLoadResult%
                    dropLoadResult% = IMAGE_IMPORT_load_file%(dropFile$)
                END IF
            END IF
        END IF
    $END IF
    k& = _KEYHIT
    
    ' Track macOS ALT key via _KEYHIT (must be before MODIFIERS_update)
    MODIFIERS_track_alt_keyhit k&
    
    ' Update modifier key state (CTRL, SHIFT, ALT) once per frame
    MODIFIERS_update
    
    ' Handle display scale hotkeys: CTRL+ALT+SHIFT+= to scale up, CTRL+ALT+SHIFT+- to scale down
    IF NOT CFG.FULLSCREEN% AND MODIFIERS.ctrlShiftAlt% THEN
        ' Numpad + : 43 (NumLock ON), 19968 (NumLock OFF)
        ' Numpad - : 45 (NumLock ON), 18944 (NumLock OFF)
        IF k& = 43 OR k& = 19968 THEN
            SCREEN_set_display_scale SCRN.displayScale% + 1
        ELSEIF k& = 45 OR k& = 18944 THEN
            SCREEN_set_display_scale SCRN.displayScale% - 1
        END IF
    END IF
    
    LOOP_start
    PERF_start PERF_MAIN_LOOP_TOTAL
    PERF_start PERF_MOUSE_INPUT
    MOUSE_input_handler
    PERF_stop PERF_MOUSE_INPUT
    PERF_start PERF_KEYBOARD_INPUT
    KEYBOARD_input_handler
    PERF_stop PERF_KEYBOARD_INPUT
    
    PERF_start PERF_STICK_INPUT
    STICK_input_handler
    PERF_stop PERF_STICK_INPUT
    
    ' Idle detection: reduce FPS when nothing is happening to save CPU
    ' Check if anything needs updating this frame
    PERF_start PERF_IDLE_DETECT
    FRAME_IDLE% = TRUE
    DIM SCENE_CHANGED AS INTEGER
    SCENE_CHANGED% = FALSE
    IF k& <> 0 THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE   ' Key was pressed
    IF MOUSE.B1% OR MOUSE.B2% OR MOUSE.B3% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE  ' Mouse button held
    IF MOUSE.RAW_X% <> IDLE_PREV_MOUSE_X% OR MOUSE.RAW_Y% <> IDLE_PREV_MOUSE_Y% THEN
        FRAME_IDLE% = FALSE                                       ' Mouse moved (cursor only)
        GUI_NEEDS_REDRAW% = TRUE                                  ' Update status bar coords
    END IF
    IF GUI_NEEDS_REDRAW% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE   ' GUI needs update (forces scene re-render)
    IF SCRN.panning% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE      ' Panning active
    IF MODIFIERS.shift% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE   ' SHIFT held (crosshair/constraint)
    IF MOUSE.SW% <> 0 THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE     ' Mouse wheel scrolled
    IF CURRENT_TOOL% = TOOL_MOVE AND MOVE.ACTIVE THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF CURRENT_TOOL% = TOOL_TEXT AND TEXT.ACTIVE THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF CROP.STATE = CROP_STATE_ACTIVE THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF CMD_PALETTE.visible THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF MENUBAR_is_open% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE
    IF SELECTION_has_active% THEN FRAME_IDLE% = FALSE  ' Animation only (marching ants) — no scene change
    IF SCENE_CHANGED% THEN SCENE_DIRTY% = TRUE
    ' Mark current layer content dirty when user is actively drawing
    IF (MOUSE.B1% OR MOUSE.B2%) AND CURRENT_LAYER% > 0 THEN
        LAYERS(CURRENT_LAYER%).contentDirty% = TRUE
    END IF
    IDLE_PREV_MOUSE_X% = MOUSE.RAW_X%
    IDLE_PREV_MOUSE_Y% = MOUSE.RAW_Y%
    PERF_stop PERF_IDLE_DETECT
    
    ' Render FIRST, then limit — this minimizes latency between
    ' reading mouse input and displaying the result on screen.
    ' (_LIMIT before render would add a full frame delay to the pointer)
    
    ' Skip full render when idle — previous frame remains on display
    IF NOT FRAME_IDLE% THEN
        SCREEN_render
    END IF
    
    ' Apply frame rate limit AFTER render+display (reduced when idle)
    PERF_start PERF_LIMIT_WAIT
    IF FRAME_IDLE% THEN
        _LIMIT IDLE_FPS_LIMIT
    ELSEIF CFG.FPS_LIMIT% > 0 AND CFG.FPS_LIMIT% <= 1000 THEN
        _LIMIT CFG.FPS_LIMIT%
    ELSE
        _LIMIT 60  ' Safe fallback
    END IF
    PERF_stop PERF_LIMIT_WAIT
    
    PERF_start PERF_POST_INPUT
    MOUSE_input_handler_loop
    KEYBOARD_input_handler_loop
    STICK_input_handler_loop
    PERF_stop PERF_POST_INPUT
    PERF_stop PERF_MAIN_LOOP_TOTAL
    PERF_frame_end
    LOOP_end
LOOP

' Check if display scale changed during session and prompt to save
IF CFG.DISPLAY_SCALE_CHANGED% THEN
    DIM save_result AS LONG
    POINTER_hide_for_dialog
    save_result& = _MESSAGEBOX("Save Configuration?", "Display scale changed to " + _TRIM$(STR$(SCRN.displayScale%)) + "x. Save configuration for next time?", "yesno", "question", 0)
    POINTER_show_after_dialog
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
    
    ' Update title bar when dirty/filename state changes
    TITLE_check
END SUB


''
' Runs at the end of the loop just before next iteration
' 
SUB LOOP_end ()
END SUB


''
' Runs at shutdown of main program
' 
SUB MAIN_shutdown ()
    DIM i AS INTEGER
    _MOUSESHOW
    SCREEN 0
    CLS

    ' =====================================================================
    ' FREE MAIN SCREEN BUFFERS
    ' =====================================================================
    IF SCRN.CANVAS& < -1 THEN _FREEIMAGE SCRN.CANVAS&
    IF SCRN.PAINTING& < -1 THEN _FREEIMAGE SCRN.PAINTING&
    IF SCRN.GUI& < -1 THEN _FREEIMAGE SCRN.GUI&
    ' SCRN.CURSOR& no longer allocated — cursors draw directly onto SCRN.CANVAS&

    ' =====================================================================
    ' FREE CACHED RENDER BUFFERS
    ' =====================================================================
    IF SCENE_CACHE& < -1 THEN _FREEIMAGE SCENE_CACHE&
    IF PG_CACHE_IMG& < -1 THEN _FREEIMAGE PG_CACHE_IMG&
    IF COMPOSITE_BUFFER& < -1 THEN _FREEIMAGE COMPOSITE_BUFFER&
    IF COMPOSITE_BELOW_CACHE& < -1 THEN _FREEIMAGE COMPOSITE_BELOW_CACHE&

    ' =====================================================================
    ' FREE TOOLBAR BUTTON IMAGES (0-20, all used slots)
    ' =====================================================================
    FOR i% = 0 TO 20
        IF GUI_TB(i%).iHnd& < -1 THEN _FREEIMAGE GUI_TB(i%).iHnd&
        IF GUI_TB(i%).iHndAlt& < -1 THEN _FREEIMAGE GUI_TB(i%).iHndAlt&
    NEXT i%

    ' =====================================================================
    ' FREE UNDO HISTORY IMAGES (pixel + workspace)
    ' =====================================================================
    UNDO_clear
    WORKSPACE_UNDO_clear

    ' =====================================================================
    ' FREE LAYER IMAGES (pixel data + opacity cache)
    ' =====================================================================
    DIM li AS INTEGER
    FOR li% = 1 TO 64
        IF LAYERS(li%).imgHandle& < -1 THEN _FREEIMAGE LAYERS(li%).imgHandle&
        IF LAYERS(li%).opacityCacheImg& < -1 THEN _FREEIMAGE LAYERS(li%).opacityCacheImg&
    NEXT li%

    ' =====================================================================
    ' FREE TOOL STATE IMAGES
    ' =====================================================================
    ' Move tool
    IF MOVE.SELECTION_IMAGE& < -1 THEN _FREEIMAGE MOVE.SELECTION_IMAGE&
    IF MOVE.PREVIEW_BUFFER& < -1 THEN _FREEIMAGE MOVE.PREVIEW_BUFFER&
    IF MOVE.ORIGINAL_IMAGE& < -1 THEN _FREEIMAGE MOVE.ORIGINAL_IMAGE&
    IF SCALE_ORIGINAL_IMAGE& < -1 THEN _FREEIMAGE SCALE_ORIGINAL_IMAGE&
    ' Selection / Clipboard
    IF CLIPBOARD.IMAGE& < -1 THEN _FREEIMAGE CLIPBOARD.IMAGE&
    IF MARQUEE.SELECTION_MASK& < -1 THEN _FREEIMAGE MARQUEE.SELECTION_MASK&
    ' Custom brush
    IF CUSTOM_BRUSH.IMAGE& < -1 THEN _FREEIMAGE CUSTOM_BRUSH.IMAGE&
    ' Image import
    IF IMG_IMPORT.IMAGE& < -1 THEN _FREEIMAGE IMG_IMPORT.IMAGE&
    IF IMG_IMPORT.PREVIEW_IMG& < -1 THEN _FREEIMAGE IMG_IMPORT.PREVIEW_IMG&
    ' Reference image
    IF REFIMG.IMAGE& < -1 THEN _FREEIMAGE REFIMG.IMAGE&
    ' Stroke opacity backup
    IF STROKE_BACKUP& < -1 THEN _FREEIMAGE STROKE_BACKUP&

    ' =====================================================================
    ' FREE GUI OVERLAY IMAGES
    ' =====================================================================
    ' Grid system
    IF GRID.imgHandle& < -1 THEN _FREEIMAGE GRID.imgHandle&
    IF PIXEL_GRID.imgHandle& < -1 THEN _FREEIMAGE PIXEL_GRID.imgHandle&
    ' Symmetry guides
    IF SYMMETRY.imgHandle& < -1 THEN _FREEIMAGE SYMMETRY.imgHandle&
    ' Transparency checkerboard
    IF TRANSPARENCY.imgHandle& < -1 THEN _FREEIMAGE TRANSPARENCY.imgHandle&

    ' =====================================================================
    ' FREE ORGANIZER WIDGET IMAGES
    ' =====================================================================
    DIM oi AS INTEGER
    FOR oi% = 0 TO 7
        IF ORG_WIDGETS(oi%).imgHandles& < -1 THEN _FREEIMAGE ORG_WIDGETS(oi%).imgHandles&
        IF ORG_WIDGETS(oi%).imgHandle2& < -1 THEN _FREEIMAGE ORG_WIDGETS(oi%).imgHandle2&
        IF ORG_WIDGETS(oi%).imgHandle3& < -1 THEN _FREEIMAGE ORG_WIDGETS(oi%).imgHandle3&
        IF ORG_WIDGETS(oi%).imgHandle4& < -1 THEN _FREEIMAGE ORG_WIDGETS(oi%).imgHandle4&
    NEXT oi%
    ' Grid mode/snap organizer icons
    DIM gi AS INTEGER
    FOR gi% = 0 TO 3
        IF GRID_MODE_IMG_OFF&(gi%) < -1 THEN _FREEIMAGE GRID_MODE_IMG_OFF&(gi%)
        IF GRID_MODE_IMG_ON&(gi%) < -1 THEN _FREEIMAGE GRID_MODE_IMG_ON&(gi%)
        IF GRID_SNAP_IMG&(gi%) < -1 THEN _FREEIMAGE GRID_SNAP_IMG&(gi%)
    NEXT gi%

    ' =====================================================================
    ' FREE BRUSH PRIMITIVE IMAGES
    ' =====================================================================
    DIM bi AS INTEGER
    FOR bi% = LBOUND(BRUSHES) TO UBOUND(BRUSHES)
        IF BRUSHES(bi%).BRUSH.IMG& < -1 THEN _FREEIMAGE BRUSHES(bi%).BRUSH.IMG&
    NEXT bi%

    ' =====================================================================
    ' FREE CURSOR IMAGES + LAYER PANEL ICONS
    ' =====================================================================
    _MOUSESHOW  ' Ensure using default system cursor before freeing cursors
    CURSOR_cleanup
    LAYER_PANEL_cleanup_icons

    ' =====================================================================
    ' FREE ALL FONT HANDLES
    ' =====================================================================
    IF TEXT.FONT_HANDLE& > 0 THEN _FREEFONT TEXT.FONT_HANDLE&
    IF TEXT.CUSTOM_FONT_HANDLE& > 0 THEN _FREEFONT TEXT.CUSTOM_FONT_HANDLE&
    IF CMD_FONT_HANDLE& > 0 THEN _FREEFONT CMD_FONT_HANDLE&
    IF STATUS_FONT& > 0 THEN _FREEFONT STATUS_FONT&
    IF PALETTE_STRIP_FONT& > 0 THEN _FREEFONT PALETTE_STRIP_FONT&
    IF MENU_BAR.fontHandle& > 0 THEN _FREEFONT MENU_BAR.fontHandle&
    IF LAYER_PANEL.fontHandle& > 0 THEN _FREEFONT LAYER_PANEL.fontHandle&

    SYSTEM
END SUB

'$INCLUDE:'./_ALL.BM'
