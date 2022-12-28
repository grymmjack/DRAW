''
' DRAW - CFG/CONFIG.BI
' =============================================================================
' UDT for configuration.
'
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE DRAW_CONFIG
    THEME              AS STRING
    FULLSCREEN         AS INTEGER
    NUDGE_N            AS INTEGER
    NUM_CUSTOM_BRUSHES AS INTEGER
    NUM_LAYERS         AS INTEGER
    FPS_LIMIT          AS INTEGER
END TYPE

DIM SHARED CFG   AS DRAW_CONFIG

CFG.FULLSCREEN%         = TRUE
CFG.THEME$              = "DEFAULT"
CFG.NUDGE_N%            = 10
CFG.NUM_LAYERS%         = 1
CFG.NUM_CUSTOM_BRUSHES% = 4
CFG.FPS_LIMIT%          = 60
