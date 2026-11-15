#!/bin/bash
# =============================================================================
# bezier-rubber-band.sh — QA test: the Bezier tool's rubber band and handles
# stay on screen while the mouse moves (BUGS.md 2026-11-15: "Can't see handle
# or rubber band, and ` doesn't toggle it - I can see it if I press ` but as
# soon as I move the mouse it vanishes")
#
#  - after an anchor is placed, the rubber band from it follows the pointer
#  - an anchor dragged out has handle arms; they stay while the pointer moves
#  - ` hides the handles (and they stay hidden as the pointer moves); ` again
#    shows them
#
# Fixture: a 320x200 solid red PNG, so the preview (FG white) shows on it.
# =============================================================================
info "=== Bezier: rubber band + handles follow the mouse ==="
BZ_DIR="$(mktemp -d /tmp/draw-qa-bezier-XXXXXX)"
magick -size 320x200 xc:'#c00000' "PNG32:$BZ_DIR/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$BZ_DIR/red.png"
draw_launch 15; wait_for 1.5 "red image loaded"
assert_no_crash
CX=$CANVAS_CX; CY=$CANVAS_CY
sat_min() { magick "$1" -colorspace HSL -channel G -separate -format '%[fx:minima]' info: 2>/dev/null; }
lt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a < b)}'; }
box() { snap_region $(( CX - 30 )) $(( CY - 50 )) 60 100 "$1"; } # between the anchor and the pointer

key q; wait_for 0.3 "bezier"
key grave; wait_for 0.1 "pointer"
click $(( CX - 60 )) $CY; wait_for 0.4 "anchor 1"
hover $(( CX + 60 )) $(( CY - 40 )); wait_for 0.3 "up-right"
hover $(( CX + 60 )) $(( CY - 45 )); wait_for 0.5 "pointer moved"
box "band-up"; UP="$SNAP_RESULT"; S=$(sat_min "$UP")
lt "$S" 0.5 && pass "the rubber band shows after the mouse moves" || fail "no rubber band after a mouse move (min saturation $S)"
hover $(( CX + 60 )) $(( CY + 40 )); wait_for 0.3 "down-right"
hover $(( CX + 60 )) $(( CY + 45 )); wait_for 0.5 "pointer moved"
box "band-down"; DOWN="$SNAP_RESULT"
assert_regions_differ "$UP" "$DOWN" "the rubber band follows the pointer"
screenshot "bezier-rubber-band"

# a second anchor, dragged out: it has handle arms
drag $(( CX + 60 )) $(( CY + 45 )) $(( CX + 90 )) $(( CY + 70 )); wait_for 0.4 "anchor 2 with handles"
hover $(( CX - 70 )) $(( CY - 70 )); wait_for 0.3 "away"
hover $(( CX - 75 )) $(( CY - 70 )); wait_for 0.5 "pointer moved"
hsnap() { snap_region $(( CX + 15 )) $(( CY + 5 )) 90 90 "$1"; } # around anchor 2 (its arms run both ways)
hsnap "handles-on"; HON="$SNAP_RESULT"
key grave; wait_for 0.4 "hide handles"
hover $(( CX - 70 )) $(( CY - 75 )); wait_for 0.5 "pointer moved"
hsnap "handles-off"; HOFF="$SNAP_RESULT"
assert_regions_differ "$HON" "$HOFF" "\` hides the handles (and they stay hidden as the mouse moves)"
key grave; wait_for 0.4 "show handles"
hover $(( CX - 75 )) $(( CY - 70 )); wait_for 0.5 "pointer moved"
hsnap "handles-back"
assert_regions_same "$HON" "$SNAP_RESULT" "\` again shows the handles, still there after a mouse move"
screenshot "bezier-handles"
key Escape; wait_for 0.3 "cancel"
assert_no_crash
rm -rf "$BZ_DIR"
