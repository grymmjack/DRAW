#!/bin/bash
# =============================================================================
# text-tdf-edit-keys.sh — QA test: editing TheDraw (TDF) text with the arrows
# and Delete (Rick 2026-11-16: "using arrows to go forward, and pressing
# delete, then trying to use arrows again - it's not updating and the cursor
# can't go forward"). Not reproduced with synthetic keys (2026-11-17); this
# pins the behaviour the report expects, read from the TXTED dump line:
#   TXTED <text data> <cursorPos> <charCount> <cursor x> <cursor y> <TDF at cursor> [text]
#   - typed in a TDF face: the text and the cursor at the end
#   - Home, Right, Right: the cursor walks forward, its x grows
#   - Delete: the character after the cursor goes, the cursor stays
#   - Right after the Delete: the cursor moves forward again, x grows
#   - Left, Delete, Right: the same mid-word; a held Right auto-repeats
# A 1600x600 canvas so the text is one line (320x200 fits two TDF glyphs).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEFAULT_CANVAS_SIZE_W=1600 DEFAULT_CANVAS_SIZE_H=600 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
D="$DRAW_ROOT/QA/.dock-dump.txt"
txted() { # read the TXTED line after a fresh dump
    hover 500 400; sleep 0.15; hover 502 401; sleep 0.35
    read -r _ T_TD T_POS T_CNT T_X T_Y T_TDF T_TXT <<< "$(grep -m1 '^TXTED ' "$D")"
    info "$1: pos=$T_POS count=$T_CNT x=$T_X tdf=$T_TDF $T_TXT"
}

info "=== Text tool: TDF text, arrows + Delete ==="
canvas_focus b; wait_for 0.3 "brush"
park_mouse; key question; wait_for 1.0 "palette"; type_text "Browse TheDraw"; wait_for 0.6 "filtered"
key Return; wait_for 2.5 "TDF browser"
key Return; wait_for 1.0 "a TDF face picked"
key t; wait_for 0.5 "text tool"
click 200 120; wait_for 0.5 "text start"
type_text "ABCDEFGH"; wait_for 0.6 "typed"
txted "typed"
if [[ -z "$T_POS" ]]; then fail "no TXTED line - the text tool did not start"; assert_no_crash; exit 0; fi
[[ "$T_TDF" == 1 ]] && pass "the text is in a TDF face" || fail "TXTED says the face at the cursor is not TDF ($T_TDF)"
[[ "$T_POS" == 8 && "$T_CNT" == 8 && "$T_TXT" == "[ABCDEFGH]" ]] && pass "typed 8 characters, the cursor at the end" || fail "after typing: pos $T_POS count $T_CNT $T_TXT"

key Home; wait_for 0.3 "Home"; txted "home"; X0=$T_X
[[ "$T_POS" == 0 ]] && pass "Home: the cursor at the start" || fail "Home: pos $T_POS"
key Right; wait_for 0.3 "Right"; txted "right1"; X1=$T_X
key Right; wait_for 0.3 "Right"; txted "right2"; X2=$T_X
(( T_POS == 2 && X0 < X1 && X1 < X2 )) && pass "Right, Right: the cursor walks forward ($X0 -> $X1 -> $X2)" || fail "Right x2: pos $T_POS x $X0 $X1 $X2"

key Delete; wait_for 0.4 "Delete"; txted "delete"
[[ "$T_POS" == 2 && "$T_CNT" == 7 && "$T_TXT" == "[ABDEFGH]" && "$T_X" == "$X2" ]] && pass "Delete takes the C, the cursor stays" || fail "Delete: pos $T_POS count $T_CNT x $T_X $T_TXT"
key Right; wait_for 0.3 "Right"; txted "right3"; X3=$T_X
key Right; wait_for 0.3 "Right"; txted "right4"; X4=$T_X
(( T_POS == 4 && X2 < X3 && X3 < X4 )) && pass "after Delete the arrows still move the cursor forward ($X2 -> $X3 -> $X4)" || fail "after Delete: pos $T_POS x $X2 $X3 $X4"
screenshot "text-tdf-after-delete"

key Left; wait_for 0.3 "Left"; txted "left"
key Delete; wait_for 0.4 "Delete"; txted "delete2"
[[ "$T_POS" == 3 && "$T_TXT" == "[ABDFGH]" ]] && pass "Left, Delete mid-word takes the E" || fail "Left, Delete: pos $T_POS $T_TXT"
key Right; wait_for 0.3 "Right"; txted "right5"
[[ "$T_POS" == 4 ]] && pass "and Right moves on again" || fail "Right after the second Delete: pos $T_POS"
key Home; wait_for 0.3 "Home"
raw_key down Right; sleep 0.8; raw_key up Right; wait_for 0.4 "held Right"; txted "held"
(( T_POS >= 4 )) && pass "a held Right auto-repeats (pos $T_POS)" || fail "held Right: pos $T_POS"
key Escape; wait_for 0.5 "text done"
assert_no_crash
info "=== TDF text editing done ==="
