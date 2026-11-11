#!/bin/bash
# =============================================================================
# animbrush-pickup.sh — QA test: AnimBrush pick up (TOOLS/ANIM-BRUSH, A1).
#
# ANIM > AnimBrush > Pick Up takes the marquee's area from several frames -
# the same spot in each frame's cell, measured from the frame the selection
# is in - as the cels of a custom brush; the brush shows cel 1 and the tool
# becomes the Brush. Which frames: the frames selected in the strip (2 or
# more), else the selection's frame to the last. Pick Up takes the current layer; Pick Up
# Merged every visible layer. Ctrl+B drops it (one picture again).
#
# Dump: ABR n cur w h merged srcFrame active brushW brushH brushCrc,
#       ABRC frame:crc per cel (CRC32 of the cel's BGRA pixels, 0 = clear),
#       ANIMSEL (the marquee box), ANIMLB / ANIMLBP (strip, panes), VIEW (tool).
# Fixture: a 76x40 sheet of 16x16 frames with a 2 px gutter and a 3 px margin
# (4 columns, 8 frames), transparent; frame k has marks of its own colour and
# size - so a cel read from the wrong place (gutter / margin) shows in its CRC.
# The expected CRCs are worked out here from the fixture and the box.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== AnimBrush: pick up ==="

AB_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AB_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
AB_DIR="/tmp/draw-qa-abpick-$$"
mkdir -p "$AB_DIR"
AB_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020 8020e0)
AB_DRAW=()
for n in 0 1 2 3 4 5 6 7; do
    cx=$(( 3 + (n % 4) * 18 )); cy=$(( 3 + (n / 4) * 18 ))
    AB_DRAW+=(-fill "#${AB_COLORS[$n]}" -draw "rectangle $(( cx + 2 )),$(( cy + 2 )) $(( cx + 3 + n )),$(( cy + 9 ))")
    AB_DRAW+=(-fill "#${AB_COLORS[$(( (n + 3) % 8 ))]}" -draw "rectangle $(( cx + 10 )),$(( cy + 4 + n )) $(( cx + 13 )),$(( cy + 5 + n ))")
done
# the gutters and margins hold a colour of their own: a cel that reads them shows it
AB_DRAW+=(-fill '#808080' -draw "rectangle 0,0 75,1" -draw "rectangle 19,0 20,39")
magick -size 76x40 xc:none "${AB_DRAW[@]}" "PNG32:$AB_DIR/plain.png"
magick "$AB_DIR/plain.png" -depth 8 "RGBA:$AB_DIR/plain.rgba"
AB_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,2,3,8,1,12,0,0).hex())")
python3 "$AB_PY" put "$AB_DIR/plain.png" "$AB_DIR/sheet.png" drAn "$AB_BLOB"

