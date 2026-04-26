''
' DRAW - GUI/TRANSPARENCY.BI
' =============================================================================
' UDT for transparency checkerboard background.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE TRANSPARENCY_OBJ
    imgHandle  AS LONG           ' Cached checkerboard image
    imgWidth   AS INTEGER        ' Cached image dimensions
    imgHeight  AS INTEGER
    checkSizeX AS INTEGER        ' Width of each checker square
    checkSizeY AS INTEGER        ' Height of each checker square
    color1     AS _UNSIGNED LONG ' Light checker color
    color2     AS _UNSIGNED LONG ' Dark checker color
    lastZoom   AS SINGLE         ' Zoom level when cache was built
END TYPE

DIM SHARED TRANSPARENCY AS TRANSPARENCY_OBJ


TRANSPARENCY_init
