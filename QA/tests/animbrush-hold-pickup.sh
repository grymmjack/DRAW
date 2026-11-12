#!/bin/bash
# =============================================================================
# animbrush-hold-pickup.sh — QA test: hold the Brush key + select = pick up
# (TOOLS/ANIM-BRUSH AB_hold_pickup; Rick's planning handoff 2026-11-12,
# PLANS/ANIMATION.md round 3, item 1).
#
#   - a selection tool in hand, B held while a marquee is dragged: the selection
#     is picked up as an AnimBrush from EVERY frame (nothing selected) and the
#     tool becomes the Brush (ABRH 2)
#   - B tapped with a selection tool: the Brush tool, no brush (ABRH 3)
#   - frames 2-3 selected and tagged "walk": B + marquee picks up just those
#     two, and the brush is named walk (ABRN, the status badge)
#   - Shift+click stores it in a bin with its name (ABBN); Save Drawer Set
#     writes the name after the DSA1 records (ABN1); a relaunch loads it and
#     picking the bin names the brush again
#   - a picture without frames: B + marquee = a still brush (as Ctrl+B)
#
# Dump: ABR / ABRC / ABRN / ABRH (the brush), ABBIN / ABBN (bins), ANIMLB /
# ANIMLBP (strip, panes), VIEW (zoom, offset, tool).
# Fixture: a 64x16 sheet of 4 frames of 16x16, frame k has a 3x5 mark at 5,5.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== AnimBrush: hold B + select = pick up ==="

HP_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
HP_DIR="/tmp/draw-qa-abhold-$$"
mkdir -p "$HP_DIR"
HP_COLORS=(c04040 40c040 4040c0 c0c040)
HP_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 ))
    HP_DRAW+=(-fill "#${HP_COLORS[$n]}" -draw "rectangle $(( x + 5 )),5 $(( x + 7 )),5" -draw "rectangle $(( x + 5 )),6 $(( x + 5 )),9")
    (( n > 0 )) && HP_DRAW+=(-draw "point $(( x + 7 )),$(( 6 + n ))")
done
magick -size 64x16 xc:none "${HP_DRAW[@]}" "PNG32:$HP_DIR/plain.png"
magick "$HP_DIR/plain.png" -depth 8 "RGBA:$HP_DIR/plain.rgba"
HP_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$HP_PY" put "$HP_DIR/plain.png" "$HP_DIR/sheet.png" drAn "$HP_BLOB"

# the cels of the 3x5 box at 5,5 in frames 1-4 ("crc crc crc crc"), and the names block of a .dset
cat > "$HP_DIR/fx.py" <<'EOF'
import struct, sys, zlib
mode = sys.argv[1]
if mode == 'cels':
    raw = open(sys.argv[2], 'rb').read()
    def px(x, y):
        r, g, b, a = raw[(y * 64 + x) * 4:(y * 64 + x) * 4 + 4]
        return bytes((b, g, r, a)) if a else bytes(4)
    out = []
    for f in range(4):
        b = b''.join(px(f * 16 + 5 + x, 5 + y) for y in range(5) for x in range(3))
        out.append('0' if not any(b) else format(zlib.crc32(b), 'x'))
    print(' '.join(out))
elif mode == 'names':
    b = open(sys.argv[2], 'rb').read()
    p = b.find(b'ABN1')
    if p < 0: print('none'); sys.exit()
    p += 4; c, = struct.unpack_from('<h', b, p); p += 2; out = []
    for _ in range(c):
        i, ln = struct.unpack_from('<2h', b, p); p += 4
        out.append('%d:%s' % (i, b[p:p + ln].decode())); p += ln
    print(' '.join(out))
EOF
hp_fx() { python3 "$HP_DIR/fx.py" "$@"; }
HP_CELS=$(hp_fx cels "$HP_DIR/plain.rgba")
HP_C=($HP_CELS)

