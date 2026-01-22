''
' DRAW - TOOLS/POLY-FILL.BI
' =============================================================================
' Polygon scanline fill algorithm interface.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Declare the polygon scanline fill function
DECLARE SUB POLY_FILL_scanline(x_coords%(), y_coords%(), num_points%, fill_color~&, dest_image&)
