''
' DRAW - GUI/CURSOR.BI
' =============================================================================
' Cursor system type definitions and constants.
'
' Each cursor has:
'   - A PNG filename loaded from the theme's CURSORS/ directory
'   - Hotspot coordinates (where the action point is within the cursor image)
'   - Optional overlay areas for FG/BG color chips
'   - Optional text overlays for coordinates and transform info
'
' Position expressions support keywords: top, bottom/bot, left, right, center
' and arithmetic: top-1, right+20, center, 2, etc.
' Expressions are evaluated relative to cursor image dimensions at load time.
'
' Text template variables:
'   %mx %my    = mouse position x/y
'   %ow %oh    = old width/height (before transform)
'   %ox %oy    = old x/y position (before transform)
'   %nw %nh    = new width/height (after transform)
'   %nx %ny    = new x/y position (after transform)
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Cursor index constants
CONST CURSOR_NULL           = 0
CONST CURSOR_BRUSH          = 1
CONST CURSOR_DROPPER        = 2
CONST CURSOR_FILL           = 3
CONST CURSOR_HAND           = 4
CONST CURSOR_MARQUEE        = 5
CONST CURSOR_MOVE           = 6
CONST CURSOR_RESIZE_CORNER  = 7
CONST CURSOR_RESIZE_HORIZ   = 8
CONST CURSOR_RESIZE_VERT    = 9
CONST CURSOR_SPRAY          = 10
CONST CURSOR_WAND           = 11
CONST CURSOR_ZOOM           = 12
CONST CURSOR_MARQUEE_RECT   = 13
CONST CURSOR_MARQUEE_FREE   = 14
CONST CURSOR_MARQUEE_POLY   = 15
CONST CURSOR_MARQUEE_ELLIP  = 16
CONST CURSOR_COUNT          = 16  ' 0-based max index

TYPE CURSOR_OBJ
    ' --- Core ---
    filename             AS STRING   ' PNG filename (e.g. "cursor-brush.png")
    img                  AS LONG     ' Loaded image handle (< -1 = valid)
    w                    AS INTEGER  ' Cached image width
    h                    AS INTEGER  ' Cached image height
    loaded               AS INTEGER  ' TRUE once load has been attempted

    ' --- Hotspot (where the action point is) ---
    hotspot_x_expr       AS STRING   ' Position expression for hotspot X (e.g. "left", "center", "4")
    hotspot_y_expr       AS STRING   ' Position expression for hotspot Y (e.g. "bottom-1", "top", "2")
    hotspot_pos_x        AS INTEGER  ' Evaluated hotspot X in pixels
    hotspot_pos_y        AS INTEGER  ' Evaluated hotspot Y in pixels

    ' --- Overlay enable flags ---
    uses_overlay_fg      AS INTEGER  ' TRUE to render FG color chip on cursor
    uses_overlay_bg      AS INTEGER  ' TRUE to render BG color chip on cursor
    uses_overlay_coords  AS INTEGER  ' TRUE to render coords text overlay
    uses_overlay_transform AS INTEGER ' TRUE to render transform text overlay

    ' --- FG color chip overlay position/size (expressions) ---
    fg_color_x           AS STRING   ' X position expression for FG color chip
    fg_color_y           AS STRING   ' Y position expression for FG color chip
    fg_color_w           AS STRING   ' Width expression for FG color chip
    fg_color_h           AS STRING   ' Height expression for FG color chip
    ' --- Evaluated FG values ---
    fg_color_px          AS INTEGER  ' Evaluated FG X
    fg_color_py          AS INTEGER  ' Evaluated FG Y
    fg_color_pw          AS INTEGER  ' Evaluated FG width
    fg_color_ph          AS INTEGER  ' Evaluated FG height

    ' --- BG color chip overlay position/size (expressions) ---
    bg_color_x           AS STRING   ' X position expression for BG color chip
    bg_color_y           AS STRING   ' Y position expression for BG color chip
    bg_color_w           AS STRING   ' Width expression for BG color chip
    bg_color_h           AS STRING   ' Height expression for BG color chip
    ' --- Evaluated BG values ---
    bg_color_px          AS INTEGER  ' Evaluated BG X
    bg_color_py          AS INTEGER  ' Evaluated BG Y
    bg_color_pw          AS INTEGER  ' Evaluated BG width
    bg_color_ph          AS INTEGER  ' Evaluated BG height

    ' --- Coords text overlay ---
    overlay_coords_x     AS STRING   ' X position expression for coords text
    overlay_coords_y     AS STRING   ' Y position expression for coords text
    overlay_coords_text  AS STRING   ' Template text (e.g. "%mx,%my")
    ' --- Evaluated coords values ---
    overlay_coords_px    AS INTEGER  ' Evaluated coords X
    overlay_coords_py    AS INTEGER  ' Evaluated coords Y

    ' --- Transform text overlay ---
    overlay_transform_x  AS STRING   ' X position expression for transform text
    overlay_transform_y  AS STRING   ' Y position expression for transform text
    overlay_transform_text AS STRING ' Template text (e.g. "%ow x %oh -> %nw x %nh")
    ' --- Evaluated transform values ---
    overlay_transform_px AS INTEGER  ' Evaluated transform X
    overlay_transform_py AS INTEGER  ' Evaluated transform Y
END TYPE

DIM SHARED CURSORS(0 TO CURSOR_COUNT) AS CURSOR_OBJ
DIM SHARED CURSORS_DIR AS STRING

' Initialize cursor system (called from POINTER_init)
DECLARE SUB CURSOR_init ()
DECLARE SUB CURSOR_load (idx AS INTEGER)
DECLARE SUB CURSOR_load_all ()
DECLARE SUB CURSOR_cleanup ()
DECLARE FUNCTION CURSOR_eval_expr% (expr AS STRING, dimension AS INTEGER, is_x_axis AS INTEGER)
DECLARE SUB CURSOR_render_overlays (idx AS INTEGER, dx AS INTEGER, dy AS INTEGER, mouse_x AS INTEGER, mouse_y AS INTEGER, ow AS INTEGER, oh AS INTEGER, ox AS INTEGER, oy AS INTEGER, nw AS INTEGER, nh AS INTEGER, nx AS INTEGER, ny AS INTEGER)
DECLARE FUNCTION CURSOR_format_text$ (template AS STRING, mouse_x AS INTEGER, mouse_y AS INTEGER, ow AS INTEGER, oh AS INTEGER, ox AS INTEGER, oy AS INTEGER, nw AS INTEGER, nh AS INTEGER, nx AS INTEGER, ny AS INTEGER)
