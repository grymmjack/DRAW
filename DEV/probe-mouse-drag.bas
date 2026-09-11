''
' DRAW - DEV/probe-mouse-drag.bas
' =============================================================================
' Standalone QB64-PE probe + measurement rig for the macOS "a drag reports no
' movement" bug. Depends on NOTHING from DRAW.
'
' The bug, as measured inside DRAW on macOS (2026-09-11): while a mouse button
' is held, _MOUSEINPUT returns ZERO events, so _MOUSEX/_MOUSEY stay pinned at
' the press point and every drag-driven tool collapses to a single pixel. Free
' (no-button) motion is delivered normally. Linux is unaffected.
'
' BUILD AND RUN
'
'   qb64pe -w -x -o probe-mouse-drag DEV/probe-mouse-drag.bas
'   ./probe-mouse-drag
'
' THE EXPERIMENT — do exactly this, it is the same gesture in every mode:
'
'   For each mode 1, 2, 3, 4 (number keys switch):
'     press the left button inside the window, drag a loop for ~2 seconds,
'     release. Repeat twice.
'
' On each release the probe scores that drag and adds a row to the on-screen
' table and to ./probe-mouse-drag.log. Nothing here depends on your judgement
' of what the trail looks like:
'
'   samples   frames the button was held
'   events    _MOUSEINPUT (or _DEVICEINPUT) events seen across those frames
'   distinct  how many times the reported position actually CHANGED
'   path      total reported travel, in pixels
'   spread    furthest reported distance from the press point
'   verdict   TRACKS / PARTIAL / FROZEN, from distinct + path
'
' A mode that reports the drag honestly scores distinct in the dozens and a
' path of hundreds of px. The bug scores distinct=0, path=0, spread=0 no
' matter how far the mouse physically travelled.
'
' THE MODES — each is a different input API for the same gesture:
'
'   1  _MOUSEINPUT drain, buttons read AFTER the loop     <- DRAW's Linux path
'   2  _MOUSEINPUT drain, buttons polled INSIDE the loop  <- DRAW's macOS path
'                                                            today; an SDL2-era
'                                                            workaround kept
'                                                            across the GLFW
'                                                            switch
'   3  _DEVICEINPUT + _AXIS device API                    <- alternative source
'   4  _MOUSEINPUT + _MOUSEMOVEMENTX/Y relative deltas    <- alternative source
'
' WHAT THE COMPARISON DECIDES
'
'   1 TRACKS, 2 FROZEN ....... DRAW's legacy macOS button-polling is the cause;
'                              delete it and dragging works.
'   1 and 2 both FROZEN ...... the gap is below DRAW, in QB64-PE's GLFW layer.
'                              Then 3 or 4 scoring TRACKS gives DRAW a usable
'                              cursor source on macOS; all four FROZEN means it
'                              has to be fixed upstream.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$CONSOLE

CONST SCRW = 900
CONST SCRH = 660
CONST LOGPATH = "probe-mouse-drag.log"

' --- Verdict thresholds -------------------------------------------------------
' A drag of ~2s at 60fps that is genuinely tracked reports well over 100 changed
' positions. These are deliberately generous so a slow or short drag still reads
' as TRACKS, and only a truly pinned position reads as FROZEN.
CONST TRACK_MIN_DISTINCT = 5
CONST TRACK_MIN_PATH = 20

DIM SHARED probeMode AS INTEGER
DIM SHARED trailImg AS LONG
DIM SHARED mouseDev AS INTEGER
DIM SHARED frameNum AS LONG

' Per-frame results, filled in by whichever mode ran
DIM SHARED evtCount AS INTEGER
DIM SHARED posX AS SINGLE, posY AS SINGLE
DIM SHARED btn1 AS INTEGER, btn2 AS INTEGER, btn3 AS INTEGER
DIM SHARED modeNote AS STRING

