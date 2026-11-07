#!/bin/bash
# =============================================================================
# anim-frame-ops.sh — QA test: frame operations (TOOLS/ANIM-OPS).
#
# Animation 1.7 (PLANS/ANIMATION.md R-03 / R-04): add (Num +: a copy of the
# last frame; Shift+Num +: blank), insert before / after, duplicate, delete,
# move earlier / later, reverse. The sheet stays in play order - every op
# moves cell pixels on every layer - and adding past the last cell grows the
# canvas by a row. One undo step each.
#
# Where the drawings are comes from the QA dump line ANIMC: one token per
# frame, "0" = empty cell, else the CRC32 of the cell's pixels on all layers.
# Fixture: a 64x32 sheet of 16x16 frames, 7 frames (4 + 3), current 3, each
# cell with its own mark.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: frame operations ==="

FO_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
FO_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
FO_DIR="/tmp/draw-qa-frameops-$$"
mkdir -p "$FO_DIR"
FO_DRAW=()
FO_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do # frame n+1: a mark of its own colour and width
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    FO_DRAW+=(-fill "#${FO_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${FO_DRAW[@]}" "$FO_DIR/plain.png"
FO_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$FO_PY" put "$FO_DIR/plain.png" "$FO_DIR/sheet.png" drAn "$FO_BLOB"

fo_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
fo_line() { grep -m1 "^$1 " "$FO_DUMP" 2>/dev/null; }
fo_read() { # -> FO_COUNT FO_CUR FO_ROWS, FO_T (the ANIMC tokens)
    fo_settle
    read -r _ _ FO_COUNT FO_CUR _ _ _ _ _ FO_ROWS _ <<< "$(fo_line ANIM)"
    read -r _ FO_T <<< "$(fo_line ANIMC)"
}
fo_cmd() { # NAME - run a command through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "$1"
}
fo_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
fo_tok() { # N TOKENS... - token N
    local n=$1; shift; local a=($*); echo "${a[$((n - 1))]:-}"
}
fo_order() { # "3 1 0 ..." -> the baseline tokens in that order (0 = empty)
    local o="" k
    for k in $1; do [[ "$k" == 0 ]] && o+=" 0" || o+=" $(fo_tok "$k" $FO_BASE)"; done
    echo "${o# }"
}
fo_expect() { # COUNT CUR "ORDER" LABEL
    fo_read
    local want; want=$(fo_order "$3")
    if [[ "$FO_COUNT" == "$1" && "$FO_CUR" == "$2" && "$FO_T" == "$want" ]]; then
        pass "$4"
    else
        fail "$4: count $FO_COUNT current $FO_CUR frames [$FO_T], wanted $1 / $2 [$want]"
    fi
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3)"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$FO_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"

fo_read
FO_BASE="$FO_T"
FO_UNIQ=$(tr ' ' '\n' <<< "$FO_BASE" | grep -v '^0$' | sort -u | wc -l)
info "frames: $FO_BASE"
[[ "$FO_COUNT" == 7 && "$FO_CUR" == 3 && "$FO_UNIQ" == 7 ]] && pass "7 frames, current 3, each its own drawing" \
    || fail "fixture: count $FO_COUNT current $FO_CUR, $FO_UNIQ distinct cells (wanted 7 / 3 / 7)"

if [[ "$FO_UNIQ" == 7 ]]; then
    # -- add: Num + (copy of the last), past the last cell the sheet grows --
    fo_key KP_Add
    fo_expect 8 8 "1 2 3 4 5 6 7 7" "Num +: a copy of the last frame, now current"
    [[ "$FO_ROWS" == 2 ]] && pass "8 frames still fit two rows" || fail "rows $FO_ROWS after 8 frames, wanted 2"
    fo_key KP_Add
    fo_expect 9 9 "1 2 3 4 5 6 7 7 7" "Num + past the last cell"
    [[ "$FO_ROWS" == 3 ]] && pass "the sheet grew a row (3 rows)" || fail "rows $FO_ROWS after 9 frames, wanted 3"
    fo_key ctrl+z
    fo_expect 8 8 "1 2 3 4 5 6 7 7" "undo: the grown row goes again"
    fo_read; [[ "$FO_ROWS" == 2 ]] && pass "undo: two rows" || fail "rows $FO_ROWS after undo, wanted 2"
    fo_key ctrl+z
    fo_expect 7 3 "1 2 3 4 5 6 7" "undo again: back to the start, current 3"
    fo_key ctrl+y
    fo_expect 8 8 "1 2 3 4 5 6 7 7" "redo"
    fo_key ctrl+z

    fo_key shift+KP_Add
    fo_expect 8 8 "1 2 3 4 5 6 7 0" "Shift+Num +: a blank frame"
    fo_key ctrl+z

    # -- the ANIM menu's frame operations (through the command palette) --
    fo_cmd "duplicate frame"
    fo_expect 8 4 "1 2 3 3 4 5 6 7" "Duplicate Frame: a copy after the current"
    fo_cmd "delete frame"
    fo_expect 7 4 "1 2 3 4 5 6 7" "Delete Frame: the copy goes, the rest close up"
    fo_cmd "insert frame before"
    fo_expect 8 4 "1 2 3 0 4 5 6 7" "Insert Frame Before: a blank before the current"
    fo_cmd "insert frame after"
    fo_expect 9 5 "1 2 3 0 0 4 5 6 7" "Insert Frame After: a blank after it"
    fo_key ctrl+z
    fo_key ctrl+z
    fo_expect 7 4 "1 2 3 4 5 6 7" "two undos: the blanks go (current 4, as after Delete)"
    fo_cmd "move frame later"
    fo_expect 7 5 "1 2 3 5 4 6 7" "Move Frame Later"
    fo_cmd "move frame earlier"
    fo_expect 7 4 "1 2 3 4 5 6 7" "Move Frame Earlier: back"
    fo_cmd "first frame"; fo_cmd "next frame"
    fo_cmd "reverse frames"
    fo_expect 7 6 "7 6 5 4 3 2 1" "Reverse Frames (current follows its frame: 2 -> 6)"
    fo_key ctrl+z
    fo_expect 7 2 "1 2 3 4 5 6 7" "undo Reverse"

    # -- every layer moves: a second layer (a copy) --
    fo_cmd "duplicate layer"
    fo_read; FO_BASE="$FO_T"
    FO_UNIQ=$(tr ' ' '\n' <<< "$FO_BASE" | sort -u | wc -l)
    [[ "$FO_UNIQ" == 7 ]] && info "two layers: $FO_BASE" || fail "two layers: $FO_UNIQ distinct cells"
    fo_cmd "reverse frames"
    fo_expect 7 6 "7 6 5 4 3 2 1" "two layers: Reverse moves both"
    fo_key ctrl+z
    fo_expect 7 2 "1 2 3 4 5 6 7" "two layers: undo"
    fo_cmd "next frame"

    # -- the Animation panel's ADD / DUP / INS / DEL --
    fo_cmd "animation panel"
    fo_settle
    read -r _ P_VIS _ P_X P_Y _ _ P_SC _ <<< "$(fo_line ANIMP)"
    read -r _ _ _ _ _ _ _ _ _ L_RH _ _ _ L_PAD L_PW L_OPS <<< "$(fo_line ANIMPL)"
    if [[ "$P_VIS" == -1 && -n "${L_OPS:-}" ]]; then
        fo_chip() { # K (0 ADD, 1 DUP, 2 INS, 3 DEL)
            local cw=$(( (L_PW - 2 * L_PAD - 6) / 4 ))
            click $(( P_X + (L_PAD + $1 * (cw + 2) + cw / 2) * P_SC / 100 )) $(( P_Y + (L_OPS + L_RH / 2) * P_SC / 100 ))
            wait_for 0.5 "chip $1"
        }
        fo_chip 3; fo_expect 6 3 "1 2 4 5 6 7" "panel DEL"
        fo_chip 1; fo_expect 7 4 "1 2 4 4 5 6 7" "panel DUP"
        fo_chip 2; fo_expect 8 5 "1 2 4 4 0 5 6 7" "panel INS: a blank after the current"
        fo_chip 0; fo_expect 9 9 "1 2 4 4 0 5 6 7 7" "panel ADD"
        fo_key ctrl+z; fo_key ctrl+z; fo_key ctrl+z; fo_key ctrl+z
        fo_expect 7 3 "1 2 3 4 5 6 7" "four undos: back to the start"
    else
        fail "the Animation panel did not open (visible=$P_VIS)"
    fi

    # -- refusals: the only frame can't go --
    for k in 1 2 3 4 5 6; do fo_cmd "delete frame"; done
    fo_read
    [[ "$FO_COUNT" == 1 ]] && pass "six deletes leave one frame" || fail "six deletes: count $FO_COUNT, wanted 1"
    fo_cmd "delete frame"
    fo_read
    [[ "$FO_COUNT" == 1 ]] && pass "the only frame can't be deleted" || fail "the last frame was deleted (count $FO_COUNT)"
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$FO_DIR"
assert_window_exists
