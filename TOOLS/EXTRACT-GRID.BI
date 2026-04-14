''
' DRAW - TOOLS/EXTRACT-GRID.BI
' =============================================================================
' Extract From Grid - exports fixed-size grid cells as PNG files.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

TYPE EXTRACT_GRID_CONFIG_OBJ
    destDir        AS STRING
    baseFilename   AS STRING
    nextNumber     AS INTEGER
END TYPE

DIM SHARED EXTRACT_GRID_CONFIG AS EXTRACT_GRID_CONFIG_OBJ

' Persisted config - saved in DRW file for per-document recall
DIM SHARED EXTRACT_GRID_HAS_CONFIG AS INTEGER
DIM SHARED EXTRACT_GRID_SAVED_DEST_DIR AS STRING
DIM SHARED EXTRACT_GRID_SAVED_BASE_FILENAME AS STRING
DIM SHARED EXTRACT_GRID_SAVED_NEXT_NUMBER AS INTEGER

DECLARE SUB EXTRACT_GRID_run ()
DECLARE SUB EXTRACT_GRID_reset_saved_config ()
