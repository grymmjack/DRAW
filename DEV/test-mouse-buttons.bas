' test-mouse-buttons.bas - Test mouse buttons 1-16
'
' QB64-PE NOTE: _MOUSEBUTTON(i > 3) always returns 0 in SDL mode (libqb hard limit).
' This test confirms that -- buttons 4+ will never fire regardless of hardware.
' Press ESC to quit.

CONST MAX_BTN = 9

SCREEN _NEWIMAGE(640, 400, 32)
_TITLE "Mouse Button Test - ESC to quit"

DIM b(MAX_BTN) AS INTEGER
DIM ob(MAX_BTN) AS INTEGER
DIM pressCount(MAX_BTN) AS INTEGER
DIM latched(MAX_BTN) AS INTEGER
DIM i AS INTEGER
DIM k AS LONG
DIM lastX AS INTEGER, lastY AS INTEGER
DIM wheel AS INTEGER
DIM heldTxt AS STRING
DIM totTxt AS STRING

DIM labels(MAX_BTN) AS STRING
labels(1) = "Left"
labels(2) = "Right"
labels(3) = "Middle / wheel click"
labels(4) = "QB64 ALWAYS 0 (SDL limit)"
labels(5) = "QB64 ALWAYS 0 (SDL limit)"
labels(6) = "QB64 ALWAYS 0 (SDL limit)"
labels(7) = "QB64 ALWAYS 0 (SDL limit)"
labels(8) = "QB64 ALWAYS 0 (SDL limit)"
labels(9) = "QB64 ALWAYS 0 (SDL limit)"

DO
    FOR i = 1 TO MAX_BTN
        ob(i) = b(i)
    NEXT i
    wheel = 0

    DO WHILE _MOUSEINPUT
        wheel = wheel + _MOUSEWHEEL
        lastX = _MOUSEX
        lastY = _MOUSEY
        FOR i = 1 TO MAX_BTN
            IF _MOUSEBUTTON(i) THEN latched(i) = -1
        NEXT i
    LOOP

    FOR i = 1 TO MAX_BTN
        b(i) = latched(i) OR _MOUSEBUTTON(i)
        IF b(i) AND NOT ob(i) THEN pressCount(i) = pressCount(i) + 1
        IF NOT _MOUSEBUTTON(i) THEN latched(i) = 0
    NEXT i

    k = _KEYHIT
    IF k = 27 THEN END

    CLS , _RGB32(25, 25, 28)
    _PRINTMODE _KEEPBACKGROUND

    COLOR _RGB32(240, 220, 60)
    LOCATE 1, 2: PRINT "Mouse Button Tester [ESC=quit]"
    COLOR _RGB32(200, 80, 80)
    LOCATE 2, 2: PRINT "QB64-PE SDL: only buttons 1-3 work. 4+ hardcoded to 0 in libqb.cpp."
    COLOR _RGB32(140, 140, 140)
    LOCATE 3, 2: PRINT "Back/Forward thumb buttons CANNOT be trapped from QB64 code."
    COLOR _RGB32(120, 180, 200)
    LOCATE 4, 2: PRINT "Mouse X:"; lastX; "  Y:"; lastY; "  Wheel:"; wheel

    COLOR _RGB32(80, 120, 180)
    LOCATE 6, 2: PRINT "BTN  HELD  TOTAL   NOTES"
    COLOR _RGB32(60, 60, 70)
    LOCATE 7, 2: PRINT STRING$(60, "-")

    FOR i = 1 TO MAX_BTN
        LOCATE 7 + i, 2
        IF b(i) THEN
            COLOR _RGB32(80, 255, 80)
        ELSEIF pressCount(i) > 0 THEN
            COLOR _RGB32(255, 210, 50)
        ELSEIF i > 3 THEN
            COLOR _RGB32(60, 40, 40)
        ELSE
            COLOR _RGB32(70, 70, 80)
        END IF
        IF b(i) THEN heldTxt = "YES " ELSE heldTxt = "no  "
        totTxt = RIGHT$("    " + LTRIM$(STR$(pressCount(i))), 4)
        PRINT RIGHT$(" " + LTRIM$(STR$(i)), 2); "   "; heldTxt; "  "; totTxt; "   "; labels(i)
    NEXT i

    _DISPLAY
    _LIMIT 60
LOOP
