''
' DRAW - TOOLS/MARQUEE.BI
' =============================================================================
' Marquee selection tool using GJ_BBX_BBOX.
'
' This tool provides a bounding box marquee selection with:
' - Dotted crosshair cursor (8x8, semi-transparent 33% opaque)
' - White and black outline like the brush cursor
' - GJ_BBX_BBOX object for bounding box manipulation
' - Resizing, dragging, and handle management
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE MARQUEE_OBJ
    ACTIVE      AS INTEGER  ' Whether marquee tool is active
    BOX         AS GJ_BBX_BBOX ' The bounding box object
    CFG         AS GJ_BBX_CFG  ' Configuration for the bounding box
    INITIALIZED AS INTEGER  ' Whether the marquee has been initialized
    DRAGGING    AS INTEGER  ' Whether currently dragging to create marquee
    DRAG_START_X AS INTEGER ' Starting X coordinate of drag
    DRAG_START_Y AS INTEGER ' Starting Y coordinate of drag
    DRAG_END_X  AS INTEGER  ' Current/ending X coordinate of drag
    DRAG_END_Y  AS INTEGER  ' Current/ending Y coordinate of drag
    RESIZING    AS INTEGER  ' Whether currently resizing
    RESIZE_HANDLE AS INTEGER ' Which handle is being resized (0=none, 1-8=handles)
    RESIZE_START_X AS INTEGER ' Starting X when resize began
    RESIZE_START_Y AS INTEGER ' Starting Y when resize began
    RESIZE_ORIG_X AS INTEGER ' Original box X when resize began
    RESIZE_ORIG_Y AS INTEGER ' Original box Y when resize began  
    RESIZE_ORIG_W AS INTEGER ' Original box W when resize began
    RESIZE_ORIG_H AS INTEGER ' Original box H when resize began
    MOVING      AS INTEGER  ' Whether currently moving/dragging the box
    MOVE_START_X AS INTEGER ' Starting X when move began
    MOVE_START_Y AS INTEGER ' Starting Y when move began
    MOVE_ORIG_X AS INTEGER  ' Original box X when move began
    MOVE_ORIG_Y AS INTEGER  ' Original box Y when move began
    ' Single-press key state tracking for nudge keys
    KEY_UP_LAST AS INTEGER     ' Previous frame's Up arrow state
    KEY_DOWN_LAST AS INTEGER   ' Previous frame's Down arrow state
    KEY_LEFT_LAST AS INTEGER   ' Previous frame's Left arrow state
    KEY_RIGHT_LAST AS INTEGER  ' Previous frame's Right arrow state
    ' Magic Wand mode fields
    MAGIC_WAND_MODE AS INTEGER ' Whether magic wand mode is active
    SELECTION_MASK AS LONG     ' Image handle for per-pixel selection mask (same size as canvas)
    WAND_MIN_X AS INTEGER      ' Bounding box of mask selection (min X)
    WAND_MIN_Y AS INTEGER      ' Bounding box of mask selection (min Y)
    WAND_MAX_X AS INTEGER      ' Bounding box of mask selection (max X)
    WAND_MAX_Y AS INTEGER      ' Bounding box of mask selection (max Y)
    WAND_HAS_SELECTION AS INTEGER ' Whether mask-based selection is active
    USER_CREATED AS INTEGER        ' TRUE if user manually created selection (vs auto for move)
    SELECTION_MODE AS INTEGER      ' Selection mode: 0=replace, 1=add (Shift), 2=subtract (Alt)
    VARIANT AS INTEGER             ' Which toolbar selection button is active (TOOL_SELECT_* constant)
    ' Freehand selection fields
    FREE_DRAWING AS INTEGER        ' Whether actively drawing freehand path
    FREE_POINT_COUNT AS INTEGER    ' Number of points in freehand path
    ' Polygon selection fields
    POLY_DRAWING AS INTEGER        ' Whether actively placing polygon vertices
    POLY_POINT_COUNT AS INTEGER    ' Number of placed vertices
    POLY_CLOSED AS INTEGER         ' Whether polygon has been closed
    ' Ellipse selection fields
    ELLIP_DRAGGING AS INTEGER      ' Whether dragging to define ellipse bounds
    ELLIP_START_X AS INTEGER       ' Start X of ellipse drag
    ELLIP_START_Y AS INTEGER       ' Start Y of ellipse drag
    ELLIP_END_X AS INTEGER         ' End X of ellipse drag
    ELLIP_END_Y AS INTEGER         ' End Y of ellipse drag
