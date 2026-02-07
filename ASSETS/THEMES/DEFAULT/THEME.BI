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

' =============================================================================
' CURSORS - PNG cursor configuration
' =============================================================================
' Each cursor has a filename, hotspot, and optional overlays.
' Hotspot expressions: left, right, top, bottom/bot, center, or number.
' Arithmetic: center+5, bottom-1, left-20, right+20, etc.
' Overlay text templates: %mx %my %ow %oh %ox %oy %nw %nh %nx %ny
' =============================================================================

' --- Null cursor (default arrow for UI areas) ---
CURSORS(CURSOR_NULL).filename$        = "cursor-null.png"
CURSORS(CURSOR_NULL).hotspot_x_expr$  = "left"
CURSORS(CURSOR_NULL).hotspot_y_expr$  = "top"

' --- Brush cursor ---
CURSORS(CURSOR_BRUSH).filename$       = "cursor-brush.png"
CURSORS(CURSOR_BRUSH).hotspot_x_expr$ = "left"
CURSORS(CURSOR_BRUSH).hotspot_y_expr$ = "top"

' --- Dropper / Picker cursor ---
CURSORS(CURSOR_DROPPER).filename$       = "cursor-dropper.png"
CURSORS(CURSOR_DROPPER).hotspot_x_expr$ = "2"
CURSORS(CURSOR_DROPPER).hotspot_y_expr$ = "bottom"

' --- Fill cursor ---
CURSORS(CURSOR_FILL).filename$       = "cursor-fill.png"
CURSORS(CURSOR_FILL).hotspot_x_expr$ = "4"
CURSORS(CURSOR_FILL).hotspot_y_expr$ = "bottom-1"

' --- Hand / Pan cursor ---
CURSORS(CURSOR_HAND).filename$       = "cursor-hand.png"
CURSORS(CURSOR_HAND).hotspot_x_expr$ = "center"
CURSORS(CURSOR_HAND).hotspot_y_expr$ = "center"

' --- Marquee cursor ---
CURSORS(CURSOR_MARQUEE).filename$       = "cursor-marquee.png"
CURSORS(CURSOR_MARQUEE).hotspot_x_expr$ = "center"
CURSORS(CURSOR_MARQUEE).hotspot_y_expr$ = "center"

' --- Move cursor ---
CURSORS(CURSOR_MOVE).filename$       = "cursor-move.png"
CURSORS(CURSOR_MOVE).hotspot_x_expr$ = "center"
CURSORS(CURSOR_MOVE).hotspot_y_expr$ = "center"

' --- Resize corner cursor ---
CURSORS(CURSOR_RESIZE_CORNER).filename$       = "cursor-resize-corner.png"
CURSORS(CURSOR_RESIZE_CORNER).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_CORNER).hotspot_y_expr$ = "center"

' --- Resize horizontal cursor ---
CURSORS(CURSOR_RESIZE_HORIZ).filename$       = "cursor-resize-horizontal.png"
CURSORS(CURSOR_RESIZE_HORIZ).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_HORIZ).hotspot_y_expr$ = "center"

' --- Resize vertical cursor ---
CURSORS(CURSOR_RESIZE_VERT).filename$       = "cursor-resize-vertical.png"
CURSORS(CURSOR_RESIZE_VERT).hotspot_x_expr$ = "center"
CURSORS(CURSOR_RESIZE_VERT).hotspot_y_expr$ = "center"

' --- Spray cursor ---
CURSORS(CURSOR_SPRAY).filename$       = "cursor-spray.png"
CURSORS(CURSOR_SPRAY).hotspot_x_expr$ = "left"
CURSORS(CURSOR_SPRAY).hotspot_y_expr$ = "top"

' --- Wand cursor (magic wand / right-click marquee) ---
CURSORS(CURSOR_WAND).filename$       = "cursor-wand.png"
CURSORS(CURSOR_WAND).hotspot_x_expr$ = "left"
CURSORS(CURSOR_WAND).hotspot_y_expr$ = "top"

' --- Zoom cursor ---
CURSORS(CURSOR_ZOOM).filename$       = "cursor-zoom.png"
CURSORS(CURSOR_ZOOM).hotspot_x_expr$ = "center"
CURSORS(CURSOR_ZOOM).hotspot_y_expr$ = "center"
