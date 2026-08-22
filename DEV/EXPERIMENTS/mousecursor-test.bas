' mousecursor-test.bas — verify hardware custom image cursor (_MOUSECURSOR) on
' QB64-PE GLFW PR #701. Builds a distinctive image and installs it as the OS
' cursor with a hotspot. Logs success to mousecursor-test-log.txt.
' Compile with the GLFW build (branch GLFW, PR #701):
'   ~/git/qb64pe-a740g-test/qb64pe -w -x -o mousecursor-test DEV/EXPERIMENTS/mousecursor-test.bas
'   ./mousecursor-test
' Syntax: _MOUSECURSOR imageHandle& [, (hotspotX&, hotspotY&)]
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0

SCREEN _NEWIMAGE(560, 360, 32)
_TITLE "Custom Cursor Test — PR #701 GLFW"

' Build a distinctive 24x24 cursor: red X + green ring, hotspot at center (12,12).
DIM cur AS LONG, oldDest AS LONG
cur = _NEWIMAGE(24, 24, 32)
oldDest = _DEST
_DEST cur
CLS , _RGBA32(0, 0, 0, 0)
LINE (0, 0)-(23, 23), _RGB32(255, 0, 0)
LINE (23, 0)-(0, 23), _RGB32(255, 0, 0)
CIRCLE (12, 12), 11, _RGB32(0, 255, 0)
_DEST oldDest

' Install it as the hardware cursor with a centered hotspot.
_MOUSECURSOR cur, (12, 12)

DIM fh AS INTEGER
fh = FREEFILE: OPEN "mousecursor-test-log.txt" FOR OUTPUT AS #fh
PRINT #fh, "=== mousecursor-test  OS="; _OS$; "  session="; ENVIRON$("XDG_SESSION_TYPE"); " ==="
PRINT #fh, "cursor image handle="; cur; "  set OK (no runtime error trapped)"
CLOSE #fh

DO
    CLS , _RGB32(20, 24, 40)
    COLOR _RGB32(120, 200, 255), 0
    _PRINTSTRING (18, 20), "CUSTOM HARDWARE CURSOR TEST (PR #701)"
    COLOR _RGB32(230, 230, 230), 0
    _PRINTSTRING (18, 60), "Move the mouse over this window."
    _PRINTSTRING (18, 80), "The pointer should be a RED X inside a GREEN ring."
    _PRINTSTRING (18, 120), "mouse x,y : " + _TRIM$(STR$(_MOUSEX)) + " , " + _TRIM$(STR$(_MOUSEY))
    COLOR _RGB32(255, 140, 140), 0
    _PRINTSTRING (18, 320), "Press ESC to quit."
    _DISPLAY
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)
SYSTEM
