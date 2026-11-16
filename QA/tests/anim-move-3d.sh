#!/bin/bash
# =============================================================================
# anim-move-3d.sh — QA test: Move Brush in 3D, typed values, AnimPaint
# (Rick 2026-11-11: "i'd like 1, 2, and 3. scale, rotate, position, opacity,
# tint, are all things we could have for sure").
#
#   - Start opens the Animation panel on the Move rows (and the end of the
#     move shuts it again)
#   - typed values (click a box, type, Enter) with no drag: a still path in
#     the middle of the frame - TURN Z 90 spins the brush in place
#   - RESET; SIZE 100 -> 50 (typed); a middle click puts a box back
#   - OPACITY 100 -> 0 fades it out; TINT 0 -> 100 ends at the FG colour
#   - MOVE Z 300 with MOVE X 8: perspective - half size, pulled toward the
#     middle of the frame
#   - the DRAWN path: the stamps follow an L-shaped drag (not the straight
#     line from its start to its end); PLAY / STOP
#   - AnimPaint (the LIVE path): a stroke is recorded in real time and
#     stamped when it ends, the mode stays on, one undo step
#
# Dump: MVB / MVBV (path count z tx ty tz s0 s1 o0 o1 t0 t1 playing nPts dur
# plain fg) / MVBP / MVBB (bounds per frame) / MVBA (most opaque pixel per
# frame); ANIMP + ANIMPM (on y1..y10 slotX1 slotX2 slotX3 valW) + ANIMPL (rowH).
# Fixture: a 192x32 sheet of 6 frames of 32x32; frame 1 has an 8x4 red bar at
# (12, 14). The brush is that bar.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Move Brush in 3D, typed values, AnimPaint ==="

M3_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
M3_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
M3_DIR="/tmp/draw-qa-animmove3d-$$"
mkdir -p "$M3_DIR"
magick -size 192x32 xc:none -fill '#c04040' -draw 'rectangle 12,14 19,17' "PNG32:$M3_DIR/plain.png"
M3_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,32,32,0,0,6,1,12,0,0).hex())")
python3 "$M3_PY" put "$M3_DIR/plain.png" "$M3_DIR/sheet.png" drAn "$M3_BLOB"

