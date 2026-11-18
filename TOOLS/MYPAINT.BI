''
' DRAW - TOOLS/MYPAINT.BI
' =============================================================================
' MyPaint brushes (PLANS/MYPAINT.md; Rick 2026-11-17: "add my paint brush engine and brush
' load/save etc. with a palette to choose those brushes" / "for now i don't have a toolbox
' tool so just add to tools menu"). libmypaint (ISC, vendored in native/mypaint) paints
' straight into the current layer through native/mypaint_draw.h; the brushes are .myb files
' (the shipped CC0 sets in ASSETS/BRUSHES/MYPAINT, the user's own in <data>/MYPAINT-BRUSHES).
' The palette is GUI/MYPAINT-PANEL.
'
$INCLUDEONCE

DECLARE LIBRARY "../native/mypaint_draw"
    FUNCTION mp_load& (path AS STRING)
    FUNCTION mp_save& (path AS STRING)
    SUB mp_defaults ()
    SUB mp_error (buf AS STRING, BYVAL cap AS LONG)
    FUNCTION mp_setting_id& (cname AS STRING)
    FUNCTION mp_get_base! (BYVAL id AS LONG)
    SUB mp_set_base (BYVAL id AS LONG, BYVAL v AS SINGLE)
    FUNCTION mp_setting_dynamic& (BYVAL id AS LONG)
    SUB mp_set_color (BYVAL r AS LONG, BYVAL g AS LONG, BYVAL b AS LONG)
    SUB mp_stroke_begin (BYVAL px AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL mask AS _OFFSET, BYVAL mw AS LONG, BYVAL mh AS LONG, BYVAL ox AS LONG, BYVAL oy AS LONG, BYVAL lk AS LONG)
    FUNCTION mp_stroke_to& (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL pressure AS SINGLE, BYVAL xtilt AS SINGLE, BYVAL ytilt AS SINGLE, BYVAL dtime AS DOUBLE, BYVAL zoom AS SINGLE)
    SUB mp_stroke_end (x1 AS LONG, y1 AS LONG, x2 AS LONG, y2 AS LONG)
    SUB mp_stroke_box (x1 AS LONG, y1 AS LONG, x2 AS LONG, y2 AS LONG)
    FUNCTION mp_stroke_steps& ()
    SUB mp_set_twist (BYVAL turns AS SINGLE)
    SUB mp_resample_area (BYVAL dst AS _OFFSET, BYVAL dw AS LONG, BYVAL dh AS LONG, BYVAL src AS _OFFSET, BYVAL sw AS LONG, BYVAL sh AS LONG)
END DECLARE

CONST MYPAINT_ASSET_DIR = "ASSETS/BRUSHES/MYPAINT/" ' the shipped sets (CC0), one folder each
CONST MYPAINT_USER_DIRNAME = "MYPAINT-BRUSHES/"     ' <data>/MYPAINT-BRUSHES: the user's own
CONST MYPAINT_USER_SET = "MY BRUSHES"               ' its name in the palette

' actions (GUI/COMMAND.BM; free range checked 2026-11-18)
CONST MYPAINT_ACT_TOOL   = 2680 ' Tools > MyPaint Brush: the tool (and the palette)
CONST MYPAINT_ACT_PANEL  = 2681 ' View > MyPaint Brushes: the palette
CONST MYPAINT_ACT_LOAD   = 2682 ' load a .myb (file dialog) as the current brush
CONST MYPAINT_ACT_SAVE   = 2683 ' save the current brush as .myb into MY BRUSHES
CONST MYPAINT_ACT_BIGGER = 2684 ' radius up (the brush's own, log steps) - [ / ] with the tool
CONST MYPAINT_ACT_SMALLER = 2685
CONST MYPAINT_ACT_RESET  = 2686 ' back to the brush file's own size / opacity

TYPE MYPAINT_OBJ
    ready      AS INTEGER ' a brush is loaded (else the engine's defaults)
    brushPath  AS STRING  ' the .myb in use ("" = defaults)
    brushName  AS STRING  ' its name (file name without .myb)
    setName    AS STRING  ' its set (folder) name
    baseRadius AS SINGLE  ' the file's radius_logarithmic
    baseOpaque AS SINGLE  ' the file's opaque
    active     AS INTEGER ' a stroke is going on
    fresh      AS INTEGER ' no event yet this stroke: the first one primes the brush at its spot
    btn        AS INTEGER ' 1 = left (FG), 2 = right (BG)
    layerSlot  AS INTEGER ' the layer it paints on
    beforeImg  AS LONG    ' that layer before the stroke (history)
    lastT      AS DOUBLE  ' TIMER of the last stroke_to
    lastX      AS SINGLE  ' last event (buffer px)
    lastY      AS SINGLE
    lastP      AS SINGLE  ' last event's pressure (the frame's samples blend from it)
    bx1        AS LONG    ' the last stroke's changed box (buffer px; x1 > x2 = none)
    by1        AS LONG
    bx2        AS LONG
    by2        AS LONG
    steps      AS LONG    ' stroke_to calls in the last stroke
    strokes    AS LONG    ' strokes painted this session (QA)
    err        AS STRING  ' the last load / save error
END TYPE
DIM SHARED MYPAINT AS MYPAINT_OBJ
DIM SHARED MYPAINT_ID_RADIUS AS LONG, MYPAINT_ID_OPAQUE AS LONG ' setting ids (mp_setting_id)
