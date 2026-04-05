''
' DRAW - OUTPUT/FILE-EXPORT.BI
' =============================================================================
' Export flattened image declarations — action IDs and constants for the
' File → Export As submenu.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Export format action IDs (used by CMD_execute_action and MENUBAR export submenu)
CONST EXPORT_ACT_PNG_NATIVE  = 2201   ' PNG with embedded drAw chunk
CONST EXPORT_ACT_PNG         = 2204   ' Plain PNG (no drAw chunk)
CONST EXPORT_ACT_GIF         = 2205   ' GIF
CONST EXPORT_ACT_JPG         = 2206   ' JPEG
CONST EXPORT_ACT_TGA         = 2208   ' Truevision TGA
CONST EXPORT_ACT_BMP         = 2209   ' Windows Bitmap
CONST EXPORT_ACT_HDR         = 2210   ' Radiance HDR
CONST EXPORT_ACT_ICO         = 2211   ' Windows Icon
CONST EXPORT_ACT_QOI         = 2216   ' Quite OK Image

' Flyout parent action ID (marker for the cascading submenu trigger)
CONST EXPORT_ACT_FLYOUT      = 217

' Total items in the export flyout
CONST EXPORT_FLYOUT_ITEMS    = 9

' Sub declarations
DECLARE SUB EXPORT_flattened_as (formatExt AS STRING, formatName AS STRING, embedDrawChunk AS INTEGER)
