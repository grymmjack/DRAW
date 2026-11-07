#!/bin/bash
# =============================================================================
# anim-panel.sh — QA test: the Animation panel (GUI/ANIM-PANEL).
#
# Animation 1.6 (PLANS/ANIMATION.md): a floating, dockable window with the
# sheet's frame W x H, gutter, margin, FPS, the current frame's hold, loop mode,
# current / total and first / previous / next / last. View / ANIM > Animation
# Panel (action 2505) opens it. Steppers: click - / +, Shift = 10, hold repeats.
# On a picture without frames a size stepper gives it a frame layout.
#
# The panel's controls come from the QA dump: ANIMP (visible docked x y w h
# scale% hold) and ANIMPL (native rows + stepper x); the layout from ANIM.
# Fixture: the 64x32 sheet of anim-frame-grid.sh (16x16, 7 frames, current 3).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Animation: Animation panel ==="

AP_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AP_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
AP_DIR="/tmp/draw-qa-animpanel-$$"
mkdir -p "$AP_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$AP_DIR/plain.png"
AP_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$AP_PY" put "$AP_DIR/plain.png" "$AP_DIR/sheet.png" drAn "$AP_BLOB"

ap_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
ap_line() { grep -m1 "^$1 " "$AP_DUMP" 2>/dev/null; }
ap_anim() { ap_settle; read -r _ A_ON A_COUNT A_CUR A_FW A_FH A_GUT A_MAR _ _ A_FPS A_LOOP _ <<< "$(ap_line ANIM)"; }
ap_panel() { ap_settle; read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC P_HOLD <<< "$(ap_line ANIMP)"
             read -r _ L_NAV L_R1 L_R2 L_R3 L_R4 L_R5 L_R6 L_LOOP L_RH L_MX L_PX L_CW L_PAD L_PW L_OPS <<< "$(ap_line ANIMPL)"; }