' In-flight drag measurement
DIM SHARED dragActive AS INTEGER
DIM SHARED dragSamples AS LONG, dragEvents AS LONG, dragDistinct AS LONG
DIM SHARED dragPath AS SINGLE, dragSpread AS SINGLE
DIM SHARED dragStartX AS SINGLE, dragStartY AS SINGLE
DIM SHARED dragLastX AS SINGLE, dragLastY AS SINGLE
DIM SHARED dragT0 AS DOUBLE

' Last completed drag per mode, for the comparison table
DIM SHARED resSamples(1 TO 4) AS LONG
DIM SHARED resEvents(1 TO 4) AS LONG
DIM SHARED resDistinct(1 TO 4) AS LONG
DIM SHARED resPath(1 TO 4) AS SINGLE
DIM SHARED resSpread(1 TO 4) AS SINGLE
DIM SHARED resSecs(1 TO 4) AS SINGLE
DIM SHARED resVerdict(1 TO 4) AS STRING
DIM SHARED resRuns(1 TO 4) AS INTEGER

' Free-motion (no button) baseline, to prove events flow when NOT dragging
DIM SHARED freeEvents AS LONG, freeDistinct AS LONG
DIM SHARED freeLastX AS SINGLE, freeLastY AS SINGLE

SCREEN _NEWIMAGE(SCRW, SCRH, 32)
_TITLE "DRAW mouse-drag probe - 1/2/3/4 = mode, C = clear, R = reset results, ESC = quit"

trailImg& = _NEWIMAGE(SCRW, SCRH, 32)
probeMode% = 1
frameNum& = 0
mouseDev% = FindMouseDevice%

StartLog

DIM keyIn AS STRING

DO
    keyIn$ = INKEY$
    IF keyIn$ = CHR$(27) THEN EXIT DO
    IF keyIn$ = "1" THEN SwitchMode 1
    IF keyIn$ = "2" THEN SwitchMode 2
    IF keyIn$ = "3" THEN SwitchMode 3
    IF keyIn$ = "4" THEN SwitchMode 4
    IF keyIn$ = "c" OR keyIn$ = "C" THEN ClearTrail
    IF keyIn$ = "r" OR keyIn$ = "R" THEN ResetResults

    frameNum& = frameNum& + 1
    evtCount% = 0
    btn1% = 0: btn2% = 0: btn3% = 0
    modeNote$ = ""

    SELECT CASE probeMode%
        CASE 1
            ProbeClassic 0
        CASE 2
            ProbeClassic 1
        CASE 3
            ProbeDevice
        CASE 4
            ProbeRelative
    END SELECT

    MeasureFrame
    RenderHud
    _DISPLAY
    _LIMIT 60
LOOP

SYSTEM


''
' Fold this frame into the drag measurement, and open/close a drag on the
' button edges.
'
SUB MeasureFrame ()
    DIM anyBtn AS INTEGER
    DIM stepDist AS SINGLE, devDist AS SINGLE

    anyBtn% = (btn1% OR btn2% OR btn3%)

    IF anyBtn% AND NOT dragActive% THEN
        ' --- press: open a new measurement ---
        dragActive% = -1
        dragSamples& = 0: dragEvents& = 0: dragDistinct& = 0
        dragPath! = 0: dragSpread! = 0
        dragStartX! = posX!: dragStartY! = posY!
        dragLastX! = posX!: dragLastY! = posY!
        dragT0# = TIMER
        ClearTrail
        LogLine "[m" + _TRIM$(STR$(probeMode%)) + "] DRAG-START at " + PosText$
    END IF

    IF anyBtn% THEN
        dragSamples& = dragSamples& + 1
        dragEvents& = dragEvents& + evtCount%

        IF posX! <> dragLastX! OR posY! <> dragLastY! THEN
            dragDistinct& = dragDistinct& + 1
            stepDist! = SQR((posX! - dragLastX!) * (posX! - dragLastX!) + (posY! - dragLastY!) * (posY! - dragLastY!))
            dragPath! = dragPath! + stepDist!
            dragLastX! = posX!: dragLastY! = posY!
        END IF

        devDist! = SQR((posX! - dragStartX!) * (posX! - dragStartX!) + (posY! - dragStartY!) * (posY! - dragStartY!))
        IF devDist! > dragSpread! THEN dragSpread! = devDist!

        PlotTrail
        LogLine "[m" + _TRIM$(STR$(probeMode%)) + "] HELD evts=" + _TRIM$(STR$(evtCount%)) + " " + PosText$

    ELSEIF dragActive% THEN
        ' --- release: score it ---
        dragActive% = 0
        ScoreDrag

    ELSE
        ' --- no button: baseline that events DO flow when not dragging ---
        freeEvents& = freeEvents& + evtCount%
        IF posX! <> freeLastX! OR posY! <> freeLastY! THEN
            freeDistinct& = freeDistinct& + 1
            freeLastX! = posX!: freeLastY! = posY!
        END IF
    END IF
