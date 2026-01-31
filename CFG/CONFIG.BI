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
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG

DECLARE SUB CONFIG_load ()
DECLARE SUB CONFIG_save ()
DECLARE SUB CONFIG_set_defaults ()
DECLARE SUB CONFIG_validate_palette_strip ()
