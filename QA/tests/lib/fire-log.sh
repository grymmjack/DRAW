#!/bin/bash
# =============================================================================
# QA/tests/lib/fire-log.sh — assert a key dispatched a given ACTION id, via the
# central dispatcher's --developer FIRE log.
#
# When DRAW runs in developer mode it appends one line per dispatched binding to
# ./inputs.log: "[FIRE] evt=.. region=.. action=<id> label=..". This helper lets a
# behavioural test prove that pressing a key actually fired the central action —
# the end-to-end check that a SOURCE guard can't give — WITHOUT hand-rolling an
# Xvfb+xdotool driver (the harness already delivers real XTEST keypresses that
# SDL2/_KEYDOWN sees; --window/XSendEvent does NOT reach SDL2, which is why ad-hoc
# `xdotool key --window` scripts never fire).
#
# Requirements:
#   - Run the suite in developer mode so DRAW writes inputs.log:
#       DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-*.sh
#     (The DRAW adapter forwards DRAW_EXTRA_ARGS to the launch; DRAW is launched
#      with cwd = repo root, so inputs.log lands there.)
#   - Drive keys with the harness `key`/`type_text`, then assert.
#
# When inputs.log is absent (suite not in developer mode), the assert SKIPS with a
# clear message instead of failing — so the test is safe in a normal suite run and
# only becomes a hard check under DRAW_EXTRA_ARGS=--developer.
# =============================================================================

# Path to the FIRE log DRAW writes (repo root; adapter launches with that cwd).
_fire_log_path() {
    if [ -n "${DRAW_ROOT:-}" ] && [ -f "$DRAW_ROOT/inputs.log" ]; then
        echo "$DRAW_ROOT/inputs.log"; return
    fi
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/inputs.log"
}

# TRUE when the FIRE log exists (i.e. the suite is running in developer mode).
fire_log_available() { [ -f "$(_fire_log_path)" ]; }

# assert_action_fires <actionId> <human desc>
# PASS if the FIRE log contains a dispatch of that action id; SKIP (not fail) when
# the log is unavailable so the test is harmless outside developer mode.
assert_action_fires() {
    local id="$1" desc="$2" lg
    lg="$(_fire_log_path)"
    if [ ! -f "$lg" ]; then
        if declare -F warn >/dev/null; then warn "FIRE-log unavailable — run with DRAW_EXTRA_ARGS=--developer; SKIP: $desc"
        else echo "  SKIP (no inputs.log; need DRAW_EXTRA_ARGS=--developer): $desc"; fi
        return 0
    fi
    if grep -Eq "\[FIRE\].*action=$id([^0-9]|$)" "$lg"; then
        pass "dispatch: $desc (action=$id fired)"
    else
        fail "dispatch: $desc — action=$id NOT in FIRE log"
    fi
}
