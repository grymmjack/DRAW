''
' DRAW - GUI/STROKE-SEL.BI
' =============================================================================
' Stroke Selection - declarations for modal dialog and apply algorithm
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST STROKE_TYPE_OUTSIDE = 0
CONST STROKE_TYPE_ON      = 1
CONST STROKE_TYPE_INSIDE  = 2

DECLARE SUB STROKE_SEL_show_dialog ()
DECLARE SUB STROKE_SEL_apply (strokeColor AS _UNSIGNED LONG, strokeType AS INTEGER, strokeWidth AS INTEGER)
