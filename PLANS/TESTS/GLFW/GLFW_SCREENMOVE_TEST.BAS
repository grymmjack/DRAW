'======================================================================
' GLFW_SCREENMOVE_TEST.BAS — verify _SCREENMOVE cross-platform (a740g)
'
'   _SCREENMOVE x, y     position the window's top-left at x,y
'   _SCREENMOVE _MIDDLE  center the window on the desktop
' Pre-a740g _SCREENMOVE did NOT work on Linux. To confirm the move actually
' happened we read _SCREENX/_SCREENY back after each move.
'
' Build/run: make a740g-run TEST=SCREENMOVE
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_SCREENMOVE
'
' PASS when, on Linux/macOS/Windows: the window jumps to each position AND the
' reported X,Y update to match.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(580, 340, 32)
_TITLE "GLFW Test: _SCREENMOVE"

DIM k AS LONG
DIM lastAction AS STRING
lastAction = "(none yet)"

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    SELECT CASE k
        CASE ASC("1"): _SCREENMOVE 0, 0: lastAction = "_SCREENMOVE 0, 0"
        CASE ASC("2"): _SCREENMOVE 200, 150: lastAction = "_SCREENMOVE 200, 150"
        CASE ASC("3"): _SCREENMOVE 600, 400: lastAction = "_SCREENMOVE 600, 400"
        CASE ASC("m"), ASC("M"): _SCREENMOVE _MIDDLE: lastAction = "_SCREENMOVE _MIDDLE"
        CASE 27: SYSTEM
    END SELECT

    CLS , _RGB32(10, 12, 22)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 12, 22)
    LOCATE 2, 3: PRINT "_SCREENMOVE cross-platform test"
    LOCATE 3, 3: PRINT STRING$(44, "-")
    LOCATE 5, 5: PRINT "Last action: "; lastAction
    LOCATE 7, 5: PRINT "Window now at  _SCREENX ="; _SCREENX; "  _SCREENY ="; _SCREENY
    LOCATE 9, 5: PRINT "1 = move 0,0     2 = move 200,150     3 = move 600,400"
    LOCATE 10, 5: PRINT "M = center (_MIDDLE)"
    LOCATE 12, 5: PRINT "PASS when the window jumps AND X,Y above update to match."
    LOCATE 14, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
