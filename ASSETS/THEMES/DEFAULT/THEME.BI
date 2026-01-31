''
' DRAW - THEME.BI
' =============================================================================
' Default theme for DRAW.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

THEME.STATUS_bg%              = 8                       ' Dark gray
THEME.STATUS_fg%              = 0                       ' Opaque black
THEME.STATUS_height%          = 11                      ' Status bar height in pixels
THEME.CROSSHAIR_fg%           = 8                       ' Dark gray / bright black
THEME.CROSSHAIR_pattern%      = &B1010101010101010      ' - - - - - - - -
THEME.GRID_fg%                = 15                      ' Bright white
THEME.TOOLBAR_x$              = "R"                     ' Screen right side (any res)
THEME.TOOLBAR_y$              = "T"                     ' Screen top side (any res)
THEME.TOOLBAR_bg%             = _RGBA32(0, 0, 0, 255)   ' Black background
THEME.TOOLBAR_border_fg%      = _RGBA32(0, 0, 0, 255)   ' Black border
THEME.PIXEL_GRID_color1~&     = _RGBA32(80, 80, 80, 64) ' Dark gray grid lines at 25% opacity
THEME.PIXEL_GRID_color2~&     = _RGBA32(60, 60, 60, 64) ' Unused (for future checkerboard) at 25% opacity
THEME.SYMMETRY_guide_fg~&     = _RGBA32(0, 255, 255, 128) ' Cyan guide lines at 50% opacity
THEME.SYMMETRY_center_fg~&    = _RGBA32(255, 255, 0, 128)  ' Yellow center crosshair at 50% opacity
