'======================================================================
' GLFW_WINDOWHASFOCUS_TEST.BAS — verify _WINDOWHASFOCUS cross-platform (a740g)
'
'   _WINDOWHASFOCUS returns -1 (true) when this program's window has focus.
' Pre-a740g: Windows & Linux only (NOT macOS) — this test answers macOS.
'
' Build/run: make a740g-run TEST=WINDOWHASFOCUS
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_WINDOWHASFOCUS
'
' PASS when, on Linux/macOS/Windows: clicking another window shows FALSE and
' clicking back on this window shows TRUE.
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(580, 320, 32)
_TITLE "GLFW Test: _WINDOWHASFOCUS"

DIM k AS LONG
DIM hasFocus AS INTEGER
DIM sawFalse AS INTEGER
DIM sawTrue AS INTEGER
sawFalse = FALSE
sawTrue = FALSE

DO
    IF _EXIT THEN SYSTEM
    k = _KEYHIT
    IF k = 27 THEN SYSTEM

    hasFocus = _WINDOWHASFOCUS
    IF hasFocus THEN sawTrue = TRUE ELSE sawFalse = TRUE

    IF hasFocus THEN CLS , _RGB32(0, 50, 0) ELSE CLS , _RGB32(50, 0, 0)
    COLOR _RGB32(255, 255, 255), 0
    LOCATE 2, 3: PRINT "_WINDOWHASFOCUS cross-platform test"
    LOCATE 3, 3: PRINT STRING$(40, "-")
    LOCATE 5, 5: PRINT "_WINDOWHASFOCUS = ";
    IF hasFocus THEN
        COLOR _RGB32(120, 255, 120), 0: PRINT "TRUE  (focused)  "
    ELSE
        COLOR _RGB32(255, 150, 150), 0: PRINT "FALSE (background)"
    END IF
    COLOR _RGB32(220, 220, 220), 0
    LOCATE 7, 5: PRINT "Click another window, then click back here."
    LOCATE 9, 5: PRINT "Seen FALSE: ";
    IF sawFalse THEN PRINT "yes" ELSE PRINT "no "
    LOCATE 10, 5: PRINT "Seen TRUE : ";
    IF sawTrue THEN PRINT "yes" ELSE PRINT "no "
    LOCATE 11, 5: PRINT "PASS when both are 'yes'."
    LOCATE 13, 5: PRINT "ESC or close window = quit"
    _DISPLAY
    _LIMIT 60
LOOP
