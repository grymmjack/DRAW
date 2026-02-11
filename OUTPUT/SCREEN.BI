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
    displayScale AS INTEGER  ' Current display scale multiplier (1-8)
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
    showMenubar AS INTEGER ' Show/hide menu bar
    toolbarManuallyHidden AS INTEGER ' Toolbar manually hidden by user
    statusManuallyHidden AS INTEGER  ' Status manually hidden by user
    menubarManuallyHidden AS INTEGER ' Menu bar manually hidden by user
    layerPanelManuallyHidden AS INTEGER ' Layer panel manually hidden by user
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ

' GUI dirty flag - when FALSE, skip toolbar/status redraw for performance
' Set to TRUE when: tool switch, palette change, window resize, toolbar/status toggle
DIM SHARED GUI_NEEDS_REDRAW AS INTEGER
GUI_NEEDS_REDRAW% = TRUE ' Start with redraw needed

' Cached pixel grid image — avoid _NEWIMAGE/_FREEIMAGE every frame at 400%+ zoom
DIM SHARED PG_CACHE_IMG AS LONG
DIM SHARED PG_CACHE_ZW AS LONG
DIM SHARED PG_CACHE_ZH AS LONG
DIM SHARED PG_CACHE_ZOOM AS INTEGER
DIM SHARED PG_CACHE_COLOR AS _UNSIGNED LONG

' Scene cache — fully rendered canvas (layers+grid+GUI) before cursor
' When only cursor position changes, copy from cache instead of full repaint
DIM SHARED SCENE_CACHE AS LONG       ' Cached pre-cursor canvas image
DIM SHARED SCENE_DIRTY AS INTEGER    ' TRUE = must do full repaint
SCENE_DIRTY% = TRUE                  ' Start dirty

SCREEN_init
