''
' DRAW - LAYERS.BI
' =============================================================================
' UDT for layers and layer panel.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Maximum layer name length (hard compile-time max)
CONST LAYER_NAME_HARD_MAX = 64

' Layer row height in panel (pixels)
CONST LAYER_ROW_HEIGHT = 20

' Layer panel button sizes
CONST LAYER_BTN_SIZE = 12

' Layer blend mode constants
CONST BLEND_NORMAL       = 0
CONST BLEND_MULTIPLY     = 1
CONST BLEND_SCREEN       = 2
CONST BLEND_OVERLAY      = 3
CONST BLEND_ADD          = 4
CONST BLEND_SUBTRACT     = 5
CONST BLEND_DIFFERENCE   = 6
CONST BLEND_DARKEN       = 7
CONST BLEND_LIGHTEN      = 8
CONST BLEND_COLOR_DODGE  = 9
CONST BLEND_COLOR_BURN   = 10
CONST BLEND_HARD_LIGHT   = 11
CONST BLEND_SOFT_LIGHT   = 12
CONST BLEND_EXCLUSION    = 13
CONST BLEND_VIVID_LIGHT  = 14
CONST BLEND_LINEAR_LIGHT = 15
CONST BLEND_PIN_LIGHT    = 16
CONST BLEND_COLOR        = 17
CONST BLEND_LUMINOSITY   = 18
CONST BLEND_MODE_COUNT   = 19 ' Total number of blend modes

TYPE DRAW_LAYER
    zIndex       AS INTEGER     ' Layer stacking order (1 = bottom)
    imgWidth     AS INTEGER     ' Layer dimensions
    imgHeight    AS INTEGER
    imgHandle    AS LONG        ' Image buffer handle
    visible      AS INTEGER     ' Visibility toggle
    isSelected   AS INTEGER     ' Currently selected layer
    lastSelected AS INTEGER     ' Previous selection state
    name         AS STRING * 64 ' Layer name (max controlled by CFG.LAYER_NAME_MAX_LEN%)
    opacity      AS INTEGER     ' Layer opacity (0-255, 255=opaque)
    opacityLock  AS INTEGER     ' Opacity lock (draw only on non-transparent pixels)
    blendMode    AS INTEGER     ' Blend mode (see BLEND_* constants, default BLEND_NORMAL)
    ' Opacity cache — avoid _COPYIMAGE + per-pixel loop every frame
    opacityCacheImg AS LONG     ' Cached opacity-adjusted image (0 = not cached)
    opacityCacheVal AS INTEGER  ' Opacity value when cache was built
    contentDirty    AS INTEGER  ' TRUE = layer content changed, invalidate opacity cache
END TYPE

TYPE LAYER_PANEL_OBJ
    visible      AS INTEGER     ' Panel visibility toggle
    scrollOffset AS INTEGER     ' Scroll offset for layer list
    fontHandle   AS LONG        ' Tiny5 font handle for panel text
    hoverRow     AS INTEGER     ' Currently hovered layer row (-1 = none)
    draggingRow  AS INTEGER     ' Row being dragged for reorder (-1 = none)
    dragStartY   AS INTEGER     ' Y position when drag started
    dragStartX   AS INTEGER     ' X position when drag started (for threshold)
    opacityDrag  AS INTEGER     ' TRUE if dragging opacity slider
    opacityDragLayer AS INTEGER ' Layer index being opacity-adjusted
    ' Layer drag-and-drop reordering state
    dragPending       AS INTEGER   ' TRUE when mouse down but not yet moved threshold
    isDragging        AS INTEGER   ' TRUE while actively dragging layer for reorder
    dragLayerIdx      AS INTEGER   ' Layer index being dragged
    dropTargetZIndex  AS INTEGER   ' Target zIndex position for drop (-1 = no target)
    dragOffsetY       AS INTEGER   ' Offset from row top where drag started
    autoScrollTimer   AS SINGLE    ' Timer for auto-scroll delay at edges
    dragPreviewY      AS INTEGER   ' Y position for drag preview cursor
    ' Layer icon handles (loaded from theme PNGs, fallback to text if < -1 check fails)
    iconVisOn         AS LONG      ' Visibility on (eye open) image handle
    iconVisOff        AS LONG      ' Visibility off (eye closed) image handle
    iconLockOn        AS LONG      ' Lock on (locked) image handle
    iconLockOff       AS LONG      ' Lock off (unlocked) image handle
    iconBtnUp         AS LONG      ' Move up button icon
    iconBtnDown       AS LONG      ' Move down button icon
    iconBtnMerge      AS LONG      ' Merge down button icon
    iconBtnDelete     AS LONG      ' Delete layer button icon
    iconBtnAdd        AS LONG      ' New layer button icon
    ' Solo mode state (alt+click on eye icon)
    soloLayer         AS INTEGER    ' Layer index currently soloed (0 = none)
    savedVisibility   AS STRING * 64 ' Saved visibility states before solo
    ' Visibility swipe state (click+drag on eye icons)
    visSwiping        AS INTEGER    ' TRUE while swiping visibility
    visSwipeAction    AS INTEGER    ' 1 = show, 0 = hide (action applied during swipe)
    visSwipedLayers   AS STRING * 64 ' Track which layers were already swiped (CHR$(1) = swiped)
END TYPE

