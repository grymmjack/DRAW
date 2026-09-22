''
' DRAW - TOOLS/ELLIPSE.BI
' =============================================================================
' UDT for ellipse (CIRCLE) tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE ELLIPSE_TYPE
    DRAGGING AS INTEGER ' TRUE when dragging to create ellipse
    START_X  AS INTEGER ' Ellipse start X (center will be calculated)
    START_Y  AS INTEGER ' Ellipse start Y (center will be calculated)
    END_X    AS INTEGER ' Ellipse end X (current mouse position)
    END_Y    AS INTEGER ' Ellipse end Y (current mouse position)
    CENTER_X AS INTEGER ' Original center X (for CTRL mode)
    CENTER_Y AS INTEGER ' Original center Y (for CTRL mode)
    FILLED   AS INTEGER ' TRUE for filled ellipse, FALSE for outline
    SLICES   AS INTEGER ' Radial spoke lines through center (0=none, n=n lines, 2n pie sectors)
    RINGS    AS INTEGER ' Concentric inner ellipses (0=none, n=n equidistant inner ellipses)
END TYPE

DIM SHARED ELLIPSE_TOOL AS ELLIPSE_TYPE
ELLIPSE_TOOL.DRAGGING = FALSE
ELLIPSE_TOOL.START_X  = 0
ELLIPSE_TOOL.START_Y  = 0
ELLIPSE_TOOL.END_X    = 0
ELLIPSE_TOOL.END_Y    = 0
ELLIPSE_TOOL.CENTER_X = 0
ELLIPSE_TOOL.CENTER_Y = 0
ELLIPSE_TOOL.FILLED   = FALSE
ELLIPSE_TOOL.SLICES   = 0
ELLIPSE_TOOL.RINGS    = 0

' Pixel-exact ellipse rasterizer (ELLIPSE_plot_outline / ELLIPSE_fill_plain).
' ELLIPSE_INSET%(row) = left inset of that row inside the ellipse's pixel box;
' filled by ELLIPSE_calc_insets, read by every hard-edged ellipse path.
CONST ELLIPSE_PLOT_PSET    = 0 ' plain PSET onto _DEST
CONST ELLIPSE_PLOT_CLIPPED = 1 ' selection clip + opacity lock + drawer paint colour
CONST ELLIPSE_PLOT_BRUSH   = 2 ' PAINT_stamp_brush (thick outline commit)
CONST ELLIPSE_PLOT_PREVIEW = 3 ' PREVIEW_stamp_brush (thick outline preview)
REDIM SHARED ELLIPSE_INSET(0 TO 0) AS INTEGER
