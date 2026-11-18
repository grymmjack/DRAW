#!/bin/bash
# =============================================================================
# anim-panel-lanes.sh — QA test: the Animation panel's LANES page
# (GUI/ANIM-PANEL-LANES).
#
# Rick 2026-11-16: "the key frame properties panel needs to exist still ... a
# panel gives people the ability to hide the xsheet and still work/adjust
# stuff, the panel would need to see all those properties like before".
#
#   - a pixel layer on a 4-frame sheet: the LANES chip on the status row; a
#     click shows every lane (X .. PIVOT Y) with its value at this frame
#   - X's key button: a key on frame 1 (linear); the wheel up 3 over X's
#     value: X 3
#   - Y's value clicked, 5 typed: Y 5
#   - ROTATE's value dragged up: a ROTATE key > 0; Ctrl+Z takes the whole
#     drag back in one step
#   - X picked (its name), EASE clicked: X's key eases in
#   - the > chip: frame 2; <KEY: back on frame 1 (the key)
#   - a middle click on X's value: X 0 (its default)
#   - X's key button again: the key gone
#   - the chip again: the frame rows back
#
# Dump: ANIMPLP on chipX chipY chipW chipH navY keyX valX valW chipW easeY modY
# modChipX amtX perX L:y:value:ease..., ANIMP (panel place / scale), ANIM.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LAYER_THUMBNAILS=0
# =============================================================================
info "=== Animation: the Animation panel's LANES page ==="

PL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
PL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
PL_DIR="/tmp/draw-qa-panlanes-$$"
mkdir -p "$PL_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$PL_DIR/plain.png"
python3 "$PL_PY" put "$PL_DIR/plain.png" "$PL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

