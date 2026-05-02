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
$RESIZE:ON

' THEME.BI (included above) runs at include-time and resets all THEME.* fields to
' compiled-in defaults, clobbering the values set by THEME_load inside SCREEN_init
' (which runs from SCREEN.BI, before THEME.BI is included in _ALL.BI).
' Re-apply runtime THEME.CFG overrides now that all BI includes are complete.
THEME_load
'$CONSOLE
$EXEICON:'./ASSETS/ICONS/icon.ico'

' === Splash screen — show ASAP with fade-in while rest of startup loads ===
DIM splashImg   AS LONG, splashStart AS DOUBLE
DIM splashDstW  AS LONG, splashDstH AS LONG
DIM splashX     AS LONG, splashY AS LONG
DIM splashAlpha AS INTEGER
DIM splashBg    AS _UNSIGNED LONG, splashBgR AS INTEGER, splashBgG AS INTEGER, splashBgB AS INTEGER
splashImg& = _LOADIMAGE("ASSETS/THEMES/" + _TRIM$(CFG.THEME$) + "/splash.png", 32)
IF splashImg& < -1 THEN
    splashBg~& = THEME.SPLASH_BG_COLOR~&
    splashBgR% = _RED32(splashBg~&): splashBgG% = _GREEN32(splashBg~&): splashBgB% = _BLUE32(splashBg~&)
    DIM splashScale   AS SINGLE
    splashScale! = _HEIGHT(0) / _HEIGHT(splashImg&)
    splashDstW&  = INT(_WIDTH(splashImg&) * splashScale!)
    splashDstH&  = _HEIGHT(0)
    splashX&     = (_WIDTH(0) - splashDstW&) \ 2
    splashY&     = 0
    DIM splashOldDest AS LONG: splashOldDest& = _DEST
    _DEST 0
    ' Fade in over ~0.4 seconds
    splashStart# = TIMER(.001)
    DO
        splashAlpha% = INT((TIMER(.001) - splashStart#) / 0.4 * 255)
        IF splashAlpha% > 255 THEN splashAlpha% = 255
        CLS , splashBg~&
        _PUTIMAGE (splashX&, splashY&)-(splashX& + splashDstW& - 1, splashY& + splashDstH& - 1), splashImg&, 0
        LINE (0, 0)-(_WIDTH(0) - 1, _HEIGHT(0) - 1), _RGBA32(splashBgR%, splashBgG%, splashBgB%, 255 - splashAlpha%), BF
        _DISPLAY
        _LIMIT 60
    LOOP UNTIL splashAlpha% >= 255
    ' Show fully opaque splash and record time for minimum-hold check
    CLS , splashBg~&
    _PUTIMAGE (splashX&, splashY&)-(splashX& + splashDstW& - 1, splashY& + splashDstH& - 1), splashImg&, 0
    _DISPLAY
    splashStart# = TIMER(.001) ' reset: hold starts after fade-in completes
    _DEST splashOldDest&
END IF

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
        ' Skip --config / -c and its value, and --config-upgrade when looking for file args
        DIM macArgIdx%
        macArgIdx% = 1
        DO WHILE macArgIdx% <= _COMMANDCOUNT
            DIM macArgVal$
            macArgVal$ = _TRIM$(COMMAND$(macArgIdx%))
            IF LCASE$(macArgVal$) = "--config" OR LCASE$(macArgVal$) = "-c" THEN
                macArgIdx% = macArgIdx% + 2 ' Skip flag + value
            ELSEIF LCASE$(macArgVal$) = "--config-upgrade" THEN
                macArgIdx% = macArgIdx% + 1 ' Skip flag only
            ELSEIF LCASE$(macArgVal$) = "--canvas-size" THEN
                macArgIdx% = macArgIdx% + 2 ' Skip flag + value
            ELSEIF LCASE$(macArgVal$) = "--portable" THEN
                macArgIdx% = macArgIdx% + 1 ' Skip flag only
            ELSEIF LCASE$(macArgVal$) = "--reset-defaults" THEN
                macArgIdx% = macArgIdx% + 1 ' Skip flag only
            ELSE
                cmdArg$ = macArgVal$
                EXIT DO
            END IF
        LOOP
    END IF
$ELSE
    ' Skip --config / -c and its value, and --config-upgrade when looking for file args
    DIM argIdx%
    argIdx% = 1
    DO WHILE argIdx% <= _COMMANDCOUNT
        DIM argVal$
        argVal$ = _TRIM$(COMMAND$(argIdx%))
        IF LCASE$(argVal$) = "--config" OR LCASE$(argVal$) = "-c" THEN
            argIdx% = argIdx% + 2 ' Skip flag + value
        ELSEIF LCASE$(argVal$) = "--config-upgrade" THEN
            argIdx% = argIdx% + 1 ' Skip flag only
        ELSEIF LCASE$(argVal$) = "--canvas-size" THEN
            argIdx% = argIdx% + 2 ' Skip flag + value
        ELSEIF LCASE$(argVal$) = "--portable" THEN
            argIdx% = argIdx% + 1 ' Skip flag only
        ELSEIF LCASE$(argVal$) = "--reset-defaults" THEN
            argIdx% = argIdx% + 1 ' Skip flag only
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

' Migrate old portable files to OS-native directories (shows dialog)
' Must be after SCREEN_init/THEME_load (needs GUI) but before CONFIG_apply
PATHS_migrate

' Apply config startup defaults (tool, brush size, directories)
' Must be called after all modules are initialized via includes
CONFIG_apply_startup_defaults
HISTORY_init
FILE_BAS_wip_reset

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

' Seed RNG once at startup so music shuffle and any other RND calls are truly random
RANDOMIZE TIMER

' Enable OS-exit trapping — prevents X button / CTRL+BREAK from bypassing cleanup.
' The first call to _EXIT starts monitoring; any non-zero return means an exit was requested.
DIM osExitTrap AS INTEGER
osExitTrap% = _EXIT     ' Discard initial value; monitoring now active

' Initialise sound system (loads handles, applies volume; respects CFG.SOUNDS_ENABLED)
SOUND_init
SOUND_play SND_NEW_FILE ' Startup chime (silent when sounds are disabled)
MUSIC_init              ' Initialise background music (plays if CFG.MUSIC_ENABLED)
IMAGE_ADJ_init          ' Initialise image adjustment library (IMGADJ)
COLORMIXER_init         ' Initialise non-modal color mixer panel
BROWSER_init            ' Initialise floating browser panel scaffold

' Main Loop
DIM k                       AS LONG
DIM exitConfirmed           AS INTEGER
DIM prevShiftHeld           AS INTEGER, prevCtrlHeld AS INTEGER, prevAltHeld AS INTEGER
DIM prevMouseOverCanvas     AS INTEGER
DIM ebPrevCanUndo           AS INTEGER, ebPrevCanRedo AS INTEGER
DIM ebPrevHasClip           AS INTEGER, ebPrevHasSel AS INTEGER
DIM resizeWatchLastW        AS LONG, resizeWatchLastH AS LONG
DIM resizeWatchSettleFrames AS INTEGER
exitConfirmed%           = FALSE
prevShiftHeld%           = MODIFIERS.shift%
prevCtrlHeld%            = MODIFIERS.ctrl%
prevAltHeld%             = MODIFIERS.alt%
prevMouseOverCanvas%     = FALSE
ebPrevCanUndo%           = FALSE
ebPrevCanRedo%           = FALSE
ebPrevHasClip%           = FALSE
ebPrevHasSel%            = FALSE
resizeWatchLastW&        = _WIDTH(0)
resizeWatchLastH&        = _HEIGHT(0)
resizeWatchSettleFrames% = 0

' === Dismiss splash screen with fade-out (after configurable hold) ===
IF splashImg& < -1 THEN
    DIM splashOldDest2 AS LONG: splashOldDest2& = _DEST
    DIM splashWinBg    AS _UNSIGNED LONG
    splashWinBg~& = THEME.WINDOW_BG_COLOR~&
    DIM splashWinR     AS INTEGER, splashWinG AS INTEGER, splashWinB AS INTEGER
    splashWinR% = _RED32(splashWinBg~&): splashWinG% = _GREEN32(splashWinBg~&): splashWinB% = _BLUE32(splashWinBg~&)
    _DEST 0
    ' Wait for configured hold time since fade-in completed
    DO WHILE TIMER(.001) - splashStart# < THEME.SPLASH_HOLD_TIME!
        _LIMIT 60
    LOOP
    ' Fade out over ~0.4 seconds toward WINDOW_BG_COLOR
    DIM splashFadeOut  AS DOUBLE
    splashFadeOut# = TIMER(.001)
    DO
        splashAlpha% = INT((TIMER(.001) - splashFadeOut#) / 0.4 * 255)
        IF splashAlpha% > 255 THEN splashAlpha% = 255
        CLS , splashBg~&
        _PUTIMAGE (splashX&, splashY&)-(splashX& + splashDstW& - 1, splashY& + splashDstH& - 1), splashImg&, 0
        LINE (0, 0)-(_WIDTH(0) - 1, _HEIGHT(0) - 1), _RGBA32(splashWinR%, splashWinG%, splashWinB%, splashAlpha%), BF
        _DISPLAY
        _LIMIT 60
    LOOP UNTIL splashAlpha% >= 255
    _DEST splashOldDest2&
    _FREEIMAGE splashImg&
END IF

DO
    ' Deferred command line file loading (after first frame when everything is initialized).
    ' Acts exactly like File -> Open: direct load, NO interactive placement.
    ' Interactive placement is reserved for File -> Import Image only.
    IF CMDLINE_FIRST_FRAME% AND CMDLINE_PENDING_FILE$ <> "" THEN
        CMDLINE_FIRST_FRAME% = FALSE
        IF FILE_ASE_is_aseprite_file%(CMDLINE_PENDING_FILE$) THEN
            FILE_ASE_load CMDLINE_PENDING_FILE$
            SOUND_play SND_NEW_FILE
            RECENT_add_file CMDLINE_PENDING_FILE$
        ELSEIF FILE_PSD_is_psd_file%(CMDLINE_PENDING_FILE$) THEN
            FILE_PSD_load CMDLINE_PENDING_FILE$
            SOUND_play SND_NEW_FILE
            RECENT_add_file CMDLINE_PENDING_FILE$
        ELSE
            ' .draw projects and raster images both go through DRW_load (direct load).
            DRW_load CMDLINE_PENDING_FILE$
            SOUND_play SND_NEW_FILE
            RECENT_add_file CMDLINE_PENDING_FILE$
            CURRENT_FILENAME$ = CMDLINE_PENDING_FILE$
            IF LCASE$(RIGHT$(CMDLINE_PENDING_FILE$, 5)) = ".draw" THEN
                CURRENT_DRW_FILENAME$ = CMDLINE_PENDING_FILE$
            END IF
        END IF
        CANVAS_DIRTY%         = FALSE
        CMDLINE_PENDING_FILE$ = "" ' Clear after loading
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
                    SOUND_play SND_NEW_FILE
                    CURRENT_DRW_FILENAME$ = dropFile$
                ELSE
                    DIM dropLoadResult%
                    dropLoadResult% = IMAGE_IMPORT_load_file%(dropFile$)
                END IF
            END IF
        END IF
    $END IF
    ' OS-initiated window resize (maximize, drag, etc.): snap back to nearest
    ' integer scale so $RESIZE:STRETCH always produces a pixel-perfect result.
    ' Also run a settle watcher because some WMs can miss/lag _RESIZE while
    ' maximizing or after native dialogs, which can leave black gaps.
    DIM resizeWinW      AS LONG, resizeWinH AS LONG
    DIM resizeExpectedW AS LONG, resizeExpectedH AS LONG
    resizeWinW&      = _WIDTH(0)
    resizeWinH&      = _HEIGHT(0)
    resizeExpectedW& = SCRN.w& * SCRN.displayScale%
    resizeExpectedH& = SCRN.h& * SCRN.displayScale%

    IF _RESIZE THEN
        IF SCREEN_DEFERRED_RESIZE% > 0 THEN
            SCREEN_DEFERRED_RESIZE% = SCREEN_DEFERRED_RESIZE% - 1
        ELSE
            SCREEN_snap_window_to_scale _ResizeWidth, _ResizeHeight
            INVALIDATE_scene
        END IF
        resizeWatchSettleFrames% = 6
        resizeWatchLastW&        = resizeWinW&
        resizeWatchLastH&        = resizeWinH&
    ELSE
        IF resizeWinW& <> resizeWatchLastW& OR resizeWinH& <> resizeWatchLastH& THEN
            resizeWatchSettleFrames% = 6
            resizeWatchLastW&        = resizeWinW&
            resizeWatchLastH&        = resizeWinH&
        ELSEIF resizeWatchSettleFrames% > 0 THEN
            resizeWatchSettleFrames% = resizeWatchSettleFrames% - 1
            IF resizeWatchSettleFrames% = 0 THEN
                IF SCREEN_DEFERRED_RESIZE% > 0 THEN
                    SCREEN_DEFERRED_RESIZE% = SCREEN_DEFERRED_RESIZE% - 1
                ELSEIF resizeWinW& <> resizeExpectedW& OR resizeWinH& <> resizeExpectedH& THEN
                    _LOGINFO "Resize watcher: corrective snap window " + _TRIM$(STR$(resizeWinW&)) + "x" + _TRIM$(STR$(resizeWinH&)) + " expected " + _TRIM$(STR$(resizeExpectedW&)) + "x" + _TRIM$(STR$(resizeExpectedH&)) + " scale " + _TRIM$(STR$(SCRN.displayScale%)) + "x"
                    SCREEN_snap_window_to_scale resizeWinW&, resizeWinH&
                    INVALIDATE_scene
                ELSE
                    ' Same size but force a repaint after settle to flush stale black regions.
                    INVALIDATE_scene
                END IF
            END IF
        END IF
    END IF

    ' Handle OS-initiated exit (window X button = bit 0, CTRL+BREAK = bit 1)
    ' Route through the standard exit action which handles unsaved-changes dialog + full cleanup.
    osExitTrap% = _EXIT
    IF osExitTrap% THEN CMD_execute_action 212

    k&               = _KEYHIT
    LAST_KEYHIT_RAW& = k&
    
    ' Build INKEY$-compatible fallback from _KEYHIT for handlers that need it
    IF k& >= 32 AND k& <= 126 THEN
        KEYHIT_CHAR$ = CHR$(k&)
    ELSEIF k& = 8 OR k& = 13 OR k& = 27 THEN
        KEYHIT_CHAR$ = CHR$(k&)
    ELSE
        KEYHIT_CHAR$ = ""
    END IF
    
    ' Track macOS ALT key via _KEYHIT (must be before MODIFIERS_update)
    MODIFIERS_track_alt_keyhit k&
    
    ' Update modifier key state (CTRL, SHIFT, ALT) once per frame
    MODIFIERS_update
    
    LOOP_start
    MUSIC_tick
    PERF_start PERF_MAIN_LOOP_TOTAL
    PERF_start PERF_MOUSE_INPUT
    MOUSE_input_handler
    PALETTE_OPS_tick
    PERF_stop PERF_MOUSE_INPUT
    PERF_start PERF_KEYBOARD_INPUT
    KEYBOARD_input_handler
    PERF_stop PERF_KEYBOARD_INPUT
    
    PERF_start PERF_STICK_INPUT
    STICK_input_handler
    PERF_stop PERF_STICK_INPUT
    
    ' Update tooltip state (must run before idle detection so hover keeps loop alive)
    TOOLTIP_update

    ' Idle detection: reduce FPS when nothing is happening to save CPU
    ' Check if anything needs updating this frame
    PERF_start PERF_IDLE_DETECT
    FRAME_IDLE% = TRUE
    DIM SCENE_CHANGED      AS INTEGER
    DIM modifiersChanged   AS INTEGER
    DIM mouseMoved         AS INTEGER
    DIM mouseOverCanvas    AS INTEGER
    DIM canvasCoordChanged AS INTEGER
    SCENE_CHANGED%      = FALSE
    modifiersChanged%   = (MODIFIERS.shift% <> prevShiftHeld% OR MODIFIERS.ctrl% <> prevCtrlHeld% OR MODIFIERS.alt% <> prevAltHeld%)
    mouseMoved%         = (MOUSE.RAW_X% <> IDLE_PREV_MOUSE_X% OR MOUSE.RAW_Y% <> IDLE_PREV_MOUSE_Y%)
    canvasCoordChanged% = (MOUSE.X% <> MOUSE.OLD_X% OR MOUSE.Y% <> MOUSE.OLD_Y%)
    mouseOverCanvas%    = FALSE

    DIM idleZW AS LONG, idleZH AS LONG, idleDX AS INTEGER, idleDY AS INTEGER
    IF SCRN.patternTileMode% THEN
        idleZW& = SCRN.canvasW& * 3 * SCRN.zoom!
        idleZH& = SCRN.canvasH& * 3 * SCRN.zoom!
    ELSE
        idleZW& = SCRN.canvasW& * SCRN.zoom!
        idleZH& = SCRN.canvasH& * SCRN.zoom!
    END IF
    idleDX% = (SCRN.w& - idleZW&) \ 2 + SCRN.offsetX% + SCRN.panelShiftX%
    idleDY% = (SCRN.h& - idleZH&) \ 2 + SCRN.offsetY%
    IF MOUSE.RAW_X% >= idleDX% AND MOUSE.RAW_X% < idleDX% + idleZW& AND MOUSE.RAW_Y% >= idleDY% AND MOUSE.RAW_Y% < idleDY% + idleZH& THEN
        mouseOverCanvas% = TRUE
    END IF

    IF k& <> 0 THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE   ' Key was pressed
    IF MOUSE.B1% OR MOUSE.B2% OR MOUSE.B3% THEN
        FRAME_IDLE% = FALSE        ' Mouse button held — keep render loop active
        IF NOT SCRN.panning% THEN
            SCENE_CHANGED%          = TRUE  ' Only rebuild scene for drawing, not panning (pan handles its own SCENE via mouseMoved)
            COMPOSITE_RESULT_VALID% = FALSE ' Drawing may have changed layer pixels — stale composite would skip them
        END IF
    END IF
    ' Button release transitions: tool release handlers commit final pixels to
    ' the layer (LINE, RECT, ELLIPSE, etc.). Must rebuild scene to show them
    ' instead of the stale rubber-band preview in the scene cache.
    IF (MOUSE.OLD_B1% AND NOT MOUSE.B1%) OR (MOUSE.OLD_B2% AND NOT MOUSE.B2%) THEN
        FRAME_IDLE%             = FALSE
        SCENE_CHANGED%          = TRUE
        COMPOSITE_RESULT_VALID% = FALSE ' Committed pixels invalidate cached composite
        IF CURRENT_LAYER% > 0 THEN LAYERS(CURRENT_LAYER%).contentDirty% = TRUE   ' Invalidate opacity cache for < 100% layers
        IF CURRENT_LAYER% > 0 THEN SYMBOL_mark_parent_dirty CURRENT_LAYER%
    END IF
    IF mouseMoved% THEN
        FRAME_IDLE% = FALSE             ' Mouse moved (cursor only)
        ' Only trigger status bar rebuild when canvas coords change (e.g. at zoom 2x
        ' two raw pixels map to the same canvas pixel — no coord display update needed).
        IF canvasCoordChanged% THEN
            STATUS_NEEDS_REDRAW% = TRUE ' Status bar coords need refresh
            GUI_NEEDS_REDRAW%    = TRUE ' Full render path needs GUI rebuild to update status text in SCRN.GUI&
        END IF
        ' Only trigger expensive full GUI rebuild on hover-zone change (not every canvas pixel).
        ' Canvas movement doesn't change toolbar/organizer visuals — status-only path handles it.
        IF NOT mouseOverCanvas% THEN
            GUI_NEEDS_REDRAW% = TRUE    ' Update hover highlights in toolbar/organizer/drawer/editbar/layerpanel
        END IF
        ' Force full render path on canvas hover — the dirty-rect/STATUS-ONLY fast
        ' paths cause visible cursor lag due to partial compositing overhead.
        ' The full path (CLS → GUI → composite → scene cache → present) is actually
        ' smoother because COMPOSITE_RESULT_VALID% caches the expensive layer merge
        ' and the single full-frame window blit has less driver overhead.
        IF mouseOverCanvas% THEN SCENE_CHANGED% = TRUE
    END IF
    IF GUI_NEEDS_REDRAW% THEN FRAME_IDLE% = FALSE   ' GUI-only updates should stay on the cached-scene path unless something else dirtied the scene
    IF STATUS_NEEDS_REDRAW% THEN FRAME_IDLE% = FALSE
    IF modifiersChanged% THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE   ' Modifier overlays affect cached scene and must repaint on press/release
    IF SCRN.panning% THEN FRAME_IDLE% = FALSE                             ' Panning active — only dirty scene when mouse moves
    IF SCRN.panning% AND mouseMoved% THEN SCENE_CHANGED% = TRUE
    IF MODIFIERS.shift% THEN
        FRAME_IDLE% = FALSE ' Keep render loop active for crosshair overlay
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Crosshair position changed — rebuild scene (crosshair is in scene cache)
        ' Transition frame (press/release) already handled by modifiersChanged above
    END IF
    IF MOUSE.SW% <> 0 THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE     ' Mouse wheel scrolled
    IF CURRENT_TOOL% = TOOL_MOVE AND MOVE.ACTIVE THEN
        FRAME_IDLE% = FALSE ' Keep render loop active
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Move overlay only changes on mouse movement
    END IF
    ' Rubber-band tools: keep scene dirty while vertices are placed (no button held)
    IF (CURRENT_TOOL% = TOOL_POLYGON OR CURRENT_TOOL% = TOOL_POLYGON_FILLED) AND POLY_LINE.HAS_LAST THEN
        FRAME_IDLE% = FALSE
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Rubber band preview only changes on mouse movement
    END IF
    IF CURRENT_TOOL% = TOOL_MARQUEE AND (MARQUEE.POLY_DRAWING OR MARQUEE.FREE_DRAWING OR MARQUEE.ELLIP_DRAGGING) THEN
        FRAME_IDLE% = FALSE
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Marquee preview only changes on mouse movement
    END IF
    IF CURRENT_TOOL% = TOOL_MARQUEE AND (MARQUEE.DRAGGING% OR MARQUEE.RESIZING% OR MARQUEE.MOVING%) THEN
        FRAME_IDLE%          = FALSE
        STATUS_NEEDS_REDRAW% = TRUE
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Keep marquee overlays and status dimensions live while editing
    END IF
    IF TRANSFORM.ACTIVE THEN
        FRAME_IDLE% = FALSE ' keep render loop active while overlay is live
        IF TRANSFORM.GRABBED >= 0 OR TRANSFORM_PREVIEW_DIRTY THEN SCENE_CHANGED% = TRUE
    END IF
    IF CURRENT_TOOL% = TOOL_TEXT AND TEXT.ACTIVE THEN
        ' Text editing must stay at full FPS so keyboard repeats are consumed
        ' promptly — dropping to 15 FPS idle makes typing feel sluggish.
        FRAME_IDLE% = FALSE
        ' Cursor blink: only dirty scene when cursor state actually toggles (every 0.5s)
        IF TIMER - TEXT.BLINK_TIMER > 0.5 THEN
            TEXT.CURSOR_BLINK = 1 - TEXT.CURSOR_BLINK
            TEXT.BLINK_TIMER  = TIMER
            SCENE_CHANGED%    = TRUE
        END IF
        ' Overflow flash animates every frame until countdown reaches 0
        IF TEXT.OVERFLOW_FLASH > 0 THEN SCENE_CHANGED% = TRUE
    END IF
    IF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN
        FRAME_IDLE% = FALSE
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Import overlay only changes on mouse movement
    END IF
    IF CROP.STATE = CROP_STATE_ACTIVE THEN
        FRAME_IDLE% = FALSE
        IF mouseMoved% THEN SCENE_CHANGED% = TRUE                 ' Crop overlay only changes on mouse movement
    END IF
    IF CMD_PALETTE.visible THEN FRAME_IDLE% = FALSE  ' Overlay only — scene cache + SkipToPointer handles rendering; no scene rebuild needed
    IF SELECTION_has_active% THEN FRAME_IDLE% = FALSE  ' Animation only (marching ants) — no scene change
    ' Tooltip hover: only keep frames active while delay is counting or tooltip
    ' needs one more frame to render. Once displayed and static, allow idle.
    IF TOOLTIP.HOVER_BTN_IDX% >= 0 AND (NOT TOOLTIP.ACTIVE% OR TOOLTIP.NEEDS_REDRAW%) THEN FRAME_IDLE% = FALSE
    ' Preview tooltip: keep render loop active while hover timer counts or tooltip is shown
    IF PREVIEW.visible% AND NOT PREVIEW.autoHidden% AND PREVIEW.mode% = PREVIEW_MODE_FLOAT THEN
        IF PREVIEW.floatTooltipHoverStart# > 0 AND NOT PREVIEW.floatTooltipActive% THEN FRAME_IDLE% = FALSE
        IF PREVIEW.floatTooltipActive% THEN FRAME_IDLE% = FALSE
    END IF
    IF SCENE_CHANGED% THEN SCENE_DIRTY% = TRUE

    ' Edit bar context-sensitive button states: force GUI redraw when any change
    IF SCRN.showEditBar% THEN
        DIM ebCanUndo AS INTEGER, ebCanRedo AS INTEGER
        DIM ebHasClip AS INTEGER, ebHasSel AS INTEGER
        ebCanUndo% = HISTORY_can_undo%
        ebCanRedo% = HISTORY_can_redo%
        ebHasClip% = CLIPBOARD.VALID
        ebHasSel%  = SELECTION_has_active%
        IF ebCanUndo% <> ebPrevCanUndo% OR ebCanRedo% <> ebPrevCanRedo% OR _
           ebHasClip% <> ebPrevHasClip% OR ebHasSel% <> ebPrevHasSel% THEN
            GUI_NEEDS_REDRAW% = TRUE
            FRAME_IDLE%       = FALSE
        END IF
        ebPrevCanUndo% = ebCanUndo%
        ebPrevCanRedo% = ebCanRedo%
        ebPrevHasClip% = ebHasClip%
        ebPrevHasSel%  = ebHasSel%
    END IF
    prevShiftHeld%       = MODIFIERS.shift%
    prevCtrlHeld%        = MODIFIERS.ctrl%
    prevAltHeld%         = MODIFIERS.alt%
    prevMouseOverCanvas% = mouseOverCanvas%
    ' Mark current layer content dirty when user is actively drawing
    IF (MOUSE.B1% OR MOUSE.B2%) AND CURRENT_LAYER% > 0 THEN
        LAYERS(CURRENT_LAYER%).contentDirty% = TRUE
        SYMBOL_mark_parent_dirty CURRENT_LAYER%
        ' Track dirty region for region-based blend compositing.
        ' Base padding = brush half-size. Spray tool has much larger radius.
        DIM compHalf  AS INTEGER
        IF CURRENT_TOOL% = TOOL_SPRAY THEN
            compHalf% = BRUSH_PIXEL_SIZES(BRUSH_SIZE.CURRENT) * 2 + 4
        ELSE
            compHalf% = BRUSH_SIZE_pixels% \ 2 + 2
        END IF
        COMP_mark_dirty MOUSE.X% - compHalf%, MOUSE.Y% - compHalf%, MOUSE.X% + compHalf%, MOUSE.Y% + compHalf%
        COMP_mark_dirty MOUSE.OLD_X% - compHalf%, MOUSE.OLD_Y% - compHalf%, MOUSE.OLD_X% + compHalf%, MOUSE.OLD_Y% + compHalf%
    END IF
    IDLE_PREV_MOUSE_X% = MOUSE.RAW_X%
    IDLE_PREV_MOUSE_Y% = MOUSE.RAW_Y%
    PERF_stop PERF_IDLE_DETECT
    
    ' Render FIRST, then limit — this minimizes latency between
    ' reading mouse input and displaying the result on screen.
    ' (_LIMIT before render would add a full frame delay to the pointer)
    
    ' Late mouse drain: re-read cursor position just before render to pick
    ' up any movement that arrived during keyboard/idle-detection processing.
    ' Only updates RAW_X/Y (screen coords for cursor drawing) — button/wheel
    ' state was already processed by MOUSE_input_handler above.
    IF NOT FRAME_IDLE% THEN
        DIM lateDrained AS INTEGER
        lateDrained% = FALSE
        DO WHILE _MOUSEINPUT
            lateDrained% = TRUE
        LOOP
        IF lateDrained% THEN
            MOUSE.RAW_X% = _MOUSEX \ SCRN.displayScale%
            MOUSE.RAW_Y% = _MOUSEY \ SCRN.displayScale%
        END IF
    END IF
    
    ' Skip full render when idle — previous frame remains on display
    IF NOT FRAME_IDLE% THEN
        SCREEN_render
    END IF
    
    ' (deferred glutReshapeWindow removed — SCREEN _NEWIMAGE in SCREEN_init
    '  sets the window to the correct size immediately; no retry needed.)
    
    ' Apply frame rate limit AFTER render+display (reduced when idle).
    ' Cursor-only movement uses CFG.FPS_CURSOR% (default 240) — the
    ' STATUS-ONLY and dirty-rect paths are ultra-lightweight partial
    ' blits, so high FPS is cheap and makes the cursor responsive.
    DIM cursorOnlyMove AS INTEGER
    cursorOnlyMove% = (mouseMoved% AND NOT SCENE_CHANGED% _
                       AND NOT MOUSE.B1% AND NOT MOUSE.B2% AND NOT MOUSE.B3%)
    PERF_start PERF_LIMIT_WAIT
    IF FRAME_IDLE% THEN
        _LIMIT CFG.FPS_IDLE%
    ELSEIF cursorOnlyMove% THEN
        _LIMIT CFG.FPS_CURSOR%
    ELSE
        _LIMIT CFG.FPS_LIMIT%
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

MAIN_shutdown


''
' Runs at the start of the loop before any other code
' 
SUB LOOP_start ()
    ' Reset undo save flag once per frame
    HISTORY_saved_this_frame% = FALSE
    ' Reset composite dirty rect for this frame
    COMP_DIRTY_VALID% = FALSE
    ' Clear smart guides each frame (re-populated during active move drag)
    IF SMART_GUIDES.hCount% > 0 OR SMART_GUIDES.vCount% > 0 THEN SMART_GUIDES_clear
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

    ' Always persist preview state on exit
    CFG.PREVIEW_X%       = PREVIEW.x%
    CFG.PREVIEW_Y%       = PREVIEW.y%
    CFG.PREVIEW_W%       = PREVIEW.w%
    CFG.PREVIEW_H%       = PREVIEW.h%
    CFG.PREVIEW_ZOOM!    = PREVIEW.zoom!
    CFG.PREVIEW_FOLLOW%  = PREVIEW.followPointer%
    CFG.PREVIEW_VISIBLE% = PREVIEW.visible%

    ' Persist color mixer state on exit
    CFG.COLOR_MIXER_VISIBLE% = COLORMIXER.visible%
    IF COLORMIXER.initialized% THEN
        CFG.COLOR_MIXER_X% = COLORMIXER.dispX%
        CFG.COLOR_MIXER_Y% = COLORMIXER.dispY%
    END IF

    ' Persist browser panel state on exit
    ' BROWSER.dispW/H are viewport pixels after BROWSER_compute_display_size;
    ' CFG.BROWSER_WIDTH/HEIGHT must store FD native pixels for BROWSER_init.
    ' Use FD_STATE.dialogW/H when initialized (authoritative native size).
    CFG.BROWSER_VISIBLE% = BROWSER.visible%
    CFG.BROWSER_POS_X%   = BROWSER.dispX%
    CFG.BROWSER_POS_Y%   = BROWSER.dispY%
    IF BROWSER.initialized% THEN
        CFG.BROWSER_WIDTH%  = FD_STATE.dialogW
        CFG.BROWSER_HEIGHT% = FD_STATE.dialogH
    ELSE
        ' Not initialized: dispW/H still hold native pixels from BROWSER_init
        CFG.BROWSER_WIDTH%  = BROWSER.dispW%
        CFG.BROWSER_HEIGHT% = BROWSER.dispH%
    END IF
    CFG.BROWSER_LAST_DIR$ = BROWSER.lastDir$
    CFG.BROWSER_DEFAULT_VIEW_MODE% = BROWSER.viewMode%
    CFG.BROWSER_DEFAULT_ZOOM_LEVEL% = BROWSER.zoomLevel%
    CFG.BROWSER_DEFAULT_SORT_TYPE% = BROWSER.sortType%
    CFG.BROWSER_DEFAULT_SORT_ORDER% = BROWSER.sortOrder%
    CFG.BROWSER_DEFAULT_PREVIEW_OPEN% = BROWSER.previewOpen%
    CONFIG_save

    BROWSER_cleanup

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
    ' FREE LAYER IMAGES (pixel data + opacity cache)
    ' =====================================================================
    DIM li AS INTEGER
    FOR li% = 1 TO MAX_LAYERS
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
    _MOUSESHOW ' Ensure using default system cursor before freeing cursors
    CURSOR_cleanup
    LAYER_PANEL_cleanup_icons

    ' =====================================================================
    ' FREE ALL FONT HANDLES
    ' =====================================================================
    ' _LOADFONT may return shared handle IDs for identical font requests.
    ' Free each loaded handle once to avoid double-free warnings on shutdown.
    DIM freedFontCount AS INTEGER
    DIM freedFontHandle(1 TO 32) AS LONG
    DIM fi             AS INTEGER
    DIM fontHandle     AS LONG
    DIM alreadyFreed   AS INTEGER

    freedFontCount% = 0

    fontHandle& = TEXT.FONT_HANDLE&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = TEXT.CUSTOM_FONT_HANDLE&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = CMD_FONT_HANDLE&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = STATUS_FONT&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = PALETTE_STRIP_FONT&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = MENU_BAR.fontHandle&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    fontHandle& = LAYER_PANEL.fontHandle&
    IF fontHandle& > 16 THEN
        alreadyFreed% = FALSE
        FOR fi% = 1 TO freedFontCount%
            IF freedFontHandle(fi%) = fontHandle& THEN alreadyFreed% = TRUE: EXIT FOR
        NEXT fi%
        IF NOT alreadyFreed% THEN
            _FREEFONT fontHandle&
            freedFontCount% = freedFontCount% + 1
            freedFontHandle(freedFontCount%) = fontHandle&
        END IF
    END IF

    ' =====================================================================
    ' FREE SOUND HANDLES
    ' =====================================================================
    SOUND_close_all

    SYSTEM
END SUB

'$INCLUDE:'./_ALL.BM'
