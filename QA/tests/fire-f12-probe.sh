#!/bin/bash
# =============================================================================
# fire-f12-probe.sh — PROBE: does pressing F12 dispatch through central dispatch?
#
# The F12 keycode is a known variant landmine: the legacy custom-brush export
# handler (INPUT/KEYBOARD.BM) uses _KEYDOWN(34304), while the registry binds F12
# at keycode 28416 -> action 9999 (a dev-mode "proof of concept"). Since the
# toolchain moved SDL2 -> GLFW, F12's real keycode may have changed, so this
# CANNOT be assumed — it must be probed on the current build.
#
# This probe presses F12 (no custom brush loaded) and reports whether action 9999
# fired. It is DIAGNOSTIC: it does not fail the suite either way — it prints the
# verdict so the F12 migration can use the RIGHT keycode instead of guessing.
#
# Run:  DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-f12-probe.sh
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/fire-log.sh"

info "=== F12 keycode probe (central dispatch) ==="
canvas_focus b
wait_for 0.4 "canvas focused"

info "Press F12"
key F12
wait_for 0.4 "dispatch F12"

LG="$(_fire_log_path)"
if [ -f "$LG" ]; then
    if grep -Eq "\[FIRE\].*action=9999" "$LG"; then
        info "VERDICT: F12 -> action=9999 FIRED — registry keycode 28416 is CORRECT for this build."
    else
        info "VERDICT: F12 did NOT fire action=9999 — registry keycode 28416 is WRONG for this build."
        info "  Any FIRE lines around the F12 press:"
        grep -E "\[FIRE\]" "$LG" | tail -5 | sed 's/^/    /'
    fi
    info "  (full inputs.log at $LG)"
else
    info "inputs.log absent — run with DRAW_EXTRA_ARGS=--developer"
fi

assert_no_crash
info "=== F12 probe done ==="
