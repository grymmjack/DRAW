#!/bin/bash
# =============================================================================
# qa-no-os-tools-in-tests.sh — source guard: DRAW's QA tests and libraries never
# call an OS input / window tool directly (xdotool today; cliclick, AutoHotkey…
# on other platforms). Everything goes through the harness's driver - raw_move,
# raw_button, raw_key, raw_seq, raw_move_in_window, app_window_title - so the
# same tests can run on macOS and Windows drivers (PLANS/_/QA-HARNESS-CROSS-
# PLATFORM-PLAN.md). Comments may mention the tools. cli-smoke.sh is a
# standalone Linux CLI check outside the harness and is exempt.
# =============================================================================
info "=== No OS tools in tests ==="
hits=$(grep -nE '\b(xdotool|xwininfo|xprop|wmctrl|cliclick)\b' "$DRAW_ROOT"/QA/tests/*.sh "$DRAW_ROOT"/QA/*-lib.sh 2>/dev/null \
       | grep -vE '^[^:]+:[0-9]+:\s*#' | grep -v 'qa-no-os-tools-in-tests.sh' | grep -vE '#.*\b(xdotool|xwininfo|xprop|wmctrl|cliclick)\b' )
if [[ -z "$hits" ]]; then
    pass "no test or QA library calls an OS input / window tool directly"
else
    fail "OS tool calls outside the driver: $(head -3 <<< "$hits" | tr '\n' ' ')"
fi
