#!/bin/bash
# =============================================================================
# anim-paste-in-place-key.sh — QA test: Paste in Place has a key, Ctrl+Alt+V,
# and Paste from OS Clipboard (Ctrl+Shift+V) no longer loses where the copy
# came from (field kit R-23, 2026-11-09: "It pastes it in the middle. not
# where it was copied from." - the kit said Ctrl+Shift+V, which is Paste from
# OS Clipboard: it centres the paste and overwrote the copy's origin, so a
# later Paste in Place landed at the pointer too).
#
# Copy a small off-centre part of frame 1 (frame 1's green block), go to
# frame 2, Ctrl+Shift+V (commit, undo), then Ctrl+Alt+V: frame 2 must hold the
# green block at the same spot, i.e. equal frame 3, which is made to hold just
# that. The old build had no Ctrl+Alt+V.
#
# Dump: ANIMC (a CRC per frame cell), ANIM, ANIMLB / ANIMLBP (panes).
# Fixture: a 64x16 sheet of 16x16 frames: frame 1 a red L (2,2)-(9,9) and a
# green block (6,3)-(7,4); frame 2 empty; frame 3 the green block alone;
# frame 4 empty.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Paste in Place: Ctrl+Alt+V, and Ctrl+Shift+V keeps the copy's origin ==="

PK_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
PK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
PK_DIR="/tmp/draw-qa-pastekey-$$"
mkdir -p "$PK_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$PK_DIR/a.png"
magick -size 16x16 xc:none -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$PK_DIR/g.png"
magick -size 16x16 xc:none "PNG32:$PK_DIR/e.png"
magick "$PK_DIR/a.png" "$PK_DIR/e.png" "$PK_DIR/g.png" "$PK_DIR/e.png" +append "PNG32:$PK_DIR/plain.png"
PK_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$PK_PY" put "$PK_DIR/plain.png" "$PK_DIR/sheet.png" drAn "$PK_BLOB"

pk_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
pk_line() { grep -m1 "^$1 " "$PK_DUMP" 2>/dev/null; }
pk_read() {
    pk_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(pk_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(pk_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN _ <<< "$(pk_line ANIMLB)"
    local p k; p=($(pk_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
pk_cells() { echo "${T[*]:1}"; }
pk_is() { local want=($1) k; for k in 1 2 3 4; do [[ "${T[$k]}" == "${T0[${want[$((k - 1))]}]}" ]] || return 1; done; }
pk_pick() { local n; pk_read; for (( n = 0; n < 5 && A_CUR != $1; n++ )); do pk_key KP_5; pk_read; done; }
pk_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
pk_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
pk_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
pk_palette() { park_mouse; key question; wait_for 1.0 "Command palette"; type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"; }

info "Launching DRAW with the 4-frame sheet"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$PK_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
pk_read
[[ "${LB_SHOWN:-}" == -1 ]] || { pk_key KP_0; pk_read; }
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 4 frames"
    # -- copy frame 1's green block (a marquee round it, clear of the red L) --
    pk_pick 1
    pk_key m; wait_for 0.4 "Marquee tool"
    hover "$(pk_px 5)" "$(pk_py 1)"; sleep 0.5
    mouse_down "$(pk_px 5)" "$(pk_py 1)"; sleep 0.2
    hover "$(pk_px 6)" "$(pk_py 2)"; sleep 0.2
    hover "$(pk_px 7)" "$(pk_py 4)"; sleep 0.2
    hover "$(pk_px 9)" "$(pk_py 6)"; sleep 0.5
    mouse_up; wait_for 0.8 "marquee released"
    pk_key ctrl+c
    pk_palette "deselect"
    pk_pick 2

    # -- Ctrl+Shift+V (Paste from OS Clipboard): centred - then undone --
    pk_key ctrl+shift+v
    pk_key Return; pk_palette "deselect"; pk_read
    PK_OS="$(pk_cells)"
    pk_key ctrl+z; pk_read
    pk_is "1 2 3 4" && pass "Ctrl+Shift+V pasted and was undone (cells after it: $PK_OS)" || fail "undo of Ctrl+Shift+V: cells $(pk_cells)"

    # -- Ctrl+Alt+V: where it was copied from, in frame 2 --
    pk_key ctrl+alt+v
    pk_key Return; pk_palette "deselect"; pk_read
    pk_is "1 3 3 4" && pass "Ctrl+Alt+V after Ctrl+Shift+V: frame 1's green block at the same spot in frame 2 (= frame 3)" \
        || fail "Ctrl+Alt+V in frame 2: cells $(pk_cells), wanted T0 frames 1 3 3 4 (T0 ${T0[*]:1})"
    pk_key ctrl+z; pk_read
    pk_is "1 2 3 4" || fail "undo the paste: cells $(pk_cells)"
fi
screenshot "anim-paste-in-place-key"
assert_no_crash
rm -rf "$PK_DIR"