END SUB


''
' Turn the finished drag into a verdict, store it for the table, log it.
'
SUB ScoreDrag ()
    DIM verdict AS STRING
    DIM secs AS SINGLE

    secs! = TIMER - dragT0#
    IF secs! < 0 THEN secs! = 0 ' midnight rollover

    IF dragDistinct& >= TRACK_MIN_DISTINCT AND dragPath! >= TRACK_MIN_PATH THEN
        verdict$ = "TRACKS"
    ELSEIF dragDistinct& > 0 THEN
        verdict$ = "PARTIAL"
    ELSE
        verdict$ = "FROZEN"
    END IF

    resSamples(probeMode%) = dragSamples&
    resEvents(probeMode%) = dragEvents&
    resDistinct(probeMode%) = dragDistinct&
    resPath(probeMode%) = dragPath!
    resSpread(probeMode%) = dragSpread!
    resSecs(probeMode%) = secs!
    resVerdict(probeMode%) = verdict$
    resRuns(probeMode%) = resRuns(probeMode%) + 1

    LogLine "[m" + _TRIM$(STR$(probeMode%)) + "] DRAG-END " + verdict$ + _
            " samples=" + _TRIM$(STR$(dragSamples&)) + _
            " events=" + _TRIM$(STR$(dragEvents&)) + _
            " distinct=" + _TRIM$(STR$(dragDistinct&)) + _
            " path=" + _TRIM$(STR$(INT(dragPath!))) + _
            " spread=" + _TRIM$(STR$(INT(dragSpread!))) + _
            " secs=" + _TRIM$(STR$(INT(secs! * 100) / 100))
END SUB


''
' Mode 1 / 2: the classic _MOUSEINPUT drain.
'
' @param pollInside INTEGER - 1 to read _MOUSEBUTTON INSIDE the drain loop
'        (DRAW's macOS path today), 0 to read it only after (every other OS)
'
SUB ProbeClassic (pollInside AS INTEGER)
    DIM capB1 AS INTEGER, capB2 AS INTEGER, capB3 AS INTEGER
    capB1% = 0: capB2% = 0: capB3% = 0

    DO WHILE _MOUSEINPUT
        evtCount% = evtCount% + 1
        IF pollInside% THEN
            IF _MOUSEBUTTON(1) THEN capB1% = -1
            IF _MOUSEBUTTON(2) THEN capB2% = -1
            IF _MOUSEBUTTON(3) THEN capB3% = -1
        END IF
        IF evtCount% > 2000 THEN EXIT DO ' never spin forever
    LOOP

    posX! = _MOUSEX
    posY! = _MOUSEY

    IF pollInside% THEN
        btn1% = capB1% OR _MOUSEBUTTON(1)
        btn2% = capB2% OR _MOUSEBUTTON(2)
        btn3% = capB3% OR _MOUSEBUTTON(3)
        modeNote$ = "buttons polled INSIDE drain (DRAW's macOS path)"
    ELSE
        btn1% = _MOUSEBUTTON(1)
        btn2% = _MOUSEBUTTON(2)
        btn3% = _MOUSEBUTTON(3)
        modeNote$ = "buttons read AFTER drain (DRAW's Linux path)"
    END IF
