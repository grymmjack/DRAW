SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "Key Code Tester - Press keys to see codes"

DO
    CLS
    COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0)

    PRINT "=== QB64-PE Key Code Tester ==="
    PRINT "Press modifier keys to see which codes register."
    PRINT "Press ESC to quit."
    PRINT

    PRINT "--- Ctrl keys ---"
    PRINT "  Left Ctrl  (100305): "; _KEYDOWN(100305)
    PRINT "  Right Ctrl (100306): "; _KEYDOWN(100306)
    PRINT

    PRINT "--- Shift keys ---"
    PRINT "  Left Shift  (100303): "; _KEYDOWN(100303)
    PRINT "  Right Shift (100304): "; _KEYDOWN(100304)
    PRINT

    PRINT "--- Alt keys ---"
    PRINT "  Left Alt  (100307): "; _KEYDOWN(100307)
    PRINT "  Right Alt (100308): "; _KEYDOWN(100308)
    PRINT

    PRINT "--- Super/Cmd/Win keys ---"
    PRINT "  Left Super/Cmd  (100311): "; _KEYDOWN(100311)
    PRINT "  Right Super/Cmd (100312): "; _KEYDOWN(100312)
    PRINT

    PRINT "--- GUI/Meta (SDL codes) ---"
    PRINT "  Left GUI   (100653): "; _KEYDOWN(100653)
    PRINT "  Right GUI  (100654): "; _KEYDOWN(100654)
    PRINT

    k& = _KEYHIT
    IF k& <> 0 THEN
        PRINT "Last _KEYHIT: "; k&
    END IF

    _DISPLAY
    _LIMIT 30
LOOP UNTIL _KEYDOWN(27)

SYSTEM
