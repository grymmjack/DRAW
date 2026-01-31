''
' DRAW - TOOLS/CUSTOM-BRUSH.BI
' =============================================================================
' Custom brush tool - Deluxe Paint style custom brush capture and painting.
'
' Captures a rectangular area from the canvas and turns it into a reusable
' brush that can be:
' - Stamped down with a single click
' - Painted with by dragging
' - Used with any drawing tool (line, rect, ellipse, etc.)
' - Flipped horizontally or vertically
' - Made transparent based on background color matching
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE CUSTOM_BRUSH_OBJ
    ACTIVE      AS INTEGER          ' Whether a custom brush is loaded
    WIDTH       AS INTEGER          ' Current brush width in pixels
    HEIGHT      AS INTEGER          ' Current brush height in pixels
    ORIG_WIDTH  AS INTEGER          ' Original brush width (for reset)
    ORIG_HEIGHT AS INTEGER          ' Original brush height (for reset)
    IMAGE       AS LONG             ' Image handle for the brush
    FLIP_H      AS INTEGER          ' Horizontal flip flag (-1 or 0)
    FLIP_V      AS INTEGER          ' Vertical flip flag (-1 or 0)
    HAS_TRANSPARENCY AS INTEGER     ' Whether brush uses transparency
    BG_COLOR    AS _UNSIGNED LONG   ' Background color used for transparency
    SCALE       AS SINGLE           ' Current scale factor (1.0 = 100%)
END TYPE

DIM SHARED CUSTOM_BRUSH AS CUSTOM_BRUSH_OBJ

' Public interface
DECLARE SUB CUSTOM_BRUSH_init ()
DECLARE SUB CUSTOM_BRUSH_reset ()
DECLARE SUB CUSTOM_BRUSH_capture_from_marquee ()
DECLARE SUB CUSTOM_BRUSH_render (x AS INTEGER, y AS INTEGER, dest AS LONG)
DECLARE SUB CUSTOM_BRUSH_render_scaled (x AS INTEGER, y AS INTEGER, dest AS LONG, zoom AS SINGLE)
DECLARE SUB CUSTOM_BRUSH_stamp (x AS INTEGER, y AS INTEGER)
DECLARE SUB CUSTOM_BRUSH_toggle_flip_h ()
DECLARE SUB CUSTOM_BRUSH_toggle_flip_v ()
DECLARE SUB CUSTOM_BRUSH_scale_up ()
DECLARE SUB CUSTOM_BRUSH_scale_down ()
DECLARE SUB CUSTOM_BRUSH_scale_reset ()
DECLARE SUB CUSTOM_BRUSH_export_png (filepath AS STRING)
DECLARE FUNCTION CUSTOM_BRUSH_is_active% ()
