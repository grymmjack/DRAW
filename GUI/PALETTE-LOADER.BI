''
' DRAW - GUI/PALETTE-LOADER.BI
' =============================================================================
' Dynamic palette loading system for switching between palettes at runtime.
' 
' This module provides functions to:
' - List available palettes in the ASSETS/PALETTES folder
' - Load any .GPL palette file at runtime
' - Switch between palettes without recompiling
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Palette info structure
TYPE PALETTE_INFO
    pname    AS STRING * 64
    filename AS STRING * 128
    count    AS INTEGER
END TYPE

DIM SHARED PALETTE_LIST(0 TO 255) AS PALETTE_INFO
DIM SHARED PALETTE_LOADER_COUNT%
DIM SHARED PALETTE_LOADER_CURRENT_IDX%
DIM SHARED PALETTE_EMBEDDED_NAME$   ' Name of embedded palette (when not found in GPL files)
DIM SHARED PALETTE_EMBEDDED_ACTIVE% ' TRUE when using embedded palette from DRW file

' Tracks which palette entries are from user sources (for filtering)
' 0=builtin ASSETS, 1=Lospec user download, 2=Created from image
DIM SHARED PALETTE_LIST_SOURCE(0 TO 255) AS INTEGER

' --- Palette color-chip preview cache (used by the palette dropdown menu) ---
' Colors are parsed lazily, one palette at a time, the first time a menu row is
' drawn — scanning every .GPL up front would stall startup on large Lospec sets.
CONST PALETTE_PREVIEW_MAX_CHIPS   = 64  ' Hard cap on chips cached/drawn per palette
CONST PALETTE_PREVIEW_CHIPS_PER_ROW = 32 ' Chips drawn per chip row (2 rows max)

' State per palette index: 0 = not parsed yet, 1 = parsed OK, -1 = parse failed
DIM SHARED PALETTE_PREVIEW_STATE(0 TO 255) AS INTEGER
' Number of chips actually cached (0 .. PALETTE_PREVIEW_MAX_CHIPS)
DIM SHARED PALETTE_PREVIEW_SHOWN(0 TO 255) AS INTEGER
' Total colors found in the file (may exceed PALETTE_PREVIEW_MAX_CHIPS)
DIM SHARED PALETTE_PREVIEW_TOTAL(0 TO 255) AS INTEGER
DIM SHARED PALETTE_PREVIEW_COLORS(0 TO 255, 0 TO PALETTE_PREVIEW_MAX_CHIPS - 1) AS _UNSIGNED LONG

' Per-frame budget so opening the menu never parses dozens of files in one frame
DIM SHARED PALETTE_PREVIEW_BUDGET% ' Remaining parses allowed this frame
DIM SHARED PALETTE_PREVIEW_PENDING% ' TRUE when rows were skipped and need another frame

' Declarations
