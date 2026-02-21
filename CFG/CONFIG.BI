''
' DRAW - CFG/CONFIG.BI
' =============================================================================
' UDT for configuration.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Default config filename (can be overridden by --config / -c command line arg)
CONST CONFIG_FILE_DEFAULT$ = "DRAW.cfg"

' Runtime config file path (set by command-line parsing below)
DIM SHARED CONFIG_FILE_PATH$
CONFIG_FILE_PATH$ = CONFIG_FILE_DEFAULT$

' Flag: TRUE if --config / -c was used (so DRAW.BAS skips those args for file open)
DIM SHARED CMDLINE_CONFIG_ARG_COUNT%
CMDLINE_CONFIG_ARG_COUNT% = 0

' Parse --config / -c from command line BEFORE CONFIG_load runs
' (CONFIG_load is called from SCREEN_init in SCREEN.BI, which is included after this)
DIM CONFIG_cmdArgIdx%
DIM CONFIG_cmdArgCount%
DIM CONFIG_cmdArgVal$
CONFIG_cmdArgCount% = _COMMANDCOUNT
CONFIG_cmdArgIdx% = 1
DO WHILE CONFIG_cmdArgIdx% <= CONFIG_cmdArgCount%
    CONFIG_cmdArgVal$ = _TRIM$(COMMAND$(CONFIG_cmdArgIdx%))
    IF LCASE$(CONFIG_cmdArgVal$) = "--config" OR LCASE$(CONFIG_cmdArgVal$) = "-c" THEN
        ' Found --config / -c flag
        IF CONFIG_cmdArgIdx% + 1 <= CONFIG_cmdArgCount% THEN
            ' Next argument is the config file path
            CONFIG_FILE_PATH$ = _TRIM$(COMMAND$(CONFIG_cmdArgIdx% + 1))
            ' Remove surrounding quotes if present
            IF LEFT$(CONFIG_FILE_PATH$, 1) = CHR$(34) AND RIGHT$(CONFIG_FILE_PATH$, 1) = CHR$(34) THEN
                CONFIG_FILE_PATH$ = MID$(CONFIG_FILE_PATH$, 2, LEN(CONFIG_FILE_PATH$) - 2)
            END IF
            CMDLINE_CONFIG_ARG_COUNT% = 2 ' --config + value = 2 args consumed

            ' Check if the specified config file exists
            IF NOT _FILEEXISTS(CONFIG_FILE_PATH$) THEN
                ' Prompt user: create it or exit?
                DIM CONFIG_msgResult%
                CONFIG_msgResult% = _MESSAGEBOX("Config File Not Found", _
                    "Config file not found:" + CHR$(10) + CHR$(10) + _
                    _CWD$ + "/" + CONFIG_FILE_PATH$ + CHR$(10) + CHR$(10) + _
                    "Create it with default settings?", "yesno", "warning")
                IF CONFIG_msgResult% = 1 THEN
                    ' User chose Yes - will be created by CONFIG_load with defaults
                    ' (CONFIG_load checks _FILEEXISTS and calls CONFIG_save if missing)
                ELSE
                    ' User chose No - exit program
                    SYSTEM
                END IF
            END IF
        ELSE
            ' --config / -c without a value - show error and exit
            DIM CONFIG_noValResult%
            CONFIG_noValResult% = _MESSAGEBOX("Missing Config Path", _
                "The --config / -c argument requires a file path." + CHR$(10) + CHR$(10) + _
                "Usage: DRAW --config DRAW.macOS.cfg" + CHR$(10) + _
                "       DRAW -c DRAW.linux.cfg", "ok", "error")
            SYSTEM
        END IF
        EXIT DO
    END IF
    CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 1
LOOP

