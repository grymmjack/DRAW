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

DECLARE SUB PICKER_init ()
DECLARE SUB PICKER_activate ()
DECLARE SUB PICKER_deactivate ()
DECLARE SUB PICKER_pick_color (x AS INTEGER, y AS INTEGER, button AS INTEGER)
DECLARE SUB PICKER_compose_region (canvasX AS INTEGER, canvasY AS INTEGER, regionW AS INTEGER, regionH AS INTEGER, destImg AS LONG)
DECLARE FUNCTION PICKER_resolve_sample_color~& (canvasX AS INTEGER, canvasY AS INTEGER, layerColor AS _UNSIGNED LONG)

PICKER_init
