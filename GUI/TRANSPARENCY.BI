''
' DRAW - GUI/TRANSPARENCY.BI
' =============================================================================
' UDT for transparency checkerboard background.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE TRANSPARENCY_OBJ
    imgHandle    AS LONG           ' Display-rect blit cache (rebuilt on zoom change via scaled _PUTIMAGE from blueprint)
    imgWidth     AS INTEGER        ' Display-rect cache dimensions
    imgHeight    AS INTEGER
    blueprint    AS LONG           ' Canvas-resolution ground-truth pattern (zoom-independent, built once via LINE BF)
    blueprintW   AS INTEGER        ' Blueprint dimensions
    blueprintH   AS INTEGER
    checkSizeX   AS INTEGER        ' Width of each checker square
    checkSizeY   AS INTEGER        ' Height of each checker square
    color1       AS _UNSIGNED LONG ' Light checker color
    color2       AS _UNSIGNED LONG ' Dark checker color
    lastZoom     AS SINGLE         ' Zoom level when display cache was last built
END TYPE

DIM SHARED TRANSPARENCY AS TRANSPARENCY_OBJ


TRANSPARENCY_init
