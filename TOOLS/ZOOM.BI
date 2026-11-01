''
' DRAW - TOOLS/ZOOM.BI
' =============================================================================
' UDT for zoom tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
 $INCLUDEONCE

TYPE ZOOM_OBJ
    DRAGGING AS INTEGER ' TRUE when drag-to-zoom in progress
    START_X  AS INTEGER ' Drag start position (screen coords)
    START_Y  AS INTEGER ' Drag start position (screen coords)
    END_X    AS INTEGER ' Drag end position (screen coords)
    END_Y    AS INTEGER ' Drag end position (screen coords)
END TYPE

DIM SHARED ZOOM AS ZOOM_OBJ

' Zoom levels below 25%, largest first (see ZOOM_small_level! in ZOOM.BM).
' Big scans and photos need these to fit on screen: a 6758x8525 scan is
' still 1690x2131 at 25%.
CONST ZOOM_SMALL_COUNT = 9
