'$DYNAMIC
OPTION _EXPLICIT
' Key-detection probe: logs every _KEYDOWN code that is active each frame to
' DEV/keytest.log, so we can see exactly what code(s) Ctrl+comma produces on
' this machine. Runs ~12 seconds then exits.

DIM logPath AS STRING  : logPath$ = "keytest.log" ' written next to the EXE (CWD)
DIM fh      AS INTEGER : fh% = FREEFILE
OPEN logPath$ FOR OUTPUT AS #fh%
PRINT #fh%, "keytest start"

SCREEN _NEWIMAGE(640, 200, 32)
_TITLE "KEYTEST - press Ctrl+, (comma)"

DIM startT   AS DOUBLE : startT# = TIMER
DIM frame    AS LONG
DIM code     AS LONG
DIM downStr  AS STRING
DIM prevLine AS STRING : prevLine$ = ""

DO
    _LIMIT 30
    frame& = frame& + 1

    ' Build a string of all currently-down codes in the common ranges.
    downStr$ = ""
    ' ASCII-ish range
    FOR code& = 1 TO 255
        IF _KEYDOWN(code&) THEN downStr$ = downStr$ + STR$(code&)
    NEXT code&
    ' QB64 scancode range (100000+)
    FOR code& = 100000 TO 100600
        IF _KEYDOWN(code&) THEN downStr$ = downStr$ + " sc" + _TRIM$(STR$(code& - 100000))
    NEXT code&

    ' Drain _KEYHIT and log any non-zero values (catches Ctrl+combos that
    ' _KEYDOWN misses). _KEYHIT returns +code on press, -code on release.
    DIM kh AS LONG
    DO
        kh& = _KEYHIT
        IF kh& = 0 THEN EXIT DO
        PRINT #fh%, "KEYHIT:" + STR$(kh&)
    LOOP

    ' Only log when the set of down-keys changes (avoids spam)
    IF downStr$ <> prevLine$ THEN
        IF LEN(downStr$) > 0 THEN
            PRINT #fh%, "DOWN:" + downStr$
        ELSE
            PRINT #fh%, "(none)"
        END IF
        prevLine$ = downStr$
    END IF

    CLS
    _PRINTSTRING (10, 10), "Press Ctrl+, (comma). Logging to DEV/keytest.log"
    _PRINTSTRING (10, 30), "Down: " + downStr$
    _DISPLAY

    IF TIMER - startT# > 12 THEN EXIT DO
    IF _KEYDOWN(27) THEN EXIT DO ' Esc to quit early
LOOP

PRINT #fh%, "keytest end"
CLOSE #fh%
SYSTEM
