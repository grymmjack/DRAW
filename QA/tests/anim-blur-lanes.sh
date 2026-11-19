#!/bin/bash
# =============================================================================
# anim-blur-lanes.sh — QA test: the BLUR lane's properties (Rick 2026-11-17:
# "we need the blur in the xsheet effects to allow motion blur - and controls
# for blur amount and blur direction ... in addition to regular old blur";
# "if we could have all the blurs we have in draw, and their properties").
#   BLUR TYPE (17, stepped: BOX / GAUSSIAN / MOTION / ZOOM / SPIN / FOLLOW MOVE)
#   and BLUR ANGLE (18) beside BLUR (13) - LL_blur_props -> IMAGE_ADJ_blur_typed_at&.
#   - + LANE lists BLUR TYPE / BLUR ANGLE right after BLUR (ANIM_XL_order%)
#   - frame 1 BLUR 0; frames 2-5 BLUR 6:
#       2 MOTION at 0 deg  -> spreads sideways, not up
#       3 GAUSSIAN (typed by name) -> spreads both ways
#       4 MOTION at 90 deg -> spreads up, not sideways
#       5 FOLLOW MOVE (the X lane moves it 8px right from frame 4, the angle
#         lane still 90) -> spreads sideways: the move, not the angle
#   - the type lane's keys are holds (raw ease 4); saved, exported in batch
# Fixture: a 160x32 sheet of 32x32 frames, each a white 2x16 bar at (15,8).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=75 XSHEET_ROWS=SMALL
# =============================================================================
info "=== Animation: blur type / angle lanes ==="

BF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
BF_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
BF_DIR="/tmp/draw-qa-blurlanes-$$"
mkdir -p "$BF_DIR/home" "$BF_DIR/o"
BF_DRAW=()
for n in 0 1 2 3 4; do
    x=$(( n * 32 + 15 ))
    BF_DRAW+=(-fill '#ffffff' -draw "rectangle $x,8 $(( x + 1 )),23")
done
magick -size 160x32 xc:none "${BF_DRAW[@]}" "PNG32:$BF_DIR/plain.png"
python3 "$BF_PY" put "$BF_DIR/plain.png" "$BF_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,32,32,0,0,5,1,10,0,0).hex())")"

