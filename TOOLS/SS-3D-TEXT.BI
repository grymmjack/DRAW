''
' DRAW - TOOLS/SS-3D-TEXT.BI
' =============================================================================
' Smart-Shape 3D TEXT — extruded wireframe text using raster silhouette
' tracing. Works with any font format the text tool can rasterize: built-in
' VGA bitmap, Tiny5 / TTF / OTF / FON / CBF — anything FONT_LIST_get_handle&
' returns a valid handle for.
'
' Workflow:
'   1. Press → DRAW_input_box$ prompts for text. Empty cancels the drag.
'   2. Drag → bbox sets size. Wireframe extruded preview rendered live.
'   3. Release → wireframe baked onto active layer with SS_stroke_line.
'
' Keyboard while dragging:
'   ↑/↓   Z_DEPTH ±5 (extrusion thickness)
'   ←/→   ROT_Y ±5
'   Wheel ROT_X ±5 (Shift = ±15 coarse)
'
' Number keys 1..0 are intentionally NOT consumed so opacity adjustment via
' the digit row keeps working during drag.
'
$INCLUDEONCE

CONST SS_TEXT_MAX_VERTS = 8192
CONST SS_TEXT_MAX_EDGES = 16384

TYPE SS_TEXT_TYPE
    DRAGGING   AS INTEGER
    X0         AS INTEGER
    Y0         AS INTEGER
    X1         AS INTEGER
    Y1         AS INTEGER
    Z_DEPTH    AS INTEGER ' 5..200 (% of min(w,h))
    ROT_X      AS INTEGER ' degrees
    ROT_Y      AS INTEGER ' degrees
    txt        AS STRING * 256
    txtLen     AS INTEGER
    fontIdx    AS INTEGER
    fontSize   AS INTEGER
    bold       AS INTEGER
    italic     AS INTEGER
    antialias  AS INTEGER
    monospace  AS INTEGER
    ' Cached canonical mesh (computed once per drag)
    meshValid  AS INTEGER
    meshVCount AS INTEGER
    meshECount AS INTEGER
    meshAspect AS SINGLE  ' canonical width / height (used for bbox fit)
    maskW      AS INTEGER ' rasterized mask width  (incl. padding)
    maskH      AS INTEGER ' rasterized mask height (incl. padding)
END TYPE
DIM SHARED SS_TEXT AS SS_TEXT_TYPE
DIM SHARED SS_TEXT_VX(0 TO SS_TEXT_MAX_VERTS - 1) AS SINGLE
DIM SHARED SS_TEXT_VY(0 TO SS_TEXT_MAX_VERTS - 1) AS SINGLE
DIM SHARED SS_TEXT_VZ(0 TO SS_TEXT_MAX_VERTS - 1) AS SINGLE
DIM SHARED SS_TEXT_EA(0 TO SS_TEXT_MAX_EDGES - 1) AS INTEGER
DIM SHARED SS_TEXT_EB(0 TO SS_TEXT_MAX_EDGES - 1) AS INTEGER
' Per-edge face-orientation kind: 0=TOP, 1=BOTTOM, 2=LEFT, 3=RIGHT
' Used by flat-shaded renderer to pick brightness per ribbon.
DIM SHARED SS_TEXT_EKIND(0 TO SS_TEXT_MAX_EDGES - 1) AS _BYTE

SS_TEXT.Z_DEPTH    = 30
SS_TEXT.ROT_X      = 15
SS_TEXT.ROT_Y      = -15
SS_TEXT.fontIdx    = 0
SS_TEXT.fontSize   = 32
SS_TEXT.bold       = FALSE
SS_TEXT.italic     = FALSE
SS_TEXT.antialias  = FALSE
SS_TEXT.monospace  = FALSE
SS_TEXT.meshAspect = 1.0
