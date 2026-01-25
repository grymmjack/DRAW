''
' DRAW - GUI/PALETTE.BI
' =============================================================================
' UDT for palette.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE COLOR_OBJ
    name  AS STRING
    value AS _UNSIGNED LONG
END TYPE

TYPE PAL_OBJ
    name     AS STRING
    filename AS STRING
    author   AS STRING
    url      AS STRING 
END TYPE

DIM SHARED PAL(0 TO 255) AS COLOR_OBJ
DIM SHARED PALS(0 TO 255) AS PAL_OBJ

DIM SHARED AS INTEGER PAL_FG_IDX, PAL_BG_IDX
PAL_FG_IDX% = 4
PAL_BG_IDX% = 0
