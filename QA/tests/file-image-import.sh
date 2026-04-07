#!/bin/bash
# =============================================================================
# file-image-import.sh — QA test: Image Import
# Tests: Trigger import via command palette, cancel file dialog, verify no crash
# NOTE: Actual import requires file selection; this tests the dialog pipeline.
# =============================================================================

info "=== Image Import Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas BEFORE import --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "import-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Trigger import via command palette --
info "Open Image Import"
key question
wait_for 0.5 "Command palette"
type_text "import image"
wait_for 0.3 "Filter"
key Return
wait_for 1.0 "Import dialog should appear"
assert_no_crash

# -- Cancel the native file dialog --
key Escape
wait_for 0.5 "Import dialog cancelled"
assert_no_crash

# -- Verify canvas unchanged after cancel --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "import-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_CANCEL" "Cancel import should not change canvas"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Image Import Test PASSED ==="
