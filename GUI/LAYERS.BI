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
CONST BLEND_PASS_THROUGH             = -1  ' Group-only: children composite AS if no group exists
CONST BLEND_PASS_THROUGH_POPUP_VALUE = 100 ' Popup menu sentinel (avoids -1 collision with POPUP_MENU_hit_value%)
CONST BLEND_NORMAL                   = 0
CONST BLEND_MULTIPLY                 = 1
CONST BLEND_SCREEN                   = 2
CONST BLEND_OVERLAY                  = 3
CONST BLEND_ADD                      = 4
CONST BLEND_SUBTRACT                 = 5
CONST BLEND_DIFFERENCE               = 6
CONST BLEND_DARKEN                   = 7
CONST BLEND_LIGHTEN                  = 8
CONST BLEND_COLOR_DODGE              = 9
CONST BLEND_COLOR_BURN               = 10
CONST BLEND_HARD_LIGHT               = 11
CONST BLEND_SOFT_LIGHT               = 12
CONST BLEND_EXCLUSION                = 13
CONST BLEND_VIVID_LIGHT              = 14
CONST BLEND_LINEAR_LIGHT             = 15
CONST BLEND_PIN_LIGHT                = 16
CONST BLEND_COLOR                    = 17
CONST BLEND_LUMINOSITY               = 18
CONST BLEND_MODE_COUNT               = 19  ' Total number of blend modes

' Layer type constants
CONST LAYER_TYPE_IMAGE         = 0         ' Standard pixel/image layer (default)
CONST LAYER_TYPE_TEXT          = 1         ' Non-destructive text layer
CONST LAYER_TYPE_GROUP         = 2         ' Group container (no pixel data, organizational only)
CONST LAYER_TYPE_SYMBOL_PARENT = 3         ' Symbol parent : editable source layer for linked instances
CONST LAYER_TYPE_SYMBOL_CHILD  = 4         ' Symbol child  : non-editable linked instance of a parent

' Export mode constants (QB64PE Code Export classification)
CONST EXPORT_MODE_VECTOR = 0               ' All ops are vector-exportable (SUB)
CONST EXPORT_MODE_TEXT   = 1               ' Text layer (SUB:TXT)
CONST EXPORT_MODE_IMG    = 2               ' Has non-vector ops — exports as PNG + _LOADIMAGE (SUB:IMG)
CONST EXPORT_MODE_NONE   = 3               ' Groups — not exported directly

TYPE DRAW_LAYER
    historyId         AS LONG        ' Stable runtime identity for unified history
    zIndex            AS INTEGER     ' Layer stacking order (1 = bottom)
    imgWidth          AS INTEGER     ' Layer dimensions
    imgHeight         AS INTEGER
    imgHandle         AS LONG        ' Image buffer handle
    visible           AS INTEGER     ' Visibility toggle
    isSelected        AS INTEGER     ' Currently selected layer
    lastSelected      AS INTEGER     ' Previous selection state
    name              AS STRING * 64 ' Layer name (max controlled by CFG.LAYER_NAME_MAX_LEN%)
    opacity           AS INTEGER     ' Layer opacity (0-255, 255 = opaque)
    opacityLock       AS INTEGER     ' Opacity lock (draw only on non-transparent pixels)
    blendMode         AS INTEGER     ' Blend mode (see BLEND_* constants, default BLEND_NORMAL)
    ' Opacity cache — avoid _COPYIMAGE + per-pixel loop every frame
    opacityCacheImg   AS LONG        ' Cached opacity-adjusted image (0 = not cached)
    opacityCacheVal   AS INTEGER     ' Opacity value when cache was built
    contentDirty      AS INTEGER     ' TRUE = layer content changed, invalidate opacity cache
    layerType         AS INTEGER     ' LAYER_TYPE_IMAGE (0), LAYER_TYPE_TEXT (1), or LAYER_TYPE_GROUP (2)
    textDataIdx       AS INTEGER     ' Index into TEXT_LAYER_DATA() pool (0 = not a text layer)
    ' Group support fields
    parentGroupIdx    AS INTEGER     ' Index into LAYERS() of parent group (0 = top-level / no group)
    collapsed         AS INTEGER     ' TRUE if group is collapsed in panel (LAYER_TYPE_GROUP only)
    passThrough       AS INTEGER     ' TRUE = pass-through blend (children composite directly); FALSE = isolated group blend
    ' Symbol layer fields
    symbolParentId    AS LONG        ' Child  : historyId& of parent; parent/other : 0
    symbolParentDirty AS INTEGER     ' Parent : TRUE when content edited since last sync
    symbolScaleX      AS SINGLE      ' Child  : X scale factor (default 1.0; negative = flip H)
    symbolScaleY      AS SINGLE      ' Child  : Y scale factor (default 1.0; negative = flip V)
    symbolOffsetX     AS INTEGER     ' Child  : canvas X for top-left of scaled content
    symbolOffsetY     AS INTEGER     ' Child  : canvas Y for top-left of scaled content
    symbolRotation    AS INTEGER     ' Child  : rotation steps (0=none, 1=90CW, 2=180, 3=270CW)
    ' QB64PE Code Export classification (computed from history, undo-aware)
    exportMode        AS INTEGER     ' EXPORT_MODE_VECTOR (0), _TEXT (1), _IMG (2), _NONE (3)
