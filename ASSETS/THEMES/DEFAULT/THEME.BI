''
' DRAW - THEME.BI
' =============================================================================
' Default theme for DRAW.
'
' @depends ../../../CFG/CONFIG-THEME.BI
' @see ../../../CFG/CONFIG-THEME.BI for documentation
' @author Rick Christy <grymmjack@gmail.com>
'

$IF THEME_BI = UNDEFINED THEN
    $LET THEME_BI = 1
$END IF

THEME.STATUS_bg%         = 8                    ' Dark gray / bright black
THEME.STATUS_fg%         = 17                   ' Opaque black (not transparent)
THEME.CROSSHAIR_fg%      = 8                    ' Dark gray / bright black
THEME.CROSSHAIR_pattern% = &B1010101010101010   ' - - - - - - - - 
THEME.TOOLBAR_x$         = "R"                  ' Screen right side (any res)
THEME.TOOLBAR_y$         = "T"                  ' Screen top side (any res)
