''
' DRAW - CORE/HELP.BI
' =============================================================================
' Early-exit handler for --help / --version command-line flags.
'
' Scans COMMAND$ at include time, prints a usage banner (or version) to the
' console, and calls SYSTEM before any graphics, paths, or config side
' effects fire. Must be included AFTER _COMMON.BI (for APP_VERSION$, TRUE/
' FALSE, $CONSOLE) but BEFORE CORE/PATHS.BI (which creates directories) and
' OUTPUT/SCREEN.BI (which opens the graphics window).
'
' Aliases supported:
'   --help, -h, /?, -?, /h, /help
'   --version, -v
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM HELP_idx%
DIM HELP_arg$
DIM HELP_showHelp%
DIM HELP_showVer%

HELP_showHelp% = FALSE
HELP_showVer%  = FALSE
HELP_idx%      = 1

DO WHILE HELP_idx% <= _COMMANDCOUNT
    HELP_arg$ = LCASE$(_TRIM$(COMMAND$(HELP_idx%)))
    SELECT CASE HELP_arg$
        CASE "--help", "-h", "/?", "-?", "/h", "/help"
            HELP_showHelp% = TRUE
            EXIT DO
        CASE "--version", "-v"
            HELP_showVer% = TRUE
            EXIT DO
    END SELECT
    HELP_idx% = HELP_idx% + 1
LOOP

IF HELP_showHelp% OR HELP_showVer% THEN
    _CONSOLE ON
    _DEST _CONSOLE
    IF HELP_showVer% THEN
        PRINT "DRAW " + APP_VERSION$
    ELSE
        CLI_print_help ' CORE/CLI.BM: colored page (+ ASSETS/DRAW.ans logo when present)
    END IF
    SYSTEM
END IF
