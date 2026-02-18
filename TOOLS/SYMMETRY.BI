''
' DRAW - TOOLS/SYMMETRY.BI
' =============================================================================
' UDT for symmetry tool - mirrors drawing across vertical, horizontal, and diagonal axes.
'
' Modes:
' 0 = OFF (no symmetry)
' 1 = VERTICAL (| - vertical line, left/right mirror)
' 2 = CROSS (+ - vertical and horizontal lines, 4-way mirror)
' 3 = ASTERISK (* - vertical, horizontal, and both diagonals, 8-way mirror)
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SYMMETRY_TYPE
    MODE        AS INTEGER        ' Symmetry mode (0-3)
    CENTER_X    AS INTEGER        ' Center point X coordinate
    CENTER_Y    AS INTEGER        ' Center point Y coordinate
    imgHandle   AS LONG           ' Image handle for guide overlay
    imgWidth    AS INTEGER        ' Width of guide overlay
    imgHeight   AS INTEGER        ' Height of guide overlay
    DIRTY       AS INTEGER        ' TRUE when guides need regeneration
    CENTER_SET  AS INTEGER        ' TRUE when center was explicitly set by user (Ctrl+Click)
    guideColor  AS _UNSIGNED LONG ' Color for guide lines
    centerColor AS _UNSIGNED LONG ' Color for center crosshair dot
END TYPE

DIM SHARED SYMMETRY AS SYMMETRY_TYPE
SYMMETRY.MODE = 0
SYMMETRY.CENTER_X% = 0  ' Set properly by SYMMETRY_init() to canvas center X
SYMMETRY.CENTER_Y% = 0  ' Set properly by SYMMETRY_init() to canvas center Y
SYMMETRY.imgHandle& = 0
SYMMETRY.imgWidth% = 0
SYMMETRY.imgHeight% = 0
SYMMETRY.DIRTY% = FALSE
SYMMETRY.CENTER_SET% = FALSE
SYMMETRY.guideColor~& = 0
SYMMETRY.centerColor~& = 0

DECLARE SUB SYMMETRY_init ()
DECLARE SUB SYMMETRY_cycle_mode ()
DECLARE SUB SYMMETRY_clear ()
DECLARE SUB SYMMETRY_set_center (x AS INTEGER, y AS INTEGER)
DECLARE SUB SYMMETRY_get_mirrored_points (x AS INTEGER, y AS INTEGER, mx%(), my%(), count%)
DECLARE SUB SYMMETRY_render_guides (zw AS LONG, zh AS LONG, zoom AS SINGLE)
