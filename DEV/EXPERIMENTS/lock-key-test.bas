' lock-key-test.bas — verify _CAPSLOCK / _NUMLOCK / _SCROLLLOCK on Wayland.
' Repro for BUG 1 in PLANS/GLFW-PR701-TEST-RESULTS.md (QB64-PE GLFW PR #701):
' on a Wayland session the lock-key events reach the window but _CAPSLOCK /
' _NUMLOCK / _SCROLLLOCK never leave 0. Logs every keypress + lock state to
' lock-key-test-log.txt (in the working dir) so results can be read back.
' Compile with the GLFW build (branch GLFW, PR #701):
'   ~/git/qb64pe-a740g-test/qb64pe -w -x -o lock-key-test DEV/EXPERIMENTS/lock-key-test.bas
'   ./lock-key-test
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0

SCREEN _NEWIMAGE(600, 380, 32)
_TITLE "Lock Key Test — PR #701 GLFW"

DIM session AS STRING, waylandDisp AS STRING
session = ENVIRON$("XDG_SESSION_TYPE")
waylandDisp = ENVIRON$("WAYLAND_DISPLAY")
IF session = "" THEN session = "(unset)"

DIM caps AS INTEGER, num AS INTEGER, scroll AS INTEGER, foc AS INTEGER
DIM keyEvents AS LONG, lastKey AS LONG, k AS LONG
DIM everCaps AS INTEGER, everNum AS INTEGER, everScroll AS INTEGER
DIM pCaps AS INTEGER, pNum AS INTEGER, pScroll AS INTEGER, pFoc AS INTEGER
DIM frame AS LONG, fh AS INTEGER
pCaps = -2: pNum = -2: pScroll = -2: pFoc = -2

fh = FREEFILE
OPEN "lock-key-test-log.txt" FOR OUTPUT AS #fh
PRINT #fh, "=== lock-key-test start  OS="; _OS$; "  session="; session; "  wayland="; waylandDisp; " ==="
CLOSE #fh

DO
    frame = frame + 1

    ' drain the key buffer; log each key event so we can prove input arrives
    DO
        k = _KEYHIT
        IF k = 0 THEN EXIT DO
        keyEvents = keyEvents + 1
        lastKey = k
        fh = FREEFILE: OPEN "lock-key-test-log.txt" FOR APPEND AS #fh
        PRINT #fh, "KEYEVENT frame="; frame; " code="; k; " (caps="; _CAPSLOCK; " num="; _NUMLOCK; " scroll="; _SCROLLLOCK; ")"
        CLOSE #fh
    LOOP

    caps = _CAPSLOCK: num = _NUMLOCK: scroll = _SCROLLLOCK
    foc = _WINDOWHASFOCUS
    IF caps THEN everCaps = TRUE
    IF num THEN everNum = TRUE
    IF scroll THEN everScroll = TRUE

    ' log any lock-state or focus change
    IF caps <> pCaps OR num <> pNum OR scroll <> pScroll OR foc <> pFoc THEN
        fh = FREEFILE: OPEN "lock-key-test-log.txt" FOR APPEND AS #fh
        PRINT #fh, "STATE   frame="; frame; " CAPS="; caps; " NUM="; num; " SCROLL="; scroll; " FOCUS="; foc; " keyEvents="; keyEvents
        CLOSE #fh
        pCaps = caps: pNum = num: pScroll = scroll: pFoc = foc
    END IF

    CLS , _RGB32(18, 20, 32)
    COLOR _RGB32(120, 200, 255), 0
    _PRINTSTRING (18, 16), "LOCK KEY TEST  (PR #701 GLFW build)"
    COLOR _RGB32(170, 170, 180), 0
    _PRINTSTRING (18, 40), "OS " + _OS$ + "   session=" + session + "   wayland=" + _IIF(waylandDisp = "", "no", waylandDisp)
    _PRINTSTRING (18, 58), "window focused: " + _IIF(foc, "YES", "no  (click the window first)")
    _PRINTSTRING (18, 76), "key events seen: " + _TRIM$(STR$(keyEvents)) + "   last key code: " + _TRIM$(STR$(lastKey))

    lockRow 18, 116, "CAPS   LOCK", caps, everCaps
    lockRow 18, 156, "NUM    LOCK", num, everNum
    lockRow 18, 196, "SCROLL LOCK", scroll, everScroll

    COLOR _RGB32(255, 230, 120), 0
    _PRINTSTRING (18, 250), "Focus this window, tap Caps / Num / Scroll Lock a few times,"
    _PRINTSTRING (18, 268), "then type a few letters. Everything is logged."
    COLOR _RGB32(255, 140, 140), 0
    _PRINTSTRING (18, 344), "Press ESC when done."

    _DISPLAY
    _LIMIT 30
LOOP UNTIL _KEYDOWN(27)

fh = FREEFILE: OPEN "lock-key-test-log.txt" FOR APPEND AS #fh
PRINT #fh, "=== end. frames="; frame; " keyEvents="; keyEvents; " everCaps="; everCaps; " everNum="; everNum; " everScroll="; everScroll; " ==="
CLOSE #fh
SYSTEM

SUB lockRow (atX AS INTEGER, atY AS INTEGER, label AS STRING, state AS INTEGER, everOn AS INTEGER)
    COLOR _RGB32(230, 230, 230), 0
    _PRINTSTRING (atX, atY), label + " :"
    IF state THEN
        COLOR _RGB32(40, 220, 90), 0
        _PRINTSTRING (atX + 130, atY), "ON  (-1)"
    ELSE
        COLOR _RGB32(230, 70, 70), 0
        _PRINTSTRING (atX + 130, atY), "off ( 0)"
    END IF
    COLOR _RGB32(140, 140, 150), 0
    _PRINTSTRING (atX + 250, atY), _IIF(everOn, "[seen ON once]", "")
END SUB
