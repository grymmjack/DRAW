''
' DRAW - TOOLS/DRW.BI
' =============================================================================
' DRAW native file format (.draw) - PNG with embedded drAw chunk
'
' File format (v2 - PNG-based):
'   Standard PNG image (merged/flattened canvas preview) with a custom
'   ancillary "drAw" chunk containing compressed project data.
'
'   The drAw chunk payload:
'     Chunk Format Version: INTEGER (2 bytes, little-endian)
'     Uncompressed Size: LONG (4 bytes, little-endian)
'     Compressed Data: DEFLATE-compressed binary project data
'
'   The binary project data (same as legacy DRW1 format):
'     Header: "DRW1" magic + version + canvas dimensions
'     Palette: colors + FG/BG indices
'     Layers: properties + pixel data per layer
'     Tool State: current tool, brush size, grid, etc.
'     Palette Name: (v3+) name of loaded GPL palette
'
'   Backward compatible: DRW_load auto-detects PNG vs legacy binary format.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Binary project data format constants
CONST DRW_MAGIC$ = "DRW1"
CONST DRW_VERSION% = 3

' PNG drAw chunk format version
CONST DRW_CHUNK_VERSION% = 1

' Declare public API
DECLARE SUB DRW_save (filename AS STRING)
DECLARE SUB DRW_load (filename AS STRING)
DECLARE SUB DRW_save_dialog ()
DECLARE SUB DRW_open_dialog ()
DECLARE SUB DRW_embed_chunk_in_png (pngFilePath AS STRING)
DECLARE SUB DRW_new_canvas ()