END TYPE

' Selection mode constants
CONST SEL_MODE_REPLACE = 0  ' Default: replace existing selection
CONST SEL_MODE_ADD = 1      ' Shift: add to existing selection
CONST SEL_MODE_SUBTRACT = 2 ' Alt: subtract from existing selection

DIM SHARED MARQUEE AS MARQUEE_OBJ

' Shared point arrays for freehand and polygon selection paths
CONST SEL_MAX_POINTS = 4000
DIM SHARED SEL_POINTS_X(SEL_MAX_POINTS) AS INTEGER
DIM SHARED SEL_POINTS_Y(SEL_MAX_POINTS) AS INTEGER

DECLARE FUNCTION MARQUEE_is_point_inside% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION MARQUEE_get_handle_at% (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_start_resize (handle AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_update_resize (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_finish_resize
DECLARE SUB MARQUEE_start_move (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_update_move (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_finish_move
DECLARE SUB MARQUEE_draw_drag_preview ()
DECLARE SUB MARQUEE_draw_existing_box (showHUD AS INTEGER)

' Magic Wand functions
DECLARE SUB MAGIC_WAND_select (x AS INTEGER, y AS INTEGER)
DECLARE SUB MAGIC_WAND_select_with_mode (x AS INTEGER, y AS INTEGER, mode AS INTEGER)
DECLARE SUB MAGIC_WAND_draw_outline ()
DECLARE SUB MAGIC_WAND_reset ()
DECLARE FUNCTION MAGIC_WAND_has_selection% ()
DECLARE SUB MAGIC_WAND_clear_selected_transparent ()

' Freehand selection functions
DECLARE SUB FREEHAND_SEL_start (x AS INTEGER, y AS INTEGER)
DECLARE SUB FREEHAND_SEL_update (x AS INTEGER, y AS INTEGER)
DECLARE SUB FREEHAND_SEL_finish (mode AS INTEGER)
DECLARE SUB FREEHAND_SEL_draw_preview ()
DECLARE SUB FREEHAND_SEL_reset ()

' Polygon selection functions
DECLARE SUB POLY_SEL_add_point (x AS INTEGER, y AS INTEGER)
DECLARE SUB POLY_SEL_close (mode AS INTEGER)
DECLARE SUB POLY_SEL_draw_preview ()
DECLARE SUB POLY_SEL_reset ()

' Ellipse selection functions
DECLARE SUB ELLIPSE_SEL_start (x AS INTEGER, y AS INTEGER)
DECLARE SUB ELLIPSE_SEL_update (x AS INTEGER, y AS INTEGER)
DECLARE SUB ELLIPSE_SEL_finish (mode AS INTEGER)
DECLARE SUB ELLIPSE_SEL_draw_preview ()
DECLARE SUB ELLIPSE_SEL_reset ()

' Selection mask merge helper
DECLARE SUB SELECTION_merge_mask (new_mask AS LONG, mode AS INTEGER)

' Selection operations
DECLARE SUB SELECTION_select_all ()
DECLARE SUB SELECTION_invert ()

' Selection clipping (shared between marquee and wand)
DECLARE FUNCTION SELECTION_is_point_inside% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION SELECTION_has_active% ()
DECLARE SUB SELECTION_get_screen_bbox (sx1 AS INTEGER, sy1 AS INTEGER, sx2 AS INTEGER, sy2 AS INTEGER)

