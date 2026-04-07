#!/bin/bash
# =============================================================================
# tool-cheatsheet.sh — QA test: Help / Cheat Sheet Overlay
# Tests: Open (H), scroll, close (Escape), reopen with F1
# =============================================================================

info "=== Cheatsheet / Help Overlay Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap center BEFORE opening help --
park_mouse
snap_region $(( CANVAS_CX - 100 )) $(( CANVAS_CY - 80 )) 200 160 "help-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open help overlay with H --
info "Open help overlay (H)"
key h
wait_for 0.5 "Help overlay opened"
assert_no_crash

# -- Snap center AFTER opening --
snap_region $(( CANVAS_CX - 100 )) $(( CANVAS_CY - 80 )) 200 160 "help-open"
HELP_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$HELP_OPEN" "Help overlay should appear"
screenshot "help-open"

# -- Scroll down --
info "Scroll help content"
key Down
wait_for 0.2 "Scroll down"
key Down
wait_for 0.2 "Scroll down"
key Down
wait_for 0.2 "Scroll down"
assert_no_crash

# -- Close with Escape --
info "Close help overlay (Escape)"
key Escape
wait_for 0.3 "Help closed"
assert_no_crash

# -- Verify closed --
park_mouse
snap_region $(( CANVAS_CX - 100 )) $(( CANVAS_CY - 80 )) 200 160 "help-closed"
HELP_CLOSED="$SNAP_RESULT"
assert_regions_differ "$HELP_OPEN" "$HELP_CLOSED" "Help overlay should disappear"

# -- Reopen with F1 --
info "Reopen help (F1)"
key F1
wait_for 0.5 "Help reopened"
assert_no_crash

snap_region $(( CANVAS_CX - 100 )) $(( CANVAS_CY - 80 )) 200 160 "help-reopen"
HELP_REOPEN="$SNAP_RESULT"
assert_regions_differ "$HELP_CLOSED" "$HELP_REOPEN" "Help should reopen with F1"

# -- Close again --
key Escape
wait_for 0.3 "Help closed again"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Cheatsheet / Help Overlay Test PASSED ==="
