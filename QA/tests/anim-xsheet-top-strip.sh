#!/bin/bash
# =============================================================================
# anim-xsheet-top-strip.sh — QA test: with the colour strip docked at the top,
# the lightbox (and the X-sheet in its top band) starts under it (Rick
# 2026-11-17, screenshot: the strip over the X-sheet's zoom and frame
# headers). ANIM_LB_area kept off the menu bar, the text bar and the top dock
# rows, not the strip.
#   - PALETTE_STRIP_EDGE=1 (top), the lightbox with the X-sheet (Num 8)
#   - the lightbox's top and the X-sheet's top are at or under the strip's
#     bottom
# Dump: PALNAME nx y w h (the strip's band) | ANIMLB shown x1 y1 x2 y2 ... |
# ANIMXS on shown x1 y1 x2 y2 ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 PALETTE_STRIP_EDGE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Animation: the X-sheet under a colour strip docked at the top ==="

TS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
TS_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
TS_DIR="/tmp/draw-qa-xstop-$$"
mkdir -p "$TS_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$TS_DIR/plain.png"
python3 "$TS_PY" put "$TS_DIR/plain.png" "$TS_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"
ts_line() { grep -m1 "^$1 " "$TS_DUMPF" 2>/dev/null; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$TS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key KP_8; wait_for 0.8 "the lightbox with the X-sheet"
hover 300 250; wait_for 0.3 "render"; hover 302 251; wait_for 0.3 "render"
read -r _ _ PY _ PH _ <<< "$(ts_line PALNAME)"
read -r _ LB_SHOWN _ LB_Y1 _ <<< "$(ts_line ANIMLB)"
read -r _ XS_ON XS_SHOWN _ XS_Y1 _ <<< "$(ts_line ANIMXS)"
SB=$(( ${PY:-0} + ${PH:-0} ))
info "strip y $PY h $PH (bottom $SB); lightbox shown $LB_SHOWN top $LB_Y1; X-sheet on $XS_ON shown $XS_SHOWN top $XS_Y1"
(( PY > 0 && PY < 60 )) && pass "the colour strip at the top (y $PY)" || fail "the strip is not at the top (PALNAME y '$PY' h '$PH')"
(( LB_SHOWN == -1 && XS_SHOWN == -1 )) || fail "the lightbox / X-sheet not showing (lightbox $LB_SHOWN, X-sheet $XS_SHOWN)"
(( LB_Y1 >= SB )) && pass "the lightbox starts under the strip ($LB_Y1 >= $SB)" || fail "the lightbox's top $LB_Y1 is under the strip (its bottom $SB)"
(( XS_Y1 >= SB )) && pass "the X-sheet's header is clear of the strip ($XS_Y1 >= $SB)" || fail "the X-sheet's top $XS_Y1 is under the strip (its bottom $SB)"
screenshot "anim-xsheet-top-strip"
rm -rf "$TS_DIR"
assert_no_crash
info "=== X-sheet under a top strip done ==="