ap_vx() { echo $(( P_X + $1 * P_SC / 100 )); }   # native -> viewport
ap_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
ap_row() { local v="L_R$1"; echo "${!v}"; }
ap_step() { # ROW minus|plus [shift|hold] - click a stepper
    ap_panel
    local nx; [[ "$2" == minus ]] && nx=$L_MX || nx=$L_PX
    local x y; x=$(ap_vx $(( nx + L_CW / 2 ))); y=$(ap_vy $(( $(ap_row "$1") + L_RH / 2 )))
    case "${3:-}" in
        shift) driver_input_key_hold down shift; sleep 0.15; click "$x" "$y"; driver_input_key_hold up shift ;;
        hold)  mouse_down "$x" "$y"; sleep 1.2; mouse_up ;;
        *)     click "$x" "$y" ;;
    esac
    wait_for 0.3 "stepper row $1 $2 ${3:-}"
}
ap_chip() { # NATIVE_ROW_Y K - click chip K (0-3) of a 4-chip row
    ap_panel
    local span=$(( L_PW - 2 * L_PAD )); local cw=$(( (span - 6) / 4 ))
    click "$(ap_vx $(( L_PAD + $2 * (cw + 2) + cw / 2 )))" "$(ap_vy $(( $1 + L_RH / 2 )))"
    wait_for 0.3 "chip $2"
}
ap_open() { # View > Animation Panel through the command palette; checked, one retry
    local try
    for try in 1 2; do
        park_mouse; key question; wait_for 1.0 "Command palette"
        type_text "animation panel"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "Panel toggled"
        ap_panel; [[ "$P_VIS" == -1 ]] && return 0
        info "the panel did not open (the palette was slow?) - again"
        key Escape; wait_for 0.3 "Escape"
    done
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (current 3)"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$AP_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"

ap_open
ap_panel
info "panel at ($P_X,$P_Y) ${P_W}x$P_H scale $P_SC%, rows $L_R1..$L_R6"
[[ "$P_VIS" == -1 && -n "$L_R1" ]] && pass "View > Animation Panel opens the panel" || fail "the Animation panel did not open (visible=$P_VIS)"
hover "$(ap_vx $(( L_PX + 2 )))" "$(ap_vy $(( L_R1 + 2 )))"; wait_for 0.3 "hover W +"
screenshot "anim-panel-open"

if [[ "$P_VIS" == -1 && -n "$L_R1" ]]; then
    # frame size
    ap_step 1 plus;  ap_anim; [[ "$A_FW" == 17 ]] && pass "FRAME W +: 17" || fail "FRAME W +: $A_FW, wanted 17"
    ap_step 1 minus; ap_anim; [[ "$A_FW" == 16 ]] && pass "FRAME W -: 16" || fail "FRAME W -: $A_FW, wanted 16"
    ap_step 2 minus shift; ap_anim; [[ "$A_FH" == 6 ]] && pass "FRAME H Shift+-: 6 (steps of 10)" || fail "FRAME H Shift+-: $A_FH, wanted 6"
    ap_step 2 plus shift;  ap_anim; [[ "$A_FH" == 16 ]] && pass "FRAME H Shift++: back to 16" || fail "FRAME H Shift++: $A_FH, wanted 16"
    ap_step 3 plus;  ap_anim; [[ "$A_GUT" == 1 ]] && pass "GUTTER +: 1" || fail "GUTTER +: $A_GUT, wanted 1"
    ap_step 3 minus; ap_step 4 plus; ap_anim
    [[ "$A_GUT" == 0 && "$A_MAR" == 1 ]] && pass "GUTTER back to 0, MARGIN +: 1" || fail "gutter $A_GUT margin $A_MAR, wanted 0 / 1"
    ap_step 4 minus; ap_anim
    [[ "$A_FW" == 16 && "$A_FH" == 16 && "$A_MAR" == 0 && "$A_COUNT" == 7 ]] && pass "layout back to 16x16, 7 frames" \
        || fail "layout ${A_FW}x$A_FH margin $A_MAR count $A_COUNT, wanted 16x16 / 0 / 7"

    # timing
    ap_step 5 plus; ap_anim; [[ "$A_FPS" == 13 ]] && pass "FPS +: 13" || fail "FPS +: $A_FPS, wanted 13"
    ap_step 5 plus hold; ap_anim
    (( A_FPS > 15 )) && pass "FPS + held repeats ($A_FPS)" || fail "holding FPS + did not repeat (fps $A_FPS)"
    ap_step 6 plus; ap_panel; [[ "$P_HOLD" == 2 ]] && pass "HOLD +: frame 3 holds 2" || fail "HOLD +: $P_HOLD, wanted 2"

    # loop mode, frame buttons
    ap_chip "$L_LOOP" 2; ap_anim; [[ "$A_LOOP" == 2 ]] && pass "loop PING" || fail "loop mode $A_LOOP after PING, wanted 2"
    ap_chip "$L_LOOP" 3; ap_anim; [[ "$A_LOOP" == 3 ]] && pass "loop ONCE" || fail "loop mode $A_LOOP after ONCE, wanted 3"
    ap_chip "$L_NAV" 2; ap_anim; [[ "$A_CUR" == 4 ]] && pass "> : next frame (4)" || fail "> : frame $A_CUR, wanted 4"
    ap_panel; [[ "$P_HOLD" == 1 ]] && pass "HOLD shows frame 4's (1)" || fail "HOLD shows $P_HOLD on frame 4, wanted 1"
    ap_chip "$L_NAV" 0; ap_anim; [[ "$A_CUR" == 1 ]] && pass "|< : first frame" || fail "|< : frame $A_CUR, wanted 1"
    ap_chip "$L_NAV" 3; ap_anim; [[ "$A_CUR" == 7 ]] && pass ">| : last frame" || fail ">| : frame $A_CUR, wanted 7"

    # docks like the other windows
    dk_move_expect animation edge-right; dk_check "the Animation panel on the right edge"
    ap_panel; [[ "$P_DOCK" == -1 ]] && pass "docked" || fail "not docked (docked=$P_DOCK)"
    ap_step 1 plus; ap_anim; [[ "$A_FW" == 17 ]] && pass "docked: FRAME W + still works" || fail "docked: FRAME W $A_FW, wanted 17"
    ap_step 1 minus
    dk_move_expect animation float; dk_check "the Animation panel floating again"

    # close box
    ap_panel
    click "$(ap_vx $(( L_PW - 4 )))" "$(ap_vy 3)"
    wait_for 0.4 "Close box"
    ap_panel; [[ "$P_VIS" == 0 ]] && pass "the close box closes it" || fail "still open after the close box (visible=$P_VIS)"
fi

# -- a picture without frames: a size stepper gives it frames --
info "Relaunching with the same picture, no frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AP_DIR/plain.png"
draw_launch 15
wait_for 3 "Picture loaded"
ap_open
ap_anim
ap_panel; info "panel visible=$P_VIS at ($P_X,$P_Y) ${P_W}x$P_H scale $P_SC%, W row $L_R1, - at $L_MX"
screenshot "anim-panel-plain"
[[ "$A_ON" == 0 ]] && pass "a plain picture has no frames" || fail "a plain picture has frames (on=$A_ON)"
ap_step 5 plus; ap_anim
[[ "$A_ON" == 0 ]] && pass "no frames: FPS is greyed (nothing changes)" || fail "FPS + gave a plain picture frames"
ap_step 1 minus; ap_anim
[[ "$A_ON" == -1 && "$A_FW" == 63 && "$A_FH" == 32 && "$A_COUNT" == 1 ]] && pass "no frames: FRAME W - makes a 63x32 frame layout" \
    || fail "after FRAME W -: on=$A_ON ${A_FW}x$A_FH count $A_COUNT, wanted -1 63x32 1"
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$AP_DIR"
assert_window_exists
