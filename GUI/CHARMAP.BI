''
' DRAW - GUI/CHARMAP.BI
' =============================================================================
' Character Map — declarations, TYPE, and shared state.
' A dockable panel showing a 16x16 grid of font glyphs (256 cells, 0-255).
' Tracks the active text font, owns a glyph cache, and feeds selected glyphs
' to the text tool (editable placement) or custom brush pipeline (stamping).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' --- Constants ---
CONST CHARMAP_COLS         = 16    ' Grid columns (fixed 16x16 = 256 cells)
CONST CHARMAP_ROWS         = 16    ' Grid rows
CONST CHARMAP_CELL_COUNT   = 256   ' Total cells (0..255)
CONST CHARMAP_DOCK_LEFT    = 0
CONST CHARMAP_DOCK_RIGHT   = 1
CONST CHARMAP_NO_SELECTION = -1    ' No glyph selected

TYPE CHARMAP_OBJ
    visible         AS INTEGER  ' TRUE when panel should render
    dockSide        AS INTEGER  ' CHARMAP_DOCK_LEFT or CHARMAP_DOCK_RIGHT
    panelX1         AS INTEGER  ' Left edge (screen coords, set by layout)
    panelX2         AS INTEGER  ' Right edge
    panelY1         AS INTEGER  ' Top (below menubar/text bar)
    panelY2         AS INTEGER  ' Bottom
    panelW          AS INTEGER  ' Total panel width (computed)
    cellW           AS INTEGER  ' Glyph cell width in pixels (config-backed)
    cellH           AS INTEGER  ' Glyph cell height in pixels (config-backed)
    cellPadding     AS INTEGER  ' Padding between cells in pixels
    selectedIdx     AS INTEGER  ' Currently selected glyph index (0-255, -1 = none)
    hoverIdx        AS INTEGER  ' Currently hovered glyph index (-1 = none)
    scrollY         AS INTEGER  ' Vertical scroll offset (for future use)
    ' Glyph cache state
    cacheValid      AS INTEGER  ' TRUE when cache matches current font settings
    cacheFontIdx    AS INTEGER  ' Font index used to build cache
    cacheFontSize   AS INTEGER  ' Font size used to build cache
    cacheMono       AS INTEGER  ' Mono flag used to build cache
    ' Flash state for typed character highlight
    flashIdx        AS INTEGER  ' Character index being flashed (-1 = none)
    flashTimer      AS SINGLE   ' Timer value when flash started
    ' Use Chars mode
    useChars        AS INTEGER  ' TRUE when Character Mode is active
    ' Computed grid origin (inside panel, after padding)
    gridX           AS INTEGER  ' Left edge of grid area
    gridY           AS INTEGER  ' Top edge of grid area
    ' On-canvas character grid overlay
    charGridShow    AS INTEGER  ' TRUE when character grid is visible on canvas
    charGridSnap    AS INTEGER  ' TRUE when snap-to-char-grid is active
    charGridW       AS INTEGER  ' Character grid cell width (pixels)
    charGridH       AS INTEGER  ' Character grid cell height (pixels)
    charGridImg     AS LONG     ' Pre-rendered character grid image handle
END TYPE

DIM SHARED CHARMAP AS CHARMAP_OBJ

' Glyph cache — one image handle per cell (0..255)
' Each handle is a pre-rendered glyph at current font/size.
' Valid handles are < -1. 0 = not yet rendered.
DIM SHARED CHARMAP_GLYPH(0 TO CHARMAP_CELL_COUNT - 1) AS LONG
DIM SHARED CHARMAP_GLYPH_W(0 TO CHARMAP_CELL_COUNT - 1) AS INTEGER  ' Actual glyph width
DIM SHARED CHARMAP_GLYPH_H(0 TO CHARMAP_CELL_COUNT - 1) AS INTEGER  ' Actual glyph height

' Per-widget dirty flag
DIM SHARED CHARMAP_NEEDS_REDRAW AS INTEGER
CHARMAP_NEEDS_REDRAW% = TRUE

DECLARE SUB CHARMAP_init ()
DECLARE SUB CHARMAP_render ()
DECLARE SUB CHARMAP_toggle ()
DECLARE SUB CHARMAP_rebuild_cache ()
DECLARE SUB CHARMAP_rebuild_cache_bitmap (fIdx AS INTEGER)
DECLARE SUB CHARMAP_free_cache ()
DECLARE SUB CHARMAP_reset ()
DECLARE SUB CHARMAP_select_glyph (idx AS INTEGER)
DECLARE SUB CHARMAP_flash_glyph (idx AS INTEGER)
DECLARE FUNCTION CHARMAP_is_over_area% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION CHARMAP_hit_test_cell% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB CHARMAP_handle_click (rawX AS INTEGER, rawY AS INTEGER, btn AS INTEGER)
DECLARE SUB CHARMAP_update_hover (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB CHARMAP_copy_glyph_to_custom_brush ()
DECLARE SUB CHARMAP_copy_glyph_to_custom_brush_bg ()
DECLARE FUNCTION CHARMAP_effective_font_size% ()
DECLARE FUNCTION CHARMAP_panel_width% ()
DECLARE SUB CHARMAP_char_grid_draw ()
DECLARE SUB CHARMAP_char_grid_toggle ()
DECLARE SUB CHARMAP_char_grid_snap_toggle ()
DECLARE SUB CHARMAP_char_grid_snap_xy (snapX AS INTEGER, snapY AS INTEGER)
DECLARE SUB CHARMAP_char_grid_update_size ()
DECLARE SUB CHARMAP_char_grid_fill_cell (px AS INTEGER, py AS INTEGER, fillColor AS _UNSIGNED LONG)
