'======================================================================
' GLFW_KEYCODE_TEST.BAS — live _KEYDOWN / _KEYHIT physical keycode scanner
'
' WHY THIS EXISTS:
'   When DRAW is built with a740g's GLFW backend, Ctrl+Alt+O stops firing.
'   _KEYDOWN physical codes are BACKEND-specific, and the QB64-PE wiki for
'   _KEYDOWN literally says: "Use _KEYHIT to find the key codes to be
'   monitored by _KEYDOWN." This tool does exactly that, live, and surfaces
'   the exact booleans DRAW's Ctrl+Alt+O check depends on so we can see
'   which one changed under GLFW vs SDL2.
'
' HOW TO DIAGNOSE:
'   Build & run with a740g:   make a740g-run TEST=KEYCODE
'   Compare vs SDL2 (v450):   make a740g-run TEST=KEYCODE QB64PE=$HOME/git/qb64pe-450/qb64pe
'   Focus the window, HOLD Ctrl+Alt, tap O. Watch the "Ctrl+Alt+O FIRES"
'   line and the named code rows under each compiler. Also try ./ , Up/Down
'   and Ctrl+B to scope whether the breakage is broad or letter-only.
'
'   Close the window (X / Alt+F4) to quit — ESC is intentionally NOT a quit
'   key here so the scanner can observe ESC (code 27) like any other key.
'
' Wiki: https://qb64phoenix.com/qb64wiki/index.php/_KEYDOWN
'======================================================================
$CONSOLE
OPTION _EXPLICIT

CONST TRUE = -1
CONST FALSE = 0

SCREEN _NEWIMAGE(900, 640, 32)
_TITLE "GLFW keycode scanner — close window to quit"

' --- state (hoisted; OPTION _EXPLICIT) ---
DIM khist(1 TO 10) AS LONG          ' ring buffer of recent _KEYHIT values
DIM k AS LONG, j AS INTEGER, c AS LONG, ei AS INTEGER, shown AS INTEGER
DIM ctrlDown AS INTEGER, altDown AS INTEGER, shiftDown AS INTEGER
DIM o111 AS INTEGER, o79 AS INTEGER, o15 AS INTEGER, fires AS INTEGER
DIM ds AS STRING, hs AS STRING

' --- curated 2-byte extended codes (from the _KEYDOWN wiki table) ---
DIM extCode(1 TO 24) AS LONG
DIM extName(1 TO 24) AS STRING
DIM ne AS INTEGER
DIM cc AS LONG, nm AS STRING
ne = 0
RESTORE extdata
DO
    READ nm
    IF nm = "END" THEN EXIT DO
    READ cc
    ne = ne + 1
    extCode(ne) = cc
    extName(ne) = nm
LOOP

_ECHO "GLFW keycode scanner started. Hold Ctrl+Alt and tap O; watch the rows."