END SUB


''
' Mode 3: the _DEVICEINPUT / _AXIS device API, potentially a different code
' path from _MOUSEINPUT. _AXIS is normalised -1..1 across the window.
'
SUB ProbeDevice ()
    IF mouseDev% = 0 THEN mouseDev% = FindMouseDevice%
    IF mouseDev% = 0 THEN
        modeNote$ = "no [MOUSE] device in the _DEVICES table"
        posX! = -1: posY! = -1
        EXIT SUB
    END IF

    DO WHILE _DEVICEINPUT(mouseDev%)
        evtCount% = evtCount% + 1
        IF evtCount% > 2000 THEN EXIT DO
    LOOP

    posX! = (_AXIS(1) + 1) / 2 * SCRW
    posY! = (_AXIS(2) + 1) / 2 * SCRH
    btn1% = _BUTTON(1)
    btn2% = _BUTTON(2)
    btn3% = _BUTTON(3)
    modeNote$ = "device " + _TRIM$(STR$(mouseDev%)) + "  axis=" + _TRIM$(STR$(_AXIS(1))) + "," + _TRIM$(STR$(_AXIS(2)))
END SUB


''
' Mode 4: relative deltas, integrated from the window centre. NOTE: this can
' put the mouse into a relative mode where the OS cursor behaves oddly — switch
' back to mode 1 when done.
'
SUB ProbeRelative ()
    STATIC accX AS SINGLE, accY AS SINGLE
    STATIC started AS INTEGER
    DIM dxSum AS SINGLE, dySum AS SINGLE

    IF NOT started% THEN
        accX! = SCRW / 2: accY! = SCRH / 2
        started% = -1
    END IF

    dxSum! = 0: dySum! = 0
    DO WHILE _MOUSEINPUT
        evtCount% = evtCount% + 1
        dxSum! = dxSum! + _MOUSEMOVEMENTX
        dySum! = dySum! + _MOUSEMOVEMENTY
        IF evtCount% > 2000 THEN EXIT DO
    LOOP

    accX! = accX! + dxSum!
    accY! = accY! + dySum!
    IF accX! < 0 THEN accX! = 0
    IF accY! < 0 THEN accY! = 0
    IF accX! > SCRW THEN accX! = SCRW
    IF accY! > SCRH THEN accY! = SCRH

    posX! = accX!
    posY! = accY!
    btn1% = _MOUSEBUTTON(1)
    btn2% = _MOUSEBUTTON(2)
    btn3% = _MOUSEBUTTON(3)
    modeNote$ = "relative delta this frame=" + _TRIM$(STR$(dxSum!)) + "," + _TRIM$(STR$(dySum!))
END SUB


''
' Locate the mouse in the _DEVICES table. 0 when it is not there (yet).
'
FUNCTION FindMouseDevice% ()
    DIM i AS INTEGER
    FindMouseDevice% = 0
    FOR i% = 1 TO _DEVICES
        IF INSTR(_DEVICE$(i%), "[MOUSE]") > 0 THEN
            FindMouseDevice% = i%
            EXIT FUNCTION
        END IF
    NEXT i%
END FUNCTION


''
' Switch mode and drop any drag in flight (so a half-measured drag from the
' previous API never lands in the table).
'
' @param newMode INTEGER - 1..4
'
SUB SwitchMode (newMode AS INTEGER)
    probeMode% = newMode%
    dragActive% = 0
    ClearTrail
    LogLine "--- switched to mode " + _TRIM$(STR$(newMode%)) + " ---"
END SUB


''
' Plot the reported position, so the trail corroborates the numbers.
'
SUB PlotTrail ()
    DIM oldDest AS LONG
    oldDest& = _DEST
    _DEST trailImg&
    CIRCLE (posX!, posY!), 2, _RGB32(255, 80, 80)
    _DEST oldDest&
END SUB


