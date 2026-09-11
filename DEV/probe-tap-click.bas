''
' DRAW - DEV/probe-tap-click.bas
' =============================================================================
' Does DRAW still need its macOS tap-to-click workaround under GLFW?
'
' THE WORKAROUND UNDER TEST (INPUT/MOUSE.BM:67 and :496, both $IF MAC):
'
'   DO WHILE _MOUSEINPUT
'       IF _MOUSEBUTTON(1) THEN mac_b1% = TRUE   ' <- capture INSIDE the drain
'   LOOP
'   MOUSE.B1% = mac_b1% OR _MOUSEBUTTON(1)       ' <- OR it with the read AFTER
'
' It dates from the SDL2 era: a trackpad tap-to-click is a press AND release
' that can land inside a single drain, and SDL2 on macOS did not preserve the
' button state to the post-loop _MOUSEBUTTON read — so the click vanished.
' DRAW now builds against GLFW, where that may no longer be true. Nobody has
' checked, so the two blocks sit there unexplained.
'
' HOW THIS MEASURES IT — no tap-counting discipline required
'
' One run does BOTH policies at once over the same physical clicks, and counts
' the only thing that matters: how often the capture rescued a press the
' post-loop read alone would have MISSED.
'
'   rescued   frames where the in-drain capture saw the button down but the
'             read after the loop did not. Every one of these is a click the
'             workaround saved. This is the whole question.
'   with      presses detected by (captured OR post-read)  <- current behavior
'   without   presses detected by the post-read alone      <- workaround removed
'
' If "with" and "without" stay equal and "rescued" stays 0 across a few dozen
' taps, the workaround is dead code on this backend and the two $IF MAC blocks
' can go. A single rescue means keep it.
'
' BUILD AND RUN (no DRAW sources involved)
'
'   qb64pe -w -x -o probe-tap-click DEV/probe-tap-click.bas
'   ./probe-tap-click
'
' WHAT TO DO, on the Mac that matters:
'
'   1. TRACKPAD TAP-TO-CLICK, ~20 times, at a normal pace. This is the case the
'      workaround exists for — tap, do not press the trackpad down.
'   2. ~10 FAST taps / double-taps. Short press-release pairs are the ones most
'      likely to land inside one drain.
'   3. ~10 clicks with a real mouse button, if one is attached.
'   4. A few slow press-hold-release, as a sanity check that normal clicks count.
'
' Read the verdict on screen. Scores also append to ./probe-tap-click.log.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$CONSOLE

CONST SCRW = 900
CONST SCRH = 560
CONST LOGPATH = "probe-tap-click.log"

DIM SHARED frameNum AS LONG
DIM SHARED evtCount AS LONG

' Counters for the two policies over the same physical clicks
DIM SHARED pressesWith AS LONG      ' captured OR post-read  (workaround in place)
DIM SHARED pressesWithout AS LONG   ' post-read only         (workaround removed)
DIM SHARED rescued AS LONG          ' captured but NOT post-read -> a saved click
DIM SHARED capturedFrames AS LONG   ' frames the in-drain capture fired at all
DIM SHARED postFrames AS LONG       ' frames the post-loop read saw a button

DIM SHARED prevWith AS INTEGER, prevWithout AS INTEGER
DIM SHARED lastEvent AS STRING

SCREEN _NEWIMAGE(SCRW, SCRH, 32)
_TITLE "DRAW tap-to-click probe - R resets, ESC quits"

StartLog
lastEvent$ = "(none yet)"

DIM keyIn AS STRING
DIM capB AS INTEGER, postB AS INTEGER
DIM withCapture AS INTEGER, withoutCapture AS INTEGER

DO
    keyIn$ = INKEY$
    IF keyIn$ = CHR$(27) THEN EXIT DO
    IF keyIn$ = "r" OR keyIn$ = "R" THEN ResetCounters

    frameNum& = frameNum& + 1
    evtCount& = 0
    capB% = 0

    ' --- exactly DRAW's macOS drain: capture button state INSIDE the loop ---
    DO WHILE _MOUSEINPUT
        evtCount& = evtCount& + 1
        IF _MOUSEBUTTON(1) THEN capB% = -1
        IF evtCount& > 2000 THEN EXIT DO
    LOOP

    ' --- and the plain read AFTER the loop, which is what every other OS uses ---
    postB% = _MOUSEBUTTON(1)

    withCapture%    = (capB% OR postB%)   ' current macOS behavior
    withoutCapture% = postB%              ' behavior if the workaround is deleted

    IF capB% THEN capturedFrames& = capturedFrames& + 1
    IF postB% THEN postFrames& = postFrames& + 1

    ' Press edges under each policy
    IF withCapture% AND NOT prevWith% THEN
        pressesWith& = pressesWith& + 1
        lastEvent$ = "press #" + _TRIM$(STR$(pressesWith&)) + " at frame " + _TRIM$(STR$(frameNum&))
    END IF
    IF withoutCapture% AND NOT prevWithout% THEN pressesWithout& = pressesWithout& + 1

    ' THE measurement: the capture saw a button the post-loop read did not.
    ' Without the workaround this frame's press would have been dropped.
    IF capB% AND NOT postB% THEN
        rescued& = rescued& + 1
        lastEvent$ = "RESCUED a click the post-read missed (frame " + _TRIM$(STR$(frameNum&)) + ")"
        LogLine "[RESCUE] f=" + _TRIM$(STR$(frameNum&)) + _
                " evts=" + _TRIM$(STR$(evtCount&)) + _
                " captured=1 postRead=0  <- workaround saved this click"
    END IF

    IF withCapture% <> prevWith% OR withoutCapture% <> prevWithout% THEN
        LogLine "[EDGE] f=" + _TRIM$(STR$(frameNum&)) + _
                " evts=" + _TRIM$(STR$(evtCount&)) + _
                " captured=" + _TRIM$(STR$(capB%)) + " postRead=" + _TRIM$(STR$(postB%)) + _
                " with=" + _TRIM$(STR$(pressesWith&)) + " without=" + _TRIM$(STR$(pressesWithout&))
    END IF

    prevWith%    = withCapture%
    prevWithout% = withoutCapture%

    RenderHud
    _DISPLAY
    _LIMIT 60
