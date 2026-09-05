' ============================================================================
' mousewheel-axis-probe.bas — does THIS compiler support _MOUSEWHEEL(axis&)?
' Rick: "_MOUSEWHEEL[(axis&)] — optional axis for horizontal / multi-axis scroll."
' If so, horizontal wheel TILT is just _MOUSEWHEEL(1) inside the normal _MOUSEINPUT
' drain — no _DEVICEINPUT/_WHEEL device API needed. Tilt the wheel left/right and
' roll it up/down; watch which axis accumulates.
'
' Build:  ~/git/qb64pe/qb64pe -w -x -o DEV/mwaxis.run DEV/mousewheel-axis-probe.bas
' Run:    ./DEV/mwaxis.run     (ESC quits)
' ============================================================================
'$DYNAMIC
OPTION _EXPLICIT
ON ERROR GOTO EH

SCREEN _NEWIMAGE(760, 300, 32)
_TITLE "_MOUSEWHEEL(axis) probe - roll (vertical) and TILT (horizontal); ESC quits"

DIM vAccum AS LONG, hAccum AS LONG      ' cumulative
DIM vNow AS INTEGER, hNow AS INTEGER    ' this frame

DO
    vNow = 0 : hNow = 0
    DO WHILE _MOUSEINPUT
        vNow = vNow + _MOUSEWHEEL         ' axis 0 (default) = vertical
        hNow = hNow + _MOUSEWHEEL(1)      ' axis 1 = horizontal (tilt) — the test
    LOOP
    vAccum = vAccum + vNow
    hAccum = hAccum + hNow

    CLS
    COLOR _RGB32(255, 255, 0): _PRINTSTRING (10, 10), "_MOUSEWHEEL(axis) PROBE  (ESC quits)"
    COLOR _RGB32(200, 200, 200)
    _PRINTSTRING (10, 44), "Roll the wheel (vertical) and TILT it left/right (horizontal)."

    IF vNow <> 0 THEN COLOR _RGB32(255, 255, 0) ELSE COLOR _RGB32(160, 160, 160)
    _PRINTSTRING (10, 90),  "VERTICAL  _MOUSEWHEEL     this frame = " + STR$(vNow) + "    cumulative = " + STR$(vAccum)
    IF hNow <> 0 THEN COLOR _RGB32(90, 255, 90) ELSE COLOR _RGB32(160, 160, 160)
    _PRINTSTRING (10, 120), "HORIZONTAL _MOUSEWHEEL(1) this frame = " + STR$(hNow) + "    cumulative = " + STR$(hAccum)

    COLOR _RGB32(150, 150, 150)
    _PRINTSTRING (10, 170), "If HORIZONTAL turns green/nonzero on a tilt, _MOUSEWHEEL(1) IS the tilt --"
    _PRINTSTRING (10, 190), "and DRAW can read it inside its existing _MOUSEINPUT drain. Done."
    _PRINTSTRING (10, 230), "If the program failed to COMPILE, this compiler lacks the axis param."

    _DISPLAY
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)
SYSTEM

EH:
    _LOGWARN "mwaxis-probe trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
    RESUME NEXT