''
' Wipe the trail.
'
SUB ClearTrail ()
    DIM oldDest AS LONG
    oldDest& = _DEST
    _DEST trailImg&
    CLS , _RGB32(0, 0, 0)
    _DEST oldDest&
END SUB


''
' Clear the per-mode results table.
'
SUB ResetResults ()
    DIM i AS INTEGER
    FOR i% = 1 TO 4
        resSamples(i%) = 0: resEvents(i%) = 0: resDistinct(i%) = 0
        resPath(i%) = 0: resSpread(i%) = 0: resSecs(i%) = 0
        resVerdict(i%) = "": resRuns(i%) = 0
    NEXT i%
    freeEvents& = 0: freeDistinct& = 0
    LogLine "--- results reset ---"
END SUB


''
' "pos=X,Y raw=_MOUSEX,_MOUSEY" for the log.
'
FUNCTION PosText$ ()
    PosText$ = "pos=" + _TRIM$(STR$(INT(posX!))) + "," + _TRIM$(STR$(INT(posY!))) + _
               " raw=" + _TRIM$(STR$(_MOUSEX)) + "," + _TRIM$(STR$(_MOUSEY))
END FUNCTION


''
' Truncate the log and write its header.
'
SUB StartLog ()
    DIM fh AS INTEGER
    fh% = FREEFILE
    OPEN LOGPATH FOR OUTPUT AS #fh%
    PRINT #fh%, "# DRAW mouse-drag probe"
    PRINT #fh%, "# mode 1 = _MOUSEINPUT drain, buttons AFTER  (DRAW's Linux path)"
    PRINT #fh%, "# mode 2 = _MOUSEINPUT drain, buttons INSIDE (DRAW's macOS path)"
    PRINT #fh%, "# mode 3 = _DEVICEINPUT + _AXIS"
    PRINT #fh%, "# mode 4 = _MOUSEINPUT + _MOUSEMOVEMENTX/Y"
    PRINT #fh%, "# DRAG-END lines carry the score for one drag"
    CLOSE #fh%
END SUB


''
' Append one line to the log.
'
' @param msg STRING
'
SUB LogLine (msg AS STRING)
    DIM fh AS INTEGER
    fh% = FREEFILE
    OPEN LOGPATH FOR APPEND AS #fh%
    PRINT #fh%, msg
    CLOSE #fh%
END SUB


