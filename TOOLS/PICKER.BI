''
' DRAW - TOOLS/PICKER.BI
' =============================================================================
' UDT for color picker tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PICKER_TOOL
    ACTIVE AS INTEGER  ' Is the picker tool currently active?
END TYPE

DIM SHARED PICKER AS PICKER_TOOL

PICKER_init
