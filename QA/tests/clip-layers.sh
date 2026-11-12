#!/bin/bash
# =============================================================================
# clip-layers.sh — QA test: clip layers, phase 1 (PLANS/CLIP-LAYERS.md,
# TOOLS/CLIP).
#
#   - Place AnimBrush as Clip: click in a frame; a new layer above, the clip's
#     cel 1 in the frame you click in (Q3), to the last frame; the Animation
#     panel opens on its clip rows
#   - modes LOOP / PING / ONCE (gone after the last cel, Q2) / HOLD / REV;
#     one undo step each
#   - the panel's boxes (typed): IN, OUT, START, EVERY, X; FLIP X
#   - the paint tools are refused on a clip layer (Q4): its pixels stay
#   - the Move tool drags the clip (every frame), one undo step; an arrow
#     key nudges it
#   - frame ops: the clip layer stays put, its In / Out follow the frames
#     (insert before, delete), undo puts them back
#   - Bake Clip to Pixels: a plain layer; undo brings the clip back
#   - Ctrl+S writes the drCl chunk; a reload has the same clip; the batch
#     export (a fresh DRAW) has the clip's pixels in its frames
#
# Dump: CLIPP placing current; CLIP slot src in out start every MODE flipX
# flipY px py; CLIPC slot cels ("." none); CLIPX slot f:x:y:w:h:TL:TR (the
# clip's pixels in each frame's cell); CLIPS src n cw ch name; ANIMP / ANIMPM /
# ANIMPC (the panel's clip rows use the Move rows' places).
# Fixture: a 96x16 sheet of 6 frames of 16x16, saved as a .draw; frame k a
# 4x4 square of its own colour at (6, 6) with a white top-left pixel. The
# clip's 4 cels are picked up from frames 3-6 (cel c = frame c + 2).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers ==="

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

