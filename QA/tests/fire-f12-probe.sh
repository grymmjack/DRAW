#!/bin/bash
# =============================================================================
# fire-f12-probe.sh — BEHAVIOURAL: F12 dispatches through central dispatch.
#
# After the Phase 2A F12 migration, F12 (keycode 34304 — GLFW-probed; the old
# registry 28416 never fired) dispatches:
#   - no custom brush  -> action 9999 (dev-mode debug dump)
#   - custom brush ON   -> action 1110 (Export Brush PNG)  [not exercised here:
#                          needs a loaded custom brush + drives a save dialog]
#
# This test presses F12 with NO custom brush and asserts action 9999 fired — the
# end-to-end proof that the corrected keycode dispatches. (Before the migration
# this FIRED NOTHING, because the binding sat on the wrong keycode 28416.)
#
# Run:  DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-f12-probe.sh
# Skips harmlessly without developer mode.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/fire-log.sh"

info "=== F12 central-dispatch behavioural test ==="
canvas_focus b
wait_for 0.4 "canvas focused (no custom brush)"

info "Press F12 (no custom brush -> dev-dump 9999)"
key F12
wait_for 0.4 "dispatch F12"

assert_action_fires 9999 "F12 (no brush) = dev debug dump"

assert_no_crash
info "=== F12 behavioural test done ==="
