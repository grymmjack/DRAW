' =============================================================================
' QA/unit/stab-unit.bas - headless unit test for INPUT/STABILIZER (Pen
' Control: position smoothing, pressure processing, pressure speed scaling).
' Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o stab-unit.run stab-unit.bas && ./stab-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
'$INCLUDE:'../../INPUT/STABILIZER.BI'

DIM t AS DOUBLE, i AS INTEGER, x AS DOUBLE, y AS DOUBLE, p AS SINGLE, g AS SINGLE
DIM jit AS DOUBLE, raw AS DOUBLE, sumRaw AS DOUBLE, sumOut AS DOUBLE, prevOut AS DOUBLE

' --- Off: the point is the pointer ---
STAB.mode = STAB_OFF: STAB.amount = 50
STAB_begin 10, 10, 0
STAB_step 25, 40, 0.016, 5
near "off follows x", STAB.x, 25, 0.0001
near "off follows y", STAB.y, 40, 0.0001
check "off is not on", STAB_on%, FALSE
STAB.mode = STAB_EMA: STAB.amount = 0
check "amount 0 is not on", STAB_on%, FALSE

' --- Pulled String: stays inside the string, moves only when pulled ---
STAB.mode = STAB_PULLED: STAB.amount = 30
STAB_begin 0, 0, 0
STAB_step 3, 4, 0.016, 10 ' 5 px away, string 10: slack
near "pulled: slack x", STAB.x, 0, 0.0001
near "pulled: slack y", STAB.y, 0, 0.0001
STAB_step 30, 40, 0.032, 10 ' 50 px away: pulled to 10 px behind
near "pulled: taut x", STAB.x, 24, 0.0001
near "pulled: taut y", STAB.y, 32, 0.0001
STAB_step 30, 40, 0.5, 10 ' at rest: it stays (no catch up)
near "pulled: rests behind", STAB.x, 24, 0.0001
STAB.catchUp = TRUE
check "pulled never catches up", STAB_catch_step%, FALSE
STAB.catchUp = FALSE

' --- Moving Average: jitter shrinks, a straight line stays on the line ---
STAB.mode = STAB_MA: STAB.amount = 30 ' 0.18 s window
STAB_begin 0, 0, 0
sumRaw = 0: sumOut = 0
FOR i = 1 TO 120
    t = i * 0.016
    jit = 4 * ((i MOD 2) * 2 - 1) ' +-4 px zig-zag on y
    STAB_step i * 2, jit, t, 0
    IF i > 20 THEN sumRaw = sumRaw + ABS(jit): sumOut = sumOut + ABS(STAB.y)
NEXT i
check "MA: jitter under a quarter", (sumOut < sumRaw / 4), TRUE
check "MA: lags behind on x", (STAB.x < 240 _ANDALSO STAB.x > 200), TRUE
' at rest without Catch Up the mean stays put
x = STAB.x
STAB_step 240, -4, t + 0.5, 0 ' the pointer has not moved
near "MA: rests without catch up", STAB.x, x, 0.0001
' with Catch Up a resting pointer pulls it in
STAB.catchUp = TRUE
FOR i = 1 TO 30: STAB_step 240, 4, t + 0.5 + i * 0.016, 0: NEXT i
near "MA: catch up while resting x", STAB.x, 240, 0.01
near "MA: catch up while resting y", STAB.y, 4, 0.01

' --- EMA + Catch Up on lift ---
STAB.mode = STAB_EMA: STAB.amount = 40: STAB.catchUp = TRUE
STAB_begin 0, 0, 0
FOR i = 1 TO 10: STAB_step i * 10, 0, i * 0.016, 0: NEXT i
check "EMA: behind the pointer", (STAB.x < 90), TRUE
prevOut = STAB.x
i = 0
DO WHILE STAB_catch_step%
    IF STAB.x < prevOut - 0.0001 THEN check "EMA catch-up goes forward", 0, 1
    prevOut = STAB.x: i = i + 1
    IF i > STAB_CATCH_MAX THEN EXIT DO
LOOP
check "EMA: catch-up finishes", (i > 0 _ANDALSO i < STAB_CATCH_MAX), TRUE
near "EMA: lands on the pointer", STAB.x, 100, 0.0001
STAB.catchUp = FALSE
STAB_begin 0, 0, 0
FOR i = 1 TO 10: STAB_step i * 10, 0, i * 0.016, 0: NEXT i
check "EMA: no catch-up when off", STAB_catch_step%, FALSE