END TYPE

TYPE LAYER_PANEL_OBJ
    visible          AS INTEGER      ' Panel visibility toggle
    scrollOffset     AS INTEGER      ' Scroll offset for layer list
    fontHandle       AS LONG         ' Tiny5 font handle for panel text
    hoverRow         AS INTEGER      ' Currently hovered layer row (-1 = none)
    draggingRow      AS INTEGER      ' Row being dragged for reorder (-1 = none)
    dragStartY       AS INTEGER      ' Y position when drag started
    dragStartX       AS INTEGER      ' X position when drag started (for threshold)
    opacityDrag      AS INTEGER      ' TRUE if dragging opacity slider
    opacityDragLayer AS INTEGER      ' Layer index being opacity-adjusted
    ' Layer drag-and-drop reordering state
    dragPending      AS INTEGER      ' TRUE when mouse down but not yet moved threshold
    isDragging       AS INTEGER      ' TRUE while actively dragging layer for reorder
    dragLayerIdx     AS INTEGER      ' Layer index being dragged
    dropTargetZIndex AS INTEGER      ' Target zIndex position for drop (-1 = no target)
    dragOffsetY      AS INTEGER      ' Offset from row top where drag started
    autoScrollTimer  AS SINGLE       ' Timer for auto-scroll delay at edges
    dragPreviewY     AS INTEGER      ' Y position for drag preview cursor
    dropOnButton     AS INTEGER      ' 0 = none, 4 = over Delete btn, 5 = over New btn during drag
    ' Layer icon handles (loaded from theme PNGs, fallback to text if < -1 check fails)
    iconVisOn        AS LONG         ' Visibility on (eye open) image handle
    iconVisOff       AS LONG         ' Visibility off (eye closed) image handle
    iconLockOn       AS LONG         ' Lock on (locked) image handle
    iconLockOff      AS LONG         ' Lock off (unlocked) image handle
    iconBtnUp        AS LONG         ' Move up button icon
    iconBtnDown      AS LONG         ' Move down button icon
    iconBtnMerge     AS LONG         ' Merge down button icon
    iconBtnDelete    AS LONG         ' Delete layer button icon
    iconBtnAdd       AS LONG         ' New layer button icon
    ' Solo mode state (alt+click on eye icon)
    soloLayer        AS INTEGER      ' Layer index currently soloed (0 = none)
    savedVisibility  AS STRING * 128 ' Saved visibility states before solo
    ' Visibility swipe state (click+drag on eye icons)
    visSwiping       AS INTEGER      ' TRUE while swiping visibility
    visSwipeAction   AS INTEGER      ' 1 = show, 0 = hide (action applied during swipe)
    visSwipedLayers  AS STRING * 128 ' Track which layers were already swiped (CHR$(1) = swiped)
    ' Scrollbar drag state
    scrollDragging   AS INTEGER      ' TRUE while dragging the scroll thumb
    scrollDragOffset AS INTEGER      ' Y offset from thumb top where drag started
    ' Blend mode popup state
    blendPopupOpen   AS INTEGER      ' TRUE while blend popup is showing
    blendPopupLayer  AS INTEGER      ' Layer index popup is for
    blendPopupX      AS INTEGER      ' Popup screen X (top-left)
    blendPopupY      AS INTEGER      ' Popup screen Y (top-left)
    blendPopupHover  AS INTEGER      ' Currently hovered item index (-1 = none, 0 = Normal, 2..19 = mode idx+1 for divider)
    ' Layer context menu state (right-click on row)
    ctxMenuOpen      AS INTEGER      ' TRUE while context menu is showing
    ctxMenuLayer     AS INTEGER      ' Layer index the context menu was invoked on
    ctxMenuX         AS INTEGER      ' Popup screen X (top-left)
    ctxMenuY         AS INTEGER      ' Popup screen Y (top-left)
    ctxMenuW         AS INTEGER      ' Popup width in pixels
    ctxMenuHover     AS INTEGER      ' Currently hovered row (-1 = none)
    ctxMenuItems     AS INTEGER      ' Number of items in current menu
    ' Opacity drag anchor
    opacityDragRowY  AS INTEGER      ' Rendered Y (drawY%) of row top when vertical opacity drag started
    ' Stored panel bounds (set each render, used for hit-testing next frame)
    panelX1          AS INTEGER      ' Left edge of rendered panel (screen coords)
    panelX2          AS INTEGER      ' Right edge of rendered panel (screen coords)
    width            AS INTEGER      ' Panel width in pixels (mirrors CFG.LAYER_PANEL_WIDTH)