bf_line() { grep -m1 "^$1 " "$BF_DUMPF" 2>/dev/null; }
bf_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(bf_line ANIM)"
    XF=($(bf_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(bf_line ANIMXS)"
    XM=($(bf_line ANIMXLM))
    read -r _ XA_SLOT XA_Y _ <<< "$(bf_line ANIMXSLA)"
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(bf_line ANIMXSLO)"
    LLN="$(grep -m1 '^LLN [0-9]* [0-9]* 1 ' "$BF_DUMPF" 2>/dev/null | cut -d' ' -f5-)"
}
bf_s() { echo "lanes [${LLN}]"; }
bf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
bf_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
bf_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
bf_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
bf_pick() {
    local iy; iy=$(bf_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; key Escape; return 1; }
    bf_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); bf_read
}
bf_lane_y() { grep -m1 "^ANIMXSLN 1 $1 " "$BF_DUMPF" 2>/dev/null | cut -d' ' -f4; }
bf_add() { # LANE - + LANE > LANE
    bf_hclick "$(bf_fmid 1)" $(( XA_Y + XLH / 2 )); bf_read
    bf_pick $(( 31100 + $1 ))
}
bf_type() { wait_for 0.9 "input box"; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $1"; bf_read; }
bf_keyval() { # LANE FRAME VALUE - a key there, then its value typed
    local y; y=$(( $(bf_lane_y "$1") + XLH / 2 ))
    double_click "$(bf_fmid "$2")" "$y"; wait_for 0.6 "add key"; bf_read
    double_click "$(bf_fmid "$2")" "$y"; bf_type "$3"
}
bf_batch() {
    ( cd "$DRAW_ROOT" && HOME="$BF_DIR/home" XDG_CONFIG_HOME="$BF_DIR/home/.config" XDG_DATA_HOME="$BF_DIR/home/.local/share" \
      XDG_CACHE_HOME="$BF_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$@" </dev/null >>"$BF_DIR/batch.txt" 2>&1 )
}
bf_px() { magick "$1" -format "%[hex:p{$2,$3}]" info: 2>/dev/null | tr 'A-F' 'a-f'; } # RRGGBBAA

bf_alpha() { bf_px "$1" "$2" "$3" | cut -c7-8; }
bf_menu_at() { # LANE FRAME ITEM - the lane's menu on that frame, then an item
    right_click "$(bf_fmid "$2")" $(( $(bf_lane_y "$1") + XLH / 2 )); wait_for 0.6 "lane menu"; bf_read
    bf_pick "$3"
}

info "Launching DRAW with a 160x32 sheet of 32x32 frames (5, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$BF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
bf_key ctrl+0
bf_key KP_8
bf_read
if [[ "$A_COUNT" != 5 || -z "$XO_X" ]]; then
    fail "start: $A_COUNT frames, arrow '${XO_X:-}'"
else
    pass "a sheet of 5 frames, the X-sheet on"
    bf_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); bf_read
    # -- + LANE: BLUR TYPE / BLUR ANGLE right after BLUR --
    bf_hclick "$(bf_fmid 1)" $(( XA_Y + XLH / 2 )); bf_read
    BU=$(bf_item 31113); BT=$(bf_item 31117); BA=$(bf_item 31118); PX=$(bf_item 31114)
    if [[ -n "$BU" && -n "$BT" && -n "$BA" && -n "$PX" ]] && (( BU < BT && BT < BA && BA < PX )); then
        pass "+ LANE: BLUR, BLUR TYPE, BLUR ANGLE, then PIXELATE (y $BU $BT $BA $PX)"
    else fail "+ LANE order: BLUR '$BU' TYPE '$BT' ANGLE '$BA' PIXELATE '$PX' [${XM[*]}]"; fi
    key Escape; wait_for 0.3 "menu closed"; bf_read
    # every lane keyed on frame 1 at its default first (the + LANE click is on frame 1)
    bf_add 17; bf_add 13; bf_add 18; bf_add 1
    [[ "$LLN" =~ 1=0:0:0\ 13=0:0:0\ 17=0:0:4\ 18=0:0:0 ]] && pass "X, BLUR, BLUR TYPE (a hold), BLUR ANGLE keyed on frame 1" || fail "+ lanes: $(bf_s)"
    bf_keyval 13 2 6
    bf_menu_at 17 2 31242   # MOTION from frame 2
    bf_keyval 17 3 gauss    # GAUSSIAN from frame 3 (typed by name)
    bf_menu_at 17 4 31242   # MOTION from frame 4
    bf_menu_at 17 5 31245   # FOLLOW MOVE from frame 5
    bf_keyval 18 3 0
    bf_keyval 18 4 90
    bf_keyval 1 4 0
    bf_keyval 1 5 8
    if [[ "$LLN" =~ 13=0:0:0,1:6:0 && "$LLN" =~ 17=0:0:4,1:2:4,2:1:4,3:2:4,4:5:4 && "$LLN" =~ 18=0:0:0,2:0:0,3:90:0 && "$LLN" =~ 1=0:0:0,3:0:0,4:8:0 ]]; then
        pass "keys: BLUR 0/6, TYPE BOX/MOTION/GAUSSIAN/MOTION/FOLLOW, ANGLE 0/0/90, X 0/0/8"
    else fail "keys: $(bf_s)"; fi
    screenshot "blur-lanes"
    bf_key ctrl+z; bf_read
    [[ "$LLN" =~ 1=0:0:0,3:0:0,4:0:0\  ]] && pass "Ctrl+Z: the typed X value undone (the key stays at 0)" || fail "undo: $(bf_s)"
    bf_key ctrl+y; bf_read
    [[ "$LLN" =~ 1=0:0:0,3:0:0,4:8:0 ]] && pass "Ctrl+Y: back" || fail "redo: $(bf_s)"

    # -- saved, exported in batch --
    bf_key ctrl+s; wait_for 1.5 "saved"
    bf_batch "$BF_DIR/sheet.png" --export-anim "$BF_DIR/o/seq.png"
    F=(); for f in 1 2 3 4 5; do F+=("$(printf "$BF_DIR/o/seq_%04d.png" "$f")"); done
    # side: 3px left of the bar's middle row; up: 3px over its top, in the bar's column
    S1=$(bf_alpha "${F[0]}" 12 16); U1=$(bf_alpha "${F[0]}" 15 5)
    S2=$(bf_alpha "${F[1]}" 12 16); U2=$(bf_alpha "${F[1]}" 15 5)
    S3=$(bf_alpha "${F[2]}" 12 16); U3=$(bf_alpha "${F[2]}" 15 5)
    S4=$(bf_alpha "${F[3]}" 12 16); U4=$(bf_alpha "${F[3]}" 15 5)
    S5=$(bf_alpha "${F[4]}" 20 16); U5=$(bf_alpha "${F[4]}" 23 5) # (moved 8px right)
    M5=$(bf_alpha "${F[4]}" 23 16)
    info "alpha side/up: f1 $S1/$U1 f2 $S2/$U2 f3 $S3/$U3 f4 $S4/$U4 f5 $S5/$U5 (f5 bar $M5)"
    [[ "$S1" == 00 && "$U1" == 00 ]] && pass "frame 1 (BLUR 0): sharp" || fail "frame 1 not sharp: side $S1 up $U1"
    [[ -n "$S2" && "$S2" != 00 && "$U2" == 00 ]] && pass "frame 2 MOTION 0 deg: sideways only" || fail "frame 2 motion: side '$S2' up '$U2'"
    [[ -n "$S3" && "$S3" != 00 && -n "$U3" && "$U3" != 00 ]] && pass "frame 3 GAUSSIAN: both ways" || fail "frame 3 gaussian: side '$S3' up '$U3'"
    [[ "$S4" == 00 && -n "$U4" && "$U4" != 00 ]] && pass "frame 4 MOTION 90 deg: up only" || fail "frame 4 motion 90: side '$S4' up '$U4'"
    [[ -n "$S5" && "$S5" != 00 && "$U5" == 00 && -n "$M5" && "$M5" != 00 ]] && pass "frame 5 FOLLOW MOVE: along the move (sideways), not the 90 deg angle" || fail "frame 5 follow: side '$S5' up '$U5' bar '$M5' ($(ls "$BF_DIR/o" | tr '\n' ' ') | $(tail -2 "$BF_DIR/batch.txt" | tr '\n' ' '))"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$BF_DIR"
assert_window_exists
info "=== Animation: blur type / angle lanes: done ==="
