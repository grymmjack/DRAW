' Headless button-mapping probe: prints to $CONSOLE which _MOUSEBUTTON index
' fires. Used to check whether Xvfb+xdotool can deliver buttons 4-9 to GLFW.
'   ~/git/qb64pe/qb64pe -w -x -o DEV/mbpc.run DEV/mbprobe-console.bas
'   xvfb-run -a bash -c './DEV/mbpc.run & sleep 2; DISPLAY=... xdotool click 8; ...'
'$DYNAMIC
OPTION _EXPLICIT
$CONSOLE:ONLY
ON ERROR GOTO EH               ' MANDATORY: never let a runtime error pop QB64's blocking dialog
SCREEN _NEWIMAGE(320, 240, 32) ' a window is required for pointer input focus
_TITLE "mbpc"
DIM b    AS INTEGER, last(1 TO 9) AS INTEGER, startT AS DOUBLE
startT = TIMER
' Detect the [MOUSE] device button count so we never sample past it (ERR 5).
DIM mdev AS INTEGER, dd AS INTEGER, nb AS INTEGER
FOR dd = 1 TO _DEVICES
    IF INSTR(_DEVICE$(dd), "[MOUSE]") > 0 THEN mdev = dd: EXIT FOR
NEXT
IF mdev > 0 THEN nb = _LASTBUTTON(mdev)
IF nb < 1 OR nb > 9 THEN nb = 3
_DEST _CONSOLE
PRINT "mbpc: [MOUSE] device #"; mdev; " _LASTBUTTON="; nb; " — polling 1.."; nb; " for ~8s"
DO
    DO WHILE _MOUSEINPUT : LOOP
    FOR b = 1 TO nb
        DIM nowD AS INTEGER : nowD = (_MOUSEBUTTON(b) <> 0)
        IF nowD AND last(b) = 0 THEN PRINT "DOWN _MOUSEBUTTON("; LTRIM$(STR$(b)); ")"
        IF nowD = 0 AND last(b) THEN PRINT "UP   _MOUSEBUTTON("; LTRIM$(STR$(b)); ")"
        last(b) = nowD
    NEXT
    _LIMIT 120
LOOP UNTIL TIMER - startT > 8 OR _KEYDOWN(27)
PRINT "mbpc: done"
SYSTEM

EH:
    ' Trap + continue — NEVER surface the default blocking "Continue?" dialog.
    PRINT "trapped ERR"; ERR; "at line"; _ERRORLINE
    RESUME NEXT
