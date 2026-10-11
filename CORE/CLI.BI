''
' DRAW - CORE/CLI.BI
' =============================================================================
' Command-line console output helpers: ANSI colors (off when NO_COLOR is set,
' with --no-color, on a "dumb" TERM, or when stdout is not a terminal - so
' `vim $(DRAW --cfg)` and pipes get plain text), the colored --help page, and
' an optional ANSI-art logo (ASSETS/DRAW.ans, CP437 -> UTF-8, SAUCE stripped)
' printed above it.
'
' Included before CORE/HELP.BI (which runs at include time).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE LIBRARY "../native/cli_tty"
    FUNCTION gj_stdout_isatty& ()
    FUNCTION gj_console_prepare& ()
END DECLARE

' [Linux] 1 = $DISPLAY's X server answers, 0 = it doesn't, -1 = can't tell
' (SCREEN_init's no-display guard; native/display_probe.h)
DECLARE LIBRARY "../native/display_probe"
    FUNCTION gj_x11_display_reachable& ()
END DECLARE

DIM SHARED CLI_COLOR_STATE AS INTEGER ' 0 = not decided yet, 1 = on, -1 = off
