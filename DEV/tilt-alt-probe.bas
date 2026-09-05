' ============================================================================
' tilt-alt-probe.bas — does the horizontal wheel TILT arrive together with a
' phantom ALT (or Ctrl/Shift, or an extra button)? DRAW's log showed the ALT
' picker firing on tilt (altHeld=-1), which would make the tilt binding (it
' forbids modifiers) reject the gesture. This isolates the question from DRAW.
'
' Tilt the wheel LEFT and RIGHT and watch:
'   - which _WHEEL(n) moves         (the tilt axis; 4 on Rick's mouse)
'   - ALT / CTRL / SHIFT live state (via the SAME keycodes DRAW uses)
'   - extra mouse buttons 4..N      (some mice send tilt as buttons 6/7)
'   - a LATCH: "TILT seen WITH Alt?" — the money question.
'
' Build:  ~/git/qb64pe/qb64pe -w -x -o DEV/tiltalt.run DEV/tilt-alt-probe.bas
' Run:    ./DEV/tiltalt.run       (ESC quits)
' ============================================================================
'$DYNAMIC
OPTION _EXPLICIT
ON ERROR GOTO EH   ' MANDATORY: never surface QB64's blocking "Continue?" dialog

' Modifier keycodes — copied verbatim from DRAW's _COMMON.BI so this sees exactly
' what DRAW's MODIFIERS_update sees.
CONST K_LSHIFT = 100304, K_RSHIFT = 100303
CONST K_LCTRL = 100305, K_RCTRL = 100306
CONST K_RALT = 100307, K_LALT = 100308

SCREEN _NEWIMAGE(900, 560, 32)
_TITLE "Tilt+ALT probe - tilt the wheel left/right; does ALT ride along? (ESC quits)"

DIM mdev AS INTEGER, d AS INTEGER, nwheels AS INTEGER, nbtn AS INTEGER
mdev = 0
FOR d = 1 TO _DEVICES
    IF INSTR(_DEVICE$(d), "[MOUSE]") > 0 THEN mdev = d: EXIT FOR
NEXT
IF mdev > 0 THEN
    nwheels = _LASTWHEEL(mdev)
    nbtn = _LASTBUTTON(mdev)
END IF
IF nwheels < 0 OR nwheels > 16 THEN nwheels = 0
IF nbtn < 0 OR nbtn > 32 THEN nbtn = 0

DIM tiltWithAlt AS INTEGER   : tiltWithAlt = 0    ' LATCH: tilt seen while Alt down
DIM tiltWithCtrl AS INTEGER  : tiltWithCtrl = 0
DIM tiltWithShift AS INTEGER : tiltWithShift = 0
DIM tiltClean AS INTEGER     : tiltClean = 0      ' LATCH: tilt seen with NO modifier
DIM lastTiltIdx AS INTEGER   : lastTiltIdx = 0
DIM tiltBtnSeen AS INTEGER   : tiltBtnSeen = 0    ' LATCH: an extra button pressed during test

DIM wv(1 TO 16) AS INTEGER, i AS INTEGER

