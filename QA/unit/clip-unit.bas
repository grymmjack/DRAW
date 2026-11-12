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

' keyframe lanes (phase 3): keyed values, eases, put / del, modulators
DIM ks AS STRING
ks = CLIP_lk$(0, 0, 0) + CLIP_lk$(4, 8, 0)
check "lane linear", lanes$(ks, -1, 5), "0 0 2 4 6 8 8"
ks = CLIP_lk$(0, 0, 4) + CLIP_lk$(4, 8, 0)
check "lane hold", lanes$(ks, -1, 5), "0 0 0 0 0 8 8"
ks = CLIP_lk$(0, 0, 1) + CLIP_lk$(4, 16, 0)
check "lane ease in", lanes$(ks, 0, 4), "0 1 4 9 16"
ks = CLIP_lk$(0, 0, 2) + CLIP_lk$(4, 16, 0)
check "lane ease out", lanes$(ks, 0, 4), "0 7 12 15 16"
ks = CLIP_lk$(0, 0, 3) + CLIP_lk$(4, 32, 0)
check "lane ease in-out", lanes$(ks, 0, 4), "0 5 16 27 32"
check "lane no keys = default", lanes$("", 0, 2), "100 100 100"
ks = CLIP_lk$(2, 5, 0)
check "lane one key", lanes$(ks, 0, 4), "5 5 5 5 5"
ks = CLIP_lk$(0, 0, 0) + CLIP_lk$(2, 10, 4) + CLIP_lk$(4, 0, 0)
check "lane three keys, hold in the middle", lanes$(ks, 0, 5), "0 5 10 10 0 0"
ks = ""
ks = CLIP_lks_put$(ks, 4, 1, 0): ks = CLIP_lks_put$(ks, 0, 2, 3): ks = CLIP_lks_put$(ks, 2, 3, 4)
check "keys put in order", keylist$(ks), "0:2:3 2:3:4 4:1:0"
ks = CLIP_lks_put$(ks, 2, 9, 0)
check "keys put replaces, keeps the ease", keylist$(ks), "0:2:3 2:9:4 4:1:0"
ks = CLIP_lks_del$(ks, 2)
check "keys del", keylist$(ks), "0:2:3 4:1:0"
check "keys del none", keylist$(CLIP_lks_del$(ks, 3)), "0:2:3 4:1:0"
check "key at or before", STR$(CLIP_lk_at_or_before%(ks, -1)) + STR$(CLIP_lk_at_or_before%(ks, 0)) + STR$(CLIP_lk_at_or_before%(ks, 3)) + STR$(CLIP_lk_at_or_before%(ks, 9)), " 0 1 1 2"
check "lfo sine", mods$(1, 0, 10, 4, 0, 0, 0, 4), "0 10 0 -10 0"
check "lfo triangle", mods$(1, 1, 8, 8, 0, 0, 0, 8), "0 4 8 4 0 -4 -8 -4 0"
check "lfo square", mods$(1, 2, 3, 4, 0, 0, 0, 4), "3 3 -3 -3 3"
check "lfo saw", mods$(1, 3, 4, 4, 0, 0, 0, 3), "-4 -2 0 2"
check "lfo phase", mods$(1, 0, 10, 4, 1, 0, 0, 2), "10 0 -10"
check "lfo none", mods$(0, 0, 10, 4, 0, 0, 0, 2), "0 0 0"
check "noise stable", mods$(2, 0, 10, 2, 0, 7, 0, 6), mods$(2, 0, 10, 2, 0, 7, 0, 6)
check "noise seed matters", STR$(mods$(2, 0, 10, 1, 0, 7, 0, 6) <> mods$(2, 0, 10, 1, 0, 8, 0, 6)), STR$(TRUE)
check "noise in range", STR$(noise_ok%(10, 3, 200)), STR$(TRUE)
check "noise on the key frames", nkey$(10, 3, 5), "ok"

PRINT "clip-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

FUNCTION lanes$ (ks AS STRING, f0 AS INTEGER, f1 AS INTEGER)
    DIM f AS INTEGER, s AS STRING
    FOR f = f0 TO f1: s = s + " " + _TRIM$(STR$(CINT(CLIP_lane_keyed!(ks, f, 100)))): NEXT f
    lanes$ = MID$(s, 2)
END FUNCTION

FUNCTION keylist$ (ks AS STRING)
    DIM i AS INTEGER, s AS STRING
    FOR i = 1 TO CLIP_lks_n%(ks)
        s = s + " " + _TRIM$(STR$(CLIP_lk_f%(ks, i))) + ":" + _TRIM$(STR$(CLIP_lk_v!(ks, i))) + ":" + _TRIM$(STR$(CLIP_lk_e%(ks, i)))
    NEXT i
    keylist$ = MID$(s, 2)
END FUNCTION

FUNCTION mods$ (kind AS INTEGER, shape AS INTEGER, amount AS SINGLE, period AS SINGLE, phase AS SINGLE, seed AS LONG, f0 AS INTEGER, f1 AS INTEGER)
    DIM f AS INTEGER, s AS STRING
    FOR f = f0 TO f1: s = s + " " + _TRIM$(STR$(CINT(CLIP_mod!(kind, shape, amount, period, phase, seed, f)))): NEXT f
    mods$ = MID$(s, 2)
END FUNCTION

FUNCTION noise_ok% (amount AS SINGLE, period AS SINGLE, n AS INTEGER)
    DIM f AS INTEGER, v AS SINGLE, lo AS SINGLE, hi AS SINGLE
    lo = 1E+09: hi = -1E+09
    FOR f = 0 TO n
        v = CLIP_mod!(2, 0, amount, period, 0, 42, f)
        IF v < lo THEN lo = v
        IF v > hi THEN hi = v
    NEXT f
    noise_ok% = (lo >= -amount _ANDALSO hi <= amount _ANDALSO hi - lo > amount / 2)
END FUNCTION

' on frames that are multiples of the period, noise = amount * hash(seed, frame / period)
FUNCTION nkey$ (amount AS SINGLE, period AS INTEGER, n AS INTEGER)
    DIM i AS INTEGER
    nkey$ = "ok"
    FOR i = 0 TO n
        IF ABS(CLIP_mod!(2, 0, amount, period, 0, 9, i * period) - amount * CLIP_hash!(9, i)) > .001 THEN nkey$ = "bad at" + STR$(i)
    NEXT i
END FUNCTION

SUB check (lbl AS STRING, got AS STRING, want AS STRING)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL "; lbl; ": got ["; got; "] want ["; want; "]"
    END IF
END SUB

'$INCLUDE:'../../TOOLS/CLIP-MATH.BM'
