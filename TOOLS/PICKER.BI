''
' DRAW - TOOLS/PICKER.BI
' =============================================================================
' UDT for color picker tool.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PICKER_TOOL
    ACTIVE AS INTEGER ' Is the picker tool currently active?
END TYPE

DIM SHARED PICKER              AS PICKER_TOOL
DIM SHARED PICKER_REFIMG_RESET AS INTEGER ' TRUE = reset R-key arm state on next resolve call (Linux/SDL2 ghost-key guard)


PICKER_init
