''
' DRAW - GUI/PREVIEW.BI
' =============================================================================
' Preview Window — declarations, TYPE, and shared state.
' A resizable, movable floating window showing a live canvas preview.
' Supports follow-pointer magnifier mode and independent pan/zoom.
' Toggle with F4. State persists to DRAW.cfg.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' --- Default geometry ---
CONST PREVIEW_DEFAULT_W = 120
CONST PREVIEW_DEFAULT_H = 100
CONST PREVIEW_MIN_W     = 120
CONST PREVIEW_MIN_H     = 100

TYPE PREVIEW_OBJ
    visible    AS INTEGER             ' TRUE = window is shown
    minimized  AS INTEGER             ' TRUE = collapsed to title bar
    positioned AS INTEGER             ' TRUE once smart-placement has run

    ' Window geometry
    x AS INTEGER                      ' Screen X of top-left corner
    y AS INTEGER                      ' Screen Y of top-left corner
    w AS INTEGER                      ' Total window width (inc title bar)
    h AS INTEGER                      ' Total window height (inc title bar)

    ' Offscreen render target
    imgHandle AS LONG

    ' Follow-pointer magnifier mode
    followPointer AS INTEGER          ' TRUE = center on mouse position

    ' Independent pan/zoom when followPointer = FALSE
    panX    AS SINGLE
    panY    AS SINGLE
    zoom    AS SINGLE
    zoomMin AS SINGLE
    zoomMax AS SINGLE

    ' Drag (move window by title bar)
    dragging AS INTEGER
    dragOffX AS INTEGER
    dragOffY AS INTEGER

    ' Pan drag (middle-click inside content area)
    panning    AS INTEGER
    panStartMX AS INTEGER
    panStartMY AS INTEGER
    panOrigX   AS SINGLE
    panOrigY   AS SINGLE

    ' Resize (8-edge handles)
    resizing     AS INTEGER
    resizeEdge   AS INTEGER           ' 1 = N 2 = NE 3 = E 4 = SE 5 = S 6 = SW 7 = W 8 = NW
    resizeStartX AS INTEGER
    resizeStartY AS INTEGER
    resizeOrigX  AS INTEGER
    resizeOrigY  AS INTEGER
    resizeOrigW  AS INTEGER
    resizeOrigH  AS INTEGER

    ' Auto-hide: window hides itself while mouse draws over its rect
    autoHidden AS INTEGER

    ' Cached title-bar font handle (loaded once in PREVIEW_init)
    fontHandle AS LONG

    ' --- Mode: 0 = Follow (magnifier), 1 = Floating Image ---
    mode AS INTEGER                   ' PREVIEW_MODE_FOLLOW or PREVIEW_MODE_FLOAT

    ' Floating image state (mode = 1)
    floatImage      AS LONG           ' Loaded image handle (< -1 when valid)
    floatImageW     AS INTEGER        ' Original image width
    floatImageH     AS INTEGER        ' Original image height
    floatImagePath  AS STRING         ' Full file path on disk
    floatImageDepth AS INTEGER        ' Color depth (e.g. 32)

    ' Color picking from preview canvas
    colorPickEnabled AS INTEGER       ' TRUE = allow alt-click color sampling

    ' Bin Quick Look state
    binQuickLookEnabled AS INTEGER    ' TRUE = show bin preview on drawer hover
    binQuickLookActive  AS INTEGER    ' TRUE = currently showing a bin preview
    binQuickLookSlot    AS INTEGER    ' Which drawer slot (1..30) is previewed
    binQuickLookMode    AS INTEGER    ' DRAWER_MODE_BRUSH / PATTERN / GRADIENT
    binQuickLookImg     AS LONG       ' Temp image handle for bin preview content

    ' Floating image tooltip hover tracking
    floatTooltipHoverStart AS DOUBLE  ' TIMER value when hover began
    floatTooltipActive     AS INTEGER ' TRUE = tooltip currently showing
    floatTooltipLastMX     AS INTEGER ' Last mouse X for hover tracking
    floatTooltipLastMY     AS INTEGER ' Last mouse Y for hover tracking
END TYPE

' Preview window mode constants
CONST PREVIEW_MODE_FOLLOW = 0
CONST PREVIEW_MODE_FLOAT  = 1

DIM SHARED PREVIEW AS PREVIEW_OBJ

