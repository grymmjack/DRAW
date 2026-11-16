#!/bin/bash
# =============================================================================
# fill-adjust-error-diffusion.sh — QA test: the error-diffusion dithers in the
# Fill Adjust D cycle (Rick, 2026-11-15: "we don't have floyd steinberg or
# atkinson ... yes add it to posterize and the d cycle")
#
#  1. D cycles past the 10 per-pixel dithers into Floyd-Steinberg (mode 4) ...
#     Shiau-Fan (15), then OFF.
#  2. Each error diffusion is a true pixel dither of the gradient (stop colors
#     only) and each one looks different from the one before it.
#  3. D + wheel (the amount = how much of the miss is carried) changes it.
#  4. A pattern fill is thinned by it.
#
# Dump: FILLADJ active mode amount% offX offY tileW tileH rot opacity dHeld | VIEW zoom offX offY tool | CVORG x y
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Fill Adjust: error-diffusion dithers in the D cycle ==="
FD_DIR="$(mktemp -d /tmp/draw-qa-filled-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FD_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$FD_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
fa() { dk_settle; read -r _ F_ACT F_MODE F_AMT F_OX F_OY F_TW F_TH F_ROT F_OP F_DH <<< "$(grep -m1 '^FILLADJ ' "$DK_DUMP")"; }
fillshot() { dk_park; snap_region "$(sx 60)" "$(sy 50)" $(( 120 * Z / 100 )) $(( 60 * Z / 100 )) "$1"; }
rect() { drag "$(sx 50)" "$(sy 40)" "$(sx 200)" "$(sy 130)"; wait_for 0.8 "filled rect"; }
NAMES=(FS JJN STUCKI BURKES SIERRA SIERRA-LITE ATKINSON FALSE-FS FAN STEVENSON-ARCE TWO-ROW-SIERRA SHIAU-FAN)

key F2; wait_for 0.3 "gradient mode"
key F8; wait_for 0.3 "fill adjust on"
key shift+r; wait_for 0.3 "filled rectangle"
rect
fa
(( F_ACT == 1 )) && pass "a gradient fill enters Fill Adjust" || fail "Fill Adjust not active after the fill (active $F_ACT)"
fillshot "smooth"; SMOOTH="$SNAP_RESULT"

# -- 1. D into the error diffusions --
n=0
while (( F_MODE != 4 && n < 24 )); do key d; wait_for 0.25 "D"; fa; n=$((n + 1)); done
(( F_MODE == 4 )) && pass "D reaches Floyd-Steinberg (mode 4) after the per-pixel dithers ($n taps)" || fail "D never reached mode 4 (at $F_MODE after $n taps)"
(( F_ACT == 1 )) && pass "the fill is still being adjusted" || fail "Fill Adjust ended while cycling"

# -- 2. each one dithers, and differently --
PREV="$SMOOTH"; DIFF=0; FLAT=0
for i in "${!NAMES[@]}"; do
    want=$(( 4 + i ))
    (( F_MODE == want )) || fail "${NAMES[$i]}: mode $F_MODE (want $want)"
    fillshot "ed-${NAMES[$i]}"
    NC=$(magick "$SNAP_RESULT" -format '%k' info: 2>/dev/null)
    if cmp -s "$PREV" "$SNAP_RESULT"; then fail "${NAMES[$i]} looks the same as the one before it"; else DIFF=$((DIFF + 1)); fi
    (( NC >= 3 && NC <= 4 )) || { FLAT=$((FLAT + 1)); fail "${NAMES[$i]}: $NC colors (want a pixel dither of the stop colors: 3-4)"; }
    (( i == 0 )) && screenshot "fill-ed-floyd-steinberg"
    (( i == 6 )) && screenshot "fill-ed-atkinson"
    PREV="$SNAP_RESULT"
    if (( i < ${#NAMES[@]} - 1 )); then key d; wait_for 0.3 "D next"; fa; fi
done
(( DIFF == ${#NAMES[@]} )) && pass "all ${#NAMES[@]} error diffusions change the fill, each its own way" || fail "only $DIFF of ${#NAMES[@]} changed the fill"
(( FLAT == 0 )) && pass "every error diffusion is a pixel dither of the stop colors"
key d; wait_for 0.3 "D past the last"; fa
(( F_MODE == -1 )) && pass "D after Shiau-Fan: OFF" || fail "D after Shiau-Fan: mode $F_MODE (want -1)"

# -- 3. the amount --
while (( F_MODE != 4 && n < 60 )); do key d; wait_for 0.2 "D"; fa; n=$((n + 1)); done
fillshot "fs-amount-$F_AMT"; A_SHOT="$SNAP_RESULT"; A0=$F_AMT
raw_key down d; sleep 0.25
for w in 1 2 3 4 5 6; do scroll_down "$(sx 120)" "$(sy 80)"; sleep 0.12; done
sleep 0.3; raw_key up d; sleep 0.4; fa
fillshot "fs-amount-$F_AMT"
(( F_AMT < A0 )) && ! cmp -s "$A_SHOT" "$SNAP_RESULT" && pass "D + wheel: amount $A0% -> $F_AMT% changes the diffusion" || fail "amount $A0% -> $F_AMT% left the fill the same"
(( F_MODE == 4 )) && pass "the wheel did not cycle the mode" || fail "mode $F_MODE after D + wheel"
screenshot "fill-ed-fs-lower-amount"
raw_key down d; sleep 0.25
for w in 1 2 3 4 5 6; do scroll_up "$(sx 120)" "$(sy 80)"; sleep 0.12; done
sleep 0.3; raw_key up d; sleep 0.4

key Return; wait_for 0.5 "commit"; fa
(( F_ACT == 0 )) && pass "Enter keeps the error-diffused fill" || fail "still adjusting after Enter"

# -- 4. pattern fill thinned --
key F3; wait_for 0.3 "pattern mode"
rect; fa
if (( F_ACT == 1 )); then
    fillshot "pattern-fs"; P1="$SNAP_RESULT"
    key Escape; wait_for 0.4 "cancel"
    key ctrl+z; wait_for 0.3
    pass "a pattern fill enters Fill Adjust with Floyd-Steinberg (mode $F_MODE)"
    screenshot "fill-ed-pattern"
else
    info "no pattern fill to adjust (no pattern selected) - skipped"
fi
key Escape; wait_for 0.3
assert_no_crash
rm -rf "$FD_DIR"
