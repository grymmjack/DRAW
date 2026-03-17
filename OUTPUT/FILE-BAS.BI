''
' DRAW - OUTPUT/FILE-BAS.BI
' =============================================================================
' UDT for BAS files.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

''
' Opens a save-file dialog and exports drawing history as a standalone QB64 BAS source file
'
DECLARE SUB FILE_BAS_export_dialog ()
''
' Exports the full drawing history as a standalone QB64 BAS source file
' @param filename$ Output file path for the generated .bas file
'
DECLARE SUB FILE_BAS_export (filename AS STRING)
''
' Resets and recreates the WIP BAS stream file with a fresh header
'
DECLARE SUB FILE_BAS_wip_reset ()
''
' Appends a single history record's drawing ops to the WIP BAS stream file
' @param recordIndex% Index into HISTORY_RECORDS() to export
'
DECLARE SUB FILE_BAS_wip_append_record (recordIndex AS INTEGER)
''
' Rebuilds the entire WIP BAS stream file from all current history records
'
DECLARE SUB FILE_BAS_wip_rebuild_from_history ()
