#!/bin/bash
# =============================================================================
# anim-menu.sh — QA test: the ANIM menu.
#
# Animation 1.5 (PLANS/ANIMATION.md): an ANIM root between AI (off in QA) and
# HELP, with First / Previous / Next / Last Frame and Frame Grid (checkbox,
# same action as View > Frame Grid). On a picture without frames the frame
# items are greyed and do nothing.
#
# Where the root and its dropdown sit comes from the QA dump (MROOT / MENU);
# a dropdown row k (1-based, no divider above) is centred at MENU y + 9 +
# 12 (k - 1) (GUI/MENUBAR: rows from subY + 2, 12 px; dividers 5 px).
# Fixture: the 64x32 sheet of anim-frame-grid.sh (7 frames, current 3).
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: ANIM menu ==="

AM_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AM_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
AM_DIR="/tmp/draw-qa-animmenu-$$"
mkdir -p "$AM_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$AM_DIR/plain.png"
AM_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$AM_PY" put "$AM_DIR/plain.png" "$AM_DIR/sheet.png" drAn "$AM_BLOB"

am_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
am_line() { am_settle; grep -m1 "^$1" "$AM_DUMP" 2>/dev/null; }
am_cur() { am_line "ANIM " | awk '{print $4}'; }
am_drawn() { am_line "ANIM " | awk '{print $13}'; }
am_pick() { # ROW_Y_OFFSET LABEL - open ANIM, click the row at MENU y + offset
    local ax aw mx my
    read -r _ _ ax aw <<< "$(am_line 'MROOT anim ')"
    [[ -z "$ax" ]] && { fail "$2: no ANIM menu"; return 1; }
    click $(( ax + aw / 2 )) 6
    wait_for 0.5 "ANIM menu open"
    read -r _ mx my _ _ <<< "$(am_line 'MENU ')"
    [[ -z "$mx" ]] && { fail "$2: the ANIM menu did not open"; return 1; }
    click $(( mx + 30 )) $(( my + $1 ))
    wait_for 0.5 "$2"
}
am_expect() { # ROW_OFFSET WANT LABEL
    am_pick "$1" "$3" || return
    local got; got=$(am_cur)
    [[ "$got" == "$2" ]] && pass "ANIM > $3: frame $2" || fail "ANIM > $3: frame '$got', wanted $2"
}
ROW_FIRST=9; ROW_PREV=21; ROW_NEXT=33; ROW_LAST=45; ROW_GRID=$(( 2 + 48 + 5 + 6 + 1 ))

info "Launching DRAW with a 64x32 sheet of 16x16 frames (current 3)"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$AM_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash

read -r _ _ AX _ <<< "$(am_line 'MROOT anim ')"
read -r _ _ EX _ <<< "$(am_line 'MROOT effects ')"
read -r _ _ HX _ <<< "$(am_line 'MROOT help ')"
info "roots: effects x=$EX, anim x=$AX, help x=$HX"
[[ -n "$AX" ]] && pass "the menu bar has an ANIM menu" || fail "no ANIM root in the menu bar"
[[ -n "$AX" && -n "$EX" && -n "$HX" ]] && (( EX < AX && AX < HX )) \
    && pass "ANIM sits between EFFECTS (AI is off) and HELP" || fail "ANIM is not between EFFECTS and HELP"

am_expect $ROW_NEXT 4 "Next Frame"
am_expect $ROW_FIRST 1 "First Frame"
am_expect $ROW_LAST 7 "Last Frame"
am_expect $ROW_PREV 6 "Previous Frame"

info "ANIM > Frame Grid: off, then on"
am_pick $ROW_GRID "Frame Grid"
D=$(am_drawn); [[ "$D" == 0 ]] && pass "ANIM > Frame Grid hides the grid" || fail "the grid still drawn after ANIM > Frame Grid (drawn=$D)"
am_pick $ROW_GRID "Frame Grid"
D=$(am_drawn); [[ "$D" == -1 ]] && pass "ANIM > Frame Grid shows it again" || fail "the grid not back after a second ANIM > Frame Grid (drawn=$D)"

# -- a picture without frames: the items are greyed and do nothing --
info "Relaunching with the same picture, no frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AM_DIR/plain.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
am_pick $ROW_NEXT "Next Frame (no frames)"
read -r _ AON _ AC _ <<< "$(am_line 'ANIM ')"
[[ "$AON" == 0 && "$AC" == 0 ]] && pass "no frames: Next Frame changes nothing" || fail "no frames: ANIM on=$AON current=$AC"
key Escape
wait_for 0.3 "Menu closed"
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$AM_DIR"
assert_window_exists
