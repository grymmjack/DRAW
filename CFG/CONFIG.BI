''
' DRAW - CFG/CONFIG.BI
' =============================================================================
' UDT for configuration.
'
' @author Rick Christy <grymmjack@gmail.com>
'

$IF CONFIG_BI = UNDEFINED THEN
    $LET CONFIG_BI = 1
$END IF

TYPE DRAW_CONFIG
    THEME              AS STRING
    FULLSCREEN         AS INTEGER
    NUDGE_N            AS INTEGER
    NUM_CUSTOM_BRUSHES AS INTEGER
    NUM_LAYERS         AS INTEGER
    FPS_LIMIT          AS INTEGER
END TYPE
