''
' DRAW - CFG/CONFIG.BI
' =============================================================================
' UDT for configuration.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CONFIG_FILE$ = "DRAW.cfg"

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
    ' Transparency checkerboard settings
    TRANSPARENCY_CHECK_COLOR1      AS _UNSIGNED LONG  ' Light checkerboard color
    TRANSPARENCY_CHECK_COLOR2      AS _UNSIGNED LONG  ' Dark checkerboard color
    TRANSPARENCY_CHECK_SIZE_X      AS INTEGER  ' Checkerboard square width (0=use theme)
    TRANSPARENCY_CHECK_SIZE_Y      AS INTEGER  ' Checkerboard square height (0=use theme)
    ' Workspace undo settings
    WORKSPACE_UNDO_MAX_STATES      AS INTEGER  ' Max workspace undo states (5-50, default 20)
    ' Default startup settings
    DEFAULT_TOOL                   AS INTEGER  ' Default tool on startup (1=brush, 2=fill, 3=dot, etc.)
    DEFAULT_BRUSH_SIZE             AS INTEGER  ' Default brush size index (1-25)
    DEFAULT_LAYER_BG_COLOR         AS _UNSIGNED LONG  ' Default layer background color
    DEFAULT_SAVE_DIR               AS STRING   ' Default directory for save dialogs
    DEFAULT_OPEN_DIR               AS STRING   ' Default directory for open dialogs
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG

DECLARE SUB CONFIG_load ()
DECLARE SUB CONFIG_save ()
DECLARE SUB CONFIG_set_defaults ()
DECLARE SUB CONFIG_apply_startup_defaults ()
DECLARE SUB CONFIG_validate_palette_strip ()
