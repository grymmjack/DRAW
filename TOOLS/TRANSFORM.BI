''
' DRAW - TOOLS/TRANSFORM.BI
' =============================================================================
' On-canvas transform modes: Scale, Rotate, Shear, Distort, Perspective.
' Activated from Edit -> TRANSFORM -> submenu.  Overlay handles live on the
' canvas; ENTER commits, ESC cancels.  No modal dialogs.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ---- Action IDs (Edit -> TRANSFORM -> submenu) ----
CONST TRANSFORM_ACT_SCALE       = 325
CONST TRANSFORM_ACT_DISTORT     = 326
CONST TRANSFORM_ACT_PERSPECTIVE = 327
CONST TRANSFORM_ACT_ROTATE      = 328
CONST TRANSFORM_ACT_SHEAR       = 329
CONST TRANSFORM_ACT_FLYOUT      = 330

CONST TRANSFORM_FLYOUT_ITEMS = 5

' ---- Transform modes ----
CONST TRANSFORM_MODE_SCALE       = 1
CONST TRANSFORM_MODE_ROTATE      = 2
CONST TRANSFORM_MODE_SHEAR       = 3
CONST TRANSFORM_MODE_DISTORT     = 4
CONST TRANSFORM_MODE_PERSPECTIVE = 5

' ---- Handle sizing (screen pixels) ----
CONST TRANSFORM_HANDLE_RADIUS = 7 ' hit-test radius
CONST TRANSFORM_HANDLE_HALF   = 5 ' draw half-size of square handle

TYPE TRANSFORM_OBJ
    ACTIVE    AS INTEGER ' TRUE while transform overlay is live
    MODE      AS INTEGER ' TRANSFORM_MODE_*
    ' Source region on layer (layer pixel coords)
    SRC_X     AS INTEGER
    SRC_Y     AS INTEGER
    SRC_W     AS INTEGER
    SRC_H     AS INTEGER
    SRC_IMG   AS LONG    ' Copy of source pixels captured on activate
    ' Drag state
    GRABBED   AS INTEGER ' -1 = none  0-3=corner handle  4=body drag
    DRAG_OFX  AS SINGLE  ' Offset from handle to mouse at press (canvas px)
    DRAG_OFY  AS SINGLE
    ' Status-bar display values
    ANGLE     AS SINGLE  ' Degrees (ROTATE)
    SCALE_X   AS SINGLE  ' (SCALE)
    SCALE_Y   AS SINGLE
    ' Restore on cancel / commit
    PREV_TOOL AS INTEGER
END TYPE
DIM SHARED TRANSFORM AS TRANSFORM_OBJ

' 4 corner handles in layer (canvas pixel) coords
' Order: 0=TL  1=TR  2=BR  3=BL
DIM SHARED TRANSFORM_HX(3) AS SINGLE
DIM SHARED TRANSFORM_HY(3) AS SINGLE
' Snapshotted positions at the start of each drag (for constrained modes)
DIM SHARED TRANSFORM_HX0(3) AS SINGLE
DIM SHARED TRANSFORM_HY0(3) AS SINGLE
' Pivot (centre) in layer coords (for ROTATE)
DIM SHARED TRANSFORM_PX            AS SINGLE
DIM SHARED TRANSFORM_PY            AS SINGLE
' Pivot snapshot at start of drag (body-drag uses this to avoid accumulation)
DIM SHARED TRANSFORM_PX0           AS SINGLE
DIM SHARED TRANSFORM_PY0           AS SINGLE
' Cached warped preview image
DIM SHARED TRANSFORM_PREVIEW_IMG   AS LONG
DIM SHARED TRANSFORM_PREVIEW_OX    AS INTEGER ' Layer-space bounding-box origin
DIM SHARED TRANSFORM_PREVIEW_OY    AS INTEGER
DIM SHARED TRANSFORM_PREVIEW_DIRTY AS INTEGER

' ---- Public declarations ----
DECLARE SUB TRANSFORM_activate (mode AS INTEGER)
DECLARE SUB TRANSFORM_cancel ()
DECLARE SUB TRANSFORM_commit ()
DECLARE SUB TRANSFORM_rotate_step (deltaDegrees AS SINGLE)
DECLARE SUB TRANSFORM_render_overlay ()
DECLARE SUB TRANSFORM_render_status (canvas AS LONG)
DECLARE SUB TRANSFORM_mouse_press (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB TRANSFORM_mouse_hold  (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB TRANSFORM_mouse_release ()
