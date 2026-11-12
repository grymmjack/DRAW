' =============================================================================
' QA/unit/clip-unit.bas - headless unit test for TOOLS/CLIP-MATH.BM (clip
' layers: the cel a clip shows in each frame, In / Out through a frame op).
' Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o clip-unit.run clip-unit.bas && ./clip-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
CONST CLIP_MODE_LOOP = 0, CLIP_MODE_PING = 1, CLIP_MODE_ONCE = 2, CLIP_MODE_HOLD = 3, CLIP_MODE_REV = 4
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER

' cel per frame 1..frames as a string ("." = none)
FUNCTION row$ (frames AS INTEGER, n AS INTEGER, every AS INTEGER, start AS INTEGER, inF AS INTEGER, outF AS INTEGER, mode AS INTEGER)
    DIM f AS INTEGER, c AS INTEGER, s AS STRING
    FOR f = 1 TO frames
        c = CLIP_cel_for%(f, n, every, start, inF, outF, mode)
        IF c = 0 THEN s = s + "." ELSE s = s + _TRIM$(STR$(c))
    NEXT f
    row$ = s
END FUNCTION

' the frames 1..frames a sound cue fires in ("x")
FUNCTION cues$ (frames AS INTEGER, kind AS INTEGER, cel AS INTEGER, n AS INTEGER, every AS INTEGER, start AS INTEGER, inF AS INTEGER, outF AS INTEGER, mode AS INTEGER)
    DIM f AS INTEGER, s AS STRING
    FOR f = 1 TO frames
        IF CLIP_cue_fires%(kind, cel, f, n, every, start, inF, outF, mode) THEN s = s + "x" ELSE s = s + "."
    NEXT f
    cues$ = s
END FUNCTION

check "loop 4 cels", row$(10, 4, 1, 1, 1, 0, CLIP_MODE_LOOP), "1234123412"
check "loop from frame 3", row$(10, 4, 1, 1, 3, 0, CLIP_MODE_LOOP), "..12341234"
check "loop out 7", row$(10, 4, 1, 1, 3, 7, CLIP_MODE_LOOP), "..12341..."
check "loop on twos", row$(10, 4, 2, 1, 1, 0, CLIP_MODE_LOOP), "1122334411"
check "loop start cel 3", row$(8, 4, 1, 3, 1, 0, CLIP_MODE_LOOP), "34123412"
check "loop 1 cel", row$(5, 1, 1, 1, 1, 0, CLIP_MODE_LOOP), "11111"
check "ping 4", row$(12, 4, 1, 1, 1, 0, CLIP_MODE_PING), "123432123432"
check "ping 2", row$(6, 2, 1, 1, 1, 0, CLIP_MODE_PING), "121212"
check "ping 1", row$(4, 1, 1, 1, 1, 0, CLIP_MODE_PING), "1111"
check "ping start 4", row$(8, 4, 1, 4, 1, 0, CLIP_MODE_PING), "43212343"
check "once 4", row$(8, 4, 1, 1, 1, 0, CLIP_MODE_ONCE), "1234...."
check "once start 3 on twos", row$(8, 4, 2, 3, 2, 0, CLIP_MODE_ONCE), ".3344..."
check "hold 4", row$(8, 4, 1, 1, 1, 0, CLIP_MODE_HOLD), "12344444"
check "hold out 6", row$(8, 4, 1, 1, 1, 6, CLIP_MODE_HOLD), "123444.."
check "rev 4", row$(8, 4, 1, 1, 1, 0, CLIP_MODE_REV), "14321432"
check "rev start 4", row$(6, 4, 1, 4, 1, 0, CLIP_MODE_REV), "432143"
check "no cels", row$(4, 0, 1, 1, 1, 0, CLIP_MODE_LOOP), "...."
check "every 0 = 1", row$(4, 2, 0, 1, 1, 0, CLIP_MODE_LOOP), "1212"
check "start past n = 1", row$(4, 2, 1, 9, 1, 0, CLIP_MODE_LOOP), "1212"

