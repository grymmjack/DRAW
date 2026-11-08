''
' DRAW - OUTPUT/BATCH.BI
' =============================================================================
' Command-line batch conversion (no dialogs, exits when done):
'
'   DRAW in.png --palette p.gpl --cycle 16-31:8:rev --export out.draw
'   DRAW art.draw --export art.bas         (single-file color cycling program)
'   DRAW art.draw --export art.gif         (GIF + GrafX2 CRNG cycle ranges)
'   DRAW art.draw --export art.lbm         (DeluxePaint ILBM + CRNG)
'   DRAW art.draw --export art.png         (the picture flattened)
'   DRAW art.draw --export-anim art.gif    (animated GIF: the frames of a sheet with frames,
'                                          colour cycling along; else the colour cycle)
'   DRAW art.draw --export-anim art.png    (PNG sequence art_0001.png ..., one per tick at the FPS)
'   DRAW art.draw --export-anim art.json   (sprite sheet art.png + frame rects art.json + art.bi)
'   DRAW art.draw --export-anim art.apng   (animated PNG)
'   DRAW art.draw --export-anim art.bas    (QB64 animation player, frames in DATA)
'   DRAW art.draw --export-anim art.sheet.bas (the player + art.sheet.png it cuts the frames from)
'
' --export and --export-anim repeat (one run, several files). The formats only
' frames have (.apng .json .sheet.bas) work from --export too; .gif and .bas
' mean the frames only with --export-anim. Each export prints one console line
' ("wrote PATH (summary)" / "FAILED PATH: why").
'
' --cycle lo-hi[:steps-per-second[:fwd|rev|ping]] adds a color cycling range
' (repeatable) after the document and --palette have loaded. All flags run on
' the first frame, in that order, then DRAW exits (code 0 = every export
' written, 1 = something failed). It runs in DRAW's window, so it needs a
' display (Xvfb on a server).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED BATCH_EXPORT_PATH      AS STRING ' --export paths, CHR$(0)-separated
DIM SHARED BATCH_EXPORT_ANIM_PATH AS STRING ' --export-anim paths, CHR$(0)-separated
DIM SHARED BATCH_CYCLE_SPECS      AS STRING ' --cycle specs, CHR$(0)-separated
DIM SHARED BATCH_FAILED           AS INTEGER