TYPE DRAW_CONFIG
    THEME                          AS STRING
    FULLSCREEN                     AS INTEGER
    DISPLAY_SCALE                  AS INTEGER  ' 0=auto-detect, 1-8=explicit scale
    DISPLAY_SCALE_MAX              AS INTEGER  ' Maximum allowed scale (default 8)
    DISPLAY_SCALE_CHANGED          AS INTEGER  ' Runtime flag: scale changed during session
    TOOLBAR_SCALE                  AS INTEGER  ' Toolbar icon scale multiplier (1-4, default 1)
    NUDGE_N                        AS INTEGER
    NUM_CUSTOM_BRUSHES             AS INTEGER
    NUM_LAYERS                     AS INTEGER
    FPS_LIMIT                      AS INTEGER
    SCREEN_WIDTH                   AS INTEGER
    SCREEN_HEIGHT                  AS INTEGER
    WIN_MIN_WIDTH                  AS INTEGER  ' Minimum viewport width (0=use 320)
    WIN_MIN_HEIGHT                 AS INTEGER  ' Minimum viewport height (0=use 200)
    WIN_MAX_WIDTH                  AS INTEGER  ' Maximum viewport width (0=unlimited)
    WIN_MAX_HEIGHT                 AS INTEGER  ' Maximum viewport height (0=unlimited)
    DEFAULT_PALETTE                AS STRING
    PALETTE_CHIP_WIDTH             AS INTEGER
    PALETTE_CHIP_HEIGHT            AS INTEGER
    PALETTE_MAX_CHIPS_PER_ROW      AS INTEGER
    PALETTE_MAX_ROWS               AS INTEGER
    PALETTE_MIN_ROWS               AS INTEGER
    PALETTE_CHIPS_ROW_THRESHOLD    AS INTEGER
    PALETTE_DEFAULT_FG_COLOR_INDEX AS INTEGER
    PALETTE_DEFAULT_BG_COLOR_INDEX AS INTEGER
    PALETTE_PICKER_CHIP_SIZE       AS INTEGER
    PALETTE_PICKER_CHIP_PADDING    AS INTEGER
    PALETTE_PICKER_COLUMNS         AS INTEGER
    ANGLE_SNAP_DEGREES             AS INTEGER
    ANGLE_SNAP_PIXEL_ART           AS INTEGER  ' TRUE = snap to pixel-art angles (integer slope ratios)
    ' Layer panel settings
    LAYER_PANEL_WIDTH              AS INTEGER  ' Width of layer panel in pixels (min 100)
    LAYER_NAME_MAX_LEN             AS INTEGER  ' Max layer name length (1-64, default 16)
    ' Grid settings
    GRID_COLOR_FG                  AS _UNSIGNED LONG  ' Grid foreground color (hex RGB, 0=use theme)
    GRID_OPACITY                   AS INTEGER  ' Grid line opacity 0-255 (0=use theme)
    GRID_SIZE_X                    AS INTEGER  ' Grid cell width in pixels (0=use theme)
    GRID_SIZE_Y                    AS INTEGER  ' Grid cell height in pixels (0=use theme)
    ' Pixel grid settings
    PIXELGRID_COLOR_FG             AS _UNSIGNED LONG  ' Pixel grid line color (hex RGB, 0=use theme)
    PIXELGRID_OPACITY              AS INTEGER  ' Pixel grid line opacity 0-255 (0=use theme)
    ' Crosshair settings
    CROSSHAIR_FG                   AS _UNSIGNED LONG  ' Crosshair line color (hex RGB, 0=use theme)
    CROSSHAIR_OPACITY              AS INTEGER  ' Crosshair line opacity 0-255 (0=use theme)
    CROSSHAIR_FONT_FG              AS _UNSIGNED LONG  ' Crosshair text color (hex RGB, 0=use theme)
    CROSSHAIR_ANGLE                AS SINGLE   ' Crosshair rotation angle in degrees (0=use theme)
    ' Grid mode and angle
    GRID_ANGLE                     AS SINGLE   ' Grid rotation angle in degrees (0=use theme)
    GRID_MODE                      AS INTEGER  ' Grid geometry mode (0=square,1=diagonal,2=iso,3=hex)
    GRID_CELL_FILL                 AS INTEGER  ' Grid cell fill mode (0=off, 1=on)
    ' Transparency checkerboard settings
    TRANSPARENCY_CHECK_COLOR1      AS _UNSIGNED LONG  ' Light checkerboard color
    TRANSPARENCY_CHECK_COLOR2      AS _UNSIGNED LONG  ' Dark checkerboard color
    TRANSPARENCY_CHECK_SIZE_X      AS INTEGER  ' Checkerboard square width (0=use theme)
    TRANSPARENCY_CHECK_SIZE_Y      AS INTEGER  ' Checkerboard square height (0=use theme)
    ' Scrollbar settings
    SCROLLBAR_BG                   AS _UNSIGNED LONG  ' Scrollbar track background color (hex RGB, 0=default)
    SCROLLBAR_HANDLE_FG            AS _UNSIGNED LONG  ' Scrollbar thumb/handle color (hex RGB, 0=default)
    SCROLLBAR_OPACITY              AS INTEGER  ' Scrollbar overall opacity 0-255 (0=use default 180)
    ' Workspace undo settings
    WORKSPACE_UNDO_MAX_STATES      AS INTEGER  ' Max workspace undo states (5-50, default 20)
    ' Default startup settings
    DEFAULT_TOOL                   AS INTEGER  ' Default tool on startup (1=brush, 2=fill, 3=dot, etc.)
    DEFAULT_BRUSH_SIZE             AS INTEGER  ' Default brush size index (1-25)
    DEFAULT_BRUSH_SHAPE            AS INTEGER  ' Default brush shape (0=circle, 1=square)
    DEFAULT_LAYER_BG_COLOR         AS _UNSIGNED LONG  ' Default layer background color
    DEFAULT_SAVE_DIR               AS STRING   ' Default directory for save dialogs
    DEFAULT_OPEN_DIR               AS STRING   ' Default directory for open dialogs
    ' Per-operation last-used directories (persisted to DRAW.cfg)
    LAST_DIR_OPEN                  AS STRING   ' Last directory for File Open / Load Image
    LAST_DIR_SAVE                  AS STRING   ' Last directory for File Save / Save As
    LAST_DIR_IMPORT                AS STRING   ' Last directory for Import Image / Ref Image
    LAST_DIR_EXPORT_BRUSH          AS STRING   ' Last directory for Export Brush
    LAST_DIR_EXPORT_LAYER          AS STRING   ' Last directory for Export Layer / Selection
    LAST_DIR_PALETTE               AS STRING   ' Last directory for Palette Import / Export
    TEMPLATE_DIR                   AS STRING   ' Default directory for New from Template dialog
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG
DIM SHARED CONFIG_NEEDS_INITIAL_SAVE%  ' Deferred save flag: set when config file doesn't exist yet

DECLARE SUB CONFIG_load ()
DECLARE SUB CONFIG_save ()
DECLARE SUB CONFIG_set_defaults ()
DECLARE SUB CONFIG_apply_startup_defaults ()
DECLARE SUB CONFIG_validate_palette_strip ()
DECLARE FUNCTION CONFIG_extract_dir$ (filepath AS STRING)
DECLARE SUB RECENT_add_file (filepath AS STRING)
DECLARE SUB RECENT_clear ()
DECLARE FUNCTION RECENT_extract_filename$ (filepath AS STRING)
