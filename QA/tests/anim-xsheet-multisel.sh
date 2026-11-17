#!/bin/bash
# =============================================================================
# anim-xsheet-multisel.sh — QA test: select several layers on the X-sheet and
# group / ungroup / rearrange them there, like the Layers panel (Rick
# 2026-11-16: "i would like to be able to select multiple x-sheet layers for
# group/ungroup/rearrange them there just like layer panel").
#   - 3 layers; click B's name, Ctrl+click A's: both selected (the Layers
#     panel's MULTI_SELECT - LAYER dump, LPANEL count), the row shaded
#   - Shift+click C: three; again: two
#   - Ctrl+Shift+G: a group of A + B; Ctrl+Shift+U on the group: gone
#   - drag C's name to the gap above B (in the group): C joins it; Ctrl+Z: out
#   - drag A's name to the top gap: out of the group, on top
# Dump: LAYER slot z parent type collapsed visible opacity multi, LPANEL,
# ANIMXSLO (name x / row y per layer), ANIMXSD (the drag).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 XSHEET_ROWS=TEXT
# =============================================================================
info "=== Animation: X-sheet layer multi-select ==="

HL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
HL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
HL_DIR="/tmp/draw-qa-xsmulti-$$"
mkdir -p "$HL_DIR"
HL_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
HL_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    HL_DRAW+=(-fill "#${HL_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${HL_DRAW[@]}" "PNG32:$HL_DIR/plain.png"
python3 "$HL_PY" put "$HL_DIR/plain.png" "$HL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

hl_line() { grep -m1 "^$1 " "$HL_DUMPF" 2>/dev/null; }
hl_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(hl_line ANIM)"
    LH="$(hl_line ANIMLH | sed 's/^ANIMLH//; s/ _$//; s/^ //')"
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(hl_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(hl_line ANIMXSLA)"
    XF=($(hl_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(hl_line ANIMXS)"
    XM=($(hl_line ANIMXLM))
    XRY=$(grep -m1 "^ANIMXSR 1 " "$HL_DUMPF" | cut -d' ' -f4)
    LLN="$(hl_line LLN | cut -d' ' -f5-)"
    LLD="$(hl_line LLD | cut -d' ' -f3-)"
    local p k; p=($(hl_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
hl_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} holds '${LH}' lanes [${LLN}] shows [${LLD}]"; }
hl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
# mid-drag: re-render in place (hl_read's hover to 300,250 would carry the drag there)
hl_peek() { hover "$1" $(( $2 + 1 )); wait_for 0.15 "render"; hover "$1" "$2"; wait_for 0.25 "render"; }
hl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
hl_fx() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo "${XF[i + 1]} ${XF[i + 2]}"; return; }; done; echo "0 0"; }
hl_fmid() { local x w; read -r x w <<< "$(hl_fx "$1")"; echo $(( x + w / 2 )); }
hl_fend() { local x w; read -r x w <<< "$(hl_fx "$1")"; echo $(( x + w - 2 )); }
hl_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
hl_pick() {
    local iy; iy=$(hl_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    hl_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); hl_read
}
hl_lane_y() { grep -m1 "^ANIMXSLN 1 $1 " "$HL_DUMPF" 2>/dev/null | cut -d' ' -f4; }
hl_drag() { # X0 X1 Y
    mouse_down "$1" "$3"; hover $(( ($1 + $2) / 2 )) "$3"; sleep 0.15; hover "$2" "$3"; sleep 0.3
    mouse_up; wait_for 0.6 "drop"
}

lay() { grep -m1 "^LAYER $1 " "$HL_DUMPF" 2>/dev/null; }
lay_z()  { lay "$1" | cut -d' ' -f3; }
lay_p()  { lay "$1" | cut -d' ' -f4; }
lay_ms() { lay "$1" | cut -d' ' -f9; }
lp_cur() { hl_line LPANEL | cut -d' ' -f3; }
lp_n()   { hl_line LPANEL | cut -d' ' -f4; }
groups() { grep '^LAYER ' "$HL_DUMPF" | awk '$5 == 2 {print $2}' | paste -sd,; }
# the name of layer slot $1 on the X-sheet: NX NY (its middle)
name_xy() { local l; l=$(grep -m1 "^ANIMXSLO $1 " "$HL_DUMPF"); NX=$(( $(echo "$l" | cut -d' ' -f4) + 10 + 8 )); NY=$(( $(echo "$l" | cut -d' ' -f5) + XLH / 2 )); NTOP=$(echo "$l" | cut -d' ' -f5); }
lst() { echo "layers [$(grep '^LAYER ' "$HL_DUMPF" | cut -d' ' -f2-4,9 | paste -sd'|')] cur $(lp_cur) n $(lp_n)"; }
name_drag() { # slot, to y
    name_xy "$1"
    mouse_down "$NX" "$NY"; hover "$NX" $(( NY + ($2 - NY) / 2 )); sleep 0.15; hover "$NX" "$2"; sleep 0.35; hl_peek "$NX" "$2"
    DRAG_D="$(hl_line ANIMXSD)"
    mouse_up; wait_for 0.7 "drop"; hl_read
}

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$HL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
hl_key ctrl+0
hl_key KP_8
hl_key ctrl+shift+n
hl_key ctrl+shift+n
hl_read
if [[ "$A_COUNT" != 6 || -z "$(lay 3)" || -z "$(grep -m1 '^ANIMXSLO 3 ' "$HL_DUMPF")" ]]; then
    fail "start: $(hl_s) $(lst)"
else
    pass "a sheet of 6 frames, 3 layers on the X-sheet ($(lst))"
    # -- Ctrl / Shift+click --
    name_xy 2; hl_hclick "$NX" "$NY"; hl_read
    [[ "$(lp_cur)" == 2 && "$(lp_n)" == 1 ]] && pass "click layer 2's name: current, alone" || fail "click: $(lst)"
    name_xy 1
    snap_region $(( NX - 20 )) $(( NTOP + 1 )) 40 $(( XLH - 2 )) "ms-a-off" >/dev/null; A_OFF="$SNAP_RESULT"
    with_mods ctrl hl_hclick "$NX" "$NY"; hl_read
    [[ "$(lp_cur)" == 2 && "$(lp_n)" == 2 && "$(lay_ms 1)" == -1 && "$(lay_ms 2)" == -1 && "$(lay_ms 3)" == 0 ]] \
        && pass "Ctrl+click layer 1's name: layers 1 + 2 selected (the Layers panel's selection)" || fail "ctrl+click: $(lst)"
    name_xy 1
    snap_region $(( NX - 20 )) $(( NTOP + 1 )) 40 $(( XLH - 2 )) "ms-a-on" >/dev/null
    assert_regions_differ "$A_OFF" "$SNAP_RESULT" "layer 1's name row shaded as selected"
    name_xy 3; with_mods shift hl_hclick "$NX" "$NY"; hl_read
    [[ "$(lp_n)" == 3 ]] && pass "Shift+click layer 3: three selected" || fail "shift+click: $(lst)"
    name_xy 3; with_mods shift hl_hclick "$NX" "$NY"; hl_read
    [[ "$(lp_n)" == 2 && "$(lay_ms 3)" == 0 ]] && pass "Shift+click it again: back to two" || fail "shift+click off: $(lst)"
    screenshot "xsheet-multisel"

    # -- group / ungroup from it --
    hl_key ctrl+shift+g; hl_read
    G=$(groups)
    if [[ -n "$G" && "$(lay_p 1)" == "$G" && "$(lay_p 2)" == "$G" && "$(lay_p 3)" == 0 ]]; then
        pass "Ctrl+Shift+G: layers 1 + 2 grouped (group $G)"
    else
        fail "group: groups '$G' $(lst)"
    fi
    # -- drag layer 3's name into the group (the gap above layer 2, a child) --
    if [[ -n "$G" ]]; then
        name_xy 2; TOY=$(( NTOP + 1 ))
        name_drag 3 "$TOY"
        [[ "$(lay_p 3)" == "$G" ]] && pass "drag layer 3's name above layer 2: into the group" || fail "drag in: drag [$DRAG_D] $(lst)"
        hl_key ctrl+z; hl_read
        [[ "$(lay_p 3)" == 0 ]] && pass "Ctrl+Z: out again (one undo step)" || fail "undo drag: $(lst)"
        # -- layer 1 out of the group to the top --
        # (the rows may be scrolled to the current layer, row 1 off the top: hold the
        # name above the first row shown until they scroll to the top - "past the
        # rows' ends they scroll" - then drop in the gap above the first row)
        FY=$(awk '$1=="ANIMXSR" && $4 >= 0 {print $4; exit}' "$HL_DUMPF")
        name_xy 1
        mouse_down "$NX" "$NY"; hover "$NX" $(( (NY + FY) / 2 )); sleep 0.15; hover "$NX" $(( FY - 3 )); sleep 1.6
        hover "$NX" $(( FY + 1 )); sleep 0.4; hl_peek "$NX" $(( FY + 1 ))
        DRAG_D="$(hl_line ANIMXSD)"
        mouse_up; wait_for 0.7 "drop"; hl_read
        [[ "$(lay_p 1)" == 0 && "$(lay_z 1)" == 4 ]] && pass "drag layer 1's name to the top: out of the group, on top" || fail "drag out: drag [$DRAG_D] $(lst)"
        hl_key ctrl+z; hl_read
        [[ "$(lay_p 1)" == "$G" ]] && pass "Ctrl+Z: back in the group" || fail "undo drag out: $(lst)"
        # -- ungroup: click the group's name, Ctrl+Shift+U --
        name_xy "$G"; hl_hclick "$NX" "$NY"; hl_read
        hl_key ctrl+shift+u; hl_read
        [[ -z "$(groups)" && "$(lay_p 1)" == 0 && "$(lay_p 2)" == 0 ]] && pass "click the group's name, Ctrl+Shift+U: ungrouped" || fail "ungroup: cur $(lp_cur) $(lst)"
    fi
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$HL_DIR"
assert_window_exists
info "=== Animation: X-sheet layer multi-select: done ==="
