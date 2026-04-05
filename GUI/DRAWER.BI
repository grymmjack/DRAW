''
' DRAW - GUI/DRAWER.BI
' =============================================================================
' Mode drawer beneath the organizer. Provides seeded brush, pattern, and
' gradient bins plus a compact mini palette.
'
$INCLUDEONCE

CONST DRAWER_MODE_NONE     = 0
CONST DRAWER_MODE_BRUSH    = 1
CONST DRAWER_MODE_PATTERN  = 2
CONST DRAWER_MODE_GRADIENT = 3
CONST DRAWER_SLOT_COUNT    = 30
CONST DRAWER_GRID_COLS     = 3
CONST DRAWER_GRID_ROWS     = 10

' Maximum color/opacity stops per gradient definition
CONST GRADIENT_MAX_STOPS   = 16

' Gradient spatial families (how t is derived from x,y)
CONST GRADIENT_FAMILY_HORIZONTAL  = 1
CONST GRADIENT_FAMILY_VERTICAL    = 2
CONST GRADIENT_FAMILY_DIAGONAL    = 3
CONST GRADIENT_FAMILY_ANTI_DIAG   = 4
CONST GRADIENT_FAMILY_RADIAL      = 5
CONST GRADIENT_FAMILY_REFLECTED_H = 6
CONST GRADIENT_FAMILY_REFLECTED_V = 7
CONST GRADIENT_FAMILY_DIAMOND     = 8

' Per-stop color source type
CONST GRAD_STOP_USER = 0          ' Fixed user-specified color
CONST GRAD_STOP_FG   = 1          ' References current foreground (PAINT_COLOR~&)
CONST GRAD_STOP_BG   = 2          ' References current background (PAINT_BG_COLOR~&)

' A single color stop in a gradient definition
TYPE GRADIENT_COLOR_STOP
    position AS SINGLE          ' 0.0 to 1.0
    clr      AS _UNSIGNED LONG  ' RGBA color at this stop
END TYPE

' A single opacity stop in a gradient definition
TYPE GRADIENT_OPACITY_STOP
    position AS SINGLE          ' 0.0 to 1.0
    opacity  AS INTEGER         ' 0 to 255
END TYPE

' Complete editable gradient definition per slot
TYPE GRADIENT_DEF
    family       AS INTEGER     ' GRADIENT_FAMILY_* constant
    colorCount   AS INTEGER     ' number of active color stops (1..GRADIENT_MAX_STOPS)
    opacityCount AS INTEGER     ' number of active opacity stops (0..GRADIENT_MAX_STOPS)
    usesFG       AS INTEGER     ' TRUE if preset references PAINT_COLOR~&
    usesBG       AS INTEGER     ' TRUE if preset references PAINT_BG_COLOR~&
    previewDirty AS INTEGER     ' TRUE when definition changed, preview needs rebuild
    gName        AS STRING * 32 ' user-editable gradient name
    ditherMode   AS INTEGER     ' GJ_IMGADJ_DITHER_* constant or DITHER_NONE (-1)
    ditherStrength AS SINGLE    ' 0.0 (none) to 1.0 (full)
END TYPE

' Operation-bounded gradient context for runtime sampling
TYPE GRADIENT_CONTEXT
    boundsX1 AS INTEGER         ' left edge of operation area
    boundsY1 AS INTEGER         ' top edge of operation area
    boundsX2 AS INTEGER         ' right edge of operation area
    boundsY2 AS INTEGER         ' bottom edge of operation area
    active   AS INTEGER         ' TRUE when context has valid bounds
END TYPE

TYPE DRAWER_STATE
    visible             AS INTEGER
    mode                AS INTEGER
    paintMode           AS INTEGER
    panelX1             AS INTEGER
    panelY1             AS INTEGER
    panelX2             AS INTEGER
    panelY2             AS INTEGER
    miniPaletteOffset   AS INTEGER
    brushSelected       AS INTEGER
    patternSelected     AS INTEGER
    gradientSelected    AS INTEGER
    paletteFGX          AS INTEGER
    paletteFGY          AS INTEGER
    paletteBGX          AS INTEGER
    paletteBGY          AS INTEGER
    contextMenuOpen     AS INTEGER
    contextMenuSlot     AS INTEGER
    contextMenuX        AS INTEGER
    contextMenuY        AS INTEGER
    contextMenuW        AS INTEGER
    contextMenuHover    AS INTEGER
    contextMenuItems    AS INTEGER
    samplesLoaded       AS INTEGER
    loadedTheme         AS STRING * 64
    ' Bin drag-and-drop reordering state
    dragPending         AS INTEGER   ' TRUE when mouse down but not yet moved threshold
    isDragging          AS INTEGER   ' TRUE while actively dragging bin for reorder
    dragSourceSlot      AS INTEGER   ' Slot index (1-30) being dragged
    dragTargetSlot      AS INTEGER   ' Current drop target slot (0 = none)
    dragStartX          AS INTEGER   ' Raw X when drag started
    dragStartY          AS INTEGER   ' Raw Y when drag started
