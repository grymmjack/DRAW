''
' DRAW - TOOLS/CANVAS-REC.BI
' =============================================================================
' Canvas recording (time-lapse). Every committed change (a new history state:
' a step, an undo, a redo) adds a frame: the rect of the flattened picture that
' changed since the frame before, deflated. Frame 1 is the whole picture as the
' recording started; a canvas size change is a whole-picture frame too. The
' frames replay in order onto one image, so frame N is the picture after N.
'
' On by default (CFG.CANVAS_RECORDING); the REC badge in the status bar pauses /
' resumes it for the document. Saved inside the .draw in its own PNG chunk
' "drRc" (an older DRAW skips it). Over CFG.CANVAS_RECORDING_MB the oldest
' frames are merged in pairs (thinned), never dropped from the end.
' View > Canvas Recording... plays / scrubs it and exports APNG or a PNG
' sequence. PLANS/HISTORY-ACTIONS-PALETTES.md section 3.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CREC_CHUNK_VERSION = 1
CONST CREC_MAX_FRAMES    = 30000 ' INTEGER slider range in the viewer; thinned past it
CONST CREC_SETTLE        = 0.15  ' seconds a new state waits before it is captured (off the stroke's frame)

CONST CREC_ACT_VIEW   = 2710 ' View > Canvas Recording...
CONST CREC_ACT_PAUSE  = 2711 ' Pause / Resume Recording (the status bar REC badge)
CONST CREC_ACT_DELETE = 2712 ' Delete Recording...
CONST CREC_ACT_TOGGLE = 2713 ' Canvas Recording on / off (the setting)

TYPE CREC_OBJ
    n        AS LONG    ' frames
    bytes    AS LONG    ' deflated bytes held (the frames' data)
    paused   AS INTEGER ' this document's recording is paused (saved with it)
    last     AS LONG    ' image: the picture after the last frame (= every frame replayed)
    pending  AS INTEGER ' a new state waits to be captured
    pendingT AS DOUBLE  ' TIMER when it was seen
    thinned  AS LONG    ' frames merged away by the size cap (saved: the viewer says so)
    omit     AS INTEGER ' the next save leaves the recording out (Save As asked)
    prevCur  AS INTEGER ' HISTORY.current at the last capture (UNDO / REDO labels)
    prevCnt  AS INTEGER ' HISTORY.count at the last capture
    capMs    AS LONG    ' the last capture took (ms; QA dump CRECT)
    flatMs   AS LONG    ' ... of it the flatten
    diffMs   AS LONG    ' ... of it the compare
END TYPE
DIM SHARED CREC AS CREC_OBJ
DIM SHARED CREC_SEEN AS STRING ' the history state last seen (HISTP_watch's key)

' Per frame (1..CREC.n): the canvas size, the changed rect, its deflated BGRA
' rows (w * h * 4 raw bytes) and the step's name.
DIM SHARED CREC_CW(1 TO 1) AS LONG, CREC_CH(1 TO 1) AS LONG
DIM SHARED CREC_FX(1 TO 1) AS LONG, CREC_FY(1 TO 1) AS LONG
DIM SHARED CREC_FW(1 TO 1) AS LONG, CREC_FH(1 TO 1) AS LONG
DIM SHARED CREC_FD(1 TO 1) AS STRING, CREC_LB(1 TO 1) AS STRING
DIM SHARED CREC_ROOMS AS LONG ' the arrays' size
DIM SHARED CREC_GIF_INFO AS STRING ' the last GIF export's colours ("40 colours", "256 colours (adaptive)")

' Status bar badge bounds (click = pause / resume); X2 < X1 = none drawn
DIM SHARED CREC_BADGE_X1 AS INTEGER, CREC_BADGE_X2 AS INTEGER

CREC_ROOMS = 1
