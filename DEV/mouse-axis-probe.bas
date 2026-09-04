' ============================================================================
' mouse-axis-probe.bas — map the mouse's ANALOG inputs (wheel tilt, sub-pixel
' movement) to QB64-PE's _AXIS / _WHEEL device API. These are new/undocumented
' for the mouse, so this probes BOTH live: tilt the wheel left/right, roll it,
' and move the mouse — watch which _AXIS(n) or _WHEEL(n) responds and its range.
'
' Reports each axis/wheel's live value plus the min/max seen, so a brief tilt is
' captured even if it snaps back to 0.
'
' Build:  ~/git/qb64pe/qb64pe -w -x -o DEV/maxprobe.run DEV/mouse-axis-probe.bas
' Run:    ./DEV/maxprobe.run     (ESC quits)
' ============================================================================
'$DYNAMIC
OPTION _EXPLICIT
ON ERROR GOTO EH   ' MANDATORY: never let a runtime error pop QB64's blocking dialog

SCREEN _NEWIMAGE(820, 520, 32)
_TITLE "Mouse _AXIS / _WHEEL probe - tilt & roll the wheel, move the mouse; ESC to quit"

' Find the [MOUSE] device and how many axes / wheels it reports.
DIM mdev AS INTEGER, d AS INTEGER, naxes AS INTEGER, nwheels AS INTEGER
mdev = 0
FOR d = 1 TO _DEVICES
    IF INSTR(_DEVICE$(d), "[MOUSE]") > 0 THEN mdev = d: EXIT FOR
NEXT
IF mdev > 0 THEN
    naxes = _LASTAXIS(mdev)
    nwheels = _LASTWHEEL(mdev)
END IF
IF naxes < 0 OR naxes > 16 THEN naxes = 0
IF nwheels < 0 OR nwheels > 16 THEN nwheels = 0

DIM axMin(1 TO 16) AS DOUBLE, axMax(1 TO 16) AS DOUBLE
DIM whMin(1 TO 16) AS DOUBLE, whMax(1 TO 16) AS DOUBLE
DIM i AS INTEGER
FOR i = 1 TO 16
    axMin(i) = 1E9: axMax(i) = -1E9: whMin(i) = 1E9: whMax(i) = -1E9
NEXT

DIM legacyWheelAccum AS DOUBLE

DO
    ' Poll the device (updates _AXIS/_WHEEL) and the legacy mouse wheel for reference.
    DIM di AS INTEGER : IF mdev > 0 THEN di = _DEVICEINPUT(mdev)
    DO WHILE _MOUSEINPUT: legacyWheelAccum = legacyWheelAccum + _MOUSEWHEEL: LOOP

    CLS
    COLOR _RGB32(255, 255, 0): _PRINTSTRING (10, 8), "MOUSE _AXIS / _WHEEL PROBE   (ESC to quit)"
    COLOR _RGB32(180, 180, 180)
    _PRINTSTRING (10, 30), "[MOUSE] device #:" + STR$(mdev) + "   _LASTAXIS:" + STR$(naxes) + "   _LASTWHEEL:" + STR$(nwheels)
    _PRINTSTRING (10, 46), "Legacy _MOUSEWHEEL accum:" + STR$(legacyWheelAccum) + "   (roll the wheel; TILT it left/right; move the mouse)"

    DIM y AS INTEGER : y = 78
    COLOR _RGB32(120, 220, 120): _PRINTSTRING (10, y), "_AXIS(n) — analog axes (movement / tilt)": y = y + 20
    COLOR _RGB32(220, 220, 220)
    IF naxes = 0 THEN _PRINTSTRING (24, y), "(none reported)": y = y + 18
    FOR i = 1 TO naxes
        DIM av AS DOUBLE : av = _AXIS(i)
        IF av < axMin(i) THEN axMin(i) = av
        IF av > axMax(i) THEN axMax(i) = av
        DIM hot AS INTEGER : hot = (ABS(av) > 0.001)
        IF hot THEN COLOR _RGB32(255, 255, 0) ELSE COLOR _RGB32(200, 200, 200)
        _PRINTSTRING (24, y), "_AXIS(" + LTRIM$(STR$(i)) + ") = " + _TRIM$(STR$(av)) + _
            "    range[ " + _TRIM$(STR$(axMin(i))) + " .. " + _TRIM$(STR$(axMax(i))) + " ]"
        y = y + 18
    NEXT

    y = y + 10
    COLOR _RGB32(120, 180, 240): _PRINTSTRING (10, y), "_WHEEL(n) — wheels (vertical roll / horizontal tilt)": y = y + 20
    COLOR _RGB32(220, 220, 220)
    IF nwheels = 0 THEN _PRINTSTRING (24, y), "(none reported)": y = y + 18
    FOR i = 1 TO nwheels
        DIM wv AS DOUBLE : wv = _WHEEL(i)
        IF wv < whMin(i) THEN whMin(i) = wv
        IF wv > whMax(i) THEN whMax(i) = wv
        DIM whot AS INTEGER : whot = (ABS(wv) > 0.001)
        IF whot THEN COLOR _RGB32(255, 255, 0) ELSE COLOR _RGB32(200, 200, 200)
        _PRINTSTRING (24, y), "_WHEEL(" + LTRIM$(STR$(i)) + ") = " + _TRIM$(STR$(wv)) + _
            "    range[ " + _TRIM$(STR$(whMin(i))) + " .. " + _TRIM$(STR$(whMax(i))) + " ]"
        y = y + 18
    NEXT

    COLOR _RGB32(150, 150, 150)
    _PRINTSTRING (10, 470), "Yellow = active this frame. Note which _AXIS/_WHEEL index lights up on a"
    _PRINTSTRING (10, 486), "LEFT/RIGHT wheel TILT, and its value range — that's the bindable tilt input."

    _DISPLAY
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)
SYSTEM

EH:
    ' Trap + continue — NEVER surface the default blocking "Continue?" dialog.
    _LOGWARN "axis-probe trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
    RESUME NEXT
