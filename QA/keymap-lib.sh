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
# km_begin: the preset was seeded and the log is there; 1 = stop the test.
# Seeding needs the adapter's per-test config folder, which only Linux has (macOS
# and Windows read their own folders): there the test SKIPS instead of pressing
# every key against the machine's own keymap (59 failures on the Mac, 2026-11-15).
km_begin() {
    km_seeded || return 1
    [[ -f "$KM_LOG" ]] || { fail "no inputs.log (DEVELOPER_MODE=TRUE did not take)"; return 1; }
}
# km_seeded: pass / skip / fail on the seeded DRAW.bindings; 1 = stop the test
km_seeded() {
    if [[ -z "${QA_CONFIG_DIR:-}" ]]; then
        skip "no per-test config folder on $(uname -s) - a keymap can't be seeded, so nothing here is tested"
        return 1
    fi
    if [[ -f "$QA_CONFIG_DIR/DRAW.bindings" ]]; then
        pass "the test's own config, keymap seeded ($(grep -cvE '^\s*(#|$)' "$QA_CONFIG_DIR/DRAW.bindings") rows)"
    else
        fail "no seeded DRAW.bindings in $QA_CONFIG_DIR (QA-BINDINGS line?)"; return 1
    fi
}
