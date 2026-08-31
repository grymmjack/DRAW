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
    ACTIVE         AS INTEGER ' TRUE while transform overlay is live
    MODE           AS INTEGER ' TRANSFORM_MODE_*
    ' Source region on layer (layer pixel coords)
    SRC_X          AS INTEGER
    SRC_Y          AS INTEGER
    SRC_W          AS INTEGER
    SRC_H          AS INTEGER
    SRC_IMG        AS LONG    ' Copy of source pixels captured on activate
    SRC_MASK       AS LONG    ' BUG-10: snapshot of the wand/lasso selection mask (canvas-sized) when
                         ' transforming an irregular selection; 0 for rect / whole-layer. Used to
                         ' lift & erase ONLY masked pixels so in-bbox/out-of-mask content survives.
    ' Drag state
    GRABBED        AS INTEGER ' -1 = none  0-3 = corner handle  4 = body drag
    DRAG_OFX       AS SINGLE  ' Offset from handle to mouse at press (canvas px)
    DRAG_OFY       AS SINGLE
    ' Status-bar display values
    ANGLE          AS SINGLE  ' Degrees (ROTATE)
    SCALE_X        AS SINGLE  ' (SCALE)
    SCALE_Y        AS SINGLE
    ' Restore on cancel / commit
    PREV_TOOL      AS INTEGER
    ' Transform Selection: TRUE = warp the SELECTION MASK only, leave layer pixels alone
    ' (Photoshop's Select > Transform Selection). SRC_IMG is a mask visualization.
    SELECTION_ONLY AS INTEGER
    ' BUG-11: activate-time apron demote is destructive (off-canvas pixels sacrificed).
    ' Stash the pre-demote buffer + apron dims so (a) commit records it as the undo
    ' target — history restore rebuilds apronW/H from the image's dimensions — and
    ' (b) cancel / any activate early-out rolls the demote back verbatim. Without
    ' this, undo restored only the compact post-demote layer (apron content gone),
    ' and an early-out demoted with nothing recorded at all — permanent loss.
    HIST_BEFORE    AS LONG    ' pre-demote _COPYIMAGE of the layer (apron-extended); 0 = none
    PRE_APRON_W    AS INTEGER ' apronW% before the demote (rollback target)
    PRE_APRON_H    AS INTEGER ' apronH% before the demote (rollback target)
    DID_DEMOTE     AS INTEGER ' TRUE if activate demoted the layer this session
    DEMOTE_LAYER   AS INTEGER ' layer slot that was demoted (rollback target)
    MODIFIED       AS INTEGER ' F5: TRUE once a handle drag / rotate actually changes the quad;
                            ' commit skips the undo record when still FALSE (Enter with no edit)
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
