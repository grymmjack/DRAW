''
' DRAW - GUI/ANNOTATE.BI
' =============================================================================
' Screenshot annotation tools (the Annotate workspace's keys; also Tools >
' Annotate and the command palette). Built on existing tools where possible:
'
'   Arrow       the line tool with a sticky arrow end cap
'   Highlighter brush on a "Highlight" layer in Multiply, yellow
'   Redact      drag a box with the rect marquee: it is pixelated at once
'   Callout     click: a filled circle with the next number (Shift+N resets)
'   Quick Save  flattened PNG to CAPTURE_SAVE_DIR, no dialog (Ctrl+S)
'   Done        quick save + copy to the clipboard + back to the document
'               and workspace you had before the capture (Ctrl+Enter)
'
' Redact and Callout are "armed" modes polled by ANN_tick after each frame;
' they disarm when another tool is picked.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANN_ACT_QUICKSAVE     = 2451
CONST ANN_ACT_DONE          = 2452
CONST ANN_ACT_ARROW         = 2453
CONST ANN_ACT_HIGHLIGHT     = 2454
CONST ANN_ACT_REDACT        = 2455
CONST ANN_ACT_CALLOUT       = 2456
CONST ANN_ACT_CALLOUT_RESET = 2457

CONST ANN_HIGHLIGHT_LAYER$ = "Highlight"

DIM SHARED ANN_ARROW_ON      AS INTEGER ' the line tool was picked as Arrow
DIM SHARED ANN_REDACT_ARMED  AS INTEGER
DIM SHARED ANN_CALLOUT_ARMED AS INTEGER
DIM SHARED ANN_CALLOUT_N     AS INTEGER ' last number placed
DIM SHARED ANN_PREV_B1       AS INTEGER
DIM SHARED ANN_EXIT_FRAMES   AS INTEGER ' >0: quit DRAW after this many frames (one-shot --capture Done)

' Capture document bookkeeping (GUI/CAPTURE fills it): Done returns here
DIM SHARED CAP_STASHED       AS INTEGER ' the previous document was saved to the cache
DIM SHARED CAP_STASH_FILE    AS STRING
DIM SHARED CAP_STASH_NAME    AS STRING  ' its CURRENT_FILENAME$
DIM SHARED CAP_STASH_DRW     AS STRING  ' its CURRENT_DRW_FILENAME$
DIM SHARED CAP_STASH_DIRTY   AS INTEGER
DIM SHARED CAP_STASH_ZOOM    AS SINGLE  ' its view, so it comes back exactly as you left it
DIM SHARED CAP_STASH_OX      AS INTEGER
DIM SHARED CAP_STASH_OY      AS INTEGER
DIM SHARED CAP_QUICK_PATH    AS STRING  ' where this capture was quick-saved ("" = not yet)