DO
    IF mdev > 0 THEN d = _DEVICEINPUT(mdev)

    ' Read wheels once each (reading resets the delta).
    DIM anyTilt AS INTEGER : anyTilt = 0
    DIM tiltIdx AS INTEGER : tiltIdx = 0
    FOR i = 1 TO nwheels
        wv(i) = SGN(_WHEEL(i))
        ' Wheel 3 is normally the vertical scroll; treat any OTHER moving wheel as a tilt.
        IF wv(i) <> 0 AND i <> 3 THEN anyTilt = -1: tiltIdx = i
    NEXT

    ' Live modifier state (same keycodes as DRAW).
    DIM altNow AS INTEGER   : altNow = (_KEYDOWN(K_LALT) OR _KEYDOWN(K_RALT))
    DIM ctrlNow AS INTEGER  : ctrlNow = (_KEYDOWN(K_LCTRL) OR _KEYDOWN(K_RCTRL))
    DIM shiftNow AS INTEGER : shiftNow = (_KEYDOWN(K_LSHIFT) OR _KEYDOWN(K_RSHIFT))

    ' Keep _MOUSEBUTTON / _MOUSEX fresh (device pump above doesn't feed them).
    DO WHILE _MOUSEINPUT: LOOP

    ' Extra buttons.
    DIM btnMask AS STRING : btnMask = ""
    FOR i = 4 TO nbtn
        DIM bdn AS INTEGER : bdn = (_MOUSEBUTTON(i) <> 0)
        btnMask = btnMask + " b" + LTRIM$(STR$(i)) + "=" + LTRIM$(STR$(-bdn))
        IF bdn THEN tiltBtnSeen = -1
    NEXT

    ' Latch what accompanies a tilt.
    IF anyTilt THEN
        lastTiltIdx = tiltIdx
        IF altNow THEN tiltWithAlt = -1
        IF ctrlNow THEN tiltWithCtrl = -1
        IF shiftNow THEN tiltWithShift = -1
        IF (NOT altNow) AND (NOT ctrlNow) AND (NOT shiftNow) THEN tiltClean = -1
    END IF

    CLS
    COLOR _RGB32(255, 255, 0): _PRINTSTRING (10, 8), "TILT + ALT PROBE   (tilt wheel LEFT/RIGHT; ESC quits)"
    COLOR _RGB32(180, 180, 180)
    _PRINTSTRING (10, 32), "[MOUSE] dev#" + STR$(mdev) + "   _LASTWHEEL=" + STR$(nwheels) + "   _LASTBUTTON=" + STR$(nbtn)

    ' Live wheels.
    DIM y AS INTEGER : y = 64
    COLOR _RGB32(120, 220, 120): _PRINTSTRING (10, y), "WHEELS (live):": y = y + 20
    COLOR _RGB32(220, 220, 220)
    FOR i = 1 TO nwheels
        IF wv(i) <> 0 THEN COLOR _RGB32(255, 255, 0) ELSE COLOR _RGB32(160, 160, 160)
        _PRINTSTRING (24, y), "_WHEEL(" + LTRIM$(STR$(i)) + ") = " + LTRIM$(STR$(wv(i))): y = y + 16
    NEXT

    y = y + 8
    IF altNow THEN COLOR _RGB32(255, 90, 90) ELSE COLOR _RGB32(160, 160, 160)
    _PRINTSTRING (10, y), "ALT now: " + LTRIM$(STR$(-altNow))
    IF ctrlNow THEN COLOR _RGB32(255, 90, 90) ELSE COLOR _RGB32(160, 160, 160)
    _PRINTSTRING (180, y), "CTRL now: " + LTRIM$(STR$(-ctrlNow))
    IF shiftNow THEN COLOR _RGB32(255, 90, 90) ELSE COLOR _RGB32(160, 160, 160)
    _PRINTSTRING (360, y), "SHIFT now: " + LTRIM$(STR$(-shiftNow))
    y = y + 20
    COLOR _RGB32(200, 200, 200): _PRINTSTRING (10, y), "extra buttons:" + btnMask: y = y + 24

    ' The verdict latches.
    COLOR _RGB32(255, 255, 255): _PRINTSTRING (10, y), "==== WHAT ACCOMPANIES A TILT (latched) ===="
    y = y + 22
    IF tiltClean THEN COLOR _RGB32(120, 255, 120) ELSE COLOR _RGB32(120, 120, 120)
    _PRINTSTRING (24, y), "tilt seen CLEAN (no modifier): " + LTRIM$(STR$(-tiltClean)): y = y + 18
    IF tiltWithAlt THEN COLOR _RGB32(255, 80, 80) ELSE COLOR _RGB32(120, 120, 120)
    _PRINTSTRING (24, y), "tilt seen WITH ALT:            " + LTRIM$(STR$(-tiltWithAlt)) + "   <== the money question": y = y + 18
    IF tiltWithCtrl THEN COLOR _RGB32(255, 160, 80) ELSE COLOR _RGB32(120, 120, 120)
    _PRINTSTRING (24, y), "tilt seen WITH CTRL:           " + LTRIM$(STR$(-tiltWithCtrl)): y = y + 18
    IF tiltWithShift THEN COLOR _RGB32(255, 160, 80) ELSE COLOR _RGB32(120, 120, 120)
    _PRINTSTRING (24, y), "tilt seen WITH SHIFT:          " + LTRIM$(STR$(-tiltWithShift)): y = y + 18
    COLOR _RGB32(200, 200, 200)
    _PRINTSTRING (24, y), "tilt axis last seen on _WHEEL(" + LTRIM$(STR$(lastTiltIdx)) + ")   extra-button-during-test: " + LTRIM$(STR$(-tiltBtnSeen)): y = y + 24

    COLOR _RGB32(150, 150, 150)
    _PRINTSTRING (10, 528), "If 'tilt WITH ALT' turns red/1, the tilt gesture carries a phantom Alt -> DRAW's"
    _PRINTSTRING (10, 544), "tilt binding (which forbids modifiers) rejects it, and the ALT picker fires instead."

    _DISPLAY
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)
SYSTEM

EH:
    _LOGWARN "tilt-alt-probe trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
    RESUME NEXT
