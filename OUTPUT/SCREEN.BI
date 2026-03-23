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
    w        AS LONG          ' Screen buffer / viewport width (GUI resolution)
    h        AS LONG          ' Screen buffer / viewport height (GUI resolution)
    canvasW  AS LONG          ' Actual artwork/canvas width (may be smaller than w)
    canvasH  AS LONG          ' Actual artwork/canvas height (may be smaller than h)
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
    layerPanelManuallyHidden AS INTEGER
    showPreviewWindow         AS INTEGER   ' TRUE when preview window is visible
    previewManuallyHidden     AS INTEGER   ' TRUE when user explicitly hid preview window
    previewHiddenByToggleAll  AS INTEGER   ' TRUE only when toggle-all (F11) hid the preview
    showEditBar               AS INTEGER   ' TRUE when edit bar is visible
    editBarManuallyHidden     AS INTEGER   ' TRUE when user explicitly hid edit bar
    editBarHiddenByToggleAll  AS INTEGER   ' TRUE only when toggle-all (F11) hid the edit bar
    textBarHiddenByToggleAll  AS INTEGER   ' TRUE only when toggle-all (F11) hid the text bar
    ' Computed layout geometry — set by SCREEN_compute_layout() each render pass
    uiLeftEdge   AS INTEGER  ' Canvas work area left X (after all left panels)
    uiRightEdge  AS INTEGER  ' Canvas work area right X (before all right panels)
    panelShiftX  AS INTEGER  ' Horizontal pixel offset to center canvas between panels
    layerPanelX  AS INTEGER  ' Left edge of layer panel (position varies by dock side)
    toolboxX     AS INTEGER  ' Left edge of toolbox stack background
    editBarX     AS INTEGER  ' Left edge of edit bar (position varies by dock side)
    menuBarLeftEdge  AS INTEGER  ' Menubar left X (after layers+toolbox, but NOT editbar)
    menuBarRightEdge AS INTEGER  ' Menubar right X (before layers+toolbox, but NOT editbar)
    ' Side-toggle bookkeeping — restore only what each side command itself hid
    toolbarHiddenByToggleLeft      AS INTEGER
    toolbarHiddenByToggleRight     AS INTEGER
    editBarHiddenByToggleRight     AS INTEGER
    editBarHiddenByToggleLeft      AS INTEGER
    layerPanelHiddenByToggleLeft   AS INTEGER
    layerPanelHiddenByToggleRight  AS INTEGER
    menubarHiddenByToggleTop       AS INTEGER
    statusHiddenByToggleBottom     AS INTEGER
    patternTileMode  AS INTEGER  ' TRUE when 3x3 pattern tile view is active (doc-scoped)
    showCanvasBorder AS INTEGER   ' TRUE when canvas border outline is drawn
    canvasBorderOpacity AS INTEGER ' Border opacity (5-100, percentage)
    showCharMap              AS INTEGER   ' TRUE when character map panel is visible
    charMapManuallyHidden    AS INTEGER   ' TRUE when user explicitly hid character map
    charMapHiddenByToggleAll AS INTEGER   ' TRUE only when toggle-all (F11) hid charmap
    charMapX                 AS INTEGER   ' Left edge of charmap panel (position varies by dock side)
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ

' Preset toolbar scale hint — set by SCREEN_detect_display_scale% when a
' resolution preset provides a recommended TOOLBAR_SCALE.  SCREEN_init
' applies it when CFG.TOOLBAR_SCALE% = 0 (auto).  0 = no preset.
DIM SHARED SCREEN_preset_toolbar_scale AS INTEGER

' TRUE when toolbar scale was auto-detected (CFG.TOOLBAR_SCALE was 0).
' When TRUE, resize/scale-change events recalculate TB automatically.
DIM SHARED SCREEN_toolbar_scale_is_auto AS INTEGER

' GUI dirty flag - when FALSE, skip toolbar/status redraw for performance
' Set to TRUE when: tool switch, palette change, window resize, toolbar/status toggle
DIM SHARED GUI_NEEDS_REDRAW AS INTEGER
GUI_NEEDS_REDRAW% = TRUE ' Start with redraw needed

' Per-widget dirty flags — allow selective GUI rendering instead of redrawing
' all 9 widgets whenever any one changes.  GUI_NEEDS_REDRAW% is the aggregate
' (OR of all per-widget flags); RENDER_gui_elements checks individual flags.
DIM SHARED TOOLBAR_NEEDS_REDRAW AS INTEGER
DIM SHARED ORGANIZER_NEEDS_REDRAW AS INTEGER
DIM SHARED DRAWER_NEEDS_REDRAW AS INTEGER
DIM SHARED EDITBAR_NEEDS_REDRAW AS INTEGER
DIM SHARED MENUBAR_NEEDS_REDRAW AS INTEGER
DIM SHARED LAYER_PANEL_NEEDS_REDRAW AS INTEGER
DIM SHARED PALETTE_STRIP_NEEDS_REDRAW AS INTEGER

' Status-only dirty flag - when TRUE, only re-render the status bar + palette strip
' strip in SCRN.GUI& (skips expensive toolbar/organizer/drawer/layerpanel/menubar).
' Set to TRUE by DRAW.BAS when the mouse moves over the canvas (coords changed).
DIM SHARED STATUS_NEEDS_REDRAW AS INTEGER
STATUS_NEEDS_REDRAW% = FALSE

' Cached pixel grid image — avoid _NEWIMAGE/_FREEIMAGE every frame at 400%+ zoom
DIM SHARED PG_CACHE_IMG AS LONG
DIM SHARED PG_CACHE_ZW AS LONG
DIM SHARED PG_CACHE_ZH AS LONG
DIM SHARED PG_CACHE_ZOOM AS INTEGER
DIM SHARED PG_CACHE_COLOR AS _UNSIGNED LONG
DIM SHARED PG_CACHE_OPACITY AS INTEGER

' Scene cache — fully rendered canvas (layers+grid+GUI) before cursor
' When only cursor position changes, copy from cache instead of full repaint
DIM SHARED SCENE_CACHE AS LONG       ' Cached pre-cursor canvas image
DIM SHARED SCENE_DIRTY AS INTEGER    ' TRUE = must do full repaint
SCENE_DIRTY% = TRUE                  ' Start dirty

' Programmatic resize event counter.
' Increment before SCREEN _NEWIMAGE so the main loop can ignore matching _RESIZE
' events generated by our own window resizes.
DIM SHARED SCREEN_DEFERRED_RESIZE AS INTEGER
SCREEN_DEFERRED_RESIZE% = FALSE

SCREEN_init
