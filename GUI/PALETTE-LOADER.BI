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
    pname     AS STRING * 64
    filename AS STRING * 128
    count    AS INTEGER
END TYPE

DIM SHARED PALETTE_LIST(0 TO 255) AS PALETTE_INFO
DIM SHARED PALETTE_LOADER_COUNT%
DIM SHARED PALETTE_LOADER_CURRENT_IDX%

' Declarations
DECLARE SUB PALETTE_LOADER_init ()
DECLARE SUB PALETTE_LOADER_scan_folder (folder AS STRING)
DECLARE SUB PALETTE_LOADER_add_palette (palname AS STRING)
DECLARE FUNCTION PALETTE_LOADER_load% (filename AS STRING)
DECLARE FUNCTION PALETTE_LOADER_load_gpl% (filepath AS STRING)
DECLARE FUNCTION PALETTE_LOADER_load_by_index% (idx AS INTEGER)
DECLARE FUNCTION PALETTE_LOADER_next% ()
DECLARE FUNCTION PALETTE_LOADER_prev% ()
DECLARE FUNCTION PALETTE_LOADER_get_name$ ()
DECLARE FUNCTION PALETTE_LOADER_get_count% ()
DECLARE FUNCTION PALETTE_LOADER_get_color_count% ()