# expected "frame:crc ..." for box BX BY BW BH picked up in frame SF from FRAMES...
cat > "$AB_DIR/exp.py" <<'EOF'
import sys, zlib
W, H, G, M, FW = 76, 40, 2, 3, 16
raw = open(sys.argv[1], 'rb').read()
bx, by, bw, bh, sf = map(int, sys.argv[2:7])
frames = [int(f) for f in sys.argv[7:]]
cell = lambda n: (M + ((n - 1) % 4) * (FW + G), M + ((n - 1) // 4) * (FW + G))
sx, sy = cell(sf)
out = []
for f in frames:
    fx, fy = cell(f)
    b = bytearray()
    for py in range(bh):
        for px in range(bw):
            x, y = bx + px + fx - sx, by + py + fy - sy
            if 0 <= x < W and 0 <= y < H:
                r, g, bb, a = raw[(y * W + x) * 4:(y * W + x) * 4 + 4]
                b += bytes((bb, g, r, a)) if a else bytes(4)
            else:
                b += bytes(4)
    out.append('%d:%s' % (f, '0' if not any(b) else format(zlib.crc32(bytes(b)), 'x')))
print(' '.join(out))
EOF
ab_exp() { python3 "$AB_DIR/exp.py" "$AB_DIR/plain.rgba" "$@"; }

ab_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
ab_line() { grep -m1 "^$1 " "$AB_DUMPF" 2>/dev/null; }
ab_read() {
    ab_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(ab_line ANIM)"
    read -r _ S_ON S_X S_Y S_W S_H _ <<< "$(ab_line ANIMSEL)"
    read -r _ AB_N AB_CUR AB_W AB_H AB_MERGED AB_SF AB_ON AB_BW AB_BH AB_BCRC <<< "$(ab_line ABR)"
    AB_CELS=$(ab_line ABRC | cut -d' ' -f2-); [[ "$(ab_line ABRC)" == "ABRC" ]] && AB_CELS=""
    read -r _ _ _ _ V_TOOL _ <<< "$(ab_line VIEW)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(ab_line ANIMLB)"
    local p k; p=($(ab_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
ab_s() { echo "ABR n=${AB_N:-?} cur=${AB_CUR:-?} ${AB_W:-?}x${AB_H:-?} merged=${AB_MERGED:-?} from=${AB_SF:-?} brush=${AB_ON:-?} ${AB_BW:-?}x${AB_BH:-?} crc=${AB_BCRC:-?} cels [${AB_CELS:-}]"; }
ab_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); }
ab_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
ab_pick() { # F [ctrl] - click frame F in the strip
    ab_read
    if [[ "${2:-}" == ctrl ]]; then with_mods ctrl click "$(ab_cx "$1")" "$(ab_cy)"; else click "$(ab_cx "$1")" "$(ab_cy)"; fi
    wait_for 0.4 "strip frame $1"; ab_read
}
ab_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # screen x / y of cell pixel (CX, CY) in the current pane
ab_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
ab_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ab_cmd() { # run a command by name through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
ab_marquee() { # X1 Y1 X2 Y2 (cell px in the current pane)
    ab_key m
    mouse_down "$(ab_px "$1")" "$(ab_py "$2")"
    hover "$(ab_px $(( ($1 + $3) / 2 )))" "$(ab_py $(( ($2 + $4) / 2 )))"; sleep 0.2
    hover "$(ab_px "$3")" "$(ab_py "$4")"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"; ab_read
}
# the first cel's CRC (the brush shows cel 1)
ab_first_crc() { local t=${1%% *}; echo "${t#*:}"; }

info "Launching DRAW with a 76x40 sheet: 8 frames of 16x16, gutter 2, margin 3"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AB_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
ab_key KP_0
ab_read
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 8 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 8 frames, current $A_CUR"

    # -- no selection: nothing picked up --
    ab_cmd "animbrush: pick up (the"; ab_read
    [[ "${AB_N:-x}" == 0 && "$AB_ON" == 0 ]] && pass "no selection: Pick Up does nothing ($(ab_s))" || fail "no selection: $(ab_s)"

    # -- frame 3, a box inside its cell: frames 3..8 --
    ab_pick 3
    ab_marquee 1 1 12 12
    if [[ "$S_ON" != -1 || "$A_CUR" != 3 ]]; then
        fail "marquee in frame 3: sel $S_ON at $S_X,$S_Y ${S_W}x$S_H, current $A_CUR"
    else
        BX=$S_X; BY=$S_Y; BW=$S_W; BH=$S_H
        info "box $BX,$BY ${BW}x$BH in frame 3"
        WANT=$(ab_exp "$BX" "$BY" "$BW" "$BH" 3 3 4 5 6 7 8)
        ab_cmd "animbrush: pick up (the"; ab_read
        [[ "$AB_N" == 6 && "$AB_CUR" == 1 && "$AB_SF" == 3 && "$AB_MERGED" == 0 ]] && pass "Pick Up from frame 3: 6 cels (frames 3-8), cel 1 shown" || fail "pick up from frame 3: $(ab_s)"
        [[ "$AB_CELS" == "$WANT" ]] && pass "each cel is the box's spot in its frame's cell (gutter + margin skipped)" || fail "cels [$AB_CELS], wanted [$WANT]"
        [[ "$AB_W" == "$BW" && "$AB_H" == "$BH" && "$AB_BW" == "$BW" && "$AB_BH" == "$BH" ]] && pass "cels and brush are the box's size (${BW}x$BH)" || fail "size: $(ab_s), box ${BW}x$BH"
        [[ "$AB_ON" == -1 && "$AB_BCRC" == "$(ab_first_crc "$WANT")" ]] && pass "the brush is on and shows cel 1" || fail "brush: $(ab_s)"
        [[ "$V_TOOL" == 1 ]] && pass "the tool is the Brush" || fail "tool $V_TOOL after Pick Up"
        [[ "$S_ON" == 0 ]] && pass "the marquee is gone (as Ctrl+B)" || fail "the marquee stayed: $S_ON"
        screenshot "animbrush-picked"
        # distinct pictures: no two cels alike (the fixture's frames all differ)
        U=$(tr ' ' '\n' <<< "$AB_CELS" | cut -d: -f2 | sort -u | wc -l)
        [[ "$U" == 6 ]] && pass "6 different cels" || fail "only $U different cels"

        # -- Ctrl+B: the brush goes, cels and all --
        ab_key ctrl+b; ab_read
        [[ "$AB_N" == 0 && "$AB_ON" == 0 && -z "$AB_CELS" ]] && pass "Ctrl+B drops the AnimBrush" || fail "after Ctrl+B: $(ab_s)"
    fi

    # -- the frames selected in the strip: 2, 4, 6 (current 6) --
    ab_pick 2; ab_pick 4 ctrl; ab_pick 6 ctrl
    ab_marquee 0 3 9 14
    if [[ "$S_ON" != -1 || "$A_CUR" != 6 ]]; then
        fail "marquee in frame 6: sel $S_ON, current $A_CUR"
    else
        BX=$S_X; BY=$S_Y; BW=$S_W; BH=$S_H
        WANT=$(ab_exp "$BX" "$BY" "$BW" "$BH" 6 2 4 6)
        ab_cmd "animbrush: pick up (the"; ab_read
        [[ "$AB_N" == 3 && "$AB_SF" == 6 && "$AB_CELS" == "$WANT" ]] && pass "selected frames 2, 4, 6: 3 cels in strip order from each frame's cell" || fail "selected frames: $(ab_s), wanted [$WANT]"
        [[ "$AB_BCRC" == "$(ab_first_crc "$WANT")" ]] && pass "the brush shows cel 1 (frame 2's)" || fail "brush crc $AB_BCRC"
        ab_key ctrl+b; ab_read
    fi

    # -- the last frame alone: one cel; a box partly in the margin keeps clear there --
    ab_pick 1; ab_key KP_9; ab_read
    ab_marquee 0 0 15 15
    if [[ "$S_ON" == -1 && "$A_CUR" == 8 ]]; then
        BX=$S_X; BY=$S_Y; BW=$S_W; BH=$S_H
        WANT=$(ab_exp "$BX" "$BY" "$BW" "$BH" 8 8)
        ab_cmd "animbrush: pick up (the"; ab_read
        [[ "$AB_N" == 1 && "$AB_CELS" == "$WANT" ]] && pass "the last frame: one cel ($WANT)" || fail "last frame: $(ab_s), wanted [$WANT]"
        ab_key ctrl+b; ab_read
    else
        fail "marquee in frame 8: sel $S_ON, current $A_CUR"
    fi

    # -- an empty layer: Pick Up = clear cels; Pick Up Merged = the drawing --
    ab_key ctrl+shift+n; ab_read
    ab_key KP_1; ab_read
    ab_marquee 2 2 13 13
    BX=$S_X; BY=$S_Y; BW=$S_W; BH=$S_H
    ab_cmd "animbrush: pick up (the"; ab_read
    Z=$(tr ' ' '\n' <<< "$AB_CELS" | cut -d: -f2 | sort -u | tr '\n' ' ')
    [[ "$AB_N" == 8 && "$Z" == "0 " ]] && pass "an empty layer: 8 clear cels (frames 1-8)" || fail "empty layer: $(ab_s)"
    ab_key ctrl+b
    ab_marquee 2 2 13 13
    WANT=$(ab_exp "$BX" "$BY" "$BW" "$BH" 1 1 2 3 4 5 6 7 8)
    ab_cmd "animbrush: pick up merged"; ab_read
    [[ "$AB_N" == 8 && "$AB_MERGED" == -1 && "$AB_CELS" == "$WANT" ]] && pass "Pick Up Merged: the drawing under the empty layer" || fail "merged: $(ab_s), wanted [$WANT]"
    screenshot "animbrush-merged"
fi
rm -rf "$AB_DIR"
assert_window_exists
info "=== AnimBrush: pick up PASSED ==="
