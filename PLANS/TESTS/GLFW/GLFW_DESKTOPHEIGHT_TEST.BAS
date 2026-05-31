'======================================================================
' GLFW_DESKTOPHEIGHT_TEST.BAS — verify _DESKTOPHEIGHT cross-platform (a740g)
'
' _DESKTOPHEIGHT returns the height of the whole desktop (not the window).
' Build/run: make a740g-run TEST=DESKTOPHEIGHT
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_DESKTOPHEIGHT
'
' PASS when, on Linux/macOS/Windows: prints the real desktop height (>0) that
' matches your actual screen resolution.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(560, 280, 32)
_TITLE "GLFW Test: _DESKTOPHEIGHT"

DIM h AS LONG
h = _DESKTOPHEIGHT
_ECHO "GLFW_DESKTOPHEIGHT_TEST: _DESKTOPHEIGHT =" + STR$(h)

DIM k AS LONG
DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    CLS , _RGB32(10, 10, 20)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 10, 20)
    LOCATE 2, 3: PRINT "_DESKTOPHEIGHT cross-platform test"
    LOCATE 3, 3: PRINT STRING$(34, "-")
    LOCATE 5, 5: PRINT "_DESKTOPHEIGHT ="; h; "px"
    LOCATE 7, 5
    IF h > 0 THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 10, 20): PRINT "PASS - non-zero desktop height."
    ELSE
        COLOR _RGB32(255, 120, 120), _RGB32(10, 10, 20): PRINT "FAIL - returned 0."
    END IF
    COLOR _RGB32(200, 200, 200), _RGB32(10, 10, 20)
    LOCATE 9, 5: PRINT "Cross-check against your real screen resolution."
    LOCATE 11, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 30
LOOP
