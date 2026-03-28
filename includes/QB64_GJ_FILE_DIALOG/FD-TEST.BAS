OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' FD-TEST.BAS — Standalone test for QB64_GJ_FILE_DIALOG
'
' Proves the library works independently from DRAW.
' ============================================================================

SCREEN _NEWIMAGE(1920, 1080, 32)
_TITLE "File Dialog Test"

'$INCLUDE:'FILE-DIALOG.BI'

' --- Test Open File ---
DIM result AS STRING
PRINT "Press ENTER to open a file dialog..."
SLEEP
result = FD_open_file$("Open File", "", "All Files|*.*|Image Files|*.png|*.bmp|*.jpg|*.gif", 0)
IF LEN(result) > 0 THEN
    PRINT "Selected: "; result
ELSE
    PRINT "Cancelled."
END IF
PRINT

' --- Test Save File ---
PRINT "Press ENTER to open a save dialog..."
SLEEP
result = FD_save_file$("Save File", "", "BMP Files|*.bmp|PNG Files|*.png|All Files|*.*", 0, "untitled.bmp", "bmp")
IF LEN(result) > 0 THEN
    PRINT "Save to: "; result
ELSE
    PRINT "Cancelled."
END IF
PRINT

' --- Test Choose Folder ---
PRINT "Press ENTER to open a folder chooser..."
SLEEP
result = FD_choose_folder$("Choose Folder", "")
IF LEN(result) > 0 THEN
    PRINT "Folder: "; result
ELSE
    PRINT "Cancelled."
END IF

PRINT
PRINT "Done. Press any key to exit."
SLEEP

SYSTEM

'$INCLUDE:'FILE-DIALOG.BM'
