''
' DRAW - OUTPUT/FILE-QB64.BI
' =============================================================================
' QB64PE Code Export — declarations and types.
'
' Generates a standalone QB64-PE program (.BAS + _ASSETS/ folder) from the
' current project. Each layer becomes a SUB with native drawing commands
' (vector layers), _LOADFONT + _UPRINTSTRING (text layers), or _LOADIMAGE
' from PNG (raster-fallback layers). Symbol parent/child layers deduplicate
' into a single SUB called multiple times.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Action ID for File > Export QB64 Project...
CONST EXPORT_QB64_ACTION = 220


'' Session-scoped last QB64 project export path (not persisted to config)
DIM SHARED FILE_QB64_LAST_EXPORT_PATH AS STRING
