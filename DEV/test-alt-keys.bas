OPTION _EXPLICIT

' test-alt-keys.bas — Test Alt key detection on macOS
' Shows real-time state of Alt, Ctrl, Shift and key combos

SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "Alt Key Test - Press keys to test (ESC to quit)"

' Physical key codes used in DRAW
CONST KEY_LALT& = 100308
CONST KEY_RALT& = 100307
CONST KEY_LCTRL& = 100306
CONST KEY_RCTRL& = 100305
CONST KEY_LSHIFT& = 100304
CONST KEY_RSHIFT& = 100303

DIM k AS LONG
DIM lastKey AS LONG
DIM lastKeyTime AS DOUBLE
DIM altDown AS INTEGER
DIM ctrlDown AS INTEGER
DIM shiftDown AS INTEGER
DIM laltDown AS INTEGER, raltDown AS INTEGER
DIM lctrlDown AS INTEGER, rctrlDown AS INTEGER
DIM testKeys(9) AS STRING
DIM testCodes(9) AS LONG
DIM testResults(9) AS STRING

' Keys to test with Alt
testKeys(0) = "F (File menu)": testCodes(0) = 102
testKeys(1) = "E (Edit menu)": testCodes(1) = 101
testKeys(2) = "V (View menu)": testCodes(2) = 118
testKeys(3) = "Z (Undo)": testCodes(3) = 122
testKeys(4) = "S (Save)": testCodes(4) = 115
testKeys(5) = "PgUp": testCodes(5) = 18688
testKeys(6) = "PgDn": testCodes(6) = 20736
testKeys(7) = ". (period)": testCodes(7) = 46
testKeys(8) = ", (comma)": testCodes(8) = 44
testKeys(9) = "/ (slash)": testCodes(9) = 47

DO
    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k <> 0 THEN
        lastKey = k
        lastKeyTime = TIMER(.001)
    END IF

    ' Check modifier states via _KEYDOWN
    laltDown = _KEYDOWN(KEY_LALT&)
    raltDown = _KEYDOWN(KEY_RALT&)
    altDown = laltDown OR raltDown
    lctrlDown = _KEYDOWN(KEY_LCTRL&)
    rctrlDown = _KEYDOWN(KEY_RCTRL&)
    ctrlDown = lctrlDown OR rctrlDown
    shiftDown = _KEYDOWN(KEY_LSHIFT&) OR _KEYDOWN(KEY_RSHIFT&)

    CLS , _RGB32(30, 30, 30)
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)

    _PRINTSTRING (20, 20), "=== ALT KEY TEST ==="
    _PRINTSTRING (20, 40), "Press modifier keys and letter keys to test detection."
    _PRINTSTRING (20, 55), "ESC to quit."

    ' Modifier status
    _PRINTSTRING (20, 85), "--- Modifier States (_KEYDOWN) ---"

    IF altDown THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(255, 80, 80)
    _PRINTSTRING (20, 105), "Alt:   " + IIF$(altDown, "DOWN", "up  ") + "  (L:" + IIF$(laltDown, "Y", "N") + " R:" + IIF$(raltDown, "Y", "N") + ")"

    IF ctrlDown THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(255, 80, 80)
    _PRINTSTRING (20, 120), "Ctrl:  " + IIF$(ctrlDown, "DOWN", "up  ") + "  (L:" + IIF$(lctrlDown, "Y", "N") + " R:" + IIF$(rctrlDown, "Y", "N") + ")"

    IF shiftDown THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(255, 80, 80)
    _PRINTSTRING (20, 135), "Shift: " + IIF$(shiftDown, "DOWN", "up  ")

    ' Last _KEYHIT
    COLOR _RGB32(200, 200, 200)
    _PRINTSTRING (20, 165), "--- Last _KEYHIT ---"
    IF lastKey <> 0 THEN
        COLOR _RGB32(255, 255, 100)
        _PRINTSTRING (20, 185), "_KEYHIT = " + LTRIM$(STR$(lastKey))
        IF lastKey > 0 AND lastKey < 256 THEN
            _PRINTSTRING (300, 185), "Char: " + CHR$(lastKey) + " (ASCII " + LTRIM$(STR$(lastKey)) + ")"
        ELSEIF lastKey >= 256 AND lastKey < 65536 THEN
            _PRINTSTRING (300, 185), "Unicode codepoint: " + LTRIM$(STR$(lastKey))
        ELSE
            _PRINTSTRING (300, 185), "Special/extended key"
        END IF
    END IF

    ' Test Alt+key combos using _KEYDOWN
    COLOR _RGB32(200, 200, 200)
    _PRINTSTRING (20, 220), "--- Alt+Key Combos (_KEYDOWN) ---"
    DIM i AS INTEGER
    FOR i = 0 TO 9
        DIM keyIsDown AS INTEGER
        keyIsDown = _KEYDOWN(testCodes(i))
        DIM comboActive AS INTEGER
        comboActive = altDown AND keyIsDown

        IF comboActive THEN
            COLOR _RGB32(0, 255, 0)
            testResults(i) = "DETECTED!"
        ELSEIF keyIsDown THEN
            COLOR _RGB32(255, 255, 100)
        ELSE
            COLOR _RGB32(150, 150, 150)
        END IF

        DIM resultStr AS STRING
        IF LEN(testResults(i)) > 0 AND TIMER(.001) - lastKeyTime < 2 THEN
            resultStr = " << " + testResults(i)
        ELSE
            testResults(i) = ""
            resultStr = ""
        END IF

        _PRINTSTRING (20, 240 + i * 18), "Alt+" + testKeys(i) + ": key=" + IIF$(keyIsDown, "DOWN", "up") + resultStr
    NEXT i

    ' Test Ctrl+Alt combos
    COLOR _RGB32(200, 200, 200)
    _PRINTSTRING (20, 430), "--- Ctrl+Alt combos ---"
    DIM ctrlAltZ AS INTEGER
    ctrlAltZ = ctrlDown AND altDown AND _KEYDOWN(122)
    IF ctrlAltZ THEN COLOR _RGB32(0, 255, 0) ELSE COLOR _RGB32(150, 150, 150)
    _PRINTSTRING (20, 450), "Ctrl+Alt+Z: " + IIF$(ctrlAltZ, "DETECTED!", "waiting...")

    _DISPLAY
    _LIMIT 60
LOOP

SYSTEM

FUNCTION IIF$ (condition AS INTEGER, trueVal AS STRING, falseVal AS STRING)
    IF condition THEN IIF$ = trueVal ELSE IIF$ = falseVal
END FUNCTION
