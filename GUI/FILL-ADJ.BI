''
' DRAW - GUI/FILL-ADJ.BI
' =============================================================================
' Interactive fill adjustment overlay mode.
' Toggled ON/OFF with F8. When enabled, every filled shape + custom brush
' release enters interactive adjustment mode (wheel=scale, drag=pan,
' Enter=commit, Esc=cancel).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST FILL_ADJ_SHAPE_RECT = 0
CONST FILL_ADJ_SHAPE_ELLIPSE = 1
CONST FILL_ADJ_SHAPE_POLYGON = 2
CONST FILL_ADJ_SHAPE_FLOOD = 3

' Paint source mode (what is being tiled/sampled)
CONST FILL_ADJ_PAINT_BRUSH = 0     ' Custom brush tiling
CONST FILL_ADJ_PAINT_PATTERN = 1   ' Drawer pattern tiling
CONST FILL_ADJ_PAINT_GRADIENT = 2  ' Drawer gradient mapping

' Drag mode constants for L-shaped handle
CONST FILL_ADJ_DRAG_NONE = 0       ' Not dragging
CONST FILL_ADJ_DRAG_PAN = 1        ' Dragging background = pan origin
CONST FILL_ADJ_DRAG_UNIFORM = 2    ' Dragging corner handle = uniform scale
CONST FILL_ADJ_DRAG_SCALE_X = 3    ' Dragging horizontal arm = scale X only
CONST FILL_ADJ_DRAG_SCALE_Y = 4    ' Dragging vertical arm = scale Y only
CONST FILL_ADJ_DRAG_ROTATE = 5     ' Dragging rotation handle = rotate tile

TYPE FILL_ADJ_OBJ
    ENABLED         AS INTEGER      ' Toggle: F8 latches this on/off
    ACTIVE          AS INTEGER      ' Whether interactive adjustment mode is on
    SHAPE_TYPE      AS INTEGER      ' FILL_ADJ_SHAPE_*
    ' Rect geometry
    RECT_X1         AS INTEGER
    RECT_Y1         AS INTEGER
    RECT_X2         AS INTEGER
    RECT_Y2         AS INTEGER
    ' Ellipse geometry
    ELL_CX          AS INTEGER
    ELL_CY          AS INTEGER
    ELL_RX          AS SINGLE
    ELL_RY          AS SINGLE
    ' Polygon vertex count (vertices in FILL_ADJ_POLY_X/Y arrays)
    POLY_COUNT      AS INTEGER
    ' Flood fill mask (canvas-sized image: white=filled, transparent=skip)
    FILL_MASK       AS LONG
    FLOOD_X1        AS INTEGER      ' Flood fill bounding box
    FLOOD_Y1        AS INTEGER
    FLOOD_X2        AS INTEGER
    FLOOD_Y2        AS INTEGER
    ' Paint source mode
    PAINT_MODE      AS INTEGER      ' FILL_ADJ_PAINT_* — what type of fill
    ' Tile adjustment parameters
    TILE_W          AS SINGLE       ' Current tile width (starts at brush width)
    TILE_H          AS SINGLE       ' Current tile height (starts at brush height)
    ORIGIN_X        AS SINGLE       ' Tile origin X offset (canvas pixels)
    ORIGIN_Y        AS SINGLE       ' Tile origin Y offset (canvas pixels)
    ROTATION        AS SINGLE       ' Tile rotation in degrees (0 = no rotation)
    ' Undo/restore images
    REDRAW_IMG      AS LONG         ' Layer state to restore before each re-render
    CANCEL_IMG      AS LONG         ' Layer state for full cancel (pre-shape)
    LAYER_IDX       AS INTEGER      ' Which layer index
    HISTORY_FLAGS   AS LONG         ' History flags for commit
    ' Drag state
    DRAGGING        AS INTEGER      ' Whether currently dragging
    DRAG_MODE       AS INTEGER      ' FILL_ADJ_DRAG_* — what's being dragged
    DRAG_START_MX   AS INTEGER      ' Screen X when drag started
    DRAG_START_MY   AS INTEGER      ' Screen Y when drag started
    DRAG_START_CX   AS INTEGER      ' Canvas X when drag started
    DRAG_START_CY   AS INTEGER      ' Canvas Y when drag started
    START_ORIGIN_X  AS SINGLE       ' Origin X at drag start
    START_ORIGIN_Y  AS SINGLE       ' Origin Y at drag start
    START_TILE_W    AS SINGLE       ' Tile W at drag start (for scale drags)
    START_TILE_H    AS SINGLE       ' Tile H at drag start (for scale drags)
    START_ROTATION  AS SINGLE       ' Rotation at drag start (for rotate drags)
    START_ANGLE     AS SINGLE       ' Mouse angle at drag start (radians)
END TYPE

DIM SHARED FILL_ADJ AS FILL_ADJ_OBJ
DIM SHARED FILL_ADJ_POLY_X(999) AS INTEGER
DIM SHARED FILL_ADJ_POLY_Y(999) AS INTEGER
DIM SHARED FILL_ADJ_ICON_HANDLE AS LONG   ' Loaded PNG widget handle (0 = not loaded, -1 = no file)

DECLARE SUB FILL_ADJ_enter_rect (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, cancel_img AS LONG, history_flags AS LONG)
DECLARE SUB FILL_ADJ_enter_ellipse (cx AS INTEGER, cy AS INTEGER, rx AS SINGLE, ry AS SINGLE, cancel_img AS LONG, history_flags AS LONG)
DECLARE SUB FILL_ADJ_enter_polygon (x_coords%(), y_coords%(), num_points AS INTEGER, cancel_img AS LONG, history_flags AS LONG)
DECLARE SUB FILL_ADJ_enter_flood (mask_img AS LONG, bx1 AS INTEGER, by1 AS INTEGER, bx2 AS INTEGER, by2 AS INTEGER, cancel_img AS LONG, history_flags AS LONG)
DECLARE SUB FILL_ADJ_update ()
DECLARE SUB FILL_ADJ_commit ()
DECLARE SUB FILL_ADJ_cancel ()
DECLARE SUB FILL_ADJ_reset ()
DECLARE SUB FILL_ADJ_handle_wheel (delta AS INTEGER)
DECLARE SUB FILL_ADJ_handle_mouse_press (cx AS INTEGER, cy AS INTEGER, rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB FILL_ADJ_handle_mouse_drag (cx AS INTEGER, cy AS INTEGER, rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB FILL_ADJ_handle_mouse_release ()
DECLARE FUNCTION FILL_ADJ_hit_test% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB FILL_ADJ_render_overlay ()
DECLARE SUB FILL_ADJ_render_mask_brush ()
DECLARE SUB FILL_ADJ_render_paint_mode ()
DECLARE SUB FILL_ADJ_detect_paint_mode ()
DECLARE SUB FILL_ADJ_compute_shape_tile_size (outW AS SINGLE, outH AS SINGLE)
DECLARE SUB FILL_ADJ_toggle_enabled ()
DECLARE SUB FILL_ADJ_rotate_coords (inX AS SINGLE, inY AS SINGLE, angleDeg AS SINGLE, outX AS SINGLE, outY AS SINGLE)
DECLARE FUNCTION FILL_ADJ_is_active% ()
