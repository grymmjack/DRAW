''
' DRAW - TOOLS/SS-ARROW.BI
' =============================================================================
' Block arrow. Drag direction sets arrow's pointing direction.
' STEM_FATNESS_PCT (10..90) — width of stem as % of overall thickness.
' HEAD_LEN_PCT (10..80) — head length as % of total length.
' HEAD_FLARE_PCT (50..200) — head width as % of total thickness.
' ↑↓ = STEM_FATNESS_PCT ±5; ←→ = HEAD_LEN_PCT ±5.
'
$INCLUDEONCE

TYPE SS_ARROW_TYPE
    DRAGGING AS INTEGER
    START_X AS INTEGER
    START_Y AS INTEGER
    END_X AS INTEGER
    END_Y AS INTEGER
    STEM_FATNESS_PCT AS INTEGER ' 10..90
    HEAD_LEN_PCT AS INTEGER     ' 10..80
    HEAD_FLARE_PCT AS INTEGER   ' 50..200
    THICKNESS AS INTEGER ' overall arrow thickness in pixels
    FILLED AS INTEGER
END TYPE
DIM SHARED SS_ARROW AS SS_ARROW_TYPE
SS_ARROW.STEM_FATNESS_PCT = 50
SS_ARROW.HEAD_LEN_PCT = 35
SS_ARROW.HEAD_FLARE_PCT = 100
SS_ARROW.THICKNESS = 20
