''
' DRAW - GUI/TRANSPARENCY.BI
' =============================================================================
' UDT for transparency checkerboard background.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE TRANSPARENCY_OBJ
    imgHandle AS LONG       ' Cached checkerboard image
    imgWidth  AS INTEGER    ' Cached image dimensions
    imgHeight AS INTEGER
    checkSize AS INTEGER    ' Size of each checker square
    color1    AS _UNSIGNED LONG  ' Light checker color
    color2    AS _UNSIGNED LONG  ' Dark checker color
END TYPE

DIM SHARED TRANSPARENCY AS TRANSPARENCY_OBJ

DECLARE SUB TRANSPARENCY_init ()
DECLARE SUB TRANSPARENCY_render (targetImg AS LONG, x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER)
DECLARE SUB TRANSPARENCY_invalidate ()

TRANSPARENCY_init