' --- Inertia: reaches the target, overshoots a little at most, stays stable ---
STAB.mode = STAB_INERTIA: STAB.amount = 50
STAB_begin 0, 0, 0
DIM maxX AS DOUBLE
FOR i = 1 TO 200
    STAB_step 100, 0, i * 0.016, 0
    IF STAB.x > maxX THEN maxX = STAB.x
NEXT i
near "inertia settles on the target", STAB.x, 100, 0.05
check "inertia overshoot under 25%", (maxX < 125), TRUE
STAB_begin 0, 0, 0
STAB_step 100, 0, 0.25, 0 ' one long frame: no blow-up
check "inertia stable on a long frame", (STAB.x >= 0 _ANDALSO STAB.x <= 130), TRUE

' --- Pressure processing ---
PPROC.mode = PPROC_OFF
PPROC_begin
nearS "proc off passes through", PPROC_step!(0.37, 0), 0.37, 0.0001
PPROC.mode = PPROC_FIXED: PPROC.amount = 60
PPROC_begin
nearS "fixed value", PPROC_step!(0.1, 0), 0.6, 0.0001
nearS "fixed value ignores the pen", PPROC_step!(0.9, 0.016), 0.6, 0.0001
PPROC.mode = PPROC_HOLD: PPROC.amount = 10 ' 3 samples
PPROC_begin
p = PPROC_step!(0.2, 0): p = PPROC_step!(0.4, 0.016): p = PPROC_step!(0.6, 0.032)
nearS "hold: mean of the first samples", p, 0.4, 0.0001
nearS "hold: locked after", PPROC_step!(1, 0.048), 0.4, 0.0001
PPROC.mode = PPROC_MA: PPROC.amount = 50 ' 0.2 s
PPROC_begin
FOR i = 0 TO 40: p = PPROC_step!(0.5 + 0.4 * ((i MOD 2) * 2 - 1), i * 0.016): NEXT i
check "MA pressure smooths a flicker", (ABS(p - 0.5) < 0.1), TRUE
PPROC.mode = PPROC_EMA: PPROC.amount = 50
PPROC_begin
p = PPROC_step!(0.2, 0)
nearS "EMA pressure starts at the first reading", p, 0.2, 0.0001
p = PPROC_step!(1, 0.016)
check "EMA pressure moves part way", (p > 0.2 _ANDALSO p < 0.5), TRUE

' --- Speed scaling ---
PSPD.slowGain = 0.26: PSPD.fastGain = 3.03: PSPD.fastSpeed = 750: PSPD.smooth = 0
check "speed scaling on", PSPD_on%, TRUE
nearS "gain at rest = slow gain", PSPD_gain_at!(0), 0.26, 0.0001
nearS "gain at fast speed = fast gain", PSPD_gain_at!(750), 3.03, 0.0001
nearS "gain past fast speed holds", PSPD_gain_at!(5000), 3.03, 0.0001
g = PSPD_gain_at!(375)
nearS "gain halfway = the middle (smoothstep)", g, (0.26 + 3.03) / 2, 0.0001
PSPD_begin 0, 0, 0
FOR i = 1 TO 20: g = PSPD_step!(i * 8, 0, i * 0.016): NEXT i ' 500 px/s
check "speed measured", (ABS(PSPD.speed - 500) < 1), TRUE
PSPD_end
check "stroke average kept", (ABS(PSPD.avgSpeed - 500) < 1), TRUE
check "stroke top kept", (ABS(PSPD.topSpeed - 500) < 1), TRUE
PSPD.slowGain = 1: PSPD.fastGain = 1
check "unit gains are off", PSPD_on%, FALSE

PRINT
PRINT "stab-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS > 0 THEN SYSTEM 1
SYSTEM 0

SUB check (lbl AS STRING, got AS LONG, want AS LONG)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1: PRINT "FAIL "; lbl; ": got"; got; " want"; want
    END IF
END SUB
SUB near (lbl AS STRING, got AS DOUBLE, want AS DOUBLE, tol AS DOUBLE)
    IF ABS(got - want) <= tol THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1: PRINT "FAIL "; lbl; ": got"; got; " want"; want
    END IF
END SUB
SUB nearS (lbl AS STRING, got AS SINGLE, want AS SINGLE, tol AS SINGLE)
    IF ABS(got - want) <= tol THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1: PRINT "FAIL "; lbl; ": got"; got; " want"; want
    END IF
END SUB
'$INCLUDE:'../../INPUT/STABILIZER.BM'
