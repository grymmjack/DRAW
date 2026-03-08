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
CONST PREVIEW_DEFAULT_W = 200
CONST PREVIEW_DEFAULT_H = 200
CONST PREVIEW_MIN_W     = 64
CONST PREVIEW_MIN_H     = 48

TYPE PREVIEW_OBJ
    visible          AS INTEGER   ' TRUE = window is shown
    minimized        AS INTEGER   ' TRUE = collapsed to title bar
    positioned       AS INTEGER   ' TRUE once smart-placement has run

    ' Window geometry
    x                AS INTEGER   ' Screen X of top-left corner
    y                AS INTEGER   ' Screen Y of top-left corner
    w                AS INTEGER   ' Total window width (inc title bar)
    h                AS INTEGER   ' Total window height (inc title bar)

    ' Offscreen render target
    imgHandle        AS LONG

    ' Follow-pointer magnifier mode
    followPointer    AS INTEGER   ' TRUE = center on mouse position

    ' Independent pan/zoom when followPointer = FALSE
    panX             AS SINGLE
    panY             AS SINGLE
    zoom             AS SINGLE
    zoomMin          AS SINGLE
    zoomMax          AS SINGLE

    ' Drag (move window by title bar)
    dragging         AS INTEGER
    dragOffX         AS INTEGER
    dragOffY         AS INTEGER

    ' Pan drag (middle-click inside content area)
    panning          AS INTEGER
    panStartMX       AS INTEGER
    panStartMY       AS INTEGER
    panOrigX         AS SINGLE
    panOrigY         AS SINGLE

    ' Resize (8-edge handles)
    resizing         AS INTEGER
    resizeEdge       AS INTEGER   ' 1=N 2=NE 3=E 4=SE 5=S 6=SW 7=W 8=NW
    resizeStartX     AS INTEGER
    resizeStartY     AS INTEGER
    resizeOrigX      AS INTEGER
    resizeOrigY      AS INTEGER
    resizeOrigW      AS INTEGER
    resizeOrigH      AS INTEGER

    ' Auto-hide: window hides itself while mouse draws over its rect
    autoHidden       AS INTEGER

    ' Cached title-bar font handle (loaded once in PREVIEW_init)
    fontHandle       AS LONG
END TYPE

DIM SHARED PREVIEW AS PREVIEW_OBJ

DECLARE SUB PREVIEW_init ()
DECLARE SUB PREVIEW_cleanup ()
DECLARE SUB PREVIEW_toggle ()
DECLARE SUB PREVIEW_auto_position ()
DECLARE SUB PREVIEW_reset ()
DECLARE SUB PREVIEW_render (destHandle AS LONG)
DECLARE SUB PREVIEW_mouse_input ()
DECLARE SUB PREVIEW_mouse_scroll (delta AS INTEGER)
