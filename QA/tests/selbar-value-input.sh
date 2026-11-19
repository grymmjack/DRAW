#!/bin/bash
# =============================================================================
# selbar-value-input.sh — QA test: the universal value input on a Selection Bar slider
# (Rick 2026-11-18: "all places that can take a slider or value need to be adjustible
# with the mousewheel - +/-1 and if shift held +/-10 as well as middle click and double
# click on slider to reset - middle click on value box to reset, double click to edit").
# FEATHER (SBC_FEATHER = 5) starts at 3; its factory default is 0.
#   1. the wheel up: 4; Shift + the wheel up: 14
#   2. a middle-click on the track: 0 (the factory default)
#   3. a click on the track then a double-click: back to 0
#   4. a double-click on the value: a number box - 7 typed
#   5. a middle-click on the value: 0
# Dump: SELBAR vis x y w h lines mode feather ...; SELBARC id x y w tx.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE SELECTION_FEATHER=3
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
sb_feather() { dk_settle; read -r _ _ _ _ _ _ _ _ F _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; echo "$F"; }
sb_xy() { read -r _ _ C_X C_Y C_W C_TX <<< "$(grep -m1 '^SELBARC 5 ' "$DK_DUMP")"; TX=$(( C_TX + 22 )); TY=$(( C_Y + ROW_H / 2 )); VX=$(( C_TX + 44 + 6 )); }

info "=== Selection Bar: wheel / middle / double-click on FEATHER ==="
dk_begin
canvas_focus m; wait_for 0.6 "marquee: the bar shows"; dk_settle
sb_xy
[[ -n "$C_TX" ]] && pass "the Selection Bar shows FEATHER (track at $C_TX,$C_Y)" || { fail "no FEATHER control in the dump"; assert_no_crash; return 0 2>/dev/null || exit 0; }
F0=$(sb_feather)
(( F0 == 3 )) && pass "FEATHER starts at 3" || fail "FEATHER starts at '$F0' (want 3)"

scroll_up "$TX" "$TY"; wait_for 0.4 "wheel up"
F1=$(sb_feather)
(( F1 == 4 )) && pass "the wheel up: +1 ($F1)" || fail "wheel up: $F1 (want 4)"
shift_scroll_up "$TX" "$TY"; wait_for 0.4 "shift wheel up"
F2=$(sb_feather)
(( F2 == 14 )) && pass "Shift + the wheel up: +10 ($F2)" || fail "shift wheel up: $F2 (want 14)"

middle_click "$TX" "$TY"; wait_for 0.4 "middle click"
F3=$(sb_feather)
(( F3 == 0 )) && pass "a middle-click on the track: the factory default 0" || fail "middle-click: $F3 (want 0)"

click $(( C_TX + 30 )) "$TY"; wait_for 0.5 "click the track"
F4=$(sb_feather)
(( F4 > 0 )) && pass "a click on the track sets it ($F4)" || fail "click on the track: $F4"
sleep 0.5
double_click $(( C_TX + 30 )) "$TY"; wait_for 0.5 "double-click the track"
F5=$(sb_feather)
(( F5 == 0 )) && pass "a double-click on the track resets it" || fail "double-click on the track: $F5 (want 0)"

double_click "$VX" "$TY"; wait_for 1.0 "the number box"
key ctrl+a; type_text "7"; key Return; wait_for 0.8 "typed"
dk_park
F6=$(sb_feather)
(( F6 == 7 )) && pass "a double-click on the value typed 7" || fail "after typing: '$F6' (want 7)"
screenshot "selbar-value-typed"

middle_click "$VX" "$TY"; wait_for 0.4 "middle click the value"
F7=$(sb_feather)
(( F7 == 0 )) && pass "a middle-click on the value resets it" || fail "middle-click on the value: $F7 (want 0)"
assert_no_crash
