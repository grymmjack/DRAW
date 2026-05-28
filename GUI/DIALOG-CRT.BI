''
' DRAW - GUI/DIALOG-CRT.BI
' =============================================================================
' Modal "CRT Effect" settings dialog. Lives in GUI/ alongside other modal
' dialogs. The state model is direct: every control writes into CFG.* and
' sets CRT.dirty% so the next render rebakes the overlay. The screenshot
' backdrop is re-captured whenever a setting changes — that gives live
' preview through DIALOG_blit's standard restore-screenshot path.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
