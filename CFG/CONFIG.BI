''
' DRAW - CFG/CONFIG.BI
' =============================================================================
' UDT for configuration.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CONFIG_FILE$ = "draw.cfg"

TYPE DRAW_CONFIG
    THEME              AS STRING
    FULLSCREEN         AS INTEGER
    NUDGE_N            AS INTEGER
    NUM_CUSTOM_BRUSHES AS INTEGER
    NUM_LAYERS         AS INTEGER
    FPS_LIMIT          AS INTEGER
    SCREEN_WIDTH       AS INTEGER
    SCREEN_HEIGHT      AS INTEGER
    DEFAULT_PALETTE    AS STRING
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG

DECLARE SUB CONFIG_load ()
DECLARE SUB CONFIG_save ()
DECLARE SUB CONFIG_set_defaults ()
