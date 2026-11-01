' Standalone check of native/display_probe.h (gj_x11_display_reachable).
'   DISPLAY=:98 ./display-probe.run  -> 0 (no X server)
'   (under xvfb-run)                 -> 1
$CONSOLE:ONLY
OPTION _EXPLICIT
ON ERROR GOTO EH
DECLARE LIBRARY "../../native/display_probe"
    FUNCTION gj_x11_display_reachable% ()
END DECLARE
PRINT "DISPLAY=" + ENVIRON$("DISPLAY") + " reachable=" + _TRIM$(STR$(gj_x11_display_reachable%))
SYSTEM 0
EH:
PRINT "trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
SYSTEM 1