pl_line() { grep -m1 "^$1 " "$PL_DUMPF" 2>/dev/null; }
pl_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(pl_line ANIM)"
    read -r _ P_VIS _ P_X P_Y _ _ P_SC _ <<< "$(pl_line ANIMP)"
    Q=($(pl_line ANIMPLP))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ L_PAD _ <<< "$(pl_line ANIMPL)"
}
pl_vx() { echo $(( P_X + $1 * P_SC / 100 )); } # native -> viewport
pl_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
pl_lane() { # L -> "y:value:ease"
    local e
    for e in "${Q[@]:16}"; do [[ "${e%%:*}" == "$1" ]] && { echo "${e#*:}"; return; }; done
}
pl_val() { local r; r="$(pl_lane "$1")"; r="${r#*:}"; echo "${r%%:*}"; }
pl_ease() { local r; r="$(pl_lane "$1")"; echo "${r##*:}"; }
pl_rowmid() { local r; r="$(pl_lane "$1")"; pl_vy $(( ${r%%:*} + 5 )); } # (rows are ~11 native px)
pl_valxy() { echo "$(pl_vx $(( ${Q[8]} + ${Q[9]} / 2 ))) $(pl_rowmid "$1")"; }
pl_keyxy() { echo "$(pl_vx $(( ${Q[7]} + ${Q[10]} / 2 ))) $(pl_rowmid "$1")"; }
pl_namexy() { echo "$(pl_vx 8) $(pl_rowmid "$1")"; }
pl_chipxy() { echo "$(pl_vx $(( ${Q[2]} + ${Q[4]} / 2 ))) $(pl_vy $(( ${Q[3]} + ${Q[5]} / 2 )))"; }
pl_navx() { # K (0 <KEY, 1 <, 2 >, 3 KEY>) -> its chip's middle (four chips across the row)
    local right=$(( ${Q[8]} + ${Q[9]} ))
    pl_vx $(( L_PAD + (2 * $1 + 1) * (right - L_PAD) / 8 ))
}
pl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; pl_read; }
pl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; pl_read; }
pl_s() { echo "frame $A_CUR/$A_COUNT page [${Q[*]}]"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$PL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
pl_read
if [[ "$P_VIS" != -1 ]]; then
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "toggle animation panel"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "panel"
    pl_read
fi
if [[ "$A_COUNT" != 4 || "${Q[1]:-}" != 0 || "${Q[2]:-0}" == 0 ]]; then
    fail "start: $A_COUNT frames, panel visible '$P_VIS', LANES chip: $(pl_s)"
else
    pass "a pixel layer on a 4-frame sheet: the LANES chip on the Animation panel"
    read -r X Y <<< "$(pl_chipxy)"; pl_hclick "$X" "$Y"
    N=$(( ${#Q[@]} - 16 ))
    if [[ "${Q[1]}" == -1 && $N -ge 9 && "$(pl_val 1)" == 0 && "$(pl_ease 1)" == -1 ]]; then
        pass "LANES clicked: $N lanes, X 0 and no key on frame 1"
    else
        fail "the page: $(pl_s)"
    fi
    screenshot "anim-panel-lanes"

    # -- X: the key button, then the wheel --
    read -r X Y <<< "$(pl_keyxy 1)"; pl_hclick "$X" "$Y"
    [[ "$(pl_ease 1)" == 0 ]] && pass "X's key button: a linear key on frame 1" || fail "key button: $(pl_s)"
    read -r X Y <<< "$(pl_valxy 1)"
    for n in 1 2 3; do scroll_up "$X" "$Y"; sleep 0.15; done
    wait_for 0.4 "wheel"; pl_read
    [[ "$(pl_val 1)" == 3 ]] && pass "the wheel up 3 over X's value: X 3" || fail "wheel: X '$(pl_val 1)' - $(pl_s)"

    # -- Y: typed --
    read -r X Y <<< "$(pl_valxy 2)"
    pl_hclick "$X" "$Y"; wait_for 0.6 "the input box"
    type_text "5"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 5"; pl_read
    [[ "$(pl_val 2)" == 5 && "$(pl_ease 2)" == 0 ]] && pass "Y's value clicked, 5 typed: a Y key of 5" || fail "typed Y: $(pl_s)"

    # -- ROTATE: dragged up, then undone --
    read -r X Y <<< "$(pl_valxy 5)"
    mouse_down "$X" "$Y"; sleep 0.15
    hover "$X" $(( Y - 10 )); sleep 0.15
    hover "$X" $(( Y - 20 )); sleep 0.15
    hover "$X" $(( Y - 30 )); sleep 0.3
    mouse_up; wait_for 0.6 "drag"; pl_read
    R="$(pl_val 5)"
    [[ "$(pl_ease 5)" == 0 && "${R%%.*}" -gt 0 ]] && pass "ROTATE's value dragged up: ROTATE $R keyed" || fail "drag: $(pl_s)"
    pl_key ctrl+z
    [[ "$(pl_ease 5)" == -1 && "$(pl_val 5)" == 0 && "$(pl_val 2)" == 5 ]] && pass "Ctrl+Z: the drag undone in one step (Y still 5)" || fail "undo drag: $(pl_s)"

    # -- X's ease --
    read -r X Y <<< "$(pl_namexy 1)"; pl_hclick "$X" "$Y"
    pl_hclick "$(pl_vx $(( ${Q[13]} + 6 )))" "$(pl_vy $(( ${Q[11]} + 5 )))"
    [[ "$(pl_ease 1)" == 1 ]] && pass "X picked, EASE clicked: X's key eases in" || fail "ease: $(pl_s)"
    screenshot "anim-panel-lanes-keys"

    # -- > then <KEY --
    NAVY=$(pl_vy $(( ${Q[6]} + 5 )))
    pl_hclick "$(pl_navx 2)" "$NAVY"
    [[ "$A_CUR" == 2 ]] && pass "the > chip: frame 2" || fail "> chip: frame $A_CUR - $(pl_s)"
    pl_hclick "$(pl_navx 0)" "$NAVY"
    [[ "$A_CUR" == 1 ]] && pass "<KEY: back on frame 1 (the key)" || fail "<KEY: frame $A_CUR - $(pl_s)"

    # -- middle click: the default --
    read -r X Y <<< "$(pl_valxy 1)"; middle_click "$X" "$Y"; wait_for 0.5 "middle"; pl_read
    [[ "$(pl_val 1)" == 0 && "$(pl_ease 1)" != -1 ]] && pass "a middle click on X's value: X 0 (its default), keyed" || fail "middle click: $(pl_s)"

    # -- the key button again: removed --
    read -r X Y <<< "$(pl_keyxy 1)"; pl_hclick "$X" "$Y"
    [[ "$(pl_ease 1)" == -1 ]] && pass "X's key button again: the key gone" || fail "remove key: $(pl_s)"

    read -r X Y <<< "$(pl_chipxy)"; pl_hclick "$X" "$Y"
    [[ "${Q[1]}" == 0 ]] && pass "the chip again: the frame rows back" || fail "page off: $(pl_s)"
fi
assert_no_crash
rm -rf "$PL_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
