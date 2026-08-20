' lock-key-a740g.bas — a740g's OWN minimal lock-key test, run verbatim on a
' Wayland session to give him a clean data point (his code, my environment).
' Only addition vs his snippet: append each lock-state change to a log file so
' the result can be read back without transcribing numbers off-screen.
' Compile with the GLFW build (branch GLFW, PR #701):
'   ~/git/qb64pe-a740g-test/qb64pe -w -x -o lock-key-a740g DEV/EXPERIMENTS/lock-key-a740g.bas
'   ./lock-key-a740g

' --- a740g's test, verbatim ---
'   WHILE _KEYHIT <> _KEY_ESC
'       LOCATE 1, 1: PRINT INT(TIMER); ": CAPS ="; _CAPSLOCK; "NUM ="; _NUMLOCK; "SCROLL ="; _SCROLLLOCK;
'       _LIMIT 60
'   WEND

DIM pC AS INTEGER, pN AS INTEGER, pS AS INTEGER, fh AS INTEGER
pC = -2: pN = -2: pS = -2

fh = FREEFILE: OPEN "lock-key-a740g-log.txt" FOR OUTPUT AS #fh
PRINT #fh, "=== a740g test  session="; ENVIRON$("XDG_SESSION_TYPE"); "  wayland="; ENVIRON$("WAYLAND_DISPLAY"); " ==="
CLOSE #fh

WHILE _KEYHIT <> _KEY_ESC
    LOCATE 1, 1: PRINT INT(TIMER); ": CAPS ="; _CAPSLOCK; "NUM ="; _NUMLOCK; "SCROLL ="; _SCROLLLOCK;
    IF _CAPSLOCK <> pC OR _NUMLOCK <> pN OR _SCROLLLOCK <> pS THEN
        fh = FREEFILE: OPEN "lock-key-a740g-log.txt" FOR APPEND AS #fh
        PRINT #fh, "CHANGE t="; INT(TIMER); " CAPS="; _CAPSLOCK; " NUM="; _NUMLOCK; " SCROLL="; _SCROLLLOCK
        CLOSE #fh
        pC = _CAPSLOCK: pN = _NUMLOCK: pS = _SCROLLLOCK
    END IF
    _LIMIT 60
WEND

fh = FREEFILE: OPEN "lock-key-a740g-log.txt" FOR APPEND AS #fh
PRINT #fh, "=== end (no CHANGE lines above = lock states never updated) ==="
CLOSE #fh
SYSTEM
