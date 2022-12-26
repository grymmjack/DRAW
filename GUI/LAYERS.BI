''
' DRAW - LAYERS.BI
' =============================================================================
' UDT for layers.
'
' @todo
' @depends ../CFG/CONFIG.BI
' @author Rick Christy <grymmjack@gmail.com>
'

$IF LAYERS_BI = UNDEFINED THEN
    $LET LAYERS_BI = 1
$END IF
$IF CONFIG_BI = UNDEFINED THEN 
'$INCLUDE:'../CFG/CONFIG.BI'
$END IF

TYPE DRAW_LAYER
    zIndex       AS INTEGER
    imgWidth     AS INTEGER
    imgHeight    AS INTEGER
    imgHandle    AS LONG
    visible      AS INTEGER
    isSelected   AS INTEGER
    lastSelected AS INTEGER
END TYPE

DIM SHARED LAYERS(1 TO CFG.NUM_LAYERS%) AS DRAW_LAYER