m3_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
m3_line() { grep -m1 "^$1 " "$M3_DUMPF" 2>/dev/null; }
m3_read() {
    m3_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(m3_line ANIM)"
    read -r _ M_ON M_DRAG M_PATH M_FROM M_EASE M_EVERY M_X0 M_Y0 M_X1 M_Y1 M_N M_HIST _ <<< "$(m3_line MVB)"
    read -r _ V_PATH V_COUNT V_Z V_TX V_TY V_TZ V_S0 V_S1 V_O0 V_O1 V_T0 V_T1 V_PLAY V_NPTS V_DUR V_PLAIN V_FG _ <<< "$(m3_line MVBV)"
    read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC _ <<< "$(m3_line ANIMP)"
    read -r _ PM_ON PM_Y1 PM_Y2 PM_Y3 PM_Y4 PM_Y5 PM_Y6 PM_Y7 PM_Y8 PM_Y9 PM_Y10 PM_S1 PM_S2 PM_S3 PM_VW _ <<< "$(m3_line ANIMPM)"
    read -r _ _ _ _ _ _ _ _ _ L_RH _ _ _ L_PAD L_PW _ <<< "$(m3_line ANIMPL)"
    M_P=$(m3_line MVBP | cut -d' ' -f2-)
    M_B=$(m3_line MVBB | cut -d' ' -f2-)
    M_A=$(m3_line MVBA | cut -d' ' -f2-)
    local p k; p=($(m3_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
m3_s() { echo "MVB on ${M_ON:-?} path ${M_PATH:-?} from ${M_FROM:-?} (${M_X0:-?},${M_Y0:-?})-(${M_X1:-?},${M_Y1:-?}) n ${M_N:-?}; MVBV $V_PATH $V_COUNT z $V_Z turn $V_TX/$V_TY/$V_TZ size $V_S0-$V_S1 op $V_O0-$V_O1 tint $V_T0-$V_T1 play $V_PLAY pts $V_NPTS plain $V_PLAIN"; }
m3_px() { echo $(( PX + (2 * $1 + 1) * PW / 64 )); }   # cell px -> viewport (32 px cells)
m3_py() { echo $(( PY + (2 * $1 + 1) * PH / 64 )); }
m3_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
m3_cmd() { # never type unless the palette is open: the query would go in as hotkeys
    local try ok=0
    for try in 1 2 3; do
        park_mouse; key question; wait_for 1.0 "Command palette"
        grep -q '^POPUP cmdpalette' "$M3_DUMPF" 2>/dev/null && { ok=1; break; }
        m3_settle; grep -q '^POPUP cmdpalette' "$M3_DUMPF" 2>/dev/null && { ok=1; break; }
        info "the palette did not open - again"
    done
    (( ok )) || { info "no palette for '$1'"; return 1; }
    type_text "$1"; wait_for "$(awk -v n=${#1} 'BEGIN{printf "%.1f", 0.6 + n * 0.08}')" "Filtered"
    key Return; wait_for 1.0 "$1"
}
m3_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
# a Move box: ROW SLOT -> viewport middle
m3_box() { # ROW SLOT
    m3_read
    local y="PM_Y$1" s="PM_S$2"
    echo "$(( P_X + (${!s} + PM_VW / 2) * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
m3_chip() { # ROW K N - chip K (0-based) of N across the row
    m3_read
    local y="PM_Y$1" w x
    w=$(( (L_PW - 2 * L_PAD - 2 * ($3 - 1)) / $3 ))
    x=$(( L_PAD + $2 * (w + 2) + w / 2 ))
    echo "$(( P_X + x * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
m3_type() { # ROW SLOT TEXT
    local x y; read -r x y <<< "$(m3_box "$1" "$2")"
    m3_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"
}
m3_set() { # ROW SLOT TEXT VAR - type, read back, once more if it did not take
    m3_type "$1" "$2" "$3"; m3_read
    [[ "${!4}" == "$3" ]] || { info "box $1/$2 is '${!4}', not $3 - again"; m3_type "$1" "$2" "$3"; m3_read; }
}
m3_tap() { local x y; read -r x y <<< "$(m3_chip "$@")"; m3_hclick "$x" "$y"; }
m3_undo() { local h0; m3_read; h0=$M_HIST; m3_key ctrl+z; m3_read; [[ "$M_HIST" == "$h0" ]] && { m3_key ctrl+z; m3_read; }; }
m3_start() { # the mode on (and the panel on its Move rows)
    m3_cmd "move brush: start"; m3_read
    [[ "$M_ON" == -1 ]] || { m3_cmd "move brush: start"; m3_read; }
}
m3_field() { # LINE FRAME -> that frame's field ("f:..." -> "...")
    local w; for w in $1; do [[ "${w%%:*}" == "$2" ]] && { echo "${w#*:}"; return; }; done
}
m3_empty="1:- 2:- 3:- 4:- 5:- 6:-"

info "Launching DRAW with a 192x32 sheet of 6 frames of 32x32"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$M3_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
m3_key KP_0
m3_read
if [[ "$A_COUNT" != 6 || -z "${PX:-}" || -z "${M_ON:-}" || -z "${V_PATH:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}', $(m3_s)"
else
    P0=$P_VIS
    # -- the brush: frame 1's bar; a new layer for the stamps --
    m3_key m
    mouse_down "$(m3_px 12)" "$(m3_py 14)"; hover "$(m3_px 16)" "$(m3_py 16)"; sleep 0.2; hover "$(m3_px 19)" "$(m3_py 17)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    m3_key ctrl+b; m3_key ctrl+shift+n; m3_read
    [[ "$M_B" == "$m3_empty" ]] && pass "the stamps' layer is empty" || fail "new layer: [$M_B]"

    # -- Start: the panel shows the Move rows --
    m3_start
    [[ "$M_ON" == -1 && "$P_VIS" == -1 && "$PM_ON" == -1 && -n "$PM_S3" ]] && pass "Start: the Animation panel is open on the Move rows (it was ${P0})" \
        || fail "Start: $(m3_s); panel visible '$P_VIS' move rows '$PM_ON'"
    screenshot "anim-move-3d-panel"

    # -- typed TURN Z 90, no drag: a spin in place --
    m3_set 4 3 90 V_TZ
    [[ "$V_TZ" == 90 && "$M_PATH" == -1 && "$M_X0 $M_Y0 $M_X1 $M_Y1" == "16 16 16 16" ]] && pass "typed TURN Z 90: a still path in the middle of the frame" \
        || fail "TURN Z typed: $(m3_s)"
    m3_key Return; m3_read
    B1=$(m3_field "$M_B" 1); B6=$(m3_field "$M_B" 6)
    [[ "$B1" == "12:14:8:4" && "$B6" == "14:12:4:8" ]] && pass "frame 1 the bar as it is ($B1), frame 6 turned 90 degrees ($B6)" \
        || fail "spin in place: frame 1 [$B1] (want 12:14:8:4), frame 6 [$B6] (want 14:12:4:8); [$M_B]"
    [[ "$M_ON" == 0 && "$P_VIS" == "$P0" ]] && pass "Enter: the mode is off and the panel is as it was" || fail "after Enter: $(m3_s); panel '$P_VIS' (was $P0)"
    m3_undo
    [[ "$M_B" == "$m3_empty" ]] && pass "Ctrl+Z takes the whole spin away" || fail "undo spin: [$M_B]"

    # -- RESET, then SIZE 100 -> 50 --
    m3_start
    m3_tap 10 1 4; m3_read
    [[ "$V_TZ" == 0 && "$V_PLAIN" == -1 ]] && pass "RESET: no turn (a plain move)" || fail "RESET: $(m3_s)"
    m3_set 5 3 50 V_S1
    m3_key Return; m3_read
    B6=$(m3_field "$M_B" 6); B1=$(m3_field "$M_B" 1)
    [[ "$B1" == "12:14:8:4" && "$B6" == "14:15:4:2" ]] && pass "SIZE 100 -> 50: frame 6 is half size ($B6)" || fail "size: frame 1 [$B1], frame 6 [$B6] (want 14:15:4:2)"
    m3_undo

    # -- a middle click puts SIZE back; OPACITY 100 -> 0 fades out --
    m3_start
    read -r x y <<< "$(m3_box 5 3)"; middle_click "$x" "$y"; wait_for 0.5 "middle"; m3_read
    [[ "$V_S1" == 100 ]] && pass "a middle click: SIZE back to 100" || fail "middle click: size end $V_S1"
    m3_set 6 3 0 V_O1
    m3_key Return; m3_read
    A1=$(m3_field "$M_A" 1); A3=$(m3_field "$M_A" 3); A6=$(m3_field "$M_A" 6)
    A3a=${A3%%:*}
    [[ "${A1%%:*}" == 255 && "$A6" == "-" && "$A3a" =~ ^[0-9]+$ ]] && (( A3a > 135 && A3a < 170 )) \
        && pass "OPACITY 100 -> 0: frame 1 solid, frame 3 at $A3a, frame 6 gone" || fail "fade: frame 1 [$A1] frame 3 [$A3] frame 6 [$A6]"
    m3_undo

    # -- TINT 0 -> 100 toward FG --
    m3_start
    m3_set 6 3 100 V_O1
    m3_set 7 3 100 V_T1
    m3_key Return; m3_read
    FG=$(printf '%d:%d:%d' 0x${V_FG:0:2} 0x${V_FG:2:2} 0x${V_FG:4:2})
    A1=$(m3_field "$M_A" 1); A6=$(m3_field "$M_A" 6)
    [[ "$A1" == "255:192:64:64" && "$A6" == "255:$FG" ]] && pass "TINT 0 -> 100: frame 1 red, frame 6 the FG colour ($FG)" || fail "tint: frame 1 [$A1], frame 6 [$A6], FG $FG"
    m3_undo

    # -- MOVE Z 300 + MOVE X 8: perspective --
    m3_start
    m3_tap 10 1 4
    m3_type 3 1 8; m3_read
    [[ "$M_X1" == 24 ]] || { m3_type 3 1 8; m3_read; }
    [[ "$M_X0 $M_X1" == "16 24" ]] && pass "typed MOVE X 8: the path runs (16,16)-(24,16)" || fail "MOVE X: $(m3_s)"
    m3_set 3 3 300 V_Z
    m3_key Return; m3_read
    B6=$(m3_field "$M_B" 6); B1=$(m3_field "$M_B" 1)
    [[ "$B1" == "12:14:8:4" && "$B6" == "18:15:4:2" ]] && pass "MOVE Z 300: frame 6 half size and pulled toward the middle ($B6, not 20:14:8:4)" \
        || fail "Z: frame 1 [$B1], frame 6 [$B6] (want 18:15:4:2)"
    m3_undo

    # -- the DRAWN path: an L --
    m3_start
    m3_tap 10 1 4
    m3_tap 1 1 3; m3_read
    [[ "$V_PATH" == 1 ]] && pass "the DRAWN chip: path kind 1" || fail "DRAWN chip: $(m3_s)"
    m3_read
    mouse_down "$(m3_px 4)" "$(m3_py 4)"
    for xx in 8 12 16 20 24 28; do hover "$(m3_px $xx)" "$(m3_py 4)"; sleep 0.12; done
    for yy in 8 12 16 20 24 28; do hover "$(m3_px 28)" "$(m3_py $yy)"; sleep 0.12; done
    sleep 0.2; mouse_up; wait_for 0.6 "path"; m3_read
    P4=$(m3_field "$M_P" 4)
    IFS=: read -r p4x p4y _ <<< "$P4"
    [[ "$p4x" == 24 ]] && (( p4y >= 5 && p4y <= 9 )) && pass "DRAWN: frame 4 is round the corner of the L ($P4), not on the straight line" \
        || fail "DRAWN: frame 4 planned at [$P4] (want 24:5..9); $(m3_s); MVBP [$M_P]"
    m3_tap 10 0 4; m3_read
    [[ "$V_PLAY" == -1 ]] && pass "PLAY: the ghost plays" || fail "PLAY: $(m3_s)"
    m3_tap 10 0 4; m3_read
    [[ "$V_PLAY" == 0 ]] && pass "STOP" || fail "STOP: $(m3_s)"
    m3_key Escape; m3_read
    [[ "$M_ON" == 0 && "$M_B" == "$m3_empty" && "$P_VIS" == "$P0" ]] && pass "Esc: nothing stamped, the panel as it was" || fail "Esc: $(m3_s) [$M_B] panel $P_VIS"

    # -- AnimPaint: a live stroke --
    m3_cmd "animpaint"; m3_read
    [[ "$M_ON" == -1 && "$V_PATH" == 2 ]] || { m3_cmd "animpaint"; m3_read; }
    [[ "$M_ON" == -1 && "$V_PATH" == 2 ]] && pass "AnimPaint: on, the live path" || fail "AnimPaint start: $(m3_s)"
    m3_read
    mouse_down "$(m3_px 4)" "$(m3_py 16)"
    for xx in 8 12 16 20 24 28; do hover "$(m3_px $xx)" "$(m3_py 16)"; sleep 0.05; done
    sleep 0.6
    sleep 0.2; mouse_up; wait_for 0.8 "stroke"; m3_read
    B1=$(m3_field "$M_B" 1); B6=$(m3_field "$M_B" 6)
    IFS=: read -r b1x _ <<< "$B1"; IFS=: read -r b6x _ <<< "$B6"
    [[ "$B1" != "-" && "$B6" != "-" && "$M_ON" == -1 ]] && (( b6x > b1x )) && pass "AnimPaint: stamped in every frame as the stroke went (frame 1 at x $b1x, frame 6 at x $b6x), still on" \
        || fail "AnimPaint stroke: [$M_B]; $(m3_s)"
    m3_undo
    [[ "$M_B" == "$m3_empty" ]] && pass "Ctrl+Z takes the stroke away in one step" || fail "AnimPaint undo: [$M_B]"
    m3_key Escape; m3_read
    [[ "$M_ON" == 0 ]] && pass "Esc stops AnimPaint" || fail "AnimPaint Esc: $(m3_s)"
    m3_cmd "move brush: path straight"; m3_read
fi

assert_no_crash
draw_quit
rm -rf "$M3_DIR"
