#!/bin/bash
# =============================================================================
# anim-lightbox-strip.sh — QA test: the lightbox strip (Animation 2.3,
# TOOLS/ANIM-LB + the selection in TOOLS/ANIM).
#
# R-12, the layers panel's rules: a click makes a frame current (and the only
# one selected), Ctrl+click adds / removes, Shift+click selects a range from
# the anchor. Selected frames are tinted. Play then plays only the selected
# span. Dragging moves the selected frames to where they are dropped, one undo
# step. The wheel scrolls the strip; a frame change scrolls the current frame
# back into view.
#
# Dump: ANIM / ANIMC (a CRC per frame cell: where each drawing went); ANIMLB
# (layout, stripFirst / stripN); ANIMLBS dragging dropSlot anchor nSelected
# then the selected frames.
# Fixture: a 64x64 sheet of 16x16 frames, 12 frames, current 3, each cell
# with a mark of its own (so every frame has its own CRC).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: the lightbox strip ==="

LS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LS_DIR="/tmp/draw-qa-lbstrip-$$"
mkdir -p "$LS_DIR"
LS_DRAW=()
for n in $(seq 0 11); do
    x=$(( (n % 4) * 16 + 1 )); y=$(( (n / 4) * 16 + 2 ))
    LS_DRAW+=(-fill "#$(printf '%02x%02x%02x' $(( 60 + n * 16 )) $(( 200 - n * 12 )) $(( 90 + n * 9 )))" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 3 + n % 5 ))")
done
magick -size 64x64 xc:none "${LS_DRAW[@]}" "$LS_DIR/plain.png"
LS_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,12,3,12,0,0).hex())")
python3 "$LS_PY" put "$LS_DIR/plain.png" "$LS_DIR/sheet.png" drAn "$LS_BLOB"

ls_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
ls_line() { grep -m1 "^$1 " "$LS_DUMP" 2>/dev/null; }
ls_read() { # A_COUNT A_CUR A_PLAY, T[1..], LB_*, S_DRAG S_ANCHOR S_N S_SEL
    ls_settle
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ _ _ _ _ _ _ _ A_PLAY _ <<< "$(ls_line ANIM)"
    local t; read -r _ t <<< "$(ls_line ANIMC)"; T=(x $t)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(ls_line ANIMLB)"
    read -r _ S_DRAG _ S_ANCHOR S_N S_SEL <<< "$(ls_line ANIMLBS)"
    S_SEL="${S_SEL:-}"
}
ls_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); } # strip cell centre x of frame F
ls_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
ls_click() { click "$(ls_cx "$1")" "$(ls_cy)"; wait_for 0.4 "strip frame $1"; }
ls_view() { # A B - wheel the strip until frames A..B are all in view (B - A < stripN)
    local i
    ls_read
    for i in $(seq 1 12); do
        if (( $1 < LB_SF )); then scroll_up "$(ls_cx "$LB_SF")" "$(ls_cy)"
        elif (( $2 > LB_SF + LB_SN - 1 )); then scroll_down "$(ls_cx "$LB_SF")" "$(ls_cy)"
        else return 0; fi
        wait_for 0.3 "wheel"; ls_read
    done
    info "ls_view $1 $2: strip stuck at $LB_SF+$LB_SN"
}
ls_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
ls_order() { # BEFORE-TOKENS -> the old frame number now in each cell ("?" = none matches)
    local b=(x $1) out="" i j hit
    for i in $(seq 1 "$A_COUNT"); do
        hit="?"; for j in $(seq 1 "$A_COUNT"); do [[ "${T[$i]}" == "${b[$j]}" ]] && { hit=$j; break; }; done
        out+="$hit "
    done
    echo "${out% }"
}

info "Launching DRAW with a 64x64 sheet of 16x16 frames (12, current 3)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
ls_key KP_0
ls_read
LS_T0="${T[*]:1}"
if [[ "${LB_SHOWN:-}" != -1 || "${A_COUNT:-}" != 12 || -z "${S_N:-}" ]]; then
    fail "lightbox with 12 frames: shown '${LB_SHOWN:-}' count '${A_COUNT:-}' selection line '${S_N:-}'"
