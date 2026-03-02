''
' DRAW - TOOLS/ERASER.BI
' =============================================================================
' Eraser tool - paints with fully transparent color to erase pixels.
' Uses the brush infrastructure but forces transparent painting with _DONTBLEND.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

TYPE ERASER_OBJ
    ACTIVE AS INTEGER           ' Whether eraser mode is engaged
END TYPE

DIM SHARED ERASER AS ERASER_OBJ

ERASER.ACTIVE% = FALSE

' Tracks which layers were modified by a Shift+Erase smart-erase stroke.
' Used in MOUSE_release_brush to save per-layer undo states.
DIM SHARED ERASER_SMART_DIRTY(1 TO 64) AS INTEGER

DECLARE SUB ERASER_activate ()
DECLARE SUB ERASER_deactivate ()
DECLARE SUB ERASER_reset ()
DECLARE SUB ERASER_draw_at (x AS INTEGER, y AS INTEGER, layerImg AS LONG)
DECLARE SUB ERASER_smart_on ()
