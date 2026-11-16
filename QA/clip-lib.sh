#!/bin/bash
# =============================================================================
# clip-lib.sh - helpers for the clip layer tests (TOOLS/CLIP). Source it from a
# test (after the harness has set DRAW_ROOT / DRAW_BIN). It makes the fixture
# - a 96x16 .draw of 6 frames of 16x16, frame k a 4x4 square of its own colour
# at (6, 6) with a white top-left pixel - in CL_DIR, and reads the dump lines
# CLIPP / CLIP / CLIPC / CLIPX / CLIPS / ANIMP / ANIMPM / ANIMPC.
# =============================================================================
CL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
CL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
CL_DIR="$(mktemp -d /tmp/draw-qa-clip-XXXXXX)"
mkdir -p "$CL_DIR/home" "$CL_DIR/o"
CL_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
CL_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 ))
    CL_DRAW+=(-fill "#${CL_COLORS[$n]}" -draw "rectangle $(( x + 6 )),6 $(( x + 9 )),9" -fill white -draw "point $(( x + 6 )),6")
done
magick -size 96x16 xc:none "${CL_DRAW[@]}" "PNG32:$CL_DIR/plain.png"
python3 "$CL_PY" put "$CL_DIR/plain.png" "$CL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,12,0,0).hex())")"
cl_batch() { # IN ARGS... - a fresh DRAW (throwaway HOME, no window)
    local in=$1; shift
    ( cd "$DRAW_ROOT" && HOME="$CL_DIR/home" XDG_CONFIG_HOME="$CL_DIR/home/.config" XDG_DATA_HOME="$CL_DIR/home/.local/share" \
      XDG_CACHE_HOME="$CL_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null >>"$CL_DIR/batch.txt" 2>&1 )
}
cl_batch "$CL_DIR/sheet.png" --export "$CL_DIR/clip.draw"

cl_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
cl_line() { grep -m1 "^$1 " "$CL_DUMPF" 2>/dev/null; }
cl_read() {
    cl_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(cl_line ANIM)"
    read -r _ AB_N AB_CUR AB_W AB_H _ <<< "$(cl_line ABR)"
    read -r _ CP_PLACING CP_CUR _ <<< "$(cl_line CLIPP)"
    C_LINE=$(cl_line CLIP | cut -d' ' -f3-)          # src in out start every MODE fx fy px py
    read -r C_SLOT <<< "$(cl_line CLIP | cut -d' ' -f2)"
    read -r C_SRC C_IN C_OUT C_START C_EVERY C_MODE C_FX C_FY C_PX C_PY _ <<< "$C_LINE"
    C_CELS=$(cl_line CLIPC | cut -d' ' -f3)
    C_PIX=$(cl_line CLIPX | cut -d' ' -f3-)
    C_SRCS=$(cl_line CLIPS | cut -d' ' -f2-)
    read -r _ P_VIS P_DOCK P_X P_Y P_W P_H P_SC _ <<< "$(cl_line ANIMP)"
    read -r _ PM_ON PM_Y1 PM_Y2 PM_Y3 PM_Y4 PM_Y5 PM_Y6 PM_Y7 PM_Y8 PM_Y9 PM_Y10 PM_S1 PM_S2 PM_S3 PM_VW _ <<< "$(cl_line ANIMPM)"
    read -r _ PC_ON _ <<< "$(cl_line ANIMPC)"
    read -r _ _ _ _ _ _ _ _ _ L_RH _ _ _ L_PAD L_PW _ <<< "$(cl_line ANIMPL)"
    local p k; p=($(cl_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
cl_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} CLIP [${C_LINE:-}] cels [${C_CELS:-}] placing ${CP_PLACING:-?} current ${CP_CUR:-?}"; }
cl_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }   # cell px -> viewport (16 px cells)
cl_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
cl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
cl_cmd() { # never type unless the palette is open: the query would go in as hotkeys
    local try ok=0
    for try in 1 2 3; do
        park_mouse; key question; wait_for 1.0 "Command palette"
        grep -q '^POPUP cmdpalette' "$CL_DUMPF" 2>/dev/null && { ok=1; break; }
        cl_settle; grep -q '^POPUP cmdpalette' "$CL_DUMPF" 2>/dev/null && { ok=1; break; }
        info "the palette did not open - again"
    done
    (( ok )) || { info "no palette for '$1'"; return 1; }
    type_text "$1"; wait_for "$(awk -v n=${#1} 'BEGIN{printf "%.1f", 0.6 + n * 0.08}')" "Filtered"
    key Return; wait_for 1.0 "$1"
}
cl_strip() { # F [shift] - click frame F in the lightbox strip
    local x1 sy sf cw ch pad
    read -r _ _ x1 _ _ _ sy _ _ _ _ _ sf _ cw ch _ _ _ pad _ <<< "$(cl_line ANIMLB)"
    local x=$(( x1 + pad + ($1 - sf) * (cw + pad) + cw / 2 )) y=$(( sy + pad + ch / 2 ))
    if [[ "${2:-}" == shift ]]; then with_mods shift click "$x" "$y"; else click "$x" "$y"; fi
    wait_for 0.4 "strip $1"
}
cl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
cl_box() { # ROW SLOT -> viewport middle of a panel number box
    cl_read
    local y="PM_Y$1" s="PM_S$2"
    echo "$(( P_X + (${!s} + PM_VW / 2) * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
cl_chip() { # ROW K N - chip K (0-based) of N across the row
    cl_read
    local y="PM_Y$1" w x
    w=$(( (L_PW - 2 * L_PAD - 2 * ($3 - 1)) / $3 ))
    x=$(( L_PAD + $2 * (w + 2) + w / 2 ))
    echo "$(( P_X + x * P_SC / 100 )) $(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
}
cl_type() { # ROW SLOT TEXT
    local x y; read -r x y <<< "$(cl_box "$1" "$2")"
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"
}
cl_set() { # ROW SLOT TEXT VAR - type, read back, once more if it did not take
    cl_type "$1" "$2" "$3"; cl_read
    [[ "${!4}" == "$3" ]] || { info "box $1/$2 is '${!4}', not $3 - again"; cl_type "$1" "$2" "$3"; cl_read; }
}
cl_tap() { local x y; read -r x y <<< "$(cl_chip "$@")"; cl_hclick "$x" "$y"; }
# the CLIPX line wanted: CELS (".12341") at cell (X, Y), flipped in X or not
cl_want_px() { # CELS X Y FLIPX
    local f c out="" tl tr col
    for (( f = 1; f <= ${#1}; f++ )); do
        c=${1:$((f - 1)):1}
        if [[ "$c" == . ]]; then out+=" $f:-"; continue; fi
        col=${CL_COLORS[$(( c + 1 ))]}
        if [[ "$4" == 0 ]]; then tl=ffffff; tr=$col; else tl=$col; tr=ffffff; fi
        out+=" $f:$2:$3:4:4:$tl:$tr"
    done
    echo "${out# }"
}
cl_expect() { # CELS X Y FLIPX LABEL - the clip's cels and its pixels
    cl_read
    local want; want=$(cl_want_px "$1" "$2" "$3" "$4")
    if [[ "$C_CELS" == "$1" && "$C_PIX" == "$want" ]]; then pass "$5"
    else fail "$5: cels [$C_CELS] want [$1]; pixels [$C_PIX] want [$want]; $(cl_s)"; fi
}


# sheet view (lightbox off): canvas px -> viewport (VIEW zoom%; ANIM ... drawn dx dy = the
# canvas's top left in the viewport)
cl_view() { read -r _ V_ZOOM _ _ V_TOOL _ <<< "$(cl_line VIEW)"; read -r _ _ _ _ _ _ _ _ _ _ _ _ _ V_OX V_OY _ <<< "$(cl_line ANIM)"; }
cl_cx() { cl_view; echo $(( V_OX + ($1 * V_ZOOM + V_ZOOM / 2) / 100 )); }
cl_cy() { cl_view; echo $(( V_OY + ($1 * V_ZOOM + V_ZOOM / 2) / 100 )); }
# layer panel row N (1 = top): viewport middle (16 px header, 20 px rows)
cl_row_y() { echo $(( 16 + ($1 - 1) * 20 + 10 )); }

# Launch on the fixture, pick up frames 3-6 as a 4-cel AnimBrush and place it
# as a clip in frame 2 at (6, 6) of the cell. Lightbox on. CL_OK=1 when it worked.
cl_setup() {
    CL_OK=0
    [[ -s "$CL_DIR/clip.draw" ]] || { fail "no .draw fixture: $(tail -3 "$CL_DIR/batch.txt" | tr '\n' ' ')"; return 1; }
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="${CL_EXTRA:+$CL_EXTRA }$CL_DIR/clip.draw" # CL_EXTRA: more launch args (--option ...)
    draw_launch 15
    wait_for 1.5 "Sheet loaded"
    assert_no_crash
    park_mouse
    cl_key KP_0
    cl_read
    [[ "$A_COUNT" == 6 && -n "${PX:-}" && -n "${CP_PLACING:-}" ]] || { fail "lightbox: $A_COUNT frames, current pane '${PX:-}', CLIPP '${CP_PLACING:-}'"; return 1; }
    cl_strip 6; cl_strip 3 shift; cl_read
    cl_key m
    mouse_down "$(cl_px 6)" "$(cl_py 6)"; hover "$(cl_px 8)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 9)" "$(cl_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    cl_cmd "animbrush: pick up (the"; cl_read
    [[ "$AB_N" == 4 && "$AB_W" == 4 && "$AB_H" == 4 ]] || { fail "pick up: n $AB_N ${AB_W}x$AB_H"; return 1; }
    cl_key ctrl+d
    cl_strip 2; cl_read
    cl_cmd "clip layer: place"; cl_read
    click "$(cl_px 8)" "$(cl_py 8)"; wait_for 0.6 "placed"
    cl_read
    [[ "$C_LINE" == "1 2 0 1 1 LOOP 0 0 6 6" ]] || { fail "place: $(cl_s)"; return 1; }
    CL_OK=1
}
cl_done() { # back to a default DRAW for the next test
    rm -rf "$CL_DIR"
    draw_quit
    DRAW_EXTRA_ARGS=""
    draw_launch 15
    wait_for 0.8 "Default instance restored"
    assert_window_exists
}
