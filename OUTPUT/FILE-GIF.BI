''
' DRAW - OUTPUT/FILE-GIF.BI
' =============================================================================
' Native GIF89a writer + reader with palette color cycling ranges.
'
' Writer (GIF_export%): the document flattened and indexed onto the palette
' (OUTPUT/PAL-INDEX), LZW-compressed. Cycle ranges are written as the GrafX2
' "CRNG" application extension right after the global color table:
'     21 FF 0B "CRNG" 00 00 00 00 "1.0"  <size> { rate BE16, flags BE16, lo, hi } ... 00
' (rate: 16384 = 60 steps/s; flags bit0 = active, bit1 = reverse) - the same
' records as a DeluxePaint ILBM CRNG chunk. Ping-pong and the held step have
' no CRNG encoding, so DRAW adds a private "DRAWCYCL1.0" extension that other
' readers skip. An animated GIF of the cycle (P4) shares the LZW encoder.
'
' Reader (GIF_load_cycling%): QB64's _LOADIMAGE remaps GIFs onto its default
' VGA palette (verified 2026-10-06), so a GIF that carries CRNG ranges is
' decoded here instead - the file's own palette, true indices and ranges.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST GIF_HSIZE = 5003 ' LZW hash table size (prime, classic compress)

' LZW encoder state
DIM SHARED GIF_HTAB(0 TO GIF_HSIZE - 1)    AS LONG
DIM SHARED GIF_CODETAB(0 TO GIF_HSIZE - 1) AS INTEGER
DIM SHARED GIF_OUT       AS STRING  ' encoded bytes (grown by doubling)
DIM SHARED GIF_OUT_N     AS LONG    ' bytes used in GIF_OUT
DIM SHARED GIF_ACC       AS LONG    ' bit accumulator
DIM SHARED GIF_ACC_BITS  AS INTEGER
DIM SHARED GIF_NBITS     AS INTEGER
DIM SHARED GIF_MAXCODE   AS LONG
DIM SHARED GIF_FREE_ENT  AS LONG
DIM SHARED GIF_CLEAR_FLG AS INTEGER
DIM SHARED GIF_INIT_BITS AS INTEGER
DIM SHARED GIF_CLEAR_CODE AS LONG
DIM SHARED GIF_EOF_CODE  AS LONG

DIM SHARED GIF_LAST_INFO AS STRING ' human summary of the last export (frames, quantized pixels...)
