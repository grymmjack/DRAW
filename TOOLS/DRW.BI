''
' DRAW - TOOLS/DRW.BI
' =============================================================================
' DRAW native file format (.draw) - saves layers, palette, tool states
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST DRW_MAGIC$ = "DRW1"
CONST DRW_VERSION% = 3

' Declare subs/functions
DECLARE SUB DRW_save (filename AS STRING)
DECLARE SUB DRW_load (filename AS STRING)
DECLARE SUB DRW_save_dialog ()
DECLARE SUB DRW_open_dialog ()

