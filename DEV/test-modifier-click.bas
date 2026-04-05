OPTION _EXPLICIT

SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "Modifier+Click Test - Click inside this window with modifiers held"

DIM AS INTEGER mb1, mb2, mb3
DIM AS INTEGER ctrlL, ctrlR, altL, altR, shiftL, shiftR
DIM AS INTEGER mx, my

DO
    CLS

    ' Process mouse input
    WHILE _MOUSEINPUT: WEND
    mx = _MOUSEX
    my = _MOUSEY
    mb1 = _MOUSEBUTTON(1)
    mb2 = _MOUSEBUTTON(2)
    mb3 = _MOUSEBUTTON(3)

    ' Check modifiers
    ctrlL = _KEYDOWN(100305)
    ctrlR = _KEYDOWN(100306)
    altL = _KEYDOWN(100307)
    altR = _KEYDOWN(100308)
    shiftL = _KEYDOWN(100303)
    shiftR = _KEYDOWN(100304)

    COLOR _RGB32(255, 255, 255)
    _PRINTSTRING (20, 20), "=== MODIFIER + CLICK TEST ==="
    _PRINTSTRING (20, 40), "Hold a modifier key, then click in this window."
    _PRINTSTRING (20, 60), "Press ESC to quit."

    ' Mouse position
    COLOR _RGB32(180, 180, 180)
    _PRINTSTRING (20, 100), "Mouse: X=" + STR$(mx) + "  Y=" + STR$(my)

    ' Mouse buttons
    _PRINTSTRING (20, 130), "--- MOUSE BUTTONS ---"
    IF mb1 THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 150), "Left (B1):   " + STR$(mb1)
    IF mb2 THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 170), "Right (B2):  " + STR$(mb2)
    IF mb3 THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 190), "Middle (B3): " + STR$(mb3)

    ' Modifier keys
    COLOR _RGB32(180, 180, 180)
    _PRINTSTRING (20, 230), "--- MODIFIER KEYS ---"

    IF ctrlL OR ctrlR THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 250), "Ctrl:    L=" + STR$(ctrlL) + "  R=" + STR$(ctrlR)

    IF altL OR altR THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 270), "Alt/Opt: L=" + STR$(altL) + "  R=" + STR$(altR)

    IF shiftL OR shiftR THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(100, 100, 100)
    _PRINTSTRING (20, 290), "Shift:   L=" + STR$(shiftL) + "  R=" + STR$(shiftR)

    ' Combo detection
    COLOR _RGB32(255, 255, 0)
    _PRINTSTRING (20, 330), "--- DETECTED COMBOS ---"

    DIM AS INTEGER anyCtrl, anyAlt, anyShift
    anyCtrl = ctrlL OR ctrlR
    anyAlt = altL OR altR
    anyShift = shiftL OR shiftR

    IF mb1 AND anyCtrl THEN
        COLOR _RGB32(0, 255, 0)
        _PRINTSTRING (20, 350), ">> CTRL + LEFT CLICK <<"
    ELSEIF mb2 AND anyCtrl THEN
        COLOR _RGB32(255, 128, 0)
        _PRINTSTRING (20, 350), ">> CTRL + RIGHT CLICK (macOS converts Ctrl+LClick to this) <<"
    ELSEIF mb1 AND NOT anyCtrl AND NOT anyAlt AND NOT anyShift THEN
        COLOR _RGB32(200, 200, 200)
        _PRINTSTRING (20, 350), "Plain left click"
    ELSEIF mb2 AND NOT anyCtrl THEN
        COLOR _RGB32(200, 200, 200)
        _PRINTSTRING (20, 350), "Plain right click"
    ELSE
        COLOR _RGB32(100, 100, 100)
        _PRINTSTRING (20, 350), "(no click)"
    END IF

    IF mb1 AND anyAlt THEN
        COLOR _RGB32(0, 255, 0)
        _PRINTSTRING (20, 370), ">> OPTION/ALT + LEFT CLICK <<"
    ELSE
        COLOR _RGB32(100, 100, 100)
        _PRINTSTRING (20, 370), "(no alt+click)"
    END IF

    IF mb1 AND anyShift THEN
        COLOR _RGB32(0, 255, 0)
        _PRINTSTRING (20, 390), ">> SHIFT + LEFT CLICK <<"
    ELSE
        COLOR _RGB32(100, 100, 100)
        _PRINTSTRING (20, 390), "(no shift+click)"
    END IF

    ' Instructions
    COLOR _RGB32(255, 200, 100)
    _PRINTSTRING (20, 430), "TRY: Ctrl+Click, Option+Click, Shift+Click"
    _PRINTSTRING (20, 450), "We need to find which combo gives B1 + modifier"

    _DISPLAY
    _LIMIT 30

    IF _KEYHIT = 27 THEN EXIT DO
LOOP

SYSTEM
