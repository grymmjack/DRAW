#!/bin/bash
# =============================================================================
# anim-lightbox-clip.sh — QA test: copy / cut / paste frames (Animation 2.5,
# TOOLS/ANIM-OPS + the lightbox bar's COPY / PASTE / CUT).
#
# COPY puts the selected frames on the OS clipboard as one picture (a column
# per frame, a row per pixel layer, the "DRAWFRAMES1|w|h|frames|layers|id|holds"
# line in a header strip on top), so another DRAW window can paste them. PASTE inserts them as new
# frames after the selection; Shift+PASTE pastes over the frames from the
# first selected one (adding frames past the end). CUT = copy + delete. Each
# is one undo step; the pasted frames end up selected.
#
# Where the bar is too narrow for the three chips, the command palette runs
# the same actions. Dump: ANIM (count, current); ANIMC (a CRC per frame cell);
# ANIMLB / ANIMLBC (layout, control x / w); ANIMLBS (the selection).
# Fixture: a 64x32 sheet of 16x16 frames, 7 frames (each a different mark),
# current 3.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: copy / cut / paste frames ==="

LC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LC_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LC_DIR="/tmp/draw-qa-lbclip-$$"
mkdir -p "$LC_DIR"
LC_DRAW=()
LC_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    LC_DRAW+=(-fill "#${LC_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${LC_DRAW[@]}" "$LC_DIR/plain.png"
LC_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$LC_PY" put "$LC_DIR/plain.png" "$LC_DIR/sheet.png" drAn "$LC_BLOB"

lc_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lc_line() { grep -m1 "^$1 " "$LC_DUMP" 2>/dev/null; }
lc_read() { # A_COUNT A_CUR, T[1..] A_T, LB_*, C_X[k] C_W[k], S_N S_SEL
    lc_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(lc_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lc_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(lc_line ANIMLB)"
    local c k; c=($(lc_line ANIMLBC)); C_X=(); C_W=()
    for k in $(seq 1 14); do C_X[$k]=${c[$((2 * k - 1))]:-0}; C_W[$k]=${c[$((2 * k))]:-0}; done
    read -r _ _ _ _ S_N S_SEL <<< "$(lc_line ANIMLBS)"
    S_SEL="${S_SEL:-}"
}
lc_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); } # strip cell centre x of frame F
lc_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
lc_view() { # A B - wheel the strip until frames A..B are all in view
    local i
    lc_read
    for i in $(seq 1 12); do
        if (( $1 < LB_SF )); then scroll_up "$(lc_cx "$LB_SF")" "$(lc_cy)"
        elif (( $2 > LB_SF + LB_SN - 1 )); then scroll_down "$(lc_cx "$LB_SF")" "$(lc_cy)"
        else return 0; fi
        wait_for 0.3 "wheel"; lc_read
    done
    info "lc_view $1 $2: strip stuck at $LB_SF+$LB_SN"
}
lc_select() { # A [B] - click frame A in the strip, Shift+click B
    lc_view "$1" "${2:-$1}"
    click "$(lc_cx "$1")" "$(lc_cy)"; wait_for 0.4 "strip frame $1"
    if [[ -n "${2:-}" ]]; then with_mods shift click "$(lc_cx "$2")" "$(lc_cy)"; wait_for 0.4 "shift strip frame $2"; fi
    lc_read
}
lc_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
lc_palette() { # run a command by name through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.8 "$1"
}
lc_do() { # copy | paste | over | cut - the bar's chip when shown, else the palette
    local k
    case "$1" in copy) k=11 ;; paste|over) k=12 ;; cut) k=13 ;; esac
    lc_read
    if (( C_W[k] > 0 )); then
        if [[ "$1" == over ]]; then with_mods shift click $(( C_X[k] + C_W[k] / 2 )) $(( LB_BY + LB_BH / 2 ))
        else click $(( C_X[k] + C_W[k] / 2 )) $(( LB_BY + LB_BH / 2 )); fi
        wait_for 0.8 "bar $1"
    else
        case "$1" in
            copy) lc_palette "copy frames" ;;
            paste) lc_palette "paste frames as new" ;;
            over) lc_palette "paste frames over" ;;
            cut) lc_palette "cut frames" ;;
        esac
    fi
    lc_read
}
lc_order() { # the T0 frame number now in each cell ("?" = none matches)
    local b=(x $LC_T0) out="" i j hit
    for i in $(seq 1 "$A_COUNT"); do
        hit="?"; for j in $(seq 1 7); do [[ "${T[$i]}" == "${b[$j]}" ]] && { hit=$j; break; }; done
        out+="$hit "
    done
    echo "${out% }"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LC_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
lc_key KP_0
lc_read
LC_T0="$A_T"
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 7 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames"
else
    pass "lightbox shown, 7 frames"
    (( C_W[11] > 0 )) && info "the bar shows COPY / PASTE / CUT" || info "COPY / PASTE / CUT are dropped at this width - the command palette runs them"

    # -- copy 2-3 --
    lc_select 2 3
    [[ "$S_SEL" == "2 3" ]] || info "selected '$S_SEL' (wanted 2 3)"
    lc_do copy
    [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "COPY changes nothing" || fail "COPY: $A_COUNT frames, order $(lc_order)"
    if [[ -n "${QA_IN_XVFB:-}" ]] && command -v xclip >/dev/null; then # offscreen only: never the user's own clipboard
        timeout 3 xclip -selection clipboard -o -t image/png > "$LC_DIR/clip.png" 2>/dev/null
        LC_SZ=$(identify -format '%wx%h' "$LC_DIR/clip.png" 2>/dev/null)
        LC_TXT=$(magick "$LC_DIR/clip.png" -alpha off -depth 8 rgb:- 2>/dev/null | python3 -c '
import sys; b = sys.stdin.buffer.read()
if b[:3] == b"DF1": n = b[3] * 256 + b[4]; print(b[6:6 + n].decode("latin-1"))')
        [[ "$LC_SZ" == 32x17 ]] && pass "the clipboard picture another window reads: 32x16 frames + a 1-row header" || fail "clipboard picture: '${LC_SZ:-none}' (wanted 32x17)"
        [[ "$LC_TXT" == DRAWFRAMES1\|16\|16\|2\|1\|*\|1,1 ]] && pass "its header: 2 frames of 16x16, 1 layer, holds 1,1" || fail "clipboard header: '${LC_TXT:0:60}'"
    fi

    # -- paste as new after frame 5 --
    lc_select 5
    lc_do paste
    [[ "$A_COUNT" == 9 && "$(lc_order)" == "1 2 3 4 5 2 3 6 7" ]] && pass "PASTE after frame 5: 1 2 3 4 5 [2 3] 6 7" || fail "PASTE: $A_COUNT frames, order $(lc_order)"
    [[ "$A_CUR" == 6 && "$S_SEL" == "6 7" ]] && pass "the pasted frames are selected, the first current" || fail "after PASTE: current $A_CUR, selected '$S_SEL'"
    lc_key ctrl+z; lc_read
    [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "undo: one step, the 7 frames back" || fail "undo PASTE: $A_COUNT frames, order $(lc_order)"

    # -- paste over frames 6-7, then over 7 (one frame past the end) --
    lc_select 6
    lc_do over
    [[ "$A_COUNT" == 7 && "$(lc_order)" == "1 2 3 4 5 2 3" ]] && pass "Shift+PASTE over 6: 1 2 3 4 5 [2 3]" || fail "PASTE over 6: $A_COUNT frames, order $(lc_order)"
    lc_key ctrl+z; lc_read
    [[ "$A_T" == "$LC_T0" ]] && pass "undo: frames 6-7 back" || fail "undo PASTE over: order $(lc_order)"
    lc_select 7
    lc_do over
    [[ "$A_COUNT" == 8 && "$(lc_order)" == "1 2 3 4 5 6 2 3" ]] && pass "PASTE over 7: one frame added past the end" || fail "PASTE over 7: $A_COUNT frames, order $(lc_order)"
    lc_key ctrl+z; lc_read
    [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "undo: 7 frames" || fail "undo PASTE over 7: $A_COUNT frames, order $(lc_order)"

    # -- cut 2-3 --
    lc_select 2 3
    lc_do cut
    [[ "$A_COUNT" == 5 && "$(lc_order)" == "1 4 5 6 7" && "$A_CUR" == 2 ]] && pass "CUT 2-3: 1 4 5 6 7, on frame 2" || fail "CUT: $A_COUNT frames, order $(lc_order), current $A_CUR"
    lc_select 5
    lc_do paste
    [[ "$A_COUNT" == 7 && "$(lc_order)" == "1 4 5 6 7 2 3" ]] && pass "the cut frames paste back: 1 4 5 6 7 [2 3]" || fail "PASTE the cut frames: $A_COUNT frames, order $(lc_order)"
    lc_key ctrl+z; lc_key ctrl+z; lc_read
    [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "undo twice: the paste, then the cut" || fail "undo PASTE + CUT: $A_COUNT frames, order $(lc_order)"

    # -- another window's frames (a picture with the header, served by xclip) --
    if [[ -n "${QA_IN_XVFB:-}" ]] && command -v xclip >/dev/null; then
        python3 -c '
import sys
m = b"DRAWFRAMES1|16|16|1|1|99.1.1|3"; w = 16
hdr = b"DF1" + bytes([len(m) >> 8, len(m) & 255, 1]) + m
hdr += bytes(w * 3 - len(hdr))
px = b"".join(hdr[i:i + 3] + b"\xff" for i in range(0, w * 3, 3))
px += b"".join((b"\x20\xd0\xf0\xff" if 3 <= x < 13 and 4 <= y < 12 else b"\0\0\0\0") for y in range(16) for x in range(16))
sys.stdout.buffer.write(px)' | magick -size 16x17 -depth 8 rgba:- "PNG32:$LC_DIR/foreign.png" # RGBA as DRAW writes it ([Linux] QB64-PE misreads a palette PNG with tRNS off the clipboard)
        timeout 3 xclip -selection clipboard -t image/png -i "$LC_DIR/foreign.png" 2>/dev/null
        lc_select 1
        lc_do paste
        [[ "$A_COUNT" == 8 && "$(lc_order)" == "1 ? 2 3 4 5 6 7" && "${T[2]}" != 0 ]] && pass "another window's frame pastes in as frame 2" || fail "paste from another window: $A_COUNT frames, order $(lc_order), frame 2 '${T[2]:-}'"
        lc_key ctrl+z; lc_read
        [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "undo: 7 frames" || fail "undo the foreign paste: $A_COUNT frames"
    fi

    # -- something else on the clipboard: nothing to paste --
    if [[ -n "${QA_IN_XVFB:-}" ]] && command -v xclip >/dev/null; then # offscreen only: never the user's own clipboard
        printf 'not frames' | timeout 3 xclip -selection clipboard -i 2>/dev/null
        lc_select 3
        lc_do paste
        [[ "$A_COUNT" == 7 && "$A_T" == "$LC_T0" ]] && pass "other text on the clipboard: PASTE adds nothing" || fail "PASTE with other text on the clipboard: $A_COUNT frames, order $(lc_order)"
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LC_DIR"
assert_window_exists
