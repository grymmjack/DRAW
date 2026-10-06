''
' DRAW - OUTPUT/BATCH.BI
' =============================================================================
' Command-line batch conversion (no dialogs, exits when done):
'
'   DRAW in.png --palette p.gpl --cycle 16-31:8:rev --export out.draw
'   DRAW art.draw --export art.bas         (single-file color cycling program)
'   DRAW art.draw --export art.gif         (GIF + GrafX2 CRNG cycle ranges)
'   DRAW art.draw --export art.lbm         (DeluxePaint ILBM + CRNG)
'   DRAW art.draw --export-anim art.gif    (animated GIF of the cycle)
'
' --cycle lo-hi[:steps-per-second[:fwd|rev|ping]] adds a color cycling range
' (repeatable) after the document and --palette have loaded. All flags run on
' the first frame, in that order, then DRAW exits (code 0 = every export
' written, 1 = something failed).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED BATCH_EXPORT_PATH      AS STRING ' --export <path>
DIM SHARED BATCH_EXPORT_ANIM_PATH AS STRING ' --export-anim <path.gif>
DIM SHARED BATCH_CYCLE_SPECS      AS STRING ' --cycle specs, CHR$(0)-separated
DIM SHARED BATCH_FAILED           AS INTEGER
