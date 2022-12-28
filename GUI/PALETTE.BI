''
' DRAW - GUI/PALETTE.BI
' =============================================================================
' UDT for palette.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE COLOR_OBJ
    name AS STRING
    value AS LONG
END TYPE

TYPE PALETTE_OBJ
    name     AS STRING
    filename AS STRING
    author   AS STRING
    url      AS STRING 
END TYPE

DIM COLORS(0 TO 255) AS COLOR_OBJ
REDIM PALETTES(0 TO 1) AS PALETTE_OBJ