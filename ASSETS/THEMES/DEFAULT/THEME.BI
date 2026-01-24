''
' DRAW - THEME.BI
' =============================================================================
' Default theme for DRAW.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

THEME.STATUS_bg%         = 8                    ' Dark gray
THEME.STATUS_fg%         = 0                    ' Opaque black
THEME.STATUS_height%     = 11                   ' Status bar height in pixels
THEME.CROSSHAIR_fg%      = 8                    ' Dark gray / bright black
THEME.CROSSHAIR_pattern% = &B1010101010101010   ' - - - - - - - - 
THEME.GRID_fg%           = 15                   ' Bright white
THEME.TOOLBAR_x$         = "R"                  ' Screen right side (any res)
THEME.TOOLBAR_y$         = "T"                  ' Screen top side (any res)
THEME.PIXEL_GRID_color1~& = _RGBA32(255, 255, 255, 255) ' White at 5% opacity
THEME.PIXEL_GRID_color2~& = _RGBA32(0, 0, 0, 255)       ' Black at 5% opacity
