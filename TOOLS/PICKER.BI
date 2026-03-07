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

DECLARE SUB PICKER_init ()
DECLARE SUB PICKER_activate ()
DECLARE SUB PICKER_deactivate ()
DECLARE SUB PICKER_pick_color (x AS INTEGER, y AS INTEGER, button AS INTEGER)
DECLARE SUB PICKER_compose_region (canvasX AS INTEGER, canvasY AS INTEGER, regionW AS INTEGER, regionH AS INTEGER, destImg AS LONG)

PICKER_init
