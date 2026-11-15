#!/bin/bash
# keymap-lib.sh — helpers for keymap-preset GUI tests (QA/tests/keymap-*.sh).
# Needs DEVELOPER_MODE=TRUE in the test's QA-OPTIONS (the dispatcher logs
# "[FIRE] ... action=N" to ./inputs.log) and a QA-BINDINGS line for the preset.
KM_LOG="$DRAW_ROOT/inputs.log"
# km_fired KEY: press KEY (xdotool name); KM_FIRED = the action ids that fired
km_fired() {
    local n; n=$(wc -l < "$KM_LOG" 2>/dev/null || echo 0)
    key "$1"; wait_for 0.35 "$1"
    KM_FIRED=" $(tail -n +$(( n + 1 )) "$KM_LOG" 2>/dev/null | grep -o 'action=[0-9]*' | cut -d= -f2 | tr '\n' ' ')"
}
# km_want KEY ID [NOT_ID...] "what": KEY fires ID and none of the NOT_IDs
km_want() {
    local k=$1 id=$2; shift 2
    local desc="${*: -1}" bad="" x
    km_fired "$k"
    for x in "${@:1:$#-1}"; do [[ "$KM_FIRED " == *" $x "* ]] && bad+=" $x"; done
    if [[ "$KM_FIRED " == *" $id "* && -z "$bad" ]]; then pass "$k -> $desc ($id)"
    else fail "$k: want $id ($desc), fired [$KM_FIRED ]${bad:+, not wanted:$bad}"; fi
}
# km_begin: the preset was seeded and the log is there
km_begin() {
    [[ -f "$KM_LOG" ]] || { fail "no inputs.log (DEVELOPER_MODE=TRUE did not take)"; return 1; }
    [[ -n "${QA_CONFIG_DIR:-}" && -f "$QA_CONFIG_DIR/DRAW.bindings" ]] \
        && pass "the test's own config, keymap seeded ($(grep -cvE '^\s*(#|$)' "$QA_CONFIG_DIR/DRAW.bindings") rows)" \
        || fail "no seeded DRAW.bindings (QA_CONFIG_DIR '${QA_CONFIG_DIR:-}')"
}
