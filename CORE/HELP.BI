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
        PRINT "DRAW " + APP_VERSION$ + " - Pixel art editor (QB64-PE)"
        PRINT
        PRINT "Usage: DRAW [file] [options]"
        PRINT
        PRINT "Positional:"
        PRINT "  file                      Open .draw, .ase, .psd, or raster image at startup"
        PRINT
        PRINT "Options:"
        PRINT "  -h, --help, /?            Show this help and exit"
        PRINT "      -?, /h, /help         (aliases for --help)"
        PRINT "  -v, --version             Show version and exit"
        PRINT "  -c, --config <path>       Use a specific config file"
        PRINT "      --config-upgrade      Reconcile config with new defaults"
        PRINT "      --reset-defaults      Restore factory configuration"
        PRINT "      --canvas-size WxH     Override startup canvas size (e.g. 320x200)"
        PRINT "      --portable            Keep config/data beside the executable"
        PRINT "      --perf                Enable render-pipeline profiling (logs to DRAW.log)"
        PRINT
        PRINT "Examples:"
        PRINT "  DRAW myproject.draw"
        PRINT "  DRAW --config DRAW.linux.cfg"
        PRINT "  DRAW --canvas-size 64x64"
        PRINT
        PRINT "Docs: https://github.com/grymmjack/DRAW"
    END IF
    SYSTEM
END IF
