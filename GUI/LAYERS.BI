''
' DRAW - LAYERS.BI
' =============================================================================
' UDT for layers and layer panel.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Maximum layer name length
CONST LAYER_NAME_MAX_LEN = 16

' Layer row height in panel (pixels)
CONST LAYER_ROW_HEIGHT = 20

' Layer panel button sizes
CONST LAYER_BTN_SIZE = 12

TYPE DRAW_LAYER
    zIndex       AS INTEGER     ' Layer stacking order (1 = bottom)
    imgWidth     AS INTEGER     ' Layer dimensions
    imgHeight    AS INTEGER
    imgHandle    AS LONG        ' Image buffer handle
    visible      AS INTEGER     ' Visibility toggle
    isSelected   AS INTEGER     ' Currently selected layer
    lastSelected AS INTEGER     ' Previous selection state
    name         AS STRING * 16 ' Layer name (max 16 chars)
    opacity      AS INTEGER     ' Layer opacity (0-255, 255=opaque)
    opacityLock  AS INTEGER     ' Opacity lock (draw only on non-transparent pixels)
END TYPE

TYPE LAYER_PANEL_OBJ
    visible      AS INTEGER     ' Panel visibility toggle
    scrollOffset AS INTEGER     ' Scroll offset for layer list
    fontHandle   AS LONG        ' Tiny5 font handle for panel text
    hoverRow     AS INTEGER     ' Currently hovered layer row (-1 = none)
    draggingRow  AS INTEGER     ' Row being dragged for reorder (-1 = none)
    dragStartY   AS INTEGER     ' Y position when drag started
    opacityDrag  AS INTEGER     ' TRUE if dragging opacity slider
    opacityDragLayer AS INTEGER ' Layer index being opacity-adjusted
END TYPE

' Global layer state
DIM SHARED LAYERS(1 TO 64) AS DRAW_LAYER  ' Fixed array, actual count in LAYER_COUNT%
DIM SHARED LAYER_PANEL AS LAYER_PANEL_OBJ
DIM SHARED CURRENT_LAYER AS INTEGER       ' Currently active layer index (1-based)
DIM SHARED LAYER_COUNT AS INTEGER         ' Number of layers currently in use

' Declare layer management functions
DECLARE SUB LAYERS_init ()
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

' Note: LAYERS_init is called from SCREEN_init after CONFIG_load
