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
CONST CONFIG_USE_THEME_DEFAULT% = -32768

' OS-specific config filenames (checked before falling back to DRAW.cfg)
$IF MAC THEN
    CONST CONFIG_FILE_OS_SPECIFIC$ = "DRAW.macOS.cfg"
$ELSEIF LINUX THEN
    CONST CONFIG_FILE_OS_SPECIFIC$ = "DRAW.linux.cfg"
$ELSEIF WIN THEN
    CONST CONFIG_FILE_OS_SPECIFIC$ = "DRAW.windows.cfg"
$ELSE
    CONST CONFIG_FILE_OS_SPECIFIC$ = ""
$END IF

' Runtime config file path (set by command-line parsing below)
DIM SHARED CONFIG_FILE_PATH$
CONFIG_FILE_PATH$ = CONFIG_FILE_DEFAULT$

' Flag: TRUE if --config / -c was used (so DRAW.BAS skips those args for file open)
DIM SHARED CMDLINE_CONFIG_ARG_COUNT%
CMDLINE_CONFIG_ARG_COUNT% = 0

' Flag: TRUE if --config-upgrade was requested
DIM SHARED CMDLINE_CONFIG_UPGRADE%
CMDLINE_CONFIG_UPGRADE% = FALSE

' Command-line canvas size override (--canvas-size WWWxHHH)
DIM SHARED CMDLINE_CANVAS_W%
DIM SHARED CMDLINE_CANVAS_H%
CMDLINE_CANVAS_W% = 0  ' 0 = not specified on command line
CMDLINE_CANVAS_H% = 0

' Parse command-line args: --config / -c, --config-upgrade
' (Executed at include time, BEFORE CONFIG_load runs from SCREEN_init)
DIM CONFIG_cmdArgIdx%
DIM CONFIG_cmdArgCount%
DIM CONFIG_cmdArgVal$
CONFIG_cmdArgCount% = _COMMANDCOUNT
CONFIG_cmdArgIdx% = 1
DO WHILE CONFIG_cmdArgIdx% <= CONFIG_cmdArgCount%
    CONFIG_cmdArgVal$ = _TRIM$(COMMAND$(CONFIG_cmdArgIdx%))

    IF LCASE$(CONFIG_cmdArgVal$) = "--config-upgrade" THEN
        CMDLINE_CONFIG_UPGRADE% = TRUE
        CMDLINE_CONFIG_ARG_COUNT% = CMDLINE_CONFIG_ARG_COUNT% + 1
        CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 1

    ELSEIF LCASE$(CONFIG_cmdArgVal$) = "--canvas-size" THEN
        ' Parse --canvas-size WWWxHHH
        IF CONFIG_cmdArgIdx% + 1 <= CONFIG_cmdArgCount% THEN
            DIM CONFIG_canvasSizeArg$
            DIM CONFIG_canvasXPos%
            CONFIG_canvasSizeArg$ = _TRIM$(COMMAND$(CONFIG_cmdArgIdx% + 1))
            CONFIG_canvasXPos% = INSTR(UCASE$(CONFIG_canvasSizeArg$), "X")
            IF CONFIG_canvasXPos% >= 2 THEN
                CMDLINE_CANVAS_W% = VAL(LEFT$(CONFIG_canvasSizeArg$, CONFIG_canvasXPos% - 1))
                CMDLINE_CANVAS_H% = VAL(MID$(CONFIG_canvasSizeArg$, CONFIG_canvasXPos% + 1))
                IF CMDLINE_CANVAS_W% < 1 THEN CMDLINE_CANVAS_W% = 0
                IF CMDLINE_CANVAS_H% < 1 THEN CMDLINE_CANVAS_H% = 0
                IF CMDLINE_CANVAS_W% > 4096 THEN CMDLINE_CANVAS_W% = 4096
                IF CMDLINE_CANVAS_H% > 4096 THEN CMDLINE_CANVAS_H% = 4096
            END IF
            CMDLINE_CONFIG_ARG_COUNT% = CMDLINE_CONFIG_ARG_COUNT% + 2
            CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 2
        ELSE
            CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 1
        END IF

    ELSEIF LCASE$(CONFIG_cmdArgVal$) = "--config" OR LCASE$(CONFIG_cmdArgVal$) = "-c" THEN
        ' Found --config / -c flag
        IF CONFIG_cmdArgIdx% + 1 <= CONFIG_cmdArgCount% THEN
            ' Next argument is the config file path
            CONFIG_FILE_PATH$ = _TRIM$(COMMAND$(CONFIG_cmdArgIdx% + 1))
            ' Remove surrounding quotes if present
            IF LEFT$(CONFIG_FILE_PATH$, 1) = CHR$(34) AND RIGHT$(CONFIG_FILE_PATH$, 1) = CHR$(34) THEN
                CONFIG_FILE_PATH$ = MID$(CONFIG_FILE_PATH$, 2, LEN(CONFIG_FILE_PATH$) - 2)
            END IF
            CMDLINE_CONFIG_ARG_COUNT% = CMDLINE_CONFIG_ARG_COUNT% + 2 ' --config + value

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
        CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 2

    ELSE
        CONFIG_cmdArgIdx% = CONFIG_cmdArgIdx% + 1
    END IF
