''
' DRAW - INPUT/FILE-LBM.BI
' =============================================================================
' DeluxePaint IFF images: FORM ILBM (planar) and FORM PBM (chunky, DPaint II
' Enhanced / PC), with their palette and CRNG color cycling ranges.
'
' Reader (this module, via the DRW_load "FORM" sniff - Open, Import, the
' command line and drag-and-drop all go through it): BMHD, CMAP (old 4-bit
' palettes are rescaled), CAMG (HAM is refused, Extra-Halfbrite expanded to
' 64 colors), CRNG, DRAW's private DRCY chunk, BODY (uncompressed or
' ByteRun1), mask plane / transparent color. 1-8 bitplanes.
' Writer: OUTPUT/FILE-LBM.BM.
'
' CRNG chunk (8 bytes, big-endian): pad(2) rate(2) flags(2) low(1) high(1);
' rate 16384 = 60 steps/s; flags bit0 = active, bit1 = reverse.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED LBM_LAST_ERROR AS STRING ' why the last LBM load/save failed
