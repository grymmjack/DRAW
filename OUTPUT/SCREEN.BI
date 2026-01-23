''
' DRAW - OUTPUT/SCREEN.BI
' =============================================================================
' UDT for screen output.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SCREEN_OBJ
    w        AS LONG
    h        AS LONG
    bpp      AS INTEGER
    CANVAS   AS LONG
    PAINTING AS LONG
    CURSOR   AS LONG
    GUI      AS LONG
    zoom     AS SINGLE   ' Current zoom level
    zoomMin  AS SINGLE   ' Minimum zoom
    zoomMax  AS SINGLE   ' Maximum zoom
    offsetX  AS INTEGER  ' Pan offset X
    offsetY  AS INTEGER  ' Pan offset Y
    panning  AS INTEGER  ' Whether in pan mode
    panStartX AS INTEGER ' Pan drag start X
    panStartY AS INTEGER ' Pan drag start Y
    panOrigOffsetX AS INTEGER ' Original offset when pan started
    panOrigOffsetY AS INTEGER ' Original offset when pan started
    showToolbar AS INTEGER ' Show/hide toolbar
    showStatus AS INTEGER  ' Show/hide status bar
    toolbarManuallyHidden AS INTEGER ' Toolbar manually hidden by user
    statusManuallyHidden AS INTEGER  ' Status manually hidden by user
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ

SCREEN_init