''
' Trail + live readout + the per-mode results table.
'
SUB RenderHud ()
    DIM i AS INTEGER
    DIM rowY AS INTEGER
    DIM rowText AS STRING

    CLS , _RGB32(16, 16, 24)
    _PUTIMAGE (0, 0), trailImg&

    COLOR _RGB32(255, 255, 255), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 10), "MODE " + _TRIM$(STR$(probeMode%)) + "  -  1/2/3/4 switch, C clear, R reset, ESC quit"
    _PRINTSTRING (10, 26), ModeName$(probeMode%)
    _PRINTSTRING (10, 42), modeNote$

    COLOR _RGB32(160, 220, 255), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 66), "events this frame : " + _TRIM$(STR$(evtCount%))
    _PRINTSTRING (10, 82), "reported position : " + _TRIM$(STR$(INT(posX!))) + ", " + _TRIM$(STR$(INT(posY!)))
    _PRINTSTRING (10, 98), "_MOUSEX / _MOUSEY : " + _TRIM$(STR$(_MOUSEX)) + ", " + _TRIM$(STR$(_MOUSEY))
    _PRINTSTRING (10, 114), "buttons           : " + _TRIM$(STR$(btn1%)) + " " + _TRIM$(STR$(btn2%)) + " " + _TRIM$(STR$(btn3%))

    IF dragActive% THEN
        COLOR _RGB32(255, 120, 120), _RGB32(16, 16, 24)
        _PRINTSTRING (10, 138), "DRAGGING  samples=" + _TRIM$(STR$(dragSamples&)) + _
                                 "  events=" + _TRIM$(STR$(dragEvents&)) + _
                                 "  distinct=" + _TRIM$(STR$(dragDistinct&)) + _
                                 "  path=" + _TRIM$(STR$(INT(dragPath!))) + _
                                 "  spread=" + _TRIM$(STR$(INT(dragSpread!)))
    ELSE
        COLOR _RGB32(255, 230, 140), _RGB32(16, 16, 24)
        _PRINTSTRING (10, 138), "PRESS AND DRAG a loop for ~2s, then release. Repeat in each mode."
    END IF

    COLOR _RGB32(200, 200, 210), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 162), "no-button baseline: events=" + _TRIM$(STR$(freeEvents&)) + _
                             "  position changes=" + _TRIM$(STR$(freeDistinct&)) + _
                             "   (proves events flow when NOT dragging)"

    ' --- results table ---
    COLOR _RGB32(255, 255, 255), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 196), "LAST DRAG PER MODE"
    _PRINTSTRING (10, 214), "mode  runs  samples  events  distinct   path  spread  secs  verdict"
    FOR i% = 1 TO 4
        rowY% = 232 + (i% - 1) * 16
        IF resRuns(i%) = 0 THEN
            COLOR _RGB32(120, 120, 130), _RGB32(16, 16, 24)
            rowText$ = Pad$(_TRIM$(STR$(i%)), 6) + "   -- not measured yet --"
        ELSE
            SELECT CASE resVerdict(i%)
                CASE "TRACKS"
                    COLOR _RGB32(120, 255, 140), _RGB32(16, 16, 24)
                CASE "PARTIAL"
                    COLOR _RGB32(255, 220, 120), _RGB32(16, 16, 24)
                CASE ELSE
                    COLOR _RGB32(255, 110, 110), _RGB32(16, 16, 24)
            END SELECT
            rowText$ = Pad$(_TRIM$(STR$(i%)), 6) + _
                       Pad$(_TRIM$(STR$(resRuns(i%))), 6) + _
                       Pad$(_TRIM$(STR$(resSamples(i%))), 9) + _
                       Pad$(_TRIM$(STR$(resEvents(i%))), 8) + _
                       Pad$(_TRIM$(STR$(resDistinct(i%))), 10) + _
                       Pad$(_TRIM$(STR$(INT(resPath(i%)))), 7) + _
                       Pad$(_TRIM$(STR$(INT(resSpread(i%)))), 8) + _
                       Pad$(_TRIM$(STR$(INT(resSecs(i%) * 10) / 10)), 6) + _
                       resVerdict(i%)
        END IF
        _PRINTSTRING (10, rowY%), rowText$
    NEXT i%

    COLOR _RGB32(200, 200, 210), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 308), "TRACKS = the API reported the drag. FROZEN = position pinned at the press point."
    _PRINTSTRING (10, 324), "Scores are also appended to " + LOGPATH

    COLOR _RGB32(255, 255, 255), _RGB32(16, 16, 24)
END SUB


''
' Left-justify text into a fixed-width column.
'
' @param src STRING - the text
' @param wide INTEGER - column width
' @return STRING
'
FUNCTION Pad$ (src AS STRING, wide AS INTEGER)
    IF LEN(src$) >= wide% THEN
        Pad$ = src$ + " "
    ELSE
        Pad$ = src$ + SPACE$(wide% - LEN(src$))
    END IF
END FUNCTION


''
' Human-readable name for a mode.
'
' @param whichMode INTEGER - 1..4
' @return STRING
'
FUNCTION ModeName$ (whichMode AS INTEGER)
    SELECT CASE whichMode%
        CASE 1
            ModeName$ = "_MOUSEINPUT drain, buttons read AFTER the loop"
        CASE 2
            ModeName$ = "_MOUSEINPUT drain, buttons polled INSIDE the loop (DRAW's macOS path)"
        CASE 3
            ModeName$ = "_DEVICEINPUT + _AXIS device API"
        CASE 4
            ModeName$ = "_MOUSEINPUT + _MOUSEMOVEMENTX/Y relative deltas"
        CASE ELSE
            ModeName$ = "?"
    END SELECT
END FUNCTION
