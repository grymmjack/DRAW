''
' DRAW - OUTPUT/FILE-BAS.BI
' =============================================================================
' UDT for BAS files.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE SUB FILE_BAS_export_dialog ()
DECLARE SUB FILE_BAS_export (filename AS STRING)
DECLARE SUB FILE_BAS_wip_reset ()
DECLARE SUB FILE_BAS_wip_append_record (recordIndex AS INTEGER)
DECLARE SUB FILE_BAS_wip_rebuild_from_history ()
