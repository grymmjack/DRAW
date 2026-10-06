''
' DRAW - GUI/PALETTE-CYCLE.BI
' =============================================================================
' Palette color cycling (DeluxePaint / GrafX2 style).
'
' A cycle RANGE is a run of palette indices lo..hi that rotates at its own
' speed. Layers stay RGBA: a pixel belongs to the FIRST palette index with
' the same RGB (the Color Ops "a chip IS its pixels" rule), so cycling is a
' display-time remap of the composite - layer pixels are never touched.
'
'   Shift+Tab (action 2060)  toggle cycling on/off (view state, not saved)
'   Palette > Color Cycling  range from marked chips, direction, pause, speed
'   Color Ops + Ctrl gestures on the strip (see PALETTE-OPS.BI)
'
' Speeds are stored in ILBM CRNG units (16384 = 60 steps/s, linear) so .LBM
' and GrafX2 GIF round-trips are lossless. Ping-pong is a DRAW extra: CRNG
' can only say forward/reverse, so exporters write it as forward plus a
' private DRAW chunk/extension that restores it.
'
' Undo: ranges ride on the palette snapshot (PALETTE_snapshot$ "CYC1" tail),
' so every palette undo record restores the ranges that went with it.
' Saved in .draw v30 (TOOLS/DRW.BM).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST PCYC_MAX       = 16
CONST PCYC_FWD       = 0
CONST PCYC_REV       = 1
CONST PCYC_PING      = 2
CONST PCYC_RATE_UNIT = 16384 ' CRNG rate for 60 steps/s
CONST PCYC_DEFAULT_RATE = 2731 ' ~10 steps/s

TYPE PCYC_RANGE
    lo        AS INTEGER ' first palette index
    hi        AS INTEGER ' last palette index (inclusive)
    rate      AS LONG    ' CRNG units: steps/s = rate * 60 / 16384
    cmode     AS INTEGER ' PCYC_FWD / PCYC_REV / PCYC_PING
    active    AS INTEGER ' FALSE = paused (holds its current step)
    origin    AS DOUBLE  ' clock time of step 0 (rebased on speed change / unpause)
    heldStep  AS LONG    ' step a paused range holds
    shift     AS INTEGER ' current rotation (0..n-1), recomputed by PCYC_tick%
END TYPE

TYPE PCYC_OBJ
    ENABLED    AS INTEGER ' cycling is running (view state only)
    COUNT      AS INTEGER ' ranges in PCYC_R(1..COUNT), sorted by lo, never overlapping
    BUF        AS LONG    ' cycled copy of the composite (render output while cycling)
    MAP_N      AS LONG    ' cycling pixels recorded in PCYC_OFF()/PCYC_SRC()
    MAP_VALID  AS INTEGER ' PCYC_OFF/SRC describe BUF's current base
    SIG        AS STRING  ' palette + ranges signature the map was built for
    APPLIED    AS STRING  ' per-index display colors last written into BUF
    BUILT_SEQ  AS LONG    ' SCREEN_RENDER_SEQ& the buffer was built for (pattern tile = 9 calls/frame)
    OVL        AS LONG    ' 8-bit overlay: opaque cycling pixels (index 0 = clear); stepped by _PALETTECOLOR
    OVL_OK     AS INTEGER ' overlay in use (range colors fit in 255 overlay indices)
    STEP_ONLY  AS INTEGER ' this frame's only scene change is a cycle step (set by DRAW.BAS)
    LAST_FULL  AS DOUBLE  ' clock of the last full composite check (step-only frames re-verify every 0.5 s)
    CLOCK_LAST AS DOUBLE  ' TIMER at the last PCYC_now# call (midnight wrap)
    CLOCK_BASE AS DOUBLE  ' accumulated midnight wraps (seconds)
    PREV_SHIFT AS STRING  ' shifts at the last tick (change detection)
    WHEEL_T    AS DOUBLE  ' time of the last Ctrl+Wheel speed step (burst undo)
    WHEEL_R    AS INTEGER ' range the burst applies to
    WHEEL_SNAP AS STRING  ' palette snapshot before the burst
    DRAG_ACTIVE AS INTEGER ' Ctrl+L-drag on the strip is defining a new range
    DRAG_START AS INTEGER ' chip the Ctrl+L-drag started on
    DRAG_LO    AS INTEGER ' drag preview span (-1 = none)
    DRAG_HI    AS INTEGER
    BLOCKED_SIG AS STRING ' palette signature PCYC_BLOCKED() was computed for
END TYPE

DIM SHARED PCYC                       AS PCYC_OBJ
DIM SHARED PCYC_R(1 TO PCYC_MAX)      AS PCYC_RANGE
REDIM SHARED PCYC_OFF(0)              AS LONG          ' byte offsets of cycling pixels in PCYC.BUF
REDIM SHARED PCYC_SRC(0)              AS _UNSIGNED _BYTE ' palette index each one belongs to
DIM SHARED PCYC_BASE                  AS STRING        ' composite bytes the map was built from
DIM SHARED PCYC_CUR                   AS STRING        ' scratch: this frame's composite bytes

' Color -> palette index lookup used while building the pixel map: a hash on
' the low 16 bits of RGB with short chains (<= 256 entries). First palette
' index with a given RGB wins, so a duplicate color outside a range blocks it.
DIM SHARED PCYC_LUT_HEAD(0 TO 65535)  AS INTEGER
DIM SHARED PCYC_LUT_RGB(1 TO 256)     AS _UNSIGNED LONG
DIM SHARED PCYC_LUT_IDX(1 TO 256)     AS INTEGER
DIM SHARED PCYC_LUT_NEXT(1 TO 256)    AS INTEGER
DIM SHARED PCYC_LUT_N                 AS INTEGER
REDIM SHARED PCYC_A(0)                AS _UNSIGNED _BYTE ' original alpha of each (partly transparent) cycling pixel
DIM SHARED PCYC_OVL_IDX(0 TO 255)     AS INTEGER         ' overlay index of each palette index (0 = not cycling)

' Strip band colors per range number, and chips whose color duplicates an
' earlier chip (their pixels belong to that chip, so they cannot cycle).
DIM SHARED PCYC_BAND_COLOR(1 TO PCYC_MAX) AS _UNSIGNED LONG
DIM SHARED PCYC_BLOCKED(0 TO 255)         AS INTEGER

' Speed table for Ctrl+Wheel (steps per second)
DIM SHARED PCYC_SPEEDS(0 TO 15) AS SINGLE

PCYC_init
