'$INCLUDEONCE

' ============================================================================
' FILE-DIALOG.BI — Leader include file for QB64_GJ_FILE_DIALOG library
'
' Usage:
'   '$INCLUDE:'path/to/FILE-DIALOG.BI'
'   ' ... your code ...
'   '$INCLUDE:'path/to/FILE-DIALOG.BM'
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Type definitions and constants ---
'$INCLUDE:'FD-TYPES.BI'

' --- Theme / layout constants ---
'$INCLUDE:'FD-THEME.BI'

' --- Reusable text input widget ---
'$INCLUDE:'../QB64_GJ_TEXT_INPUT/TEXT-INPUT.BI'

' --- C interop declarations ---
'$INCLUDE:'FD-PLATFORM.BI'

' --- Thumbnail types ---
'$INCLUDE:'FD-THUMB.BI'

' --- Forward declarations for cross-module calls ---
DECLARE SUB FD_add_favorite (dirPath AS STRING)
DECLARE SUB FD_remove_favorite (dirPath AS STRING)
DECLARE SUB FD_save_favorites
DECLARE SUB FD_init_places