LOOP

' OS-specific config auto-detection (only if --config was NOT explicitly passed)
' Priority: --config arg > OS-specific file > DRAW.cfg
IF CMDLINE_CONFIG_ARG_COUNT% = 0 OR (CMDLINE_CONFIG_UPGRADE% AND CMDLINE_CONFIG_ARG_COUNT% = 1) THEN
    ' No --config was specified — check for OS-specific config file
    IF CONFIG_FILE_OS_SPECIFIC$ <> "" THEN
        IF _FILEEXISTS(CONFIG_FILE_OS_SPECIFIC$) THEN
            CONFIG_FILE_PATH$ = CONFIG_FILE_OS_SPECIFIC$
        END IF
    END IF
END IF

TYPE DRAW_CONFIG
    THEME                          AS STRING   ' Active theme directory name (e.g. "DEFAULT")
    FULLSCREEN                     AS INTEGER  ' TRUE = fullscreen, FALSE = windowed
    DISPLAY_SCALE                  AS INTEGER  ' 0=auto-detect, 1-8=explicit scale
    DISPLAY_SCALE_MAX              AS INTEGER  ' Maximum allowed scale (default 8)
    DISPLAY_SCALE_CHANGED          AS INTEGER  ' Runtime flag: scale changed during session
    TOOLBAR_SCALE                  AS INTEGER  ' Toolbar icon scale multiplier (1-4, default 1)
    NUDGE_N                        AS INTEGER  ' Multi-pixel nudge distance (default 10)
    NUM_CUSTOM_BRUSHES             AS INTEGER  ' Number of custom brush slots (default 4)
    NUM_LAYERS                     AS INTEGER  ' Initial number of layers on new file
    FPS_LIMIT                      AS INTEGER  ' Maximum frames per second when active (default 60)
    FPS_IDLE                       AS INTEGER  ' Reduced FPS when idle (default 15)
    FPS_CURSOR                     AS INTEGER  ' Reduced FPS cursor-only movement (default 20)
    FPS_DIALOG                     AS INTEGER  ' FPS for modal dialogs (default 60)
    SCREEN_WIDTH                   AS INTEGER  ' Viewport width in pixels (0=auto-detect)
    SCREEN_HEIGHT                  AS INTEGER  ' Viewport height in pixels (0=auto-detect)
    WIN_MIN_WIDTH                  AS INTEGER  ' Minimum viewport width (0=use 320)
    WIN_MIN_HEIGHT                 AS INTEGER  ' Minimum viewport height (0=use 200)
    WIN_MAX_WIDTH                  AS INTEGER  ' Maximum viewport width (0=unlimited)
    WIN_MAX_HEIGHT                 AS INTEGER  ' Maximum viewport height (0=unlimited)
    DEFAULT_PALETTE                AS STRING   ' Default palette name to load on startup
    PALETTE_CHIP_WIDTH             AS INTEGER  ' Width of each color chip in palette strip
    PALETTE_CHIP_HEIGHT            AS INTEGER  ' Height of each color chip in palette strip
    PALETTE_MAX_CHIPS_PER_ROW      AS INTEGER  ' Maximum color chips per row in strip
    PALETTE_MAX_ROWS               AS INTEGER  ' Maximum palette strip rows (1-8)
    PALETTE_MIN_ROWS               AS INTEGER  ' Minimum palette strip rows always shown
    PALETTE_CHIPS_ROW_THRESHOLD    AS INTEGER  ' Start new row every N chips
    PALETTE_DEFAULT_FG_COLOR_INDEX AS INTEGER  ' Default foreground palette index (0-based)
    PALETTE_DEFAULT_BG_COLOR_INDEX AS INTEGER  ' Default background palette index (0-based)
    PALETTE_PICKER_CHIP_SIZE       AS INTEGER  ' Chip size in palette picker dialog (8-48)
    PALETTE_PICKER_CHIP_PADDING    AS INTEGER  ' Padding between chips in palette picker
    PALETTE_PICKER_COLUMNS         AS INTEGER  ' Number of columns in palette picker grid
    ANGLE_SNAP_DEGREES             AS INTEGER  ' Angle snapping increment in degrees
    ANGLE_SNAP_PIXEL_ART           AS INTEGER  ' TRUE = snap to pixel-art angles (integer slope ratios)
    ' Layer panel settings
    LAYER_PANEL_WIDTH              AS INTEGER  ' Width of layer panel in pixels (min 100)
    LAYER_NAME_MAX_LEN             AS INTEGER  ' Max layer name length (1-64, default 16)
    LAYERS_PANEL_DOCK_EDGE         AS STRING  ' "LEFT" or "RIGHT" (default: "LEFT")
    TOOLBOX_DOCK_EDGE              AS STRING  ' "LEFT" or "RIGHT" (default: "RIGHT")
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
    CROSSHAIR_FONT                 AS STRING   ' Crosshair text font filename (empty=use theme/global font)
    CROSSHAIR_FONT_SIZE            AS INTEGER  ' Crosshair text font size in pixels
    CROSSHAIR_FONT_FG              AS _UNSIGNED LONG  ' Crosshair text color (hex RGB, 0=use theme)
    CROSSHAIR_FONT_STROKE_FG       AS _UNSIGNED LONG  ' Crosshair text outline color (hex RGB, 0=use theme)
    CROSSHAIR_FONT_STROKE_WIDTH    AS INTEGER  ' Crosshair text outline width in pixels
    CROSSHAIR_FONT_OFFSET_X        AS INTEGER  ' Crosshair text X offset from cursor (CONFIG_USE_THEME_DEFAULT=use theme)
    CROSSHAIR_FONT_OFFSET_Y        AS INTEGER  ' Crosshair text Y offset from cursor (CONFIG_USE_THEME_DEFAULT=use theme)
    CROSSHAIR_ANGLE                AS SINGLE   ' Crosshair rotation angle in degrees (0=use theme)
    CROSSHAIR_OUTLINE_FG           AS _UNSIGNED LONG  ' Crosshair outline stroke color (hex RGB, 0=use theme)
    CROSSHAIR_OUTLINE_OPACITY      AS INTEGER  ' Crosshair outline stroke opacity 0-255 (0=use theme)
    CROSSHAIR_OUTLINE_WIDTH        AS INTEGER  ' Crosshair outline stroke width in pixels
    ' Picker loupe settings
    PICKER_LOUPE_ZOOM_LEVEL        AS INTEGER  ' Loupe zoom factor (1-8)
    PICKER_LOUPE_RECT_X_OFFSET     AS INTEGER  ' Loupe X offset from cursor in screen pixels
    PICKER_LOUPE_RECT_Y_OFFSET     AS INTEGER  ' Loupe Y offset from cursor in screen pixels
    PICKER_LOUPE_RECT_WIDTH        AS INTEGER  ' Loupe rectangle width in screen pixels
    PICKER_LOUPE_RECT_HEIGHT       AS INTEGER  ' Loupe rectangle height in screen pixels
    PICKER_LOUPE_RGBA_X            AS INTEGER  ' RGB text X offset relative to loupe
    PICKER_LOUPE_RGBA_Y            AS INTEGER  ' RGB text Y offset relative to loupe
    PICKER_LOUPE_FONT              AS STRING   ' Loupe font filename override (empty=global)
    PICKER_LOUPE_FONT_SIZE         AS INTEGER  ' Loupe font size in pixels
    PICKER_LOUPE_FONT_FG           AS _UNSIGNED LONG  ' Loupe label foreground color
    PICKER_LOUPE_FONT_BG           AS _UNSIGNED LONG  ' Loupe label background color
    PICKER_LOUPE_FONT_STROKE_FG    AS _UNSIGNED LONG  ' Loupe label outline color
    PICKER_LOUPE_FONT_STROKE_WIDTH AS INTEGER  ' Loupe label outline width in pixels
    PICKER_LOUPE_RECT_STROKE_FG    AS _UNSIGNED LONG  ' Loupe border color
    PICKER_LOUPE_RECT_STROKE_WIDTH AS INTEGER  ' Loupe border width in pixels
    PICKER_LOUPE_PIXEL_PICKUP_COLOR AS _UNSIGNED LONG ' Loupe sampled-pixel marker color
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
    ' Sound / music settings
    SOUNDS_ENABLED                 AS INTEGER  ' TRUE=-1 / FALSE=0 (default 0=off)
    SOUNDS_VOLUME                  AS INTEGER  ' Volume percent 0-100 (default 35)
    SOUNDS_MUTED                   AS INTEGER  ' TRUE=-1 / FALSE=0 (mute SFX without disabling)
    MUSIC_ENABLED                  AS INTEGER  ' TRUE=-1 / FALSE=0 (default 0=off)
    MUSIC_VOLUME                   AS INTEGER  ' Volume percent 0-100 for music (default 35)
    MUSIC_MUTED                    AS INTEGER  ' TRUE=-1 / FALSE=0 (mute music without stopping)
    ' Default startup settings
    DEFAULT_TOOL                   AS INTEGER  ' Default tool on startup (1=brush, 2=fill, 3=dot, etc.)
    DEFAULT_BRUSH_SIZE             AS INTEGER  ' Default brush size index (1-25)
    DEFAULT_BRUSH_SHAPE            AS INTEGER  ' Default brush shape (0=circle, 1=square)
    DEFAULT_DRAW_MODE              AS INTEGER  ' Default paint mode on startup (1=color, 2=gradient, 3=pattern)
    DEFAULT_BIN_MODE               AS INTEGER  ' Default bins panel on startup (1=brush, 2=pattern, 3=gradient)
    DEFAULT_LAYER_BG_COLOR         AS _UNSIGNED LONG  ' Default layer background color
    BAS_EXPORT_BG_COLOR            AS _UNSIGNED LONG  ' Default generated BAS screen background color
    BAS_WIP_ENABLED                AS INTEGER  ' TRUE = keep live *-wip.bas stream in sync with history
    DEFAULT_SAVE_DIR               AS STRING   ' Default directory for save dialogs
    DEFAULT_OPEN_DIR               AS STRING   ' Default directory for open dialogs
    ' Per-operation last-used directories (persisted to DRAW.cfg)
    LAST_DIR_OPEN                  AS STRING   ' Last directory for File Open / Load Image
    LAST_DIR_SAVE                  AS STRING   ' Last directory for File Save / Save As
    LAST_DIR_IMPORT                AS STRING   ' Last directory for Import Image / Ref Image
    LAST_DIR_EXPORT_BRUSH          AS STRING   ' Last directory for Export Brush
    LAST_DIR_EXPORT_LAYER          AS STRING   ' Last directory for Export Layer / Selection
    LAST_DIR_EXTRACT               AS STRING   ' Last directory for Extract Images
    LAST_DIR_PALETTE               AS STRING   ' Last directory for Palette Import / Export
    TEMPLATE_DIR                   AS STRING   ' Default directory for New from Template dialog
    ' User palette visibility settings
    PALETTE_SHOW_LOSPEC            AS INTEGER  ' TRUE = include USER/PALETTES/*.gpl in picker
    PALETTE_SHOW_CREATED           AS INTEGER  ' TRUE = include USER/PALETTES/CREATED/*.gpl in picker
    ' Color extraction max for "Create from image"
    PALETTE_CREATE_MAX_COLORS      AS INTEGER  ' Default max colors for Create from Image (default 32)
    ' Preview Window settings
    PREVIEW_VISIBLE                AS INTEGER  ' TRUE = preview window open at startup
    PREVIEW_X                      AS INTEGER  ' Last window X (-1 = use auto-position)
    PREVIEW_Y                      AS INTEGER  ' Last window Y (-1 = use auto-position)
    PREVIEW_W                      AS INTEGER  ' Last window width
    PREVIEW_H                      AS INTEGER  ' Last window height
    PREVIEW_FOLLOW                 AS INTEGER  ' TRUE = follow-pointer magnifier mode
    PREVIEW_ZOOM                   AS SINGLE   ' Independent preview zoom level
    PREVIEW_PAN_X                  AS SINGLE   ' Independent preview pan X (canvas pixels)
    PREVIEW_PAN_Y                  AS SINGLE   ' Independent preview pan Y (canvas pixels)
    PREVIEW_MODE                   AS INTEGER  ' 0=Follow, 1=Floating Image
    PREVIEW_COLOR_PICK             AS INTEGER  ' TRUE = allow color picking from preview
    PREVIEW_BIN_QUICK_LOOK         AS INTEGER  ' TRUE = enable Bin Quick Look hover preview
    PREVIEW_FLOAT_IMAGE_PATH       AS STRING   ' Last loaded floating image path
    PREVIEW_FLOAT_LAST_DIR         AS STRING   ' Last directory used for Load Image dialog
    EDIT_BAR_VISIBLE               AS INTEGER  ' TRUE = edit bar visible at startup
    EDIT_BAR_DOCK_POSITION         AS STRING  ' "LEFT" or "RIGHT"
    ' Default drawer set files (path to .dset, empty = use built-in samples)
    DEFAULT_DSET_BRUSHES_FILE      AS STRING   ' Default brush drawer set (.dset)
    DEFAULT_DSET_PATTERNS_FILE     AS STRING   ' Default pattern drawer set (.dset)
    DEFAULT_DSET_GRADIENTS_FILE    AS STRING   ' Default gradient drawer set (.dset)
    ' Canvas size settings
    DEFAULT_CANVAS_SIZE_W          AS INTEGER  ' Default canvas width (0=fill viewport, >0=explicit)
    DEFAULT_CANVAS_SIZE_H          AS INTEGER  ' Default canvas height (>0=explicit)
    CANVAS_APRON_COLOR             AS _UNSIGNED LONG ' Background color around canvas when smaller than viewport
    SYSTEM_CURSORS_ENABLED         AS INTEGER  ' TRUE = use OS system cursors for resize/hand/text/move
    ' Tooltip settings
    TOOLTIP_HOVER_DELAY_MS         AS INTEGER  ' Milliseconds before tooltip appears (default 500)
    TOOLTIPS_DISABLED              AS INTEGER  ' TRUE = hide toolbar tooltips entirely
    ' Text tool default font settings
    FONT_DEFAULT_FONT              AS STRING   ' Default font name for text tool (empty=use Tiny5 Regular)
    FONT_DEFAULT_SIZE              AS INTEGER  ' Default font size for text tool (4-128, 0=use program default 8)
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG
DIM SHARED CONFIG_NEEDS_INITIAL_SAVE%  ' Deferred save flag: set when config file doesn't exist yet

DECLARE SUB CONFIG_load ()
DECLARE SUB CONFIG_save ()
DECLARE SUB CONFIG_set_defaults ()
DECLARE SUB CONFIG_upgrade ()
DECLARE SUB CONFIG_apply_startup_defaults ()
DECLARE SUB CONFIG_validate_palette_strip ()
DECLARE FUNCTION CONFIG_extract_dir$ (filepath AS STRING)
DECLARE SUB RECENT_add_file (filepath AS STRING)
DECLARE SUB RECENT_clear ()
DECLARE FUNCTION RECENT_extract_filename$ (filepath AS STRING)