END TYPE

' Global layer state
DIM SHARED LAYERS(1 TO MAX_LAYERS) AS DRAW_LAYER                   ' Fixed array, actual count in LAYER_COUNT%
DIM SHARED LAYER_PANEL           AS LAYER_PANEL_OBJ
DIM SHARED CURRENT_LAYER         AS INTEGER                        ' Currently active layer index (1-based)
DIM SHARED LAYER_COUNT           AS INTEGER                        ' Number of layers currently in use
DIM SHARED NEXT_LAYER_HISTORY_ID AS LONG                           ' Monotonic stable layer id allocator

' Declare layer management functions
DECLARE SUB LAYERS_init ()
DECLARE FUNCTION LAYERS_recount% ()
DECLARE FUNCTION LAYERS_alloc_history_id& ()
DECLARE FUNCTION LAYERS_new% ()
DECLARE FUNCTION LAYERS_new_at_top% ()
DECLARE FUNCTION LAYERS_new_text% (x AS INTEGER, y AS INTEGER)
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
DECLARE SUB LAYER_PANEL_handle_opacity_drag (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_handle_drag (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_handle_drop ()
DECLARE SUB LAYER_PANEL_drag_cancel ()
DECLARE FUNCTION LAYER_PANEL_is_dragging% ()
DECLARE SUB LAYER_PANEL_handle_vis_swipe (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_end_vis_swipe ()
DECLARE SUB LAYER_PANEL_handle_scroll_drag (rawY AS INTEGER)
DECLARE FUNCTION LAYER_PANEL_visible_row_count% ()

DECLARE SUB LAYER_PANEL_load_icons ()
DECLARE SUB LAYER_PANEL_cleanup_icons ()
DECLARE SUB LAYER_select_non_transparent (layerIdx AS INTEGER)
DECLARE SUB LAYER_PANEL_scroll_to_layer (layerIdx AS INTEGER)

' Blend mode popup
DECLARE SUB LAYER_PANEL_blend_popup_show (layerIdx AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB LAYER_PANEL_blend_popup_close ()
DECLARE SUB LAYER_PANEL_blend_popup_render ()
DECLARE FUNCTION LAYER_PANEL_blend_popup_hit% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_blend_popup_hover (rawX AS INTEGER, rawY AS INTEGER)

' Layer context menu (right-click on row)
CONST LAYER_CTX_ITEM_H = 12
DECLARE SUB LAYER_PANEL_ctx_menu_build (layerIdx AS INTEGER, itemCount AS INTEGER)
DECLARE SUB LAYER_PANEL_ctx_menu_show (layerIdx AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE SUB LAYER_PANEL_ctx_menu_close ()
DECLARE SUB LAYER_PANEL_ctx_menu_render ()
DECLARE FUNCTION LAYER_PANEL_ctx_menu_hit% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_ctx_menu_hover (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB LAYER_PANEL_ctx_menu_activate (actionValue AS INTEGER)

' Blend mode functions
DECLARE FUNCTION BLEND_mode_name$ (mode AS INTEGER)
DECLARE FUNCTION BLEND_mode_short$ (mode AS INTEGER)
DECLARE SUB LAYER_blend_composite (dst AS LONG, src AS LONG, blendMode AS INTEGER, opacity AS INTEGER)
DECLARE SUB LAYER_blend_composite_region (dst AS LONG, src AS LONG, blendMode AS INTEGER, opacity AS INTEGER, rx1 AS INTEGER, ry1 AS INTEGER, rx2 AS INTEGER, ry2 AS INTEGER)
DECLARE FUNCTION BLEND_needs_composite% ()
DECLARE SUB BLEND_invalidate_cache ()
DECLARE SUB BLEND_invalidate_visibility (changedLayer AS INTEGER)
DECLARE SUB RENDER_ORDER_rebuild ()

' Layer render order — pre-sorted array avoids O(n×64) lookup per frame
' RENDER_ORDER%(i) = layer index for z-level i, rebuilt when layer order changes
DIM SHARED RENDER_ORDER(1 TO MAX_LAYERS) AS INTEGER
DIM SHARED RENDER_ORDER_COUNT AS INTEGER
DIM SHARED RENDER_ORDER_DIRTY AS INTEGER                           ' TRUE = must rebuild
RENDER_ORDER_DIRTY% = TRUE                                         ' Start dirty

' Blend composite cache — avoid re-scanning 64 slots every frame
DIM SHARED BLEND_COMPOSITE_CACHED AS INTEGER                       ' Cached result of BLEND_needs_composite%
DIM SHARED BLEND_COMPOSITE_DIRTY  AS INTEGER                       ' TRUE = must rescan
BLEND_COMPOSITE_DIRTY% = TRUE                                      ' Start dirty

' Persist composite buffer — avoid _NEWIMAGE/_FREEIMAGE every frame
DIM SHARED COMPOSITE_BUFFER   AS LONG
DIM SHARED COMPOSITE_BUFFER_W AS LONG
DIM SHARED COMPOSITE_BUFFER_H AS LONG

' Partial composite cache — skip re-compositing layers below current during painting
DIM SHARED COMPOSITE_BELOW_CACHE AS LONG                           ' Cached composite of layers below CURRENT_LAYER%
DIM SHARED COMPOSITE_BELOW_LAYER AS INTEGER                        ' Which CURRENT_LAYER% this cache was built for
DIM SHARED COMPOSITE_BELOW_VALID AS INTEGER                        ' Is the cache still valid?
COMPOSITE_BELOW_VALID% = FALSE

' Full composite result cache — skip re-compositing when only a small region changed.
' When COMP_DIRTY_VALID% is TRUE and COMPOSITE_RESULT_VALID% is TRUE, RENDER_layers
' restores from COMPOSITE_RESULT_CACHE& and only re-blends the dirty region.
DIM SHARED COMPOSITE_RESULT_CACHE AS LONG                          ' Previous frame's completed composite
DIM SHARED COMPOSITE_RESULT_VALID AS INTEGER                       ' Is the full composite cache usable?
COMPOSITE_RESULT_VALID% = FALSE

' Multi-layer selection — allows selecting multiple layers at once for bulk operations
' MULTI_SELECT_LAYERS(i): TRUE if layer i is selected (1-based, matches LAYERS array)
' MULTI_SELECT_COUNT: number of selected layers (invariant: always >= 1)
DIM SHARED MULTI_SELECT_LAYERS(1 TO MAX_LAYERS) AS INTEGER
DIM SHARED MULTI_SELECT_COUNT AS INTEGER
MULTI_SELECT_COUNT% = 0

DECLARE SUB MULTI_SELECT_clear ()
DECLARE FUNCTION MULTI_SELECT_has_any% ()
DECLARE SUB MULTI_SELECT_toggle (layerIndex AS INTEGER)
DECLARE SUB LAYER_get_content_bounds (layerIndex AS INTEGER, bx AS INTEGER, by AS INTEGER, bw AS INTEGER, bh AS INTEGER)
DECLARE SUB LAYER_translate_content (layerIndex AS INTEGER, dx AS INTEGER, dy AS INTEGER)

' Group layer management functions
DIM SHARED NEXT_GROUP_NUM AS INTEGER                               ' Auto-incrementing counter for group naming
DECLARE FUNCTION LAYERS_new_group% ()
DECLARE FUNCTION LAYERS_group_from_selection% ()
DECLARE SUB LAYERS_ungroup (groupIdx AS INTEGER)
DECLARE SUB LAYERS_move_into_group (layerIdx AS INTEGER, groupIdx AS INTEGER)
DECLARE SUB LAYERS_move_out_of_group (layerIdx AS INTEGER)
DECLARE FUNCTION LAYERS_group_child_count% (groupIdx AS INTEGER)
DECLARE SUB LAYERS_group_descendants (groupIdx AS INTEGER, outArray() AS INTEGER, outCount AS INTEGER)
DECLARE SUB LAYERS_group_children (groupIdx AS INTEGER, outArray() AS INTEGER, outCount AS INTEGER)
DECLARE SUB LAYERS_group_zIndex_range (groupIdx AS INTEGER, outMinZ AS INTEGER, outMaxZ AS INTEGER)
DECLARE SUB LAYERS_enforce_group_contiguity ()
DECLARE SUB LAYERS_merge_group (groupIdx AS INTEGER)
DECLARE SUB LAYERS_select_group (groupIdx AS INTEGER)
DECLARE SUB LAYERS_delete_group (groupIdx AS INTEGER)
DECLARE SUB LAYERS_toggle_group_visibility (groupIdx AS INTEGER)

' Group compositing — stack of buffers for nested isolated groups
' Each nesting level of isolated groups needs its own composite buffer.
CONST MAX_GROUP_NESTING = 8                                        ' Maximum supported group nesting depth
DIM SHARED GROUP_COMP_STACK(1 TO MAX_GROUP_NESTING) AS LONG        ' Image handles
DIM SHARED GROUP_COMP_STACK_IDX(1 TO MAX_GROUP_NESTING) AS INTEGER ' Group layer indices
DIM SHARED GROUP_COMP_STACK_TOP      AS INTEGER                    ' Current stack depth (0 = empty)
DIM SHARED GROUP_COMP_STACK_W        AS LONG                       ' Width of allocated buffers
DIM SHARED GROUP_COMP_STACK_H        AS LONG                       ' Height of allocated buffers
DIM SHARED BLEND_HAS_ISOLATED_GROUPS AS INTEGER                    ' TRUE when isolated groups exist (cached)

' Helper: get nesting depth of a layer (0 = top-level)
DECLARE FUNCTION LAYERS_nesting_depth% (layerIdx AS INTEGER)

' Note: LAYERS_init is called from SCREEN_init after CONFIG_load
' LAYER_PANEL_load_icons is called from DRAW.BAS after CONFIG_apply_startup_defaults