' --- In / Out through a plan (src(j) = old frame of new frame j, 0 = blank) ---
DIM src(1 TO 16) AS INTEGER, a AS INTEGER, b AS INTEGER, r AS INTEGER, j AS INTEGER
' insert one blank before frame 1 of 6: new = 0 1 2 3 4 5 6
src(1) = 0: FOR j = 2 TO 7: src(j) = j - 1: NEXT j
a = 3: b = 5: r = CLIP_remap%(src(), 7, 6, a, b)
check "insert before: in/out shift", STR$(r) + STR$(a) + STR$(b), STR$(TRUE) + STR$(4) + STR$(6)
a = 3: b = 0: r = CLIP_remap%(src(), 7, 6, a, b)
check "insert before: open end stays open", STR$(a) + STR$(b), STR$(4) + STR$(0)
' delete frame 4 of 6: new = 1 2 3 5 6
src(1) = 1: src(2) = 2: src(3) = 3: src(4) = 5: src(5) = 6
a = 4: b = 5: r = CLIP_remap%(src(), 5, 6, a, b)
check "delete in: in moves to the next kept", STR$(a) + STR$(b), STR$(4) + STR$(4)
a = 4: b = 4: r = CLIP_remap%(src(), 5, 6, a, b)
check "all its frames gone", STR$(r) + STR$(a) + STR$(b), STR$(FALSE) + STR$(4) + STR$(4)
' append a blank: new = 1..6 0
FOR j = 1 TO 6: src(j) = j: NEXT j: src(7) = 0
a = 2: b = 0: r = CLIP_remap%(src(), 7, 6, a, b)
check "append: open end stays open", STR$(a) + STR$(b), STR$(2) + STR$(0)
a = 2: b = 6: r = CLIP_remap%(src(), 7, 6, a, b)
check "append: a closed end stays", STR$(a) + STR$(b), STR$(2) + STR$(6)

' sound cues: the frames a cue fires in ("x" = fires)
check "cue cel 1, loop 4", cues$(10, 0, 1, 4, 1, 1, 1, 0, CLIP_MODE_LOOP), "x...x...x."
check "cue cel 3, loop from 2", cues$(8, 0, 3, 4, 1, 1, 2, 0, CLIP_MODE_LOOP), "...x...x"
check "cue cel 2, on twos", cues$(12, 0, 2, 4, 2, 1, 1, 0, CLIP_MODE_LOOP), "..x.......x."
check "cue cel 1, 1 cel looping on twos", cues$(6, 0, 1, 1, 2, 1, 1, 0, CLIP_MODE_LOOP), "x.x.x."
check "cue cel 4, hold: once", cues$(8, 0, 4, 4, 1, 1, 1, 0, CLIP_MODE_HOLD), "...x...."
check "cue cel 2, ping 4", cues$(12, 0, 2, 4, 1, 1, 1, 0, CLIP_MODE_PING), ".x...x.x...x"
check "cue cel 1, once, out 3", cues$(8, 0, 1, 4, 1, 1, 1, 3, CLIP_MODE_ONCE), "x......."
check "cue start", cues$(10, 1, 0, 4, 1, 1, 3, 0, CLIP_MODE_LOOP), "..x......."
check "cue each loop, loop 4", cues$(10, 2, 0, 4, 1, 1, 1, 0, CLIP_MODE_LOOP), "x...x...x."
check "cue each loop, start cel 3", cues$(10, 2, 0, 4, 1, 3, 1, 0, CLIP_MODE_LOOP), "x...x...x."
check "cue each loop, ping 3", cues$(10, 2, 0, 3, 1, 1, 1, 0, CLIP_MODE_PING), "x...x...x."
check "cue each loop, on twos", cues$(12, 2, 0, 2, 2, 1, 1, 0, CLIP_MODE_LOOP), "x...x...x..."
check "cue each loop, once", cues$(10, 2, 0, 4, 1, 1, 1, 0, CLIP_MODE_ONCE), "x........."
check "cue each loop, hold", cues$(10, 2, 0, 4, 1, 1, 1, 0, CLIP_MODE_HOLD), "x........."
check "cue each loop, out 6", cues$(10, 2, 0, 4, 1, 1, 1, 6, CLIP_MODE_LOOP), "x...x....."

PRINT "clip-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

SUB check (lbl AS STRING, got AS STRING, want AS STRING)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL "; lbl; ": got ["; got; "] want ["; want; "]"
    END IF
END SUB

'$INCLUDE:'../../TOOLS/CLIP-MATH.BM'