END TYPE

DIM SHARED DRAWER AS DRAWER_STATE
DIM SHARED DRAWER_BRUSH_SLOTS(1 TO DRAWER_SLOT_COUNT) AS DRAW_BRUSH
DIM SHARED DRAWER_PATTERN_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_PATTERN_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_PATTERN_1BIT(1 TO DRAWER_SLOT_COUNT) AS INTEGER          ' TRUE if pattern is 1-bit
DIM SHARED DRAWER_PATTERN_1BIT_FG(1 TO DRAWER_SLOT_COUNT) AS _UNSIGNED LONG ' Original opaque color in 1-bit pattern
DIM SHARED DRAWER_PATTERN_1BIT_HAS_BG(1 TO DRAWER_SLOT_COUNT) AS INTEGER   ' TRUE if 1-bit pattern has opaque BG (2 colors, not just FG+transparent)
DIM SHARED DRAWER_GRADIENT_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_GRADIENT_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_GRADIENT_CUSTOM(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_SLOT AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_MODE AS INTEGER

' Gradient definition arrays — parallel to DRAWER_GRADIENT_SLOTS
DIM SHARED GRAD_DEFS(1 TO DRAWER_SLOT_COUNT) AS GRADIENT_DEF
DIM SHARED GRAD_COLOR_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_COLOR_STOP
DIM SHARED GRAD_OPACITY_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_OPACITY_STOP
DIM SHARED GRAD_STOP_TYPES(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS INTEGER

' Shared gradient context for operation-bounded sampling
DIM SHARED GRAD_CTX AS GRADIENT_CONTEXT

DECLARE SUB DRAWER_init ()
DECLARE SUB DRAWER_reset ()
DECLARE SUB DRAWER_render ()
DECLARE SUB DRAWER_set_mode (mode AS INTEGER)
DECLARE SUB DRAWER_apply_config_defaults ()
DECLARE SUB DRAWER_queue_slot_import (slotIndex AS INTEGER)
DECLARE SUB DRAWER_run_deferred_action ()
DECLARE FUNCTION DRAWER_is_over_area% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_is_over_slot% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_is_over_palette% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_handle_click% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_handle_right_click% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_handle_middle_click% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB DRAWER_handle_wheel (mouseX AS INTEGER, mouseY AS INTEGER, wheelDelta AS INTEGER)
DECLARE FUNCTION DRAWER_is_dragging% ()
DECLARE SUB DRAWER_drag_cancel ()
DECLARE SUB DRAWER_handle_drag (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB DRAWER_handle_drop ()
DECLARE SUB DRAWER_context_menu_show (slotIndex AS INTEGER, mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB DRAWER_context_menu_close ()
DECLARE SUB DRAWER_context_menu_hover (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_context_menu_hit% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB DRAWER_context_menu_activate (actionValue AS INTEGER)
DECLARE SUB DRAWER_context_menu_render ()
DECLARE FUNCTION DRAWER_mode_is_active% (mode AS INTEGER)
DECLARE FUNCTION DRAWER_has_paint_mode% ()
DECLARE FUNCTION DRAWER_resolve_paint_color~& (x AS INTEGER, y AS INTEGER, baseColor AS _UNSIGNED LONG)
DECLARE FUNCTION DRAWER_resolve_gradient_color~& (x AS INTEGER, y AS INTEGER, baseColor AS _UNSIGNED LONG, ctx AS GRADIENT_CONTEXT)
DECLARE SUB GRAD_CTX_set (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER)
DECLARE SUB GRAD_CTX_clear ()
DECLARE SUB GRAD_CTX_expand (x AS INTEGER, y AS INTEGER)
DECLARE SUB GRAD_DEF_init_presets ()
DECLARE SUB GRAD_DEF_rebuild_preview (slotIndex AS INTEGER)
DECLARE FUNCTION GRAD_DEF_eval_color~& (slotIndex AS INTEGER, t AS SINGLE)
DECLARE SUB GRAD_DEF_set_stop (slotIndex AS INTEGER, stopIndex AS INTEGER, stopPos AS SINGLE, c AS _UNSIGNED LONG)
DECLARE SUB GRAD_DEF_update_fg_bg_stops ()
DECLARE SUB GRADIENT_editor_dialog ()
DECLARE SUB DRAWER_save_state_binary (fh AS INTEGER)
DECLARE SUB DRAWER_load_state_binary (fh AS INTEGER)
DECLARE SUB DRAWER_export_set_dialog ()
DECLARE SUB DRAWER_import_set_dialog ()
DECLARE SUB DRAWER_clear_active_set ()
DECLARE SUB DRAWER_explore_sets_folder ()
DECLARE FUNCTION DRAWER_pattern_is_1bit% (slotIndex AS INTEGER)
DECLARE SUB DRAWER_analyze_1bit (slotIndex AS INTEGER)
DECLARE SUB DRAWER_analyze_all_1bit ()

' Font handle for 1-bit sigil (loaded lazily in DRAWER_render)
DIM SHARED DRAWER_1BIT_FONT AS LONG

' Context menu constants
CONST DRAWER_CONTEXT_ITEM_H = 12 ' Must match MENU_ITEM_HEIGHT in MENUBAR.BI
CONST DRAWER_CONTEXT_MAX_ITEMS = 14
CONST DRAWER_CONTEXT_LOAD_SET = 1
CONST DRAWER_CONTEXT_SAVE_SET = 2
CONST DRAWER_CONTEXT_CLEAR_SET = 3
CONST DRAWER_CONTEXT_EXPLORE_FOLDER = 4
CONST DRAWER_CONTEXT_EDIT_GRADIENT = 5
CONST DRAWER_CONTEXT_LOAD_IMAGES = 6

' Forward declarations for internal helpers
DECLARE SUB DRAWER_free_samples ()
DECLARE SUB DRAWER_ensure_samples ()
DECLARE FUNCTION DRAWER_load_theme_image& (subdir AS STRING, filename AS STRING)
DECLARE FUNCTION DRAWER_create_gradient_sample& (slotIndex AS INTEGER)
DECLARE FUNCTION DRAWER_gradient_eval_t! (slotIndex AS INTEGER, x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER)
DECLARE FUNCTION DRAWER_gradient_sample_stop~& (slotIndex AS INTEGER, t AS SINGLE)
DECLARE FUNCTION DRAWER_gradient_lerp_color~& (c1 AS _UNSIGNED LONG, c2 AS _UNSIGNED LONG, t AS SINGLE)
DECLARE FUNCTION GRAD_with_stop_alpha~& (c AS _UNSIGNED LONG, stopAlpha AS INTEGER)
DECLARE FUNCTION GRAD_DEF_eval_opacity% (slotIndex AS INTEGER, t AS SINGLE)
DECLARE FUNCTION DRAWER_paint_mode_from_panel% (panelMode AS INTEGER)
DECLARE FUNCTION DRAWER_panel_mode_from_config% (binMode AS INTEGER)
DECLARE SUB DRAWER_layout (contentX AS INTEGER, contentY AS INTEGER, binW AS INTEGER, binH AS INTEGER, binGapX AS INTEGER, binGapY AS INTEGER, miniX AS INTEGER, miniY AS INTEGER, miniCellW AS INTEGER, miniCellH AS INTEGER, miniGapX AS INTEGER, miniGapY AS INTEGER, pageBtnY AS INTEGER, scrollX AS INTEGER, scrollY AS INTEGER, scrollH AS INTEGER)
DECLARE FUNCTION DRAWER_slot_at% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_palette_cell_at% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION DRAWER_palette_page_button_at% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB DRAWER_load_brush_slot_to_custom (slotIndex AS INTEGER)
DECLARE SUB DRAWER_store_to_slot (slotIndex AS INTEGER)
DECLARE SUB DRAWER_clear_slot (slotIndex AS INTEGER)
DECLARE SUB DRAWER_select_palette_color (mouseX AS INTEGER, mouseY AS INTEGER, setBackground AS INTEGER)
DECLARE SUB DRAWER_sync_palette_marker (targetColor AS _UNSIGNED LONG, setBackground AS INTEGER)
DECLARE SUB DRAWER_draw_checker_fill (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, cellSize AS INTEGER)
DECLARE SUB DRAWER_draw_transparent_chip (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, borderColor AS _UNSIGNED LONG)
DECLARE SUB DRAWER_cycle_mode ()
DECLARE SUB DRAWER_select_slot (slotIndex AS INTEGER)
DECLARE SUB DRAWER_swap_slots (slotA AS INTEGER, slotB AS INTEGER)
DECLARE SUB DRAWER_insert_slot (srcSlot AS INTEGER, dstSlot AS INTEGER)
DECLARE SUB DRAWER_clear_deferred_action ()
DECLARE SUB DRAWER_save_slot_image (fh AS INTEGER, imgHandle AS LONG)
DECLARE FUNCTION DRAWER_load_slot_image& (fh AS INTEGER)
DECLARE FUNCTION DRAWER_set_mode_name$ (mode AS INTEGER)
DECLARE FUNCTION DRAWER_popup_font_handle& ()
DECLARE SUB DRAWER_context_menu_build (itemCount AS INTEGER)
DECLARE SUB DRAWER_explore_context_folder ()
DECLARE FUNCTION DRAWER_sets_dir$ ()
DECLARE SUB DRAWER_ensure_sets_dir ()
DECLARE FUNCTION DRAWER_load_dset_file% (filename AS STRING, targetMode AS INTEGER)

' Palette/gradient rendering state (lazily initialized)
DIM SHARED DRAWER_PALETTE_IMG AS LONG
DIM SHARED DRAWER_PALETTE_LEFT_IMG AS LONG
DIM SHARED DRAWER_PALETTE_RIGHT_IMG AS LONG
DIM SHARED DRAWER_GRADIENT_LAST_FG AS _UNSIGNED LONG
DIM SHARED DRAWER_GRADIENT_LAST_BG AS _UNSIGNED LONG

DRAWER_init