DO
    IF _EXIT THEN SYSTEM

    ' Drain all _KEYHIT events this frame into the ring buffer (newest at 1).
    DO
        k = _KEYHIT
        IF k = 0 THEN EXIT DO
        FOR j = 10 TO 2 STEP -1: khist(j) = khist(j - 1): NEXT
        khist(1) = k
    LOOP

    ' The exact inputs DRAW's Ctrl+Alt+O detection reads.
    ctrlDown = (_KEYDOWN(100305) OR _KEYDOWN(100306))
    altDown = (_KEYDOWN(100307) OR _KEYDOWN(100308))
    shiftDown = (_KEYDOWN(100303) OR _KEYDOWN(100304))
    o111 = _KEYDOWN(111)
    o79 = _KEYDOWN(79)
    o15 = _KEYDOWN(15)
    fires = (ctrlDown AND altDown AND (NOT shiftDown) AND (o111 OR o79))

    CLS , _RGB32(8, 8, 16)
    COLOR _RGB32(255, 255, 255), _RGB32(8, 8, 16)
    LOCATE 1, 2: PRINT "GLFW _KEYDOWN / _KEYHIT SCANNER      (close window to quit)"
    LOCATE 2, 2: PRINT STRING$(74, "-")

    COLOR _RGB32(120, 220, 255), _RGB32(8, 8, 16)
    LOCATE 4, 2: PRINT "DRAW Ctrl+Alt+O inputs (KEYBOARD.BM:3391 / MODIFIERS.BM):"
    COLOR _RGB32(255, 255, 255), _RGB32(8, 8, 16)
    LOCATE 5, 4: PRINT "CTRL  = "; onoff$(ctrlDown); "   [100305="; yn$(_KEYDOWN(100305)); " 100306="; yn$(_KEYDOWN(100306)); "]"
    LOCATE 6, 4: PRINT "ALT   = "; onoff$(altDown); "   [100307="; yn$(_KEYDOWN(100307)); " 100308="; yn$(_KEYDOWN(100308)); "]"
    LOCATE 7, 4: PRINT "SHIFT = "; onoff$(shiftDown); "   [100303="; yn$(_KEYDOWN(100303)); " 100304="; yn$(_KEYDOWN(100304)); "]"
    LOCATE 8, 4: PRINT "O key : 111(o)="; yn$(o111); "   79(O)="; yn$(o79); "   15(^O)="; yn$(o15)

    IF fires THEN COLOR _RGB32(120, 255, 120), _RGB32(8, 8, 16) ELSE COLOR _RGB32(255, 230, 90), _RGB32(8, 8, 16)
    LOCATE 10, 4: PRINT "Ctrl+Alt+O FIRES (DRAW logic) = "; onoff$(fires); "        "

    COLOR _RGB32(180, 255, 180), _RGB32(8, 8, 16)
    LOCATE 12, 4: PRINT "Recent _KEYHIT (newest first; negative = key release):"
    hs = ""
    FOR j = 1 TO 10
        IF khist(j) <> 0 THEN hs = hs + LTRIM$(STR$(khist(j))) + " "
    NEXT
    COLOR _RGB32(255, 255, 255), _RGB32(8, 8, 16)
    LOCATE 13, 6: PRINT hs; SPACE$(50)

    ' Build the list of every currently-down code. NOTE: _KEYDOWN(0) is an
    ' ILLEGAL FUNCTION CALL (the code must be POSITIVE) — it raises runtime
    ' error 5 every frame — so start at 1. We also scan only the gap-free
    ' virtual-key ranges the wiki defines; undefined codes in the gaps can
    ' likewise raise error 5, so we avoid them.
    ds = ""
    shown = 0
    FOR c = 1 TO 255 ' ASCII / extended (0 is illegal for _KEYDOWN)
        IF _KEYDOWN(c) THEN ds = ds + LTRIM$(STR$(c)) + " ": shown = shown + 1
    NEXT
    IF _KEYDOWN(100019) THEN ds = ds + "100019 ": shown = shown + 1 ' Pause
    FOR c = 100256 TO 100271 ' keypad 0-9 . / * - + Enter
        IF _KEYDOWN(c) THEN ds = ds + LTRIM$(STR$(c)) + " ": shown = shown + 1
    NEXT
    FOR c = 100300 TO 100322 ' locks, modifiers, meta, super, etc.
        IF _KEYDOWN(c) THEN ds = ds + LTRIM$(STR$(c)) + " ": shown = shown + 1
    NEXT
    FOR c = 200000 TO 200012 ' keypad navigation / edit
        IF _KEYDOWN(c) THEN ds = ds + LTRIM$(STR$(c)) + " ": shown = shown + 1
    NEXT
    FOR ei = 1 TO ne ' curated 2-byte extended (arrows / F-keys / etc.)
        IF _KEYDOWN(extCode(ei)) THEN ds = ds + extName(ei) + "(" + LTRIM$(STR$(extCode(ei))) + ") ": shown = shown + 1
    NEXT

    COLOR _RGB32(255, 200, 120), _RGB32(8, 8, 16)
    LOCATE 15, 4: PRINT "Currently DOWN codes ("; LTRIM$(STR$(shown)); "):                 "
    COLOR _RGB32(255, 255, 255), _RGB32(8, 8, 16)
    LOCATE 16, 6: PRINT LEFT$(ds + SPACE$(120), 120)

    COLOR _RGB32(170, 170, 170), _RGB32(8, 8, 16)
    LOCATE 22, 4: PRINT "Diagnose: hold Ctrl+Alt, tap O. If CTRL/ALT show ON but 111/79"
    LOCATE 23, 4: PRINT "are both n (maybe 15 lights up) -> the LETTER code changed under GLFW."
    LOCATE 24, 4: PRINT "If CTRL/ALT themselves read off -> the MODIFIER codes changed."

    _DISPLAY
    _LIMIT 60
LOOP

extdata:
DATA "Up", 18432, "Down", 20480, "Left", 19200, "Right", 19712
DATA "Home", 18176, "End", 20224, "PgUp", 18688, "PgDn", 20736
DATA "Ins", 20992, "Del", 21248
DATA "F1", 15104, "F2", 15360, "F3", 15616, "F4", 15872, "F5", 16128, "F6", 16384
DATA "F7", 16640, "F8", 16896, "F9", 17152, "F10", 17408, "F11", 34048, "F12", 34304
DATA "END", 0

FUNCTION yn$ (v AS INTEGER)
    DIM r AS STRING
    IF v THEN r = "Y" ELSE r = "n"
    yn$ = r
END FUNCTION

FUNCTION onoff$ (v AS INTEGER)
    DIM r AS STRING
    IF v THEN r = "ON " ELSE r = "off"
    onoff$ = r
END FUNCTION
