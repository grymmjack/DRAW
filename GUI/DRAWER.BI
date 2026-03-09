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
    samplesLoaded       AS INTEGER
    loadedTheme         AS STRING * 64
END TYPE

DIM SHARED DRAWER AS DRAWER_STATE
DIM SHARED DRAWER_BRUSH_SLOTS(1 TO DRAWER_SLOT_COUNT) AS DRAW_BRUSH
DIM SHARED DRAWER_PATTERN_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_PATTERN_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_GRADIENT_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_GRADIENT_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_GRADIENT_CUSTOM(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_SLOT AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_MODE AS INTEGER

' Gradient definition arrays — parallel to DRAWER_GRADIENT_SLOTS
DIM SHARED GRAD_DEFS(1 TO DRAWER_SLOT_COUNT) AS GRADIENT_DEF
DIM SHARED GRAD_COLOR_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_COLOR_STOP
DIM SHARED GRAD_OPACITY_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_OPACITY_STOP

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

DRAWER_init