hp_line() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
hp_read() {
    dk_settle
    read -r _ AB_N AB_CUR AB_W AB_H _ _ AB_ON AB_BW AB_BH AB_BCRC <<< "$(hp_line ABR)"
    AB_CELS=$(hp_line ABRC | cut -d' ' -f2- | tr ' ' '\n' | cut -d: -f2 | tr '\n' ' ' | sed 's/ $//'); [[ "$(hp_line ABRC)" == "" ]] && AB_CELS=""
    AB_NAME=$(hp_line ABRN | cut -d' ' -f2-)
    read -r _ AB_HOLD _ <<< "$(hp_line ABRH)"
    BNAMES=$(grep -m1 '^ABBN' "$DK_DUMP" | cut -s -d' ' -f2-)
    read -r _ _ A_COUNT A_CUR _ <<< "$(hp_line ANIM)"
    read -r _ V_ZOOM V_OX V_OY V_TOOL _ <<< "$(hp_line VIEW)"
    read -r _ S_ON _ <<< "$(hp_line ANIMSEL)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(hp_line ANIMLB)"
    local p k; p=($(hp_line ANIMLBP)); PX=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
hp_s() { echo "brush n=${AB_N:-?} ${AB_W:-?}x${AB_H:-?} on=${AB_ON:-?} name '${AB_NAME:-}' hold ${AB_HOLD:-?} tool ${V_TOOL:-?} cels [${AB_CELS:-}] bin names [${BNAMES:-}]"; }
hp_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
hp_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
hp_launch() { # extra args
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$*"
    draw_launch 15
    wait_for 1.5 "loaded"
    assert_no_crash
    dk_begin
    hp_read
}
hp_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # cell pixel -> screen, current pane
hp_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
hp_sx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); } # strip frame -> screen
hp_sy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
hp_drag_box() { # X1 Y1 X2 Y2 (screen) - a marquee drag
    mouse_down "$1" "$2"; hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); sleep 0.2; hover "$3" "$4"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
}
hp_hold_box() { # X1 Y1 X2 Y2 (screen): B held through the marquee drag
    park_mouse
    raw_key down b; sleep 0.3
    hp_drag_box "$@"
    raw_key up b; wait_for 0.6 "B up"
}
# cel crc of the brush picked up from frames A..B ("crc crc")
hp_want() { local f o=""; for (( f = $1; f <= $2; f++ )); do o="$o ${HP_C[$(( f - 1 ))]}"; done; echo "${o# }"; }
# centre of bin $1 as it is laid out now; 1 = that row is not showing
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(hp_line DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(hp_line DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}

info "Launching with a 4-frame sheet"
hp_launch "$HP_DIR/sheet.png"
hp_key KP_0; hp_key KP_1; hp_read
if [[ "$A_COUNT" != 4 || -z "$PX" || "$LB_SHOWN" != -1 ]]; then
    fail "start: $A_COUNT frames, lightbox '$LB_SHOWN', pane '$PX' ($(hp_line ANIMLBP))"
else
    pass "4 frames, the lightbox on frame 1"

    # -- hold B + marquee, nothing selected: every frame --
    hp_key m; hp_read
    [[ "$V_TOOL" == 5 ]] || fail "M: tool $V_TOOL (wanted the marquee, 5)"
    hp_hold_box "$(hp_px 5)" "$(hp_py 5)" "$(hp_px 7)" "$(hp_py 9)"; hp_read
    [[ "$AB_HOLD" == 2 && "$AB_N" == 4 && "$AB_CELS" == "$HP_CELS" ]] && pass "B held through a marquee drag: picked up from all 4 frames" || fail "hold B pick up: $(hp_s), wanted [$HP_CELS]"
    [[ "$V_TOOL" == 1 && "$AB_ON" == -1 && "$S_ON" == 0 ]] && pass "the tool is the Brush, the brush is on, the marquee is gone" || fail "after the hold: tool $V_TOOL, brush $AB_ON, marquee $S_ON"
    [[ -z "$AB_NAME" ]] && pass "no tag: no name" || fail "name '$AB_NAME' without a tag"
    screenshot "abhold-picked"

    # -- tap B with the marquee: the Brush, nothing picked up --
    hp_key ctrl+b; hp_key m; hp_read
    [[ "$AB_N" == 0 && "$AB_ON" == 0 && "$V_TOOL" == 5 ]] || fail "before the tap: $(hp_s)"
    hp_key b; hp_read
    [[ "$AB_HOLD" == 3 && "$V_TOOL" == 1 && "$AB_ON" == 0 ]] && pass "B tapped with the marquee: the Brush tool, no brush" || fail "tap B: $(hp_s)"

    # -- B with another tool switches on the press as always --
    hp_key l; hp_key b; hp_read
    [[ "$V_TOOL" == 1 && "$AB_HOLD" == 3 ]] && pass "B with the Line tool: the Brush, as before (no hold armed)" || fail "B from Line: $(hp_s)"

    # -- frames 2-3 tagged walk: just those, named walk --
    click "$(hp_sx 2)" "$(hp_sy)"; wait_for 0.4 "strip 2"
    hp_read; with_mods shift click "$(hp_sx 3)" "$(hp_sy)"; wait_for 0.4 "strip shift 3"
    hp_cmd "tag frames"; type_text walk; wait_for 0.3 "typed"; key Return; wait_for 0.8 "Tag Frames box"
    grep -q "^ANIMTG 1 1 walk 2 3" "$DK_DUMP" && pass "frames 2-3 tagged walk (selected)" || fail "tag: $(hp_line ANIMTG)"
    hp_key m; hp_read
    hp_hold_box "$(hp_px 5)" "$(hp_py 5)" "$(hp_px 7)" "$(hp_py 9)"; hp_read
    [[ "$AB_N" == 2 && "$AB_CELS" == "$(hp_want 2 3)" ]] && pass "with the tag's frames selected: 2 cels, frames 2-3" || fail "tagged pick up: $(hp_s), wanted [$(hp_want 2 3)]"
    [[ "$AB_NAME" == walk ]] && pass "the brush is named after the tag: walk" || fail "name: '$AB_NAME'"

    # -- into bin 3 with its name; Save Drawer Set writes it --
    bin_xy 3 && { with_mods shift click "$BX" "$BY"; wait_for 0.6 "store"; }
    dk_park; hp_read
    [[ "$BNAMES" == "3:walk" ]] && pass "Shift+click stores it in bin 3, named walk" || fail "bin names: [$BNAMES]"
    hp_cmd "save drawer set"; wait_for 1.0 "the save dialog"
    for (( i = 0; i < 30; i++ )); do key BackSpace; done
    type_text "$HP_DIR/out.dset"; wait_for 0.3 "typed"; key Return; wait_for 1.5 "saved"
    GOT=$(hp_fx names "$HP_DIR/out.dset" 2>/dev/null)
    [[ "$GOT" == "3:walk" ]] && pass "Save Drawer Set writes the name after the AnimBrush records (ABN1 3:walk)" || fail "saved names: [${GOT:-no file}]"
fi

if [[ -f "$HP_DIR/out.dset" ]]; then
    info "Relaunching with the saved set"
    hp_launch "--option DEFAULT_DSET_BRUSHES_FILE=$HP_DIR/out.dset $HP_DIR/sheet.png"
    [[ "$BNAMES" == "3:walk" ]] && pass "the saved set loads bin 3 named walk" || fail "reloaded bin names: [$BNAMES]"
    bin_xy 3 && { click "$BX" "$BY"; wait_for 0.6 "pick bin 3"; }
    dk_park; hp_read
    [[ "$AB_N" == 2 && "$AB_NAME" == walk ]] && pass "picking bin 3: the AnimBrush walk, 2 cels" || fail "bin 3 picked: $(hp_s)"
fi

# -- a picture without frames: a still brush --
info "Opening a plain picture (no frames)"
hp_launch "$HP_DIR/plain.png"
hp_key m; hp_read
if [[ -z "$V_ZOOM" || "$V_ZOOM" -lt 100 ]]; then
    fail "plain picture view: '$(hp_line VIEW)'"
else
    cx() { echo $(( V_OX + $1 * V_ZOOM / 100 + V_ZOOM / 200 )); }
    cy() { echo $(( V_OY + $1 * V_ZOOM / 100 + V_ZOOM / 200 )); }
    hp_hold_box "$(cx 21)" "$(cy 5)" "$(cx 23)" "$(cy 9)"; hp_read
    [[ "$AB_HOLD" == 2 && "$AB_N" == 0 && "$AB_ON" == -1 && "$V_TOOL" == 1 ]] && pass "no frames: B + marquee = a still brush (${AB_BW}x$AB_BH), the Brush tool" || fail "plain picture: $(hp_s)"
fi

rm -rf "$HP_DIR"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== AnimBrush: hold B + select PASSED ==="
