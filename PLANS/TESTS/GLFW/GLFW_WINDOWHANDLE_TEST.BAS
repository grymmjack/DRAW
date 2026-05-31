'======================================================================
' GLFW_WINDOWHANDLE_TEST.BAS — verify _WINDOWHANDLE cross-platform (a740g)
'
'   h&& = _WINDOWHANDLE  returns the OS window handle (an _INTEGER64). On
'   Windows this is the HWND used for user32 API calls. Pre-a740g it was
'   Windows-only (0 / unsupported elsewhere); a740g returns the GLFW/X11/
'   Cocoa window handle on Linux/macOS too. We can't portably USE the handle,
'   only confirm a real one exists.
'
' Build/run: make a740g-run TEST=WINDOWHANDLE
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_WINDOWHANDLE
'
' PASS when, on Linux/macOS/Windows: the handle is non-zero.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(600, 280, 32)
_TITLE "GLFW Test: _WINDOWHANDLE"

DIM h AS _INTEGER64
h = _WINDOWHANDLE
_ECHO "GLFW_WINDOWHANDLE_TEST: _WINDOWHANDLE =" + STR$(h)

DIM k AS LONG
DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    CLS , _RGB32(10, 10, 20)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 10, 20)
    LOCATE 2, 3: PRINT "_WINDOWHANDLE cross-platform test"
    LOCATE 3, 3: PRINT STRING$(38, "-")
    LOCATE 5, 5: PRINT "_WINDOWHANDLE ="; h
    LOCATE 7, 5
    IF h <> 0 THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 10, 20): PRINT "PASS - non-zero window handle."
    ELSE
        COLOR _RGB32(255, 120, 120), _RGB32(10, 10, 20): PRINT "FAIL - handle is 0 (unsupported on this platform)."
    END IF
    COLOR _RGB32(200, 200, 200), _RGB32(10, 10, 20)
    LOCATE 9, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 30
LOOP