else
    pass "lightbox shown: strip frames $LB_SF-$(( LB_SF + LB_SN - 1 )) of 12, nothing selected yet"
    (( LB_SN >= 6 )) || info "the strip shows only $LB_SN frames here"

    # -- click / Ctrl / Shift (frames 1-4: they fit even a 4-cell strip) --
    ls_view 1 4
    ls_click 4; ls_read
    [[ "$A_CUR" == 4 && "$S_SEL" == 4 ]] && pass "click frame 4: current, the only one selected" || fail "click 4: current $A_CUR selected [$S_SEL]"
    snap_region $(( $(ls_cx 2) - LB_CW / 4 )) $(( $(ls_cy) - LB_CH / 4 )) $(( LB_CW / 2 )) $(( LB_CH / 2 )) "strip2-plain"; LS_F2A="$SNAP_RESULT"
    with_mods ctrl click "$(ls_cx 1)" "$(ls_cy)"; wait_for 0.4 "ctrl+click 1"
    ls_read
    [[ "$A_CUR" == 1 && "$S_SEL" == "1 4" ]] && pass "Ctrl+click frame 1: added, current" || fail "ctrl+click 1: current $A_CUR selected [$S_SEL]"
    with_mods shift click "$(ls_cx 3)" "$(ls_cy)"; wait_for 0.4 "shift+click 3"
    ls_read
    [[ "$A_CUR" == 3 && "$S_SEL" == "1 2 3" ]] && pass "Shift+click frame 3: frames 1-3 from the anchor" || fail "shift+click 3: current $A_CUR selected [$S_SEL] anchor $S_ANCHOR"
    snap_region $(( $(ls_cx 2) - LB_CW / 4 )) $(( $(ls_cy) - LB_CH / 4 )) $(( LB_CW / 2 )) $(( LB_CH / 2 )) "strip2-selected"; LS_F2B="$SNAP_RESULT"
    assert_regions_differ "$LS_F2A" "$LS_F2B" "a selected frame is tinted in the strip"

    # -- Play plays the selected span --
    ls_key KP_Enter
    LS_SEEN=""
    for i in $(seq 1 12); do read -r _ _ _ c _ <<< "$(ls_line ANIM)"; LS_SEEN+="$c "; sleep 0.1; done
    ls_key KP_Enter
    LS_OUT=$(tr ' ' '\n' <<< "$LS_SEEN" | grep -v '^$' | sort -un | tr '\n' ' ')
    [[ "$LS_OUT" =~ ^(1\ )?(2\ )?(3\ )?$ && $(wc -w <<< "$LS_OUT") -ge 2 ]] && pass "Play runs only the selected frames 1-3 (seen: $LS_OUT)" \
        || fail "play with 1-3 selected went through frames: $LS_OUT"

    # -- drag the selection (1-3) to before frame 5 --
    ls_view 2 5
    # held mid-drag: the strip shows where they will land (drop slot 5)
    snap_region "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) "$LB_SH" "strip-still"; LS_SA="$SNAP_RESULT"
    mouse_down "$(ls_cx 3)" "$(ls_cy)"
    hover $(( $(ls_cx 5) - LB_CW / 4 )) "$(ls_cy)"; sleep 0.3; hover $(( $(ls_cx 5) - LB_CW / 4 + 1 )) "$(ls_cy)"; sleep 0.3
    read -r _ LS_D LS_SLOT _ <<< "$(ls_line ANIMLBS)"
    snap_region "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) "$LB_SH" "strip-dragging"; LS_SB="$SNAP_RESULT"
    hover "$(ls_cx 3)" "$(ls_cy)"; sleep 0.3; hover $(( $(ls_cx 3) + 1 )) "$(ls_cy)"; sleep 0.3 # back where it started: no move
    mouse_up; wait_for 0.5 "dropped in place"
    [[ "$LS_D" == -1 && "$LS_SLOT" == 5 ]] && pass "mid-drag: dragging, drop slot 5" || fail "mid-drag: dragging '$LS_D' slot '$LS_SLOT'"
    assert_regions_differ "$LS_SA" "$LS_SB" "the drop marker shows in the strip while dragging"
    ls_read
    [[ "$(ls_order "$LS_T0")" == "1 2 3 4 5 6 7 8 9 10 11 12" && "$S_SEL" == "1 2 3" ]] && pass "dropped where they started: nothing moves, the selection stays" \
        || fail "drop in place: order [$(ls_order "$LS_T0")] selected [$S_SEL]"

    ls_view 2 5
    drag "$(ls_cx 3)" "$(ls_cy)" $(( $(ls_cx 5) - LB_CW / 4 )) "$(ls_cy)"; wait_for 0.6 "drag 1-3 before 5"
    ls_read
    LS_ORD=$(ls_order "$LS_T0")
    [[ "$LS_ORD" == "4 1 2 3 5 6 7 8 9 10 11 12" ]] && pass "dragged 1-3 before frame 5: order now $LS_ORD" || fail "drag 1-3 before 5: order [$LS_ORD]"
    [[ "$S_SEL" == "2 3 4" && "$A_CUR" == 4 ]] && pass "the selection and the current frame went with them (2-4, current 4)" \
        || fail "after the drag: selected [$S_SEL] current $A_CUR (wanted 2 3 4 / 4)"
    ls_key ctrl+z; ls_read
    [[ "$(ls_order "$LS_T0")" == "1 2 3 4 5 6 7 8 9 10 11 12" ]] && pass "undo: one step puts the order back" || fail "undo drag: order [$(ls_order "$LS_T0")]"

    # -- dragging an unselected frame moves just it --
    ls_view 1 4
    ls_click 2; ls_read
    drag "$(ls_cx 4)" "$(ls_cy)" $(( $(ls_cx 1) - LB_CW / 4 )) "$(ls_cy)"; wait_for 0.6 "drag 4 to the front"
    ls_read
    LS_ORD=$(ls_order "$LS_T0")
    [[ "$LS_ORD" == "4 1 2 3 5 6 7 8 9 10 11 12" && "$A_CUR" == 1 ]] && pass "dragging frame 4 to the front moves only it (now frame 1, current)" \
        || fail "drag 4 to front: order [$LS_ORD] current $A_CUR"
    ls_key ctrl+z; ls_read

    # -- a plain click inside a multi-selection: just that frame on release --
    ls_view 1 4
    ls_click 1; with_mods shift click "$(ls_cx 3)" "$(ls_cy)"; wait_for 0.4 "shift+click 3"
    ls_click 2; ls_read
    [[ "$S_SEL" == 2 && "$A_CUR" == 2 ]] && pass "a click on a selected frame selects just it" || fail "click in the selection: selected [$S_SEL] current $A_CUR"
    [[ "$(ls_order "$LS_T0")" == "1 2 3 4 5 6 7 8 9 10 11 12" ]] && pass "clicks never reorder" || fail "clicks reordered: [$(ls_order "$LS_T0")]"
    ls_key KP_5; ls_read # current 3 for the wheel checks
    # -- the wheel scrolls the strip; a frame step brings the current one back --
    if (( LB_SN < 12 )); then
        LS_SF0=$LB_SF
        scroll_down "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.3 "wheel"; scroll_down "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.4 "wheel"
        ls_read
        (( LB_SF > LS_SF0 )) && [[ "$A_CUR" == 3 ]] && pass "the wheel scrolls the strip (first frame $LS_SF0 -> $LB_SF), the current frame stays 3" \
            || fail "wheel down: strip first $LS_SF0 -> $LB_SF, current $A_CUR"
        LS_SF1=$LB_SF
        scroll_up "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.4 "wheel up"
        ls_read
        (( LB_SF < LS_SF1 )) && pass "wheel up scrolls back (first frame $LB_SF)" || fail "wheel up: strip first $LS_SF1 -> $LB_SF"
        scroll_down "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.2 "wheel"; scroll_down "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.2 "wheel"
        scroll_down "$(ls_cx $(( LB_SF + 1 )))" "$(ls_cy)"; wait_for 0.4 "wheel"
        ls_key KP_1; ls_read
        [[ "$A_CUR" == 1 && "$LB_SF" == 1 ]] && pass "Num 1 (first frame) scrolls the strip back to it" || fail "Num 1 after scrolling: current $A_CUR strip first $LB_SF"
    else
        info "all 12 frames fit the strip here - wheel checks skipped"
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LS_DIR"
assert_window_exists