' Global layer state
DIM SHARED LAYERS(1 TO 64) AS DRAW_LAYER  ' Fixed array, actual count in LAYER_COUNT%
DIM SHARED LAYER_PANEL AS LAYER_PANEL_OBJ
DIM SHARED CURRENT_LAYER AS INTEGER       ' Currently active layer index (1-based)
DIM SHARED LAYER_COUNT AS INTEGER         ' Number of layers currently in use

' Declare layer management functions
DECLARE SUB LAYERS_init ()
DECLARE FUNCTION LAYERS_recount% ()
DECLARE FUNCTION LAYERS_new% ()
DECLARE SUB LAYERS_delete (layerIndex AS INTEGER)
DECLARE SUB LAYERS_duplicate (layerIndex AS INTEGER)
DECLARE SUB LAYERS_clear (layerIndex AS INTEGER)
DECLARE SUB LAYERS_rename (layerIndex AS INTEGER)
DECLARE SUB LAYERS_select (layerIndex AS INTEGER)
DECLARE SUB LAYERS_move_up (layerIndex AS INTEGER)
DECLARE SUB LAYERS_move_down (layerIndex AS INTEGER)
DECLARE SUB LAYERS_to_top (layerIndex AS INTEGER)
DECLARE SUB LAYERS_to_bottom (layerIndex AS INTEGER)
DECLARE SUB LAYERS_toggle_visibility (layerIndex AS INTEGER)
DECLARE SUB LAYERS_set_opacity (layerIndex AS INTEGER, opacity AS INTEGER)
DECLARE SUB LAYERS_toggle_opacity_lock (layerIndex AS INTEGER)
DECLARE SUB LAYERS_merge_down (layerIndex AS INTEGER)
DECLARE SUB LAYERS_merge_visible ()
DECLARE FUNCTION LAYERS_flatten& ()
DECLARE FUNCTION LAYER_current_image& ()

' Layer panel UI functions
DECLARE SUB LAYER_PANEL_render (canvasHeight AS INTEGER)
DECLARE FUNCTION LAYER_PANEL_in_bounds% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE FUNCTION LAYER_PANEL_handle_click% (rawX AS INTEGER, rawY AS INTEGER, button AS INTEGER)
DECLARE SUB LAYER_PANEL_handle_wheel (rawX AS INTEGER, rawY AS INTEGER, delta AS INTEGER)
DECLARE SUB LAYER_PANEL_handle_drag (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_handle_drop ()
DECLARE SUB LAYER_PANEL_drag_cancel ()
DECLARE FUNCTION LAYER_PANEL_is_dragging% ()
DECLARE SUB LAYER_PANEL_handle_vis_swipe (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_end_vis_swipe ()

DECLARE SUB LAYER_PANEL_load_icons ()
DECLARE SUB LAYER_PANEL_cleanup_icons ()
DECLARE SUB LAYER_select_non_transparent (layerIdx AS INTEGER)

' Blend mode functions
DECLARE FUNCTION BLEND_mode_name$ (mode AS INTEGER)
DECLARE FUNCTION BLEND_mode_short$ (mode AS INTEGER)
DECLARE SUB LAYER_blend_composite (dst AS LONG, src AS LONG, blendMode AS INTEGER, opacity AS INTEGER)
DECLARE FUNCTION BLEND_needs_composite% ()
DECLARE SUB BLEND_invalidate_cache ()
DECLARE SUB RENDER_ORDER_rebuild ()

' Layer render order — pre-sorted array avoids O(n×64) lookup per frame
' RENDER_ORDER%(i) = layer index for z-level i, rebuilt when layer order changes
DIM SHARED RENDER_ORDER(1 TO 64) AS INTEGER
DIM SHARED RENDER_ORDER_COUNT AS INTEGER
DIM SHARED RENDER_ORDER_DIRTY AS INTEGER       ' TRUE = must rebuild
RENDER_ORDER_DIRTY% = TRUE                     ' Start dirty

' Blend composite cache — avoid re-scanning 64 slots every frame
DIM SHARED BLEND_COMPOSITE_CACHED AS INTEGER   ' Cached result of BLEND_needs_composite%
DIM SHARED BLEND_COMPOSITE_DIRTY AS INTEGER    ' TRUE = must rescan
BLEND_COMPOSITE_DIRTY% = TRUE                  ' Start dirty

' Persistent composite buffer — avoid _NEWIMAGE/_FREEIMAGE every frame
DIM SHARED COMPOSITE_BUFFER AS LONG
DIM SHARED COMPOSITE_BUFFER_W AS LONG
DIM SHARED COMPOSITE_BUFFER_H AS LONG

' Partial composite cache — skip re-compositing layers below current during painting
DIM SHARED COMPOSITE_BELOW_CACHE AS LONG      ' Cached composite of layers below CURRENT_LAYER%
DIM SHARED COMPOSITE_BELOW_LAYER AS INTEGER    ' Which CURRENT_LAYER% this cache was built for
DIM SHARED COMPOSITE_BELOW_VALID AS INTEGER    ' Is the cache still valid?
COMPOSITE_BELOW_VALID% = FALSE

' Note: LAYERS_init is called from SCREEN_init after CONFIG_load
' LAYER_PANEL_load_icons is called from DRAW.BAS after CONFIG_apply_startup_defaults
