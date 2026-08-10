#!/bin/bash
# =============================================================================
# ansi-import.sh — QA test: File > Import ANSI dispatch + dialog cycle
# Action ANS_ACT_IMPORT (2301) -> IMPORT_ansi, which opens a native file dialog
# then renders the chosen .ans onto a new document. Native file dialogs are
# unreliable to drive from xdotool (see file-image-import.sh), so this test
# verifies the command dispatches, the dialog cycle completes, and DRAW stays
# responsive — it does not drive the native picker.
#
# A committed sample for manual/interactive verification lives at:
#   QA/tests/fixtures/ansi-sample.ans
# Load it via File > Import ANSI... and confirm coloured half-blocks + text
# render onto a fresh canvas.
# =============================================================================

info "=== ANSI Import Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Trigger Import ANSI via the command palette --
info "Open Import ANSI (command palette)"
key question
wait_for 0.5 "Command palette"
type_text "import ansi"
wait_for 0.3 "Filter"
key Return
wait_for 1.5 "Import ANSI dialog should appear (native file dialog)"
assert_no_crash

# -- Cancel the native file dialog --
key Escape
wait_for 1.5 "Import dialog cancelled (give it time to close)"
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify DRAW still responsive after the dialog cycle --
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash

assert_no_crash
assert_window_exists
info "=== ANSI Import Test PASSED ==="
