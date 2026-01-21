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
END TYPE

DIM SHARED MARQUEE AS MARQUEE_OBJ

DECLARE FUNCTION MARQUEE_is_point_inside% (x AS INTEGER, y AS INTEGER)

