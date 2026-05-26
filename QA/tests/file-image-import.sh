#!/bin/bash
# =============================================================================
# file-image-import.sh — QA test: Image Import
# Tests: Trigger import via command palette, cancel file dialog, verify no crash
# NOTE: native dialogs are unreliable to snap immediately after Escape; we
# verify the dialog cycle completes and DRAW remains responsive.
# =============================================================================

info "=== Image Import Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Trigger import via command palette --
info "Open Image Import"
key question
wait_for 0.5 "Command palette"
type_text "import image"
wait_for 0.3 "Filter"
key Return
wait_for 1.5 "Import dialog should appear (native file dialog)"
assert_no_crash

# -- Cancel the native file dialog --
key Escape
wait_for 1.5 "Import dialog cancelled (give it time to close)"
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify DRAW still responsive --
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Image Import Test PASSED ==="
