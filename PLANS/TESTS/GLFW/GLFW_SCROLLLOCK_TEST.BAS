'======================================================================
' GLFW_SCROLLLOCK_TEST.BAS — verify _SCROLLLOCK (function/read) cross-platform
'
' IMPORTANT (per a740g): the _SCROLLLOCK *function* (read) works on all
' platforms; the _SCROLLLOCK *statement* (set: ON/OFF/_TOGGLE) is WINDOWS-ONLY
' by design. So on Linux/macOS, test by pressing the PHYSICAL Scroll Lock key
' and watching the reading flip. The O/F/T setters below do nothing on
' Linux/macOS (that is expected, not a bug).
'
' Build/run: make a740g-run TEST=SCROLLLOCK
' Wiki (function): https://qb64phoenix.com/qb64wiki/index.php/_SCROLLLOCK_(function)
'
' PASS (Linux/macOS/Windows): pressing the PHYSICAL Scroll Lock key flips the
' "value% = _SCROLLLOCK" reading and bumps the change counter.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(660, 400, 32)
_TITLE "GLFW Test: _SCROLLLOCK (read)"

DIM k AS LONG
DIM st AS INTEGER
DIM prev AS INTEGER
DIM changes AS LONG
prev% = _SCROLLLOCK ' read via the % (INTEGER) form, exactly as a740g specified
changes = 0

_ECHO "GLFW_SCROLLLOCK_TEST: press the PHYSICAL Scroll Lock key; watch the reading."

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    SELECT CASE k
        ' Setter form is WINDOWS-ONLY (no effect on Linux/macOS):
        CASE ASC("o"), ASC("O"): _SCROLLLOCK ON
        CASE ASC("f"), ASC("F"): _SCROLLLOCK OFF
        CASE ASC("t"), ASC("T"): _SCROLLLOCK _TOGGLE
        CASE 27: SYSTEM
    END SELECT

    st% = _SCROLLLOCK ' function/read via % form (a740g: value% = _SCROLLLOCK)
    IF st% <> prev% THEN changes = changes + 1: prev% = st%

    CLS , _RGB32(10, 10, 20)
    COLOR _RGB32(255, 255, 255), _RGB32(10, 10, 20)
    LOCATE 2, 3: PRINT "_SCROLLLOCK (function / read) cross-platform test"
    LOCATE 3, 3: PRINT STRING$(50, "-")
    LOCATE 5, 5: PRINT "value% = _SCROLLLOCK : ";
    IF st% THEN
        COLOR _RGB32(120, 255, 120), _RGB32(10, 10, 20): PRINT "ON "
    ELSE
        COLOR _RGB32(255, 160, 120), _RGB32(10, 10, 20): PRINT "OFF"
    END IF
    COLOR _RGB32(255, 255, 120), _RGB32(10, 10, 20)
    LOCATE 7, 5: PRINT ">> Press the PHYSICAL Scroll Lock key and watch the value flip."
    COLOR _RGB32(220, 220, 220), _RGB32(10, 10, 20)
    LOCATE 8, 5: PRINT "   Reading changed this many times: "; changes
    LOCATE 10, 5: PRINT "PASS = the value tracks your physical Scroll Lock key."
    LOCATE 12, 5: PRINT "O/F/T set ON/OFF/_TOGGLE -- WINDOWS ONLY (no effect here)."
    LOCATE 14, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
