''
' DRAW - GUI/CHARMAP.BI
' =============================================================================
' Character Map — declarations, TYPE, and shared state.
' A dockable panel showing a config-driven grid of font glyphs (256 cells, 0-255).
' Tracks the active text font, owns a glyph cache, and feeds selected glyphs
' to the text tool (editable placement) or custom brush pipeline (stamping).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' --- Constants ---
CONST CHARMAP_MIN_CELLS_PER_ROW = 4
CONST CHARMAP_MAX_CELLS_PER_ROW = 16
CONST CHARMAP_CELL_COUNT        = 256   ' Total cells (0..255) per page
CONST CHARMAP_DOCK_LEFT         = 0
CONST CHARMAP_DOCK_RIGHT        = 1
CONST CHARMAP_NO_SELECTION      = -1    ' No glyph selected
CONST CHARMAP_MAX_UNICODE_CPS   = 16384 ' Max discoverable Unicode codepoints per font
CONST CHARMAP_PAGE_INDICATOR_H  = 14    ' Height of page nav bar in pixels

TYPE CHARMAP_OBJ
    visible          AS INTEGER ' TRUE when panel should render
    dockSide         AS INTEGER ' CHARMAP_DOCK_LEFT or CHARMAP_DOCK_RIGHT
    panelX1          AS INTEGER ' Left edge (screen coords, set by layout)
    panelX2          AS INTEGER ' Right edge
    panelY1          AS INTEGER ' Top (below menubar/text bar)
    panelY2          AS INTEGER ' Bottom
    panelW           AS INTEGER ' Total panel width (computed)
    cellsPerRow      AS INTEGER ' Grid columns per row (config-backed, 4..16)
    cellW            AS INTEGER ' Glyph cell width in pixels (config-backed)
    cellH            AS INTEGER ' Glyph cell height in pixels (config-backed)
    cellPadding      AS INTEGER ' Padding between cells in pixels
    selectedIdx      AS INTEGER ' Currently selected glyph index (0-255, -1 = none)
    hoverIdx         AS INTEGER ' Currently hovered glyph index (-1 = none)
    scrollY          AS INTEGER ' Vertical scroll offset (for future use)
    ' Glyph cache state
    cacheValid       AS INTEGER ' TRUE when cache matches current font settings
    cacheFontIdx     AS INTEGER ' Font index used to build cache
    cacheFontSize    AS INTEGER ' Font size used to build cache
    cacheMono        AS INTEGER ' Mono flag used to build cache
    ' Flash state for typed character highlight
    flashIdx         AS INTEGER ' Character index being flashed (-1 = none)
    flashTimer       AS SINGLE  ' Timer value when flash started
    ' Use Chars mode
    useChars         AS INTEGER ' TRUE when Character Mode is active
    ' Computed grid origin (inside panel, after padding)
    gridX            AS INTEGER ' Left edge of grid area
    gridY            AS INTEGER ' Top edge of grid area
    ' On-canvas character grid overlay
    charGridShow     AS INTEGER ' TRUE when character grid is visible on canvas
    charGridSnap     AS INTEGER ' TRUE when snap-to-char-grid is active
    charGridW        AS INTEGER ' Character grid cell width (pixels)
    charGridH        AS INTEGER ' Character grid cell height (pixels)
    charGridImg      AS LONG    ' Pre-rendered character grid image handle
    ' Unicode mode
    unicodeMode      AS INTEGER ' TRUE when showing Unicode codepoints (not CP437)
    unicodePage      AS INTEGER ' Current page index (0-based)
    unicodePageCount AS INTEGER ' Total number of discovered pages
    unicodeScanDone  AS INTEGER ' TRUE when font has been scanned for glyphs
END TYPE

DIM SHARED CHARMAP AS CHARMAP_OBJ

' Glyph cache — one image handle per cell (0..255)
' Each handle is a pre-rendered glyph at current font/size.
' Valid handles are < -1. 0 = not yet rendered.
DIM SHARED CHARMAP_GLYPH(0 TO CHARMAP_CELL_COUNT - 1) AS LONG
DIM SHARED CHARMAP_GLYPH_W(0 TO CHARMAP_CELL_COUNT - 1) AS INTEGER    ' Actual glyph width
DIM SHARED CHARMAP_GLYPH_H(0 TO CHARMAP_CELL_COUNT - 1) AS INTEGER    ' Actual glyph height
DIM SHARED CHARMAP_GLYPH_YOFF(0 TO CHARMAP_CELL_COUNT - 1) AS INTEGER ' Y offset from font top (inkMinY)

' Unicode codepoint mapping — maps cell index (0..255) to actual codepoint.
' In CP437 mode: CHARMAP_CODEPOINT(i) = i.  In Unicode mode: actual Unicode CP.
DIM SHARED CHARMAP_CODEPOINT(0 TO CHARMAP_CELL_COUNT - 1) AS LONG

' Discovered Unicode codepoints for the current font (flat list, all pages).
DIM SHARED CHARMAP_FOUND_CP(0 TO CHARMAP_MAX_UNICODE_CPS - 1) AS LONG
DIM SHARED CHARMAP_FOUND_CP_COUNT AS LONG

' Per-widget dirty flag
DIM SHARED CHARMAP_NEEDS_REDRAW AS INTEGER
CHARMAP_NEEDS_REDRAW% = TRUE

