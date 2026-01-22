''
' DRAW - TOOLS/MOVE.BI
' =============================================================================
' Move and transform tool - moves and transforms selected pixels.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE MOVE_OBJ
    ACTIVE       AS INTEGER  ' Whether move tool is active
    TRANSFORMING AS INTEGER  ' Whether actively transforming
    TRANSFORM_TYPE AS INTEGER ' 0=move, 1=scale, 2=stretch
    SELECTION_IMAGE AS LONG  ' Image buffer holding selected pixels
    ORIGINAL_X   AS INTEGER  ' Original selection X (for ESC cancel)
    ORIGINAL_Y   AS INTEGER  ' Original selection Y (for ESC cancel)
    ORIGINAL_W   AS INTEGER  ' Original selection width (for ESC cancel)
    ORIGINAL_H   AS INTEGER  ' Original selection height (for ESC cancel)
    SELECTION_X  AS INTEGER  ' Current base selection X
    SELECTION_Y  AS INTEGER  ' Current base selection Y
    SELECTION_W  AS INTEGER  ' Current base selection width
    SELECTION_H  AS INTEGER  ' Current base selection height
    START_X      AS INTEGER  ' Transform start X
    START_Y      AS INTEGER  ' Transform start Y
    CURRENT_X    AS INTEGER  ' Current transform X
    CURRENT_Y    AS INTEGER  ' Current transform Y
    CURRENT_W    AS INTEGER  ' Current transform width
    CURRENT_H    AS INTEGER  ' Current transform height
    HANDLE       AS INTEGER  ' Which handle being dragged (0=center, 1-8=corners/sides)
    CLONING      AS INTEGER  ' Whether ALT is held (clone mode)
    CONSTRAIN    AS INTEGER  ' Whether SHIFT is held (constrain proportions)
END TYPE

DIM SHARED MOVE AS MOVE_OBJ

DECLARE SUB MOVE_init ()
DECLARE SUB MOVE_reset ()
DECLARE SUB MOVE_capture_selection ()
DECLARE SUB MOVE_start_transform (handle AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB MOVE_update_transform (x AS INTEGER, y AS INTEGER)
DECLARE SUB MOVE_apply_transform ()
DECLARE SUB MOVE_cancel_transform ()
DECLARE SUB MOVE_render_preview (dest AS LONG)
