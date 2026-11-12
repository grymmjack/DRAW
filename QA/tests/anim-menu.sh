#!/bin/bash
# =============================================================================
# anim-menu.sh — QA test: the ANIM menu.
#
# Animation 1.5 (PLANS/ANIMATION.md): an ANIM root between AI (off in QA) and
# HELP, with Animation Panel (1.6), First / Previous / Next / Last Frame, Play
# (1.9), then flyouts (PLANS/PERSONAS.md, 2026-11-12): FRAMES (the frame
# operations, 1.7), SET UP (Frame Grid - checkbox, same action as View > Frame
# Grid - ...), VIEW, ANIMBRUSH ... EXPORT. On a picture without frames the frame
# items are greyed and do nothing.
#
# Where the root and its dropdown sit comes from the QA dump (MROOT / MENU);
# a dropdown row k (1-based, no divider above) is centred at MENU y + 9 +
# 12 (k - 1) (GUI/MENUBAR: rows from subY + 2, 12 px; dividers 5 px). A
# flyout (POPUP flyout-gen x y w h) has the same row geometry.
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
am_fly() { # PARENT_ROW_OFFSET FLY_ROW_OFFSET LABEL - open ANIM, hover a flyout parent, click its row
    local ax aw mx my fx fy
    read -r _ _ ax aw <<< "$(am_line 'MROOT anim ')"
    click $(( ax + aw / 2 )) 6
    wait_for 0.5 "ANIM menu open"
    read -r _ mx my _ _ <<< "$(am_line 'MENU ')"
    [[ -z "$mx" ]] && { fail "$3: the ANIM menu did not open"; return 1; }
    hover $(( mx + 30 )) $(( my + $1 )); wait_for 0.8 "flyout"
    read -r _ _ fx fy _ _ <<< "$(grep -m1 '^POPUP flyout-gen ' "$AM_DUMP" 2>/dev/null)"
    [[ -z "$fx" ]] && { fail "$3: the flyout did not open"; key Escape; return 1; }
    hover $(( fx + 30 )) $(( fy + $2 )); wait_for 0.3 "row"
    click $(( fx + 30 )) $(( fy + $2 ))
    wait_for 0.5 "$3"
}
am_expect() { # ROW_OFFSET WANT LABEL
    am_pick "$1" "$3" || return
    local got; got=$(am_cur)
    [[ "$got" == "$2" ]] && pass "ANIM > $3: frame $2" || fail "ANIM > $3: frame '$got', wanted $2"
}
ROW_PANEL=9 # Animation Panel, then a divider
ROW_FIRST=$(( 9 + 12 + 5 )); ROW_PREV=$(( ROW_FIRST + 12 )); ROW_NEXT=$(( ROW_FIRST + 24 )); ROW_LAST=$(( ROW_FIRST + 36 ))
ROW_PLAY=$(( ROW_LAST + 12 ))                    # Play (1.9), then a divider
ROW_FRAMES=$(( ROW_PLAY + 12 + 5 ))              # FRAMES >, SET UP >, VIEW >, divider, ANIMBRUSH > ...
ROW_SETUP=$(( ROW_FRAMES + 12 ))
FLY_ROW1=9                                        # a flyout's first row (Add Frame / Frame Grid)

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

# the dropdown is short now (it was ~50 rows and ran off a 514 px window)
read -r _ _ AX AW <<< "$(am_line 'MROOT anim ')"
click $(( AX + AW / 2 )) 6; wait_for 0.5 "ANIM menu open"
read -r _ _ _ _ MH <<< "$(grep -m1 '^MENU ' "$AM_DUMP")"
key Escape; wait_for 0.3 "closed"
info "ANIM dropdown height: ${MH:-?} px"
[[ -n "$MH" ]] && (( MH <= 300 )) && pass "the ANIM dropdown fits ($MH px tall)" || fail "ANIM dropdown ${MH:-?} px tall"

am_expect $ROW_NEXT 4 "Next Frame"
am_expect $ROW_FIRST 1 "First Frame"
am_expect $ROW_LAST 7 "Last Frame"
am_expect $ROW_PREV 6 "Previous Frame"

am_pick $ROW_PLAY "Play"
P=$(am_line "ANIM " | awk '{print $18}'); [[ "$P" == -1 ]] && pass "ANIM > Play plays" || fail "ANIM > Play: playing '$P'"
am_pick $ROW_PLAY "Stop"
P=$(am_line "ANIM " | awk '{print $18}'); [[ "$P" == 0 ]] && pass "ANIM > Play again stops" || fail "ANIM > Play again: playing '$P'"
am_pick $ROW_FIRST "First Frame"
am_fly $ROW_FRAMES $FLY_ROW1 "Add Frame"
read -r _ _ AC ACUR _ <<< "$(am_line 'ANIM ')"
[[ "$AC" == 8 && "$ACUR" == 8 ]] && pass "ANIM > Add Frame: 8 frames, the new one current" || fail "ANIM > Add Frame: count $AC current $ACUR, wanted 8 / 8"
key ctrl+z
wait_for 0.5 "Undo"

info "ANIM > Animation Panel: open, then closed"
am_pick $ROW_PANEL "Animation Panel"
V=$(am_line "ANIMP " | awk '{print $2}'); [[ "$V" == -1 ]] && pass "ANIM > Animation Panel opens the panel" || fail "the panel not open after ANIM > Animation Panel (visible=$V)"
am_pick $ROW_PANEL "Animation Panel"
V=$(am_line "ANIMP " | awk '{print $2}'); [[ "$V" == 0 ]] && pass "ANIM > Animation Panel closes it again" || fail "the panel still open after a second ANIM > Animation Panel (visible=$V)"

info "ANIM > Frame Grid: off, then on"
am_fly $ROW_SETUP $FLY_ROW1 "Frame Grid"
D=$(am_drawn); [[ "$D" == 0 ]] && pass "ANIM > Frame Grid hides the grid" || fail "the grid still drawn after ANIM > Frame Grid (drawn=$D)"
am_fly $ROW_SETUP $FLY_ROW1 "Frame Grid"
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
