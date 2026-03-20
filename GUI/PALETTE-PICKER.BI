''
' DRAW - GUI/PALETTE-PICKER.BI
' =============================================================================
' Palette picker dialog
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE FUNCTION PALETTE_PICKER_show~& (title AS STRING, current_color AS _UNSIGNED LONG)

' Set TRUE by PALETTE_PICKER_show when user clicks the Transparent button
DIM SHARED PALETTE_PICKER_CHOSE_TRANSPARENT%
