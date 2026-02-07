''
' DRAW - TOOLS/CROP.BI
' =============================================================================
' UDT for crop tool (stub - future canvas resize).
'
' @todo Implement canvas crop/resize functionality
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE CROP_OBJ
    ACTIVE AS INTEGER  ' TRUE when crop region is being defined
END TYPE

DIM SHARED CROP AS CROP_OBJ

CROP.ACTIVE = FALSE
