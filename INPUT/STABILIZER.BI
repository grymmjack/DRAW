''
' DRAW - INPUT/STABILIZER.BI
' =============================================================================
' Pen Control's stroke filters (Rick 2026-11-17, after Lazy Nezumi Pro):
'
'   STAB_   position smoothing - the point a stroke draws to follows the
'           pointer through one of four filters:
'             Pulled String  the point hangs on a string Amount screen px
'                            long: it moves only when the pointer pulls it
'                            (slow, detailed work with sharp corners)
'             Moving Average the mean of the pointer over a time window
'                            (curved lines, soft corners)
'             Exponential MA each sample pulls the point a share of the way
'                            (massive amounts of smoothing, long curves)
'             Inertia        a spring with a little mass (fast, flowy lines)
'           Catch Up (MA / EMA): the point keeps converging while the pointer
'           rests, and the stroke is finished to the pointer on lift.
'   PPROC_  pressure processing - Fixed Value, Sample & Hold, Moving Average,
'           Exponential MA over the pen's pressure (tames line dynamics).
'   PSPD_   pressure speed scaling - a gain on pressure from how fast the
'           pointer moves: Slow Gain at rest, Fast Gain at Fast Speed and
'           above, an S-curve between; the speed itself smoothed.
'
' Pure math: no DRAW globals. The caller hands in canvas coords (floats), a
' clock in seconds and the string length in canvas px (screen px / zoom), and
' copies the settings into STAB / PPROC / PSPD from CFG. QA/unit/stab-unit.bas
' runs it headless.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST STAB_OFF = 0
CONST STAB_PULLED = 1
CONST STAB_MA = 2
CONST STAB_EMA = 3
CONST STAB_INERTIA = 4
CONST STAB_MODE_COUNT = 4

CONST STAB_HIST = 128 ' moving-average samples kept (a ring)
CONST STAB_CATCH_DT = 0.016 ' a catch-up step on lift (s): one 60 fps frame
CONST STAB_CATCH_MAX = 400 ' ... at most this many

TYPE STAB_OBJ
    ' settings (the caller copies these from CFG)
    mode    AS INTEGER ' STAB_*
    amount  AS INTEGER ' 0..100
    catchUp AS INTEGER ' TRUE: MA / EMA converge while resting and on lift
    ' state
    active  AS INTEGER ' a stroke is being filtered
    x       AS DOUBLE  ' the filtered point (canvas px)
    y       AS DOUBLE
    vx      AS DOUBLE  ' inertia velocity (canvas px / s)
    vy      AS DOUBLE
    rawX    AS DOUBLE  ' the last pointer position fed in
    rawY    AS DOUBLE
    lastT   AS DOUBLE  ' clock of the last step (s)
    hHead   AS INTEGER ' next ring slot
    hCount  AS INTEGER ' samples in the ring
END TYPE
DIM SHARED STAB AS STAB_OBJ
DIM SHARED STAB_HX(0 TO STAB_HIST - 1) AS DOUBLE, STAB_HY(0 TO STAB_HIST - 1) AS DOUBLE
DIM SHARED STAB_HT(0 TO STAB_HIST - 1) AS DOUBLE

CONST PPROC_OFF = 0
CONST PPROC_FIXED = 1
CONST PPROC_HOLD = 2
CONST PPROC_MA = 3
CONST PPROC_EMA = 4
CONST PPROC_MODE_COUNT = 4

TYPE PPROC_OBJ
    mode   AS INTEGER ' PPROC_*
    amount AS INTEGER ' 0..100 (Fixed: the pressure %; Hold: samples; MA / EMA: strength)
    ' state
    p      AS SINGLE  ' the processed pressure
    n      AS INTEGER ' samples seen this stroke
    sum    AS SINGLE  ' Sample & Hold: running sum until it locks
    held   AS INTEGER ' Sample & Hold: locked
    lastT  AS DOUBLE
    hHead  AS INTEGER
    hCount AS INTEGER
END TYPE
DIM SHARED PPROC AS PPROC_OBJ
DIM SHARED PPROC_HP(0 TO STAB_HIST - 1) AS SINGLE, PPROC_HT(0 TO STAB_HIST - 1) AS DOUBLE

TYPE PSPD_OBJ
    ' settings
    slowGain  AS SINGLE  ' gain at rest (0.1..1)
    fastGain  AS SINGLE  ' gain at fastSpeed and above (1..5)
    fastSpeed AS SINGLE  ' screen px / s where the gain reaches fastGain
    smooth    AS SINGLE  ' 0..1: how much the speed is smoothed
    ' state
    speed     AS SINGLE  ' smoothed speed (screen px / s)
    gain      AS SINGLE  ' the gain at that speed
    lastX     AS DOUBLE  ' last pointer position (screen px)
    lastY     AS DOUBLE
    lastT     AS DOUBLE
    started   AS INTEGER
    sumSpeed  AS DOUBLE  ' this stroke: for its average
    nSpeed    AS LONG
    maxSpeed  AS SINGLE
    ' the last finished stroke (the panel's graph markers)
    avgSpeed  AS SINGLE
    avgGain   AS SINGLE
    topSpeed  AS SINGLE
    topGain   AS SINGLE
END TYPE
DIM SHARED PSPD AS PSPD_OBJ
PSPD.slowGain = 1: PSPD.fastGain = 1: PSPD.fastSpeed = 750: PSPD.gain = 1