info "Launching DRAW with a .draw sheet of 6 frames of 16x16"
[[ -s "$CL_DIR/clip.draw" ]] || fail "no .draw fixture: $(tail -3 "$CL_DIR/batch.txt" | tr '\n' ' ')"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$CL_DIR/clip.draw"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
cl_key KP_0
cl_read
if [[ "$A_COUNT" != 6 || -z "${PX:-}" || -z "${CP_PLACING:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}', CLIPP '${CP_PLACING:-}'"
else
    # -- the AnimBrush: frames 3-6 (selected in the strip), the 4x4 square --
    cl_strip 6; cl_strip 3 shift; cl_read
    cl_key m
    mouse_down "$(cl_px 6)" "$(cl_py 6)"; hover "$(cl_px 8)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 9)" "$(cl_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    cl_cmd "animbrush: pick up (the"; cl_read
    [[ "$AB_N" == 4 && "$AB_W" == 4 && "$AB_H" == 4 ]] && pass "an AnimBrush of 4 cels of 4x4" || fail "pick up: n $AB_N ${AB_W}x$AB_H"
    cl_key ctrl+d # no selection: the clicks below go to the frames
    cl_strip 2; cl_read

    # -- Place as Clip: click in frame 2 --
    cl_cmd "clip layer: place"; cl_read
    [[ "$CP_PLACING" == 1 ]] && pass "Place as Clip waits for a click" || fail "placing: $(cl_s)"
    click "$(cl_px 8)" "$(cl_py 8)"; wait_for 0.6 "placed"
    cl_read
    [[ "$CP_PLACING" == 0 && -n "$C_SLOT" && "$CP_CUR" != 0 && "$C_LINE" == "1 2 0 1 1 LOOP 0 0 6 6" ]] \
        && pass "placed: a clip layer, cel 1 in frame 2 at (6, 6) of the cell, to the end, LOOP" || fail "placed: $(cl_s)"
    [[ "$C_SRCS" == "1 4 4 4 "* ]] && pass "its source: 4 cels of 4x4, copied into the document" || fail "CLIPS [$C_SRCS]"
    [[ "$P_VIS" == -1 && "$PC_ON" == -1 ]] && pass "the Animation panel is open on the clip rows" || fail "panel visible '$P_VIS' clip rows '$PC_ON'"
    cl_expect ".12341" 6 6 0 "LOOP from frame 2: .12341, the cels' pixels in each frame"
    screenshot "clip-layers-placed"

    # -- modes (the menu / palette): one undo step each --
    cl_cmd "clip layer: mode ping";    cl_expect ".12343" 6 6 0 "PING: .12343"
    cl_cmd "clip layer: mode once";    cl_expect ".1234." 6 6 0 "ONCE: gone after the last cel"
    cl_cmd "clip layer: mode hold";    cl_expect ".12344" 6 6 0 "HOLD: stays on the last cel"
    cl_cmd "clip layer: mode reverse"; cl_expect ".14321" 6 6 0 "REV: .14321"
    cl_cmd "clip layer: mode loop";    cl_read
    [[ "$C_MODE" == LOOP ]] && pass "back to LOOP" || fail "loop: $(cl_s)"
    cl_key ctrl+z; cl_read
    [[ "$C_MODE" == REV && "$C_CELS" == ".14321" ]] && pass "Ctrl+Z: back to REV" || fail "undo mode: $(cl_s)"
    cl_key ctrl+y; cl_read
    [[ "$C_MODE" == LOOP ]] && pass "Ctrl+Y: LOOP again" || fail "redo mode: $(cl_s)"

    # -- the panel's boxes (rows 3 IN OUT, 4 START EVERY, 5 X Y; slots 2 and 3) --
    cl_set 3 2 3 C_IN;    cl_expect "..1234" 6 6 0 "IN 3 (typed): ..1234"
    cl_set 3 3 5 C_OUT;   cl_expect "..123." 6 6 0 "OUT 5: ..123."
    cl_set 4 3 2 C_EVERY; cl_expect "..112." 6 6 0 "EVERY 2: ..112."
    cl_set 4 2 2 C_START; cl_expect "..223." 6 6 0 "START 2: ..223."
    cl_set 5 2 2 C_PX;    cl_expect "..223." 2 6 0 "X 2: the clip at x 2 in every frame"
    cl_set 5 3 3 C_PY
    [[ "$C_PY" == 3 ]] && pass "Y 3" || fail "Y: $(cl_s)"
    cl_key ctrl+z; cl_expect "..223." 2 6 0 "Ctrl+Z: Y back to 6 (one step for a typed value)"

    # -- FLIP X: the chip, then the command --
    cl_tap 6 0 3; cl_expect "..223." 2 6 -1 "FLIP X (the panel chip): each cel mirrored"
    cl_cmd "clip layer: flip x"; cl_expect "..223." 2 6 0 "Flip X again (the command): back"

    # -- the paint tools are refused: the pixels stay --
    cl_strip 3; cl_read
    cl_key b
    click "$(cl_px 12)" "$(cl_py 12)"; wait_for 0.5 "paint"
    cl_expect "..223." 2 6 0 "the brush on a clip layer: refused, its pixels unchanged"

    # -- the Move tool drags the clip: every frame, one undo step --
    cl_key v; cl_read
    mouse_down "$(cl_px 3)" "$(cl_py 7)"; hover "$(cl_px 4)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 5)" "$(cl_py 9)"; sleep 0.3
    mouse_up; wait_for 0.8 "moved"
    cl_read
    [[ "$C_PX $C_PY" == "4 8" ]] && pass "Move: the clip went 2 right, 2 down (x 4, y 8)" || fail "move: $(cl_s)"
    cl_expect "..223." 4 8 0 "Move: its pixels moved in every frame"
    cl_key ctrl+z; cl_expect "..223." 2 6 0 "Ctrl+Z: the move undone"
    cl_key Right; cl_expect "..223." 3 6 0 "Right (the Move tool): the clip nudged 1 px in every frame"
    cl_key ctrl+z; cl_expect "..223." 2 6 0 "Ctrl+Z: the nudge undone"
    cl_key b

    # -- frame ops: the clip layer stays put, In / Out follow --
    cl_strip 1; cl_read
    cl_cmd "insert frame before"; cl_read
    [[ "$A_COUNT" == 7 && "$C_IN $C_OUT" == "4 6" ]] && pass "a frame inserted before frame 1: IN 4 OUT 6" || fail "insert before: $(cl_s)"
    cl_expect "...223." 2 6 0 "after the insert: ...223."
    cl_key ctrl+z; cl_read
    [[ "$A_COUNT" == 6 && "$C_IN $C_OUT" == "3 5" ]] && pass "Ctrl+Z: IN 3 OUT 5 again" || fail "undo insert: $(cl_s)"
    cl_strip 1; cl_cmd "delete frame"; cl_read
    [[ "$A_COUNT" == 5 && "$C_IN $C_OUT" == "2 4" ]] && pass "frame 1 deleted: IN 2 OUT 4" || fail "delete: $(cl_s)"
    cl_expect ".223." 2 6 0 "after the delete: .223."
    cl_key ctrl+z; cl_expect "..223." 2 6 0 "Ctrl+Z: the frame and the clip's place back"

    # -- Bake: a plain layer; undo brings the clip back --
    cl_cmd "clip layer: bake"; cl_read
    [[ -z "$C_SLOT" && "$CP_CUR" == 0 ]] && pass "Bake: no clip layer left" || fail "bake: $(cl_s)"
    cl_key ctrl+z; cl_expect "..223." 2 6 0 "Ctrl+Z: the clip is back"

    # -- save, reload --
    C_SAVED="$C_LINE|$C_CELS|$C_PIX"
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    [[ "$(python3 "$CL_PY" get "$CL_DIR/clip.draw" drCl)" != none ]] && pass "Ctrl+S writes the drCl chunk" || fail "no drCl chunk in the saved .draw"
    draw_quit
    draw_settle
    draw_launch 15
    wait_for 1.5 "Reloaded"
    assert_no_crash
    cl_read
    [[ "$C_LINE|$C_CELS|$C_PIX" == "$C_SAVED" ]] && pass "the reload has the same clip: [$C_LINE] $C_CELS" || fail "reload: [$C_LINE|$C_CELS|$C_PIX], saved [$C_SAVED]"

    # -- a fresh DRAW exports the frames with the clip in them --
    cl_batch "$CL_DIR/clip.draw" --export-anim "$CL_DIR/o/seq.png"
    px() { magick "$1" -format "%[hex:u.p{$2,$3}]" info: 2>/dev/null | cut -c1-8 | tr 'A-F' 'a-f'; }
    E3a=$(px "$CL_DIR/o/seq_0003.png" 2 6); E3b=$(px "$CL_DIR/o/seq_0003.png" 5 6); E6=$(px "$CL_DIR/o/seq_0006.png" 5 6)
    [[ "$E3a" == ffffffff && "$E3b" == "${CL_COLORS[3]}ff" && "$E6" != *ff ]] \
        && pass "the export: frame 3 has cel 2 at (2, 6), frame 6 (after OUT) has none" \
        || fail "export pixels: frame 3 (2,6) $E3a (5,6) $E3b want ffffffff ${CL_COLORS[3]}ff; frame 6 (5,6) $E6 want clear; $(tail -2 "$CL_DIR/batch.txt" | tr '\n' ' ')"
fi
rm -rf "$CL_DIR"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== Clip layers: done ==="
