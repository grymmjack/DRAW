'======================================================================
' GLFW_DESKTOPWIDTH_TEST.BAS — verify _DESKTOPWIDTH cross-platform (a740g)
'
' _DESKTOPWIDTH returns the width of the whole desktop (not the window).
' Build/run: make a740g-run TEST=DESKTOPWIDTH
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_DESKTOPWIDTH
'
' PASS when, on Linux/macOS/Windows: prints the real desktop width (>0) that
' matches your actual screen resolution.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(560, 280, 32)
_TITLE "GLFW Test: _DESKTOPWIDTH"

DIM w AS LONG
w = _DESKTOPWIDTH
_ECHO "GLFW_DESKTOPWIDTH_TEST: _DESKTOPWIDTH =" + STR$(w)

DIM k AS LONG
DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    CLS , _RGB32(10, 10, 20)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 10, 20)
    LOCATE 2, 3: PRINT "_DESKTOPWIDTH cross-platform test"
    LOCATE 3, 3: PRINT STRING$(34, "-")
    LOCATE 5, 5: PRINT "_DESKTOPWIDTH ="; w; "px"
    LOCATE 7, 5
    IF w > 0 THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 10, 20): PRINT "PASS - non-zero desktop width."
    ELSE
        COLOR _RGB32(255, 120, 120), _RGB32(10, 10, 20): PRINT "FAIL - returned 0."
    END IF
    COLOR _RGB32(200, 200, 200), _RGB32(10, 10, 20)
    LOCATE 9, 5: PRINT "Cross-check against your real screen resolution."
    LOCATE 11, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 30
LOOP
