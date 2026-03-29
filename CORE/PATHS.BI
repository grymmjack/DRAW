''
' DRAW - CORE/PATHS.BI
' =============================================================================
' Cross-platform OS-native path resolution for user config, data, and cache.
'
' Linux:   XDG_CONFIG_HOME / XDG_DATA_HOME / XDG_CACHE_HOME (fallback ~/.config, etc.)
' macOS:   ~/Library/Application Support/DRAW/ and ~/Library/Caches/DRAW/
' Windows: %APPDATA%\DRAW\ and %LOCALAPPDATA%\DRAW\Cache\
'
' Supports --portable CLI flag to keep all files beside the executable.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST PATHS_APP_NAME$ = "DRAW"

' Resolved directory paths (set by PATHS_init, always end with separator)
DIM SHARED PATHS_CONFIG_DIR$   ' Config files (DRAW.cfg, font blacklist/favorites)
DIM SHARED PATHS_DATA_DIR$     ' User data (drawer sets, palettes, text styles, fonts)
DIM SHARED PATHS_CACHE_DIR$    ' Cache/temp files (scan tmps, lospec tmps, music list)
DIM SHARED PATHS_PORTABLE%     ' TRUE when --portable flag was passed
DIM SHARED PATHS_INITIALIZED%  ' TRUE after PATHS_init has run

' Set defaults to CWD (overridden by PATHS_init for native mode)
PATHS_CONFIG_DIR$ = ""
PATHS_DATA_DIR$ = ""
PATHS_CACHE_DIR$ = ""
PATHS_PORTABLE% = FALSE
PATHS_INITIALIZED% = FALSE

DECLARE SUB PATHS_init ()
DECLARE FUNCTION PATHS_config$ (filename$)
DECLARE FUNCTION PATHS_data$ (filename$)
DECLARE FUNCTION PATHS_cache$ (filename$)
DECLARE SUB PATHS_ensure_dir (dirPath$)
DECLARE SUB PATHS_migrate ()

' Parse --portable from command line at include time (before CONFIG.BI runs)
DIM PATHS_cmdIdx%
DIM PATHS_cmdVal$
PATHS_cmdIdx% = 1
DO WHILE PATHS_cmdIdx% <= _COMMANDCOUNT
    PATHS_cmdVal$ = LCASE$(_TRIM$(COMMAND$(PATHS_cmdIdx%)))
    IF PATHS_cmdVal$ = "--portable" THEN
        PATHS_PORTABLE% = TRUE
        EXIT DO
    END IF
    PATHS_cmdIdx% = PATHS_cmdIdx% + 1
LOOP

' Initialize paths immediately (before CONFIG.BI needs them)
PATHS_init
