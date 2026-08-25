''
' DRAW - OUTPUT/FILE-ANS.BI
' =============================================================================
' ANSI (.ans) import/export declarations — action IDs, color modes, and the
' shared export-settings singleton.
'
' Export algorithm reference: img2ans (half-block, SGR run-length, SAUCE).
' Import  algorithm reference: kaleidotron (CSI state machine, CP437 raster).
'
' Half-block primitive (both directions): one character cell = two vertically
' stacked pixels — top pixel becomes the foreground, bottom pixel the
' background, drawn with CP437 glyph 223 (upper-half block, U+2580 ▀).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' -----------------------------------------------------------------------------
' Action IDs — claimed range 2300-2319 (audit-clean; see CLAUDE.md gotcha #17).
' -----------------------------------------------------------------------------
CONST ANS_ACT_EXPORT       = 2300 ' File > Export ANSI... (opens export dialog)
CONST ANS_ACT_IMPORT       = 2301 ' File > Import ANSI... (opens file dialog)
CONST ANS_ACT_EXPORT_QUICK = 2302 ' Export ANSI with last/auto settings, no dialog
' 2303-2319 reserved for future ANSI actions (dialog buttons, mode presets, etc.)

' -----------------------------------------------------------------------------
' Color modes (ANS_EXPORT_SETTINGS.mode / import detection)
' -----------------------------------------------------------------------------
CONST ANS_MODE_16  = 0            ' 16 colors, standard SGR 30-37 / 40-47
CONST ANS_MODE_ICE = 1            ' iCE colors: bright backgrounds (100-107), blink=bright bg
CONST ANS_MODE_256 = 2            ' xterm-256 (xbin-style) via 38;5;n / 48;5;n
CONST ANS_MODE_RGB = 3            ' 24-bit truecolor via 38;2;r;g;b / 48;2;r;g;b (xterm)

' Half-block CP437 glyphs
CONST ANS_GLYPH_FULL = 219        ' █ full block
CONST ANS_GLYPH_TOP  = 223        ' ▀ upper half (FG=top, BG=bottom)
CONST ANS_GLYPH_BOT  = 220        ' ▄ lower half (FG=bottom, BG=top)

' Cell font metrics (glyph height selects SAUCE font name later)
CONST ANS_CELL_W   = 8
CONST ANS_CELL_H16 = 16
CONST ANS_CELL_H8  = 8

' Export cell-size mapping (canvas pixels -> one character cell)
CONST ANS_CELLMODE_PERPIXEL = 0   ' 1 canvas px -> 1 column (max detail; big col counts)
CONST ANS_CELLMODE_BLOCK    = 1   ' 8 canvas px -> 1 column (round-trips 1:1 with import)

' -----------------------------------------------------------------------------
' Export settings singleton
' -----------------------------------------------------------------------------
' Export source (which pixels become ANSI)
CONST ANS_SRC_FLAT      = 0       ' flattened document (all visible layers)
CONST ANS_SRC_LAYER     = 1       ' current layer only
CONST ANS_SRC_SELECTION = 2       ' active marquee selection region

TYPE ANS_EXPORT_SETTINGS
    mode      AS INTEGER ' ANS_MODE_*
    source    AS INTEGER ' ANS_SRC_* (flattened / current layer / selection)
    cellMode  AS INTEGER ' ANS_CELLMODE_* (per-pixel vs 8px block)
    cols      AS INTEGER ' explicit column override (0 = auto from cellMode)
    rows      AS INTEGER ' derived from cols to preserve aspect (0 = auto)
    autoSize  AS INTEGER ' TRUE = derive cols/rows automatically
    font8x8   AS INTEGER ' TRUE = 8x8 font (VGA50), FALSE = 8x16 (VGA)
    ice       AS INTEGER ' TRUE = iCE colors flag (also implied by ANS_MODE_ICE)
    fontName  AS STRING  ' SAUCE font name, e.g. "IBM VGA" / "IBM VGA50"
    saucTitle AS STRING  ' SAUCE title
    saucAuthr AS STRING  ' SAUCE author
    saucGroup AS STRING  ' SAUCE group
    writeSauc AS INTEGER ' TRUE = append SAUCE record on export
END TYPE
DIM SHARED ANS_EXPORT AS ANS_EXPORT_SETTINGS

' -----------------------------------------------------------------------------
' Standard 16-color ANSI palette, in SGR index order (0=black .. 15=white).
' Index maps directly: fg SGR n (30-37) -> n-30; bright (90-97) -> n-90+8.
' -----------------------------------------------------------------------------
DIM SHARED ANS_PAL(0 TO 15) AS _UNSIGNED LONG

