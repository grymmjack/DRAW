$CONSOLE:ONLY
_SCREENHIDE

CONST KEY_LALT& = 100308
CONST KEY_RALT& = 100307

PRINT "Testing ALT key detection..."
PRINT "Press Left ALT, Right ALT, or ALT+P"
PRINT "Press ESC to exit"
PRINT ""

DO
    _LIMIT 30
    
    ' Check for ALT keys
    IF _KEYDOWN(KEY_LALT&) THEN
        PRINT "Left ALT is DOWN"
    END IF
    
    IF _KEYDOWN(KEY_RALT&) THEN
        PRINT "Right ALT is DOWN"
    END IF
    
    ' Check for ALT+P combination
    IF (_KEYDOWN(KEY_LALT&) OR _KEYDOWN(KEY_RALT&)) AND _KEYDOWN(112) THEN ' 112 is lowercase 'p'
        PRINT "ALT+P detected!"
    END IF
    
    ' Also try with INKEY$ to see what we get
    k$ = INKEY$
    IF k$ <> "" THEN
        PRINT "INKEY$: '"; k$; "' ASCII:"; ASC(k$)
    END IF
    
    ' ESC to exit
    IF _KEYDOWN(27) THEN EXIT DO
LOOP

PRINT ""
PRINT "Test complete."
END
