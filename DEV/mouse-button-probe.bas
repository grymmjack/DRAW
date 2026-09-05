' ============================================================================
' mouse-button-probe.bas — determine how THIS machine exposes extra mouse
' buttons (back / forward / etc.) so DRAW can sample them correctly.
'
' DRAW's 2B.2 mouse rebinding needs to read buttons 4-6. QB64-PE offers two
' possible APIs and the wiki only documents _MOUSEBUTTON for 1-3, so which one
' actually reports the thumb buttons is hardware/driver-specific. This probe
' shows BOTH live. Press each mouse button (incl. back/forward/extra) and note
' which column lights up and at what index. Roll/tilt the wheel too.
'
' Build:  ~/git/qb64pe/qb64pe -w -x -o DEV/mbprobe.run DEV/mouse-button-probe.bas
' Run:    ./DEV/mbprobe.run     (ESC quits)
' ============================================================================
'$DYNAMIC
OPTION _EXPLICIT
ON ERROR GOTO EH                ' MANDATORY: never let a runtime error pop QB64's blocking dialog

SCREEN _NEWIMAGE(760, 440, 32)
_TITLE "Mouse button probe - press every button; roll/tilt wheel; ESC to quit"

' Find the [MOUSE] device number for the _DEVICEINPUT / _BUTTON API.
DIM mouseDev AS INTEGER, d AS INTEGER, nb AS INTEGER
mouseDev = 0
FOR d = 1 TO _DEVICES
    IF INSTR(_DEVICE$(d), "[MOUSE]") > 0 THEN mouseDev = d: EXIT FOR
NEXT
IF mouseDev > 0 THEN nb = _LASTBUTTON(mouseDev)

DIM b AS INTEGER, wheel AS INTEGER
DIM everMB(1 TO 12) AS INTEGER  ' latch: _MOUSEBUTTON(n) ever seen down
DIM everDev(1 TO 12) AS INTEGER ' latch: _BUTTON(n) via _DEVICEINPUT ever seen down

DO
    ' Poll both input streams this frame.
    DO WHILE _MOUSEINPUT : wheel = wheel + _MOUSEWHEEL : LOOP
    DIM di AS INTEGER    : IF mouseDev > 0 THEN di = _DEVICEINPUT(mouseDev)

    CLS
    COLOR _RGB32(255, 255, 0): _PRINTSTRING (10, 8), "MOUSE BUTTON PROBE   (ESC to quit)"
    COLOR _RGB32(180, 180, 180)
    _PRINTSTRING (10, 30), "[MOUSE] device #:" + STR$(mouseDev) + "   _LASTBUTTON:" + STR$(nb)
    _PRINTSTRING (10, 46), "Press each physical button (left/right/mid/back/forward/extra). Wheel accum:" + STR$(wheel)

    COLOR _RGB32(120, 220, 120): _PRINTSTRING (10, 74), "_MOUSEBUTTON(n)         _DEVICEINPUT/_BUTTON(n)"
    COLOR _RGB32(220, 220, 220)
    FOR b = 1 TO 8
        DIM mbNow  AS INTEGER : mbNow = (_MOUSEBUTTON(b) <> 0)
        IF mbNow THEN everMB(b) = -1
        DIM devNow AS INTEGER                                           : devNow = 0
        IF mouseDev > 0 AND b <= nb THEN IF _BUTTON(b) THEN devNow = -1 : everDev(b) = -1

        DIM lineY AS INTEGER : lineY = 96 + (b - 1) * 22
        DIM lcol  AS _UNSIGNED LONG
        IF mbNow THEN lcol = _RGB32(255, 255, 0) ELSE IF everMB(b) THEN lcol = _RGB32(90, 140, 90) ELSE lcol = _RGB32(90, 90, 90)
        COLOR lcol
        _PRINTSTRING (10, lineY), "btn" + STR$(b) + ":  " + _IIF(mbNow, "DOWN", _IIF(everMB(b), "(seen)", "  -  "))

        IF devNow THEN lcol = _RGB32(255, 255, 0) ELSE IF everDev(b) THEN lcol = _RGB32(90, 140, 90) ELSE lcol = _RGB32(90, 90, 90)
        COLOR lcol
        _PRINTSTRING (270, lineY), "btn" + STR$(b) + ":  " + _IIF(devNow, "DOWN", _IIF(everDev(b), "(seen)", "  -  "))
    NEXT

    COLOR _RGB32(150, 150, 150)
    _PRINTSTRING (10, 300), "Yellow = down now.  (seen) = fired at least once.  Note which index each"
    _PRINTSTRING (10, 316), "physical button lights up, and whether it appears in the LEFT column"
    _PRINTSTRING (10, 332), "(_MOUSEBUTTON) or only the RIGHT column (_DEVICEINPUT/_BUTTON)."

    _DISPLAY
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)
SYSTEM

EH:
    ' Trap + continue — NEVER surface the default blocking "Continue?" dialog.
    _LOGWARN "mouse-probe trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
    RESUME NEXT
