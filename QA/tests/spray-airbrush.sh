#!/bin/bash
# =============================================================================
# spray-airbrush.sh — QA test: the Spray tool with Antialias on is an airbrush
# (Rick 2026-11-18: "can we get the spray when in antialias mode to spray like a
# real airbrush?"). A soft gaussian cloud of sub-pixel droplets, flowing per second:
#   1. held still: paint appears, and keeps building up the longer it is held
#   2. the cloud is soft (many distinct colours), not a handful of hard dots
#   3. the middle is denser than the rim (gaussian falloff)
#   4. undo takes the stroke off
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=TRUE
# =============================================================================
info "=== Airbrush (Spray + Antialias) ==="
mae() { magick compare -metric MAE "$1" "$2" null: 2>&1 | sed -n 's/.*(\([0-9.e-]*\)).*/\1/p'; }
colours() { magick "$1" -format '%k' info: 2>/dev/null; }

canvas_focus k
wait_for 0.3 "spray tool"
for _ in 1 2 3 4 5; do key bracketright; done
wait_for 0.3 "bigger"
key grave; wait_for 0.2 "pointer hidden"
park_mouse; wait_for 0.3 "settle"
RX=$(( CANVAS_CX - 40 )); RY=$(( CANVAS_CY - 40 ))
snap_region "$RX" "$RY" 80 80 "ab-before"; BEFORE="$SNAP_RESULT"

read -r ax ay <<< "$(_abs "$CANVAS_CX" "$CANVAS_CY")"
draw_focus
raw_move "$ax" "$ay"; sleep 0.1
raw_button down 1
sleep 0.35
snap_region "$RX" "$RY" 80 80 "ab-short"; SHORT="$SNAP_RESULT"
sleep 1.4
snap_region "$RX" "$RY" 80 80 "ab-long"; LONG="$SNAP_RESULT"
screenshot "spray-airbrush-held"
raw_button up 1
wait_for 0.4 "released"

M1=$(mae "$BEFORE" "$SHORT"); M2=$(mae "$BEFORE" "$LONG")
info "change after 0.35 s: $M1, after 1.75 s: $M2"
awk -v a="$M1" 'BEGIN { exit !(a > 0.001) }' && pass "the airbrush paints while held still ($M1)" || fail "nothing sprayed in 0.35 s ($M1)"
awk -v a="$M1" -v b="$M2" 'BEGIN { exit !(b > a * 1.4) }' && pass "it builds up the longer it is held ($M1 -> $M2)" || fail "no build-up: $M1 -> $M2"

N=$(colours "$LONG"); info "distinct colours in the cloud: $N"
(( N > 40 )) && pass "the cloud is soft ($N colours)" || fail "the cloud has only $N colours (hard dots?)"

# middle 16x16 vs a ring 16x16 near the edge: the middle changed more
TMPD="${QA_TMP_DIR:-/tmp}"
magick "$BEFORE" -gravity center -crop 20%x20%+0+0 +repage "$TMPD/ab-b-mid.$$.png"
magick "$LONG"   -gravity center -crop 20%x20%+0+0 +repage "$TMPD/ab-l-mid.$$.png"
magick "$BEFORE" -gravity north -crop 20%x20%+0+0 +repage "$TMPD/ab-b-rim.$$.png"
magick "$LONG"   -gravity north -crop 20%x20%+0+0 +repage "$TMPD/ab-l-rim.$$.png"
MM=$(mae "$TMPD/ab-b-mid.$$.png" "$TMPD/ab-l-mid.$$.png"); MR=$(mae "$TMPD/ab-b-rim.$$.png" "$TMPD/ab-l-rim.$$.png")
rm -f "$TMPD"/ab-[bl]-{mid,rim}.$$.png
info "middle change $MM, rim change $MR"
awk -v m="$MM" -v r="$MR" 'BEGIN { exit !(m > r * 1.5) }' && pass "denser in the middle than at the rim" || fail "no falloff: middle $MM, rim $MR"

key ctrl+z; wait_for 0.6 "undo"
park_mouse; wait_for 0.3 "settle"
snap_region "$RX" "$RY" 80 80 "ab-undo"
D=$(magick compare -metric AE "$BEFORE" "$SNAP_RESULT" null: 2>&1 | awk '$1 ~ /^[0-9.]+$/ {print int($1); exit} {print "ERR"; exit}')
[[ "$D" == 0 ]] && pass "undo takes the airbrush stroke off" || fail "after undo $D px differ"
assert_no_crash