LOOP

WriteSummary
SYSTEM


''
' Zero the counters.
'
SUB ResetCounters ()
    pressesWith& = 0: pressesWithout& = 0: rescued& = 0
    capturedFrames& = 0: postFrames& = 0
    lastEvent$ = "(reset)"
    LogLine "--- counters reset ---"
END SUB


''
' The verdict, from the counters alone.
'
FUNCTION Verdict$ ()
    IF pressesWith& = 0 THEN
        Verdict$ = "no clicks recorded yet"
    ELSEIF rescued& = 0 AND pressesWith& = pressesWithout& THEN
        Verdict$ = "WORKAROUND UNNECESSARY so far - both policies agree"
    ELSE
        Verdict$ = "WORKAROUND STILL NEEDED - it saved " + _TRIM$(STR$(rescued&)) + " click(s)"
    END IF
END FUNCTION


''
' Live readout.
'
SUB RenderHud ()
    CLS , _RGB32(16, 16, 24)

    COLOR _RGB32(255, 255, 255), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 10), "DRAW tap-to-click probe   (R resets, ESC quits)"
    _PRINTSTRING (10, 26), "Is the macOS in-drain button capture still doing anything under GLFW?"

    COLOR _RGB32(255, 230, 140), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 56), "1. TRACKPAD TAP-TO-CLICK about 20 times (tap, do not press down)"
    _PRINTSTRING (10, 72), "2. About 10 FAST taps / double-taps"
    _PRINTSTRING (10, 88), "3. About 10 clicks with a real mouse button, if you have one"
    _PRINTSTRING (10, 104), "4. A few slow press-hold-release as a sanity check"

    COLOR _RGB32(160, 220, 255), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 140), "presses WITH capture (today)    : " + _TRIM$(STR$(pressesWith&))
    _PRINTSTRING (10, 156), "presses WITHOUT it (if removed) : " + _TRIM$(STR$(pressesWithout&))

    IF rescued& > 0 THEN
        COLOR _RGB32(255, 110, 110), _RGB32(16, 16, 24)
    ELSE
        COLOR _RGB32(120, 255, 140), _RGB32(16, 16, 24)
    END IF
    _PRINTSTRING (10, 180), "clicks RESCUED by the capture   : " + _TRIM$(STR$(rescued&)) + _
                            "   <- the whole question"

    COLOR _RGB32(200, 200, 210), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 208), "frames capture fired : " + _TRIM$(STR$(capturedFrames&)) + _
                            "    frames post-read saw a button : " + _TRIM$(STR$(postFrames&))
    _PRINTSTRING (10, 224), "events this frame    : " + _TRIM$(STR$(evtCount&)) + _
                            "    frame : " + _TRIM$(STR$(frameNum&))
    _PRINTSTRING (10, 240), "last               : " + lastEvent$

    IF rescued& > 0 THEN
        COLOR _RGB32(255, 110, 110), _RGB32(16, 16, 24)
    ELSEIF pressesWith& > 0 THEN
        COLOR _RGB32(120, 255, 140), _RGB32(16, 16, 24)
    ELSE
        COLOR _RGB32(160, 160, 170), _RGB32(16, 16, 24)
    END IF
    _PRINTSTRING (10, 276), "VERDICT: " + Verdict$

    COLOR _RGB32(200, 200, 210), _RGB32(16, 16, 24)
    _PRINTSTRING (10, 308), "A rescue means a tap the plain post-loop read would have DROPPED."
    _PRINTSTRING (10, 324), "Zero rescues over ~40 varied clicks = the two $IF MAC blocks can go."
    _PRINTSTRING (10, 340), "Scores append to " + LOGPATH + " and a summary is written on exit."

    COLOR _RGB32(255, 255, 255), _RGB32(16, 16, 24)
END SUB


''
' Truncate the log, write its header.
'
SUB StartLog ()
    DIM fh AS INTEGER
    fh% = FREEFILE
    OPEN LOGPATH FOR OUTPUT AS #fh%
    PRINT #fh%, "# DRAW tap-to-click probe"
    PRINT #fh%, "# Does the macOS in-drain _MOUSEBUTTON capture still rescue any click under GLFW?"
    PRINT #fh%, "# [RESCUE] = the capture saw a press the post-loop read missed (workaround earning its keep)"
    CLOSE #fh%
END SUB


''
' Append a line.
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
' Final tally, so the log answers the question on its own.
'
SUB WriteSummary ()
    LogLine ""
    LogLine "================ SUMMARY ================"
    LogLine "presses WITH capture    : " + _TRIM$(STR$(pressesWith&))
    LogLine "presses WITHOUT capture : " + _TRIM$(STR$(pressesWithout&))
    LogLine "clicks RESCUED          : " + _TRIM$(STR$(rescued&))
    LogLine "frames capture fired    : " + _TRIM$(STR$(capturedFrames&))
    LogLine "frames post-read saw btn: " + _TRIM$(STR$(postFrames&))
    LogLine "VERDICT: " + Verdict$
END SUB
