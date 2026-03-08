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
CONST DRAWER_SLOT_COUNT    = 16
CONST DRAWER_GRID_COLS     = 4
CONST DRAWER_GRID_ROWS     = 4

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
DECLARE FUNCTION DRAWER_mode_is_active% (mode AS INTEGER)
DECLARE FUNCTION DRAWER_has_paint_mode% ()
DECLARE FUNCTION DRAWER_resolve_paint_color~& (x AS INTEGER, y AS INTEGER, baseColor AS _UNSIGNED LONG)
DECLARE SUB DRAWER_save_state_binary (fh AS INTEGER)
DECLARE SUB DRAWER_load_state_binary (fh AS INTEGER)
DECLARE SUB DRAWER_export_set_dialog ()
DECLARE SUB DRAWER_import_set_dialog ()

DRAWER_init