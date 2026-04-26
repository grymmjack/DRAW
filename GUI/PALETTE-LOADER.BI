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

' Declarations
