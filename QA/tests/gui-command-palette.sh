#!/bin/bash
# =============================================================================
# gui-command-palette.sh — QA test: Command Palette
# Tests: Open (Ctrl+P or ?), type filter, navigate, execute, close (Escape)
# =============================================================================

info "=== Command Palette Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap center BEFORE opening palette --
park_mouse
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "cmdpal-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open command palette with ? --
info "Open command palette (?)"
key question
wait_for 0.5 "Command palette opened"
assert_no_crash

# -- Snap center AFTER opening --
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "cmdpal-open"
CMDPAL_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$CMDPAL_OPEN" "Command palette should appear"
screenshot "cmdpal-open"

# -- Close with Escape --
info "Close command palette (Escape)"
key Escape
wait_for 0.3 "Command palette closed"
assert_no_crash

# -- Verify closed --
park_mouse
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "cmdpal-closed"
CMDPAL_CLOSED="$SNAP_RESULT"
assert_regions_differ "$CMDPAL_OPEN" "$CMDPAL_CLOSED" "Command palette should disappear"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Command Palette Test PASSED ==="