' VGA attribute-order palette (index = text-mode attribute nibble: 1=blue, 4=red).
' Used by the binary formats (BIN / XBIN) whose bytes store raw VGA attributes,
' unlike ANS_PAL which is SGR order. XBIN files may override this with their own.
DIM SHARED ANS_VGA_PAL(0 TO 15) AS _UNSIGNED LONG

' Import source formats (for dispatch / logging)
CONST ANS_FMT_ANSI = 0 ' SGR text ANSI (.ans/.asc/.nfo/.diz)
CONST ANS_FMT_BIN  = 1 ' raw char+attr binary (.bin)
CONST ANS_FMT_XBIN = 2 ' XBIN (.xb/.xbin)
CONST ANS_FMT_TND  = 3 ' TundraDraw 24-bit (.tnd)

' -----------------------------------------------------------------------------
' Cell grid — the intermediate representation shared by every export mode and
' produced by ANS_build_cells. One cell = one CP437 character position.
' -----------------------------------------------------------------------------
TYPE ANS_CELL
    ch    AS INTEGER        ' CP437 glyph: 223 ▀ (fg=top,bg=bottom) or 219 █ (solid)
    fg    AS _UNSIGNED LONG ' foreground RGB (top half, or whole cell if solid)
    bg    AS _UNSIGNED LONG ' background RGB (bottom half)
    fgIdx AS INTEGER        ' nearest ANS_PAL index for fg (16/iCE modes)
    bgIdx AS INTEGER        ' nearest ANS_PAL index for bg
END TYPE
REDIM SHARED ANS_CELLS(0, 0) AS ANS_CELL
DIM SHARED ANS_GRID_COLS      AS INTEGER
DIM SHARED ANS_GRID_ROWS      AS INTEGER
DIM SHARED ANS_IMPORT_FONT8X8 AS INTEGER             ' cell height from the last binary parse (TRUE = 8x8)
DIM SHARED ANS_SRC_W          AS INTEGER             ' pixel dims of the last resolved export source (0 = use canvas)
DIM SHARED ANS_SRC_H          AS INTEGER

' Import metadata (set by the parsers, read by the import dialog)
DIM SHARED ANS_IMPORT_FMT      AS STRING             ' detected format name ("ANSI"/"XBIN"/"BIN"/"TundraDraw")
DIM SHARED ANS_IMPORT_GLYPHS   AS INTEGER            ' embedded-font glyph count (0 = none)
DIM SHARED ANS_IMPORT_FONTH    AS INTEGER            ' embedded-font height in px (0 = none)
DIM SHARED ANS_IMPORT_HASPAL   AS INTEGER            ' TRUE if a custom palette was embedded
DIM SHARED ANS_IMPORT_PAL(0 TO 15) AS _UNSIGNED LONG ' embedded palette (when HASPAL)
DIM SHARED ANS_IMPORT_FONTDATA AS STRING             ' raw embedded font bytes (glyphs*fontH), for font import
DIM SHARED ANS_IMPORT_DO_FONT  AS INTEGER            ' import-dialog choice: install embedded font
DIM SHARED ANS_IMPORT_DO_PAL   AS INTEGER            ' import-dialog choice: install custom palette

' Import render options (set by the import dialog, used by ANS_build_document)
DIM SHARED ANS_IMP_CELLW  AS INTEGER                 ' 8 or 9 (VGA 9-dot)
DIM SHARED ANS_IMP_ASPECT AS INTEGER                 ' vertical stretch percent: 100 square, 120 DOS aspect
DIM SHARED ANS_IMP_SCALE  AS INTEGER                 ' integer output scale multiplier (1..8)
DIM SHARED ANS_IMP_TARGET AS INTEGER                 ' import destination: 0 = new document, 1 = new layer, 2 = into selection

CONST ANS_TARGET_DOC   = 0                           ' replace the whole document with a new canvas
CONST ANS_TARGET_LAYER = 1                           ' add the art as a new layer on the current document
CONST ANS_TARGET_SEL   = 2                           ' fit the art into the active selection (like an image import)

' Optional source region — import only a char-cell rectangle of the parsed art.
' Set by the import dialog's REGION mode; applied by ANS_crop_cells_to_region.
DIM SHARED ANS_IMP_RGN_ON AS INTEGER                 ' TRUE = crop to the cell rect below
DIM SHARED ANS_IMP_RGN_C0 AS INTEGER                 ' left column   (0-based, inclusive)
DIM SHARED ANS_IMP_RGN_R0 AS INTEGER                 ' top row       (0-based, inclusive)
DIM SHARED ANS_IMP_RGN_C1 AS INTEGER                 ' right column  (0-based, inclusive)
DIM SHARED ANS_IMP_RGN_R1 AS INTEGER                 ' bottom row    (0-based, inclusive)

' Initialize the shared tables/settings (called from DRAW.BAS init chain).
ANS_export_settings_defaults
ANS_palette_init
ANS_vga_palette_init
