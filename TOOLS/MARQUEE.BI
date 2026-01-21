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
END TYPE

DIM SHARED MARQUEE AS MARQUEE_OBJ

DECLARE FUNCTION MARQUEE_is_point_inside% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION MARQUEE_get_handle_at% (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_start_resize (handle AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_update_resize (x AS INTEGER, y AS INTEGER)
DECLARE SUB MARQUEE_finish_resize

