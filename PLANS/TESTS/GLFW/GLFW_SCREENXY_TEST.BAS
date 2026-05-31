'======================================================================
' GLFW_SCREENXY_TEST.BAS — verify _SCREENX / _SCREENY cross-platform (a740g)
'
'   _SCREENX / _SCREENY return the window's top-left position on the desktop.
' (Paired: "window position" is one unit.) Pre-a740g these were Windows-only.
'
' Build/run: make a740g-run TEST=SCREENXY
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_SCREENX
'
' PASS when, on Linux/macOS/Windows: dragging the window updates the reported
' X,Y live (the "values changed since start" flag flips to YES).
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(580, 340, 32)
_TITLE "GLFW Test: _SCREENX / _SCREENY"

DIM k AS LONG
DIM sx AS LONG, sy AS LONG
DIM x0 AS LONG, y0 AS LONG
DIM moved AS INTEGER
x0 = _SCREENX
y0 = _SCREENY
moved = FALSE
_ECHO "GLFW_SCREENXY_TEST: start position" + STR$(x0) + "," + STR$(y0)

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    sx = _SCREENX
    sy = _SCREENY
    IF sx <> x0 OR sy <> y0 THEN moved = TRUE

    CLS , _RGB32(10, 12, 22)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 12, 22)
    LOCATE 2, 3: PRINT "_SCREENX / _SCREENY cross-platform test"
    LOCATE 3, 3: PRINT STRING$(44, "-")
    LOCATE 5, 5: PRINT "Start position:  "; x0; ","; y0
    LOCATE 6, 5: PRINT "Live position:   "; sx; ","; sy; "        "
    LOCATE 8, 5: PRINT "Drag this window around with the mouse."
    LOCATE 10, 5: PRINT "Values changed since start: ";
    IF moved THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 12, 22): PRINT "YES - PASS"
    ELSE
        COLOR _RGB32(255, 200, 120), _RGB32(10, 12, 22): PRINT "not yet"
    END IF
    COLOR _RGB32(200, 200, 200), _RGB32(10, 12, 22)
    LOCATE 12, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
