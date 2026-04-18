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
DIM SHARED PAL_COLOR_COUNT AS INTEGER           ' Actual number of colors in PAL() array

' Special index for transparent "eraser" color
CONST PAL_TRANSPARENT_IDX = -1

DIM SHARED AS INTEGER PAL_FG_IDX, PAL_BG_IDX
DIM SHARED AS INTEGER PAL_FG_IS_TRANSPARENT, PAL_BG_IS_TRANSPARENT
DIM SHARED PAL_FG_SAVED_COLOR AS _UNSIGNED LONG ' Saved FG color before transparent toggle
DIM SHARED PAL_FG_SAVED_VALID AS INTEGER        ' TRUE if saved color is valid
PAL_FG_IDX%            = 4
PAL_BG_IDX%            = 0
PAL_FG_IS_TRANSPARENT% = FALSE
PAL_BG_IS_TRANSPARENT% = FALSE                  ' Overridden by CFG.PALETTE_DEFAULT_BG_TRANSPARENT% after config loads
PAL_FG_SAVED_VALID%    = FALSE
