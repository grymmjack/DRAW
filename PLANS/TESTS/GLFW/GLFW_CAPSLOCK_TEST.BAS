'======================================================================
' GLFW_CAPSLOCK_TEST.BAS — verify _CAPSLOCK works cross-platform (a740g)
'
' _CAPSLOCK is TWO keywords:
'   * function : state% = _CAPSLOCK          (reads current lock state)
'   * statement: _CAPSLOCK ON|OFF|_TOGGLE    (sets the lock LED)
' Pre-a740g it was Windows-only ("Not supported on Linux/macOS").
'
' Build/run: make a740g-run TEST=CAPSLOCK
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_CAPSLOCK
'
' PASS when, on Linux/macOS/Windows: the displayed state tracks the physical
' Caps Lock LED, AND O/F/T set it both on screen and on the keyboard LED.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(640, 360, 32)
_TITLE "GLFW Test: _CAPSLOCK"

DIM k AS LONG
DIM st AS INTEGER

_ECHO "GLFW_CAPSLOCK_TEST: reading _CAPSLOCK on this platform."

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    SELECT CASE k
        CASE ASC("o"), ASC("O"): _CAPSLOCK ON
        CASE ASC("f"), ASC("F"): _CAPSLOCK OFF
        CASE ASC("t"), ASC("T"): _CAPSLOCK _TOGGLE
        CASE 27: SYSTEM
    END SELECT

    st = _CAPSLOCK ' function form: current lock state

    CLS , _RGB32(10, 10, 20)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 10, 20)
    LOCATE 2, 3: PRINT "_CAPSLOCK cross-platform test"
    LOCATE 3, 3: PRINT STRING$(40, "-")
    LOCATE 5, 5: PRINT "Current state (function _CAPSLOCK): ";
    IF st THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 10, 20): PRINT "ON "
    ELSE
        COLOR _RGB32(255, 160, 120), _RGB32(10, 10, 20): PRINT "OFF"
    END IF
    COLOR _RGB32(220, 220, 220), _RGB32(10, 10, 20)
    LOCATE 7, 5: PRINT "O = set ON      F = set OFF      T = _TOGGLE"
    LOCATE 8, 5: PRINT "...or press the physical Caps Lock key."
    LOCATE 10, 5: PRINT "Watch: does the keyboard LED match the state above?"
    LOCATE 12, